# Evidence for a cloud-delivered change

Prepare an acceptance-to-proof record before implementation and fill it with actual outcomes as
work progresses. Keep runtime evidence outside the checkout unless the task intentionally adds
a test fixture or documentation artifact. Do not commit conversation journals or credentials.

## Identity and environment

- Task key and actual cloud task ID if provided; source thread/issue and current fork PR.
- Final full head SHA, base branch, and whether any behavior was checked only before committing.
- Current environment identity and observation time, actual Node/Yarn/browser/runner versions,
  lockfile identity when useful, and services/configuration exercised.
- Current-instance validation versus actual fresh-task restoration, remote integration, or
  production validation. State each only when it was directly verified.

Checks performed before committing can support the final commit when the relevant verified files
exactly match its tree; record that mapping. Do not repeat unchanged checks merely because a
commit was created. Refresh affected proof after a behavior change, and always match remote CI
results to the current PR head.

## Acceptance-to-proof mapping

| Criterion                                   | Check or artifact                                               | Actual outcome                             | Head SHA             | Material limit                                 |
| ------------------------------------------- | --------------------------------------------------------------- | ------------------------------------------ | -------------------- | ---------------------------------------------- |
| Describe an observable acceptance criterion | Exact test name/command, functional request, or visual workflow | Passed, failed, skipped, pending, or unrun | SHA actually checked | Missing integration, unsupported mode, or none |

Use meaningful assertions and negative/boundary cases rather than a successful process start,
open port, generic screenshot, or zero-test command. Distinguish application bugs from setup,
permissions, secrets, and runner failures. Preserve the underlying command exit status.

For shared-database tests, preserve/restore the developer's file and run mutating suites serially.
For runtime setup changes, exercise the saved commands and test repeatability where files change.
Do not broaden validation after sufficient checks pass unless a new change or unresolved concern
justifies it.

## Visual artifacts

For UI changes, show the affected workflow and the result that supports the claim. Use a unique
run directory under `/workspace/artifacts/`, note the exact head, and inspect screenshots/video.
Require a decodable, nonempty video with the expected UI; a file's existence alone is insufficient.

The prepared helper commands are:

```bash
source /workspace/.tools/rwa-env.sh
node /workspace/.tools/rwa-playwright.cjs --screenshot
node /workspace/.tools/rwa-playwright.cjs --record
```

These helpers verify the example sign-in/sign-up routes. For a different engineering task, drive
and assert its actual changed workflow with available MCP tools or an authorized focused helper;
do not call the example demo feature-specific proof. The MP4 mode uses system FFmpeg to record an
MCP-controlled browser. Native MCP WebM recording is a separate capability.

Before sharing, inspect artifacts/log excerpts for unintended sensitive data. A local artifact
path can be opened in the current task, but does not prove the Slack recipient can access it.
Upload or link via a supported authorized destination and retain its successful attachment/link
result. If uploads are unsupported, report that delivery gap rather than inventing a public URL.

## Before the final thread reply

- Verify PR repository/base and current pushed head.
- Match CI results and material tests to that head; refresh stale proof after a relevant fix.
- State which acceptance criteria are supported and which remain blocked/unverified.
- Check that all provided PR/artifact URLs exist and are intended for the customer's audience.
- Reconfirm original channel/thread and prior updates; avoid a duplicate post.
- Verify Slack's send/upload result before marking delivery complete.
