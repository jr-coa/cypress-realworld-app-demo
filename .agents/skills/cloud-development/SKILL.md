---
name: cloud-development
description: Start and validate the existing Cypress Real World App demo fork in its managed cloud environment, with Playwright MCP screenshots and browser video recording.
---

# Cloud development for the demo fork

Read the repository's [AGENTS.md](../../../AGENTS.md) to select the task workflow. For a delegated
Slack-origin engineering task or an explicitly requested end-to-end cloud delivery, follow
[cloud-task-delivery](../cloud-task-delivery/SKILL.md) after preparing the environment. It composes
the project PR, review, and test skills and returns verified results to the originating thread.
Environment setup alone does not authorize a PR, Slack messages, or a background task dispatcher.

Use the existing checkout of `jr-coa/cypress-realworld-app-demo`. The current machine uses `/workspace/cypress-realworld-app`; a fresh machine may use `/workspace/cypress-realworld-app-demo` or another configured mount. The bootstrap script discovers the actual fork checkout from its Git origin instead of assuming a folder name. `origin` is `https://github.com/jr-coa/cypress-realworld-app-demo.git`, `develop` tracks `origin/develop`, and `upstream` is the original `https://github.com/cypress-io/cypress-realworld-app.git`. Future requested changes belong to the fork. Push directly to `develop` only when explicitly requested; otherwise use the PR workflow.

Each task already runs in an isolated environment. Do not create a Git worktree unless the user explicitly requests one. Preserve existing user changes, tracked source, tests, dependency declarations, lockfiles, custom authentication configuration, and database contents during setup.

At the start of a managed cloud task, use the cloud-environment runtime guidance and `environment_status` when available. Respect the applied network policy and existing credentials. Never dump environment or credential values. Configuration drafts, the current machine, publication, and restoration in a new task are separate states.

## Install or refresh

The environment's `install_script` is the companion `scripts/bootstrap.sh`. It locates the existing fork checkout, exports `RWA_REPO_DIR`, and runs the complete versioned installer at `scripts/install.sh` beside this skill. Select the fork's `develop` branch in a fresh environment so these files are present. From any directory, run the bootstrap file using its actual checkout path, or from the checkout run:

```bash
bash .agents/skills/cloud-development/scripts/bootstrap.sh
```

The concise environment `start_skill` contents are versioned in
[start-instructions.md](references/start-instructions.md). Those instructions load this full skill
and the repository's workflow routing after activating the detected checkout.

The installer records the detected root in `/workspace/.tools/rwa-repo-path`, which its shell and Node helpers use in future sessions. Set `RWA_REPO_DIR` explicitly if multiple copies of this fork exist. It installs Node **22.20.0**, Yarn Classic **1.22.22**, and official `@playwright/mcp` **0.0.83** under `/workspace/.tools`; uses the user-approved public npm registry; installs application dependencies with the frozen Yarn lockfile; creates missing ignored Cognito mock files without replacing existing configuration; checks types; builds the application; and recreates the runtime helpers outside the checkout. Generated helpers that differ from existing files are backed up before replacement.

The current base image supplies `/usr/bin/chromium`, FFmpeg/ffprobe, Xorg with its dummy driver, and xdpyinfo. The script checks these prerequisites and reports a concrete failure if a future base image lacks them. It does not install another browser or disable TLS, signature, or package-integrity verification. Chromium's `--no-sandbox` is needed in this container runtime and is unrelated to TLS verification.

No external secrets are needed for local authentication. Third-party sign-in, Cypress Cloud recording, Percy, and native Playwright video encoding are optional. Do not request credentials for these optional workflows unless the user selects them.

## Start the development servers

Activate tools in every shell:

```bash
source /workspace/.tools/rwa-env.sh
cd "$RWA_REPO_DIR"
```

Start each server in its own long-lived execution session:

```bash
bash /workspace/.tools/rwa-start.sh frontend
```

```bash
bash /workspace/.tools/rwa-start.sh api
```

The frontend uses `NODE_ENV=development yarn start:react --host 0.0.0.0 --port 3000 --strictPort`. The API uses `NODE_ENV=development yarn start:api:watch` on port 3001. Explicit IPv4 binding is required: Vite's default here listened only on `::1` and failed IPv4 requests. `--strictPort` prevents silently selecting a different preview port.

If the sandbox blocks network-interface enumeration, local sockets, browser processes, or access to the long-lived local servers, use `exec_command` with `sandbox_permissions="require_escalated"` and a specific local-runtime justification. Use the supported approval mechanism; do not patch application code, disable verification, or bypass network policy to work around the sandbox.

Do not assume live processes survive publication or a new task. Inspect running processes and ports before starting duplicates; inspect logs when startup fails. The `prepare` mode creates only missing ignored authentication mocks. Never reseed automatically over existing work. Only when the user wants a fresh demo dataset, run:

```bash
bash /workspace/.tools/rwa-start.sh reset-demo-data
```

## Verify readiness

With both servers running, use the same local-runtime access as the servers:

```bash
node /workspace/.tools/rwa-check.cjs
node /workspace/.tools/rwa-playwright.cjs --screenshot
```

