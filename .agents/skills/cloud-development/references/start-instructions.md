Use the existing checkout of `jr-coa/cypress-realworld-app-demo`, branch `develop` or the task's
authorized feature branch. Each cloud task is already isolated; do not create a Git worktree
unless the user explicitly requests one. Preserve unrelated changes, credentials, custom auth
configuration, and database contents. Push only to the user's fork when authorized.

After the install script finishes, activate tools and locate the checkout in every shell:

```bash
source /workspace/.tools/rwa-env.sh
cd "$RWA_REPO_DIR"
```

The installer detects the fork by Git origin and records its real path. Do not assume the folder
is named `cypress-realworld-app` or `cypress-realworld-app-demo`. If setup files are absent, select
the fork's `develop` branch and run the install script first.

Read `AGENTS.md`, `.agents/skills/README.md`, and
`.agents/skills/cloud-development/SKILL.md` in that checkout. Follow `cloud-task-delivery` for a
Slack-origin engineering task or requested end-to-end delivery, and the appropriate project
review/PR/test skills for other work. Preserve the original Slack thread and task identity.
Skill files describe the workflow; an actual Slack connection and task trigger are separate.

Node 22.20.0, Yarn Classic 1.22.22, and Playwright MCP 0.0.83 are pinned under `/workspace/.tools`.
The base image must provide Chromium, FFmpeg/ffprobe, Xorg with its dummy driver, and xdpyinfo;
the installer checks these. Local authentication needs no external secrets. Missing optional
cloud credentials or the Cypress desktop binary do not block app/Playwright setup.

Start these in separate long-lived execution sessions:

```bash
bash /workspace/.tools/rwa-start.sh frontend
bash /workspace/.tools/rwa-start.sh api
```

The frontend binds `0.0.0.0:3000` with strict port selection; the API uses port 3001. If the sandbox
blocks local sockets, network-interface enumeration, or browser access, use supported escalated
execution with a specific local-runtime justification. Do not patch app code to bypass it.
Processes must restart in a new task; do not assume publication preserves them.

Verify actual readiness and browser rendering:

```bash
node /workspace/.tools/rwa-check.cjs
node /workspace/.tools/rwa-playwright.cjs --screenshot
```

The first helper checks IPv4 frontend/API responses, demo login, session, and transactions. The
second uses a real stdio Playwright MCP server and checks the sign-in route and controls. Outputs
are saved in unique folders under `/workspace/artifacts/`.

Use `bash /workspace/.tools/rwa-mcp.sh` to start the pinned headless MCP server for a client. For a
verified MP4 recording path, run `node /workspace/.tools/rwa-playwright.cjs --record`; it uses the
MCP-controlled browser, system FFmpeg, and a local Xorg display that it starts/cleans up if needed.
Native MCP WebM encoding requires its optional separate encoder download. For feature-specific
proof, exercise and assert the actual changed workflow rather than relying on the sample demo.

Use the project's types/lint/build/tests as relevant. For database-mutating unit tests, use
`bash /workspace/.tools/rwa-unit.sh`, which restores the original file and test exit status. Keep
mutating suites sequential. Do not reseed existing data automatically; `reset-demo-data` is an
explicit opt-in. Record current outcomes and tie final proof to the intended commit/environment.

Cypress desktop installation is optional: opt in with `RWA_INSTALL_CYPRESS=1` when rerunning the
bootstrap. Its download needs `download.cypress.io` and `cdn.cypress.io`; verify the executable
exists after installation, then verify/run actual specs with a display. Native Playwright encoder
downloads use `cdn.playwright.dev` and fallback `playwright.download.prss.microsoft.com`. Preserve
TLS, signatures, checksums, assertions, and existing supported authentication.

Cloud localhost is not a URL the user can open from their own computer. Do not invent a preview
URL, editor connection, or UI control. Use accessible screenshots/video, and only claim remote
access, integrations, publication, or fresh-instance restoration after verifying them.
