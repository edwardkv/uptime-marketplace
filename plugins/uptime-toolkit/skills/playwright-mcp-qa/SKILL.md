---
name: playwright-mcp-qa
description: Verify completed uptime-app UI and user-flow changes in a real browser with Playwright MCP, covering visual layout and functional behavior before reporting completion.
metadata:
  short-description: Verify UI changes with Playwright MCP
---

# Playwright MCP QA for uptime-app

Use this skill after implementing any change that can affect the frontend, rendered markup, styles, navigation, forms, authentication, API-backed UI behavior, or another browser-visible user flow. The verification is mandatory for those changes; do not claim the task is complete based only on linting, unit tests, or code inspection.

## Required workflow

1. Establish the browser target:
   - Use the Playwright MCP tools (`mcp__playwright__browser_*`) for all browser interaction.
   - Prefer the project's running local frontend, normally `http://localhost:3000`; inspect repository instructions or the actual dev-server output if the port differs.
   - If the required app is not running, start it using the repository's documented command when that is in scope. If it cannot be started, report the verification as blocked instead of implying it passed.
2. Identify the changed user-visible behavior from the diff and choose the smallest meaningful end-to-end scenario that exercises it. Include the relevant happy path and at least one changed validation, error, empty, loading, or navigation state when applicable.
3. Verify functionality with Playwright MCP:
   - Navigate with `browser_navigate` and inspect the accessibility tree with `browser_snapshot`.
   - Use stable snapshot references or accessible roles/names for clicks and form input; do not invent selectors when the snapshot provides a target.
   - Exercise the flow with the appropriate click, fill, type, select, keyboard, dialog, and wait tools.
   - Confirm the resulting URL, visible feedback, persisted state, and any relevant API-backed result.
4. Verify layout and responsive behavior:
   - Take a screenshot with `browser_take_screenshot` at the primary viewport and visually inspect it for clipping, overlap, broken spacing, unreadable text, missing controls, and unexpected overflow.
   - Resize to at least one additional relevant viewport (desktop and mobile for responsive UI) and repeat the snapshot/screenshot check when the change can affect responsive layout.
   - Use the accessibility snapshot to confirm headings, labels, buttons, links, and form controls remain discoverable and correctly named.
5. Check the browser console for new errors with `browser_console_messages`. Treat errors introduced by the change as a failed verification unless they are demonstrably unrelated and documented.
6. Report the result with:
   - the route and user scenario tested,
   - viewport(s) checked,
   - functional outcome,
   - layout/accessibility outcome,
   - console result,
   - any limitation or blocked step.

## Boundaries

- This skill verifies behavior; it does not replace unit, integration, lint, or build checks.
- Do not create real external accounts, send messages, purchase anything, or mutate production data during verification. Use local/test data and stop before CAPTCHA, email confirmation, payment, or other external confirmation steps.
- Never use screenshots as the source of element references for actions; use `browser_snapshot` and accessible targets for interaction.
- If a failure is found, fix it when the user requested implementation, then rerun the affected browser scenario and the relevant layout checks.