The API check waits for IPv4 application HTML and the expected backend response, then checks demo login, session authentication, and transaction data. It reads the current database's first user and the repository's demo password without printing either. If custom users no longer use the seeded password, preserve their data and diagnose authentication; do not silently reset it to make the check pass.

The browser check launches the actual official MCP server over stdio, initializes it, verifies its browser and video tool availability, opens `/signin`, checks the exact route and sign-in controls with `browser_evaluate`, rejects a Vite error overlay, and saves a screenshot. Success prints its unique directory under `/workspace/artifacts/`. Every run uses a new directory and an isolated browser context. It closes the browser and the MCP process it created. The legacy `rwa-browser-smoke.cjs` command delegates to this check.

For code changes, run the relevant repository checks. These commands were validated at the original prepared commit:

```bash
yarn types
bash /workspace/.tools/rwa-unit.sh
CYPRESS_COVERAGE=true yarn exec vite build
```

The unit helper preserves and restores `data/database.json`, including the test command's exit status. Run it serially with other database-mutating checks. The initial repository result was **44 passing tests and 10 repository-defined skips**; rerun and report current results after code changes. The direct Vite build matches the `build:ci` build command after mock preparation and avoids that script's unconditional replacement of custom ignored Cognito files.

## Use Playwright MCP

Prefer connected Playwright MCP tools if the session exposes them. If none are connected, a tested local MCP server is available over stdio:

```bash
bash /workspace/.tools/rwa-mcp.sh
```

For an MCP client's configuration, use command `bash`, arguments `["/workspace/.tools/rwa-mcp.sh"]`, and working directory `/workspace`. The wrapper uses the pinned Node/MCP versions, installed Chromium, an isolated context, the `devtools` capability, and headless mode. No public listener or tunnel is created. The local helper `rwa-playwright.cjs` is a real stdio MCP client, not a substitute browser implementation.

## Record video

The working recording path uses Playwright MCP to control a headed Chromium browser and the installed FFmpeg to record its local X display:

```bash
node /workspace/.tools/rwa-playwright.cjs --record
```

Run with supported escalated local-runtime access. The helper reuses `DISPLAY` or `:99` when available. Otherwise it starts a dummy Xorg display using `/workspace/.tools/xorg-rwa.conf`, waits for it to become ready, and stops only that owned display after recording. Keep display `:99` at the provided **1280x1024** resolution. If using a different display, confirm compatible capture dimensions first.

The walkthrough opens sign-in, navigates directly to sign-up, verifies that route and its controls, and returns to sign-in. It does not create an account or mutate the database. It saves `frontend.mp4`, `frontend.png`, and video metadata in a unique artifact directory. It stops FFmpeg cleanly and uses ffprobe to require a decodable video with nonzero duration. This is a screen recording of an MCP-controlled browser; do not describe it as native MCP video encoding.

MCP also exposes `browser_start_video` and `browser_stop_video`. Their native WebM path needs Playwright's separate FFmpeg binary, which was unavailable because its official download failed in the current network policy. If that capability is selected, use the supported installer:

```bash
node /workspace/.tools/node_modules/playwright/cli.js install ffmpeg
node /workspace/.tools/rwa-playwright.cjs --native-video
```

Required official download hosts are `cdn.playwright.dev` and fallback `playwright.download.prss.microsoft.com`. They are not required for the working system-recorder path. Preserve TLS and artifact verification; do not fake the Playwright cache or replace a pinned encoder with a symlink. Native video remains unverified until its download and an actual recording succeed.

## Cypress remains optional during installation

The Cypress npm dependency is installed, but its desktop binary is skipped by default so the development environment and Playwright do not depend on a blocked download. The saved network draft contains `download.cypress.io` and `cdn.cypress.io`; the running instance still reported no custom hosts at the last check. Saving a draft alone does not apply that policy.

After the policy is applied, opt in with:

```bash
RWA_INSTALL_CYPRESS=1 bash .agents/skills/cloud-development/scripts/install.sh
```

The install script calls `yarn cypress install` and explicitly requires the expected executable afterward: Cypress 16.1.1 previously exited successfully after a proxy reset without installing anything. An exit code of zero alone is insufficient.

For Cypress verification, start/reuse the dummy display described above and export `DISPLAY=:99`. Then run `yarn cypress verify` and representative existing API/UI tests without Cloud recording, preserving the database around mutations. These tests remain unverified until a desktop binary is present. Do not disable assertions, tests, TLS, signatures, or checksums.

## Frontend access and publication

The frontend is `http://localhost:3000` **inside the cloud machine**. The user added port 3000 to HTTP Previews, but the onboarding configuration panel shown in this session provided neither an Open action nor a generated URL. Do not invent either, or present cloud localhost as reachable from the user's computer. The available configuration tools cannot read or register preview URLs.

Use Playwright screenshots and recordings to show the UI here. A separate supported forwarding or deployment capability is needed for direct user-browser access. The application's browser API URLs also hardcode `localhost:3001`; a remote frontend needs supported API routing before remote login can be claimed to work. Make application changes only when requested.

Saving the install/start fields preserves a draft; it does not execute scripts, apply network policy, publish a snapshot, or prove restoration. After validated setup, tell the user to review/save the environment settings and publish when ready. Claim fresh-task readiness only after testing in an actual new task.
