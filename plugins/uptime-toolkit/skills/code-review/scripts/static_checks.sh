#!/usr/bin/env bash
set -uo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../../../.." && pwd)"

declare -a changed_files=()
all_stacks=0

while (($# > 0)); do
  case "$1" in
    --all)
      all_stacks=1
      shift
      ;;
    --changed-files)
      shift
      while (($# > 0)) && [[ "$1" != --* ]]; do
        changed_files+=("$1")
        shift
      done
      ;;
    -h|--help)
      printf 'Usage: %s [--all] [--changed-files PATH... ]\n' "$0"
      exit 0
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

if ((${#changed_files[@]} == 0)) && ((all_stacks == 0)); then
  all_stacks=1
fi

has_backend=0
has_frontend=0
if ((all_stacks)); then
  has_backend=1
  has_frontend=1
else
  for path in "${changed_files[@]}"; do
    case "$path" in
      backend/*) has_backend=1 ;;
      frontend/*) has_frontend=1 ;;
    esac
  done
fi

status=0
run_check() {
  local label="$1"
  shift
  printf '\n==> %s\n' "$label"
  if ! "$@"; then
    status=1
    printf 'FAILED: %s\n' "$label" >&2
  fi
}

if ((has_backend)); then
  if ! command -v go >/dev/null 2>&1; then
    printf 'SKIPPED: Go checks require the go executable\n' >&2
    status=1
  else
    backend_go_files=()
    if ((${#changed_files[@]} > 0)) && ((all_stacks == 0)); then
      for path in "${changed_files[@]}"; do
        [[ "$path" == backend/*.go ]] && backend_go_files+=("$repo_root/$path")
      done
    else
      while IFS= read -r path; do backend_go_files+=("$repo_root/backend/$path"); done < <(cd "$repo_root/backend" && find . -name '*.go' -type f -print | sed 's#^./##')
    fi
    if ((${#backend_go_files[@]} > 0)); then
      run_check 'gofmt (changed Go files)' gofmt -l "${backend_go_files[@]}"
      if [[ -n "$(gofmt -l "${backend_go_files[@]}" 2>/dev/null)" ]]; then status=1; fi
    fi
    run_check 'go vet ./...' bash -c 'cd "$1" && go vet ./...' _ "$repo_root/backend"
    run_check 'go test ./...' bash -c 'cd "$1" && go test ./...' _ "$repo_root/backend"
  fi
fi

if ((has_frontend)); then
  if ! command -v npm >/dev/null 2>&1; then
    printf 'SKIPPED: Next.js checks require npm\n' >&2
    status=1
  elif [[ ! -d "$repo_root/frontend/node_modules" ]]; then
    printf 'SKIPPED: frontend/node_modules is missing; install from package-lock.json first\n' >&2
    status=1
  else
    run_check 'npm run lint' bash -c 'cd "$1" && npm run lint' _ "$repo_root/frontend"
    run_check 'TypeScript noEmit' bash -c 'cd "$1" && npm exec -- tsc --noEmit' _ "$repo_root/frontend"
  fi
fi

if ((has_backend == 0 && has_frontend == 0)); then
  printf 'No backend or frontend paths were selected; no stack checks run.\n'
fi

exit "$status"
