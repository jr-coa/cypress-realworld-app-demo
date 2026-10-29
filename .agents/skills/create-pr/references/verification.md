# Project verification

Read the current package scripts and CI workflow before choosing checks. These commands match the
prepared fork; future changes can alter them. Start with [cloud-development](../../cloud-development/SKILL.md)
when tools or services are not initialized.

```bash
source /workspace/.tools/rwa-env.sh
cd "$RWA_REPO_DIR"
```

| Change                                             | Relevant evidence                                                                                                          |
| -------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| Markdown, PR guidance, or skills                   | Prettier on changed Markdown, valid skill frontmatter, resolvable local references, and accurate repository commands.      |
| Shell/setup scripts                                | Shell syntax plus the affected install/start/check operation; verify repeatability when persistent files change.           |
| TypeScript utilities, models, or database behavior | Types, lint/formatting, focused existing/new unit tests, and affected API/browser checks when the public contract changes. |
| React components, forms, or state machines         | Types, lint/formatting, build, affected component/UI tests, and meaningful rendered behavior.                              |
| Express routes or authentication                   | Types, lint/formatting, request/response and authorization coverage, and representative functional API requests.           |
| Cypress configuration/support                      | Relevant Cypress specs using an actual installed binary and the expected app services.                                     |

Format/check explicit files rather than rewriting the repository:

```bash
yarn exec -- prettier --write path/to/changed-file.ts path/to/changed-guide.md
yarn exec -- prettier --check path/to/changed-file.ts path/to/changed-guide.md
```

For application changes, the current CI install job runs types, lint, unit tests, and a build:

```bash
yarn types
yarn lint
bash /workspace/.tools/rwa-unit.sh
CYPRESS_COVERAGE=true yarn exec vite build
```

The unit wrapper restores `data/database.json` and preserves the test exit status. The direct
Vite build is the build command used by `build:ci` after mock preparation; it avoids that script's
unconditional copying over ignored custom authentication files. Prepare missing mocks using
`bash /workspace/.tools/rwa-start.sh prepare` rather than replacing existing configuration.

Pure utility tests can be selected directly when they do not mutate the database:

```bash
yarn exec -- vitest --run src/utils/__tests__/transactionUtils.test.ts
```

For browser changes, start the frontend and API as described in the cloud skill, then run the
readiness helper. A Playwright screenshot or recording can show the UI and assert its route and
controls; it does not mean a Cypress suite executed:

```bash
node /workspace/.tools/rwa-check.cjs
node /workspace/.tools/rwa-playwright.cjs --screenshot
```

Cypress's npm package and desktop executable are separate prerequisites. In the initial cloud
instance the desktop download was blocked, and the install script intentionally made it optional.
Only after the binary is installed and verified, and a compatible local display is ready, run
representative specs without Cloud recording:

```bash
yarn cypress run --browser /usr/bin/chromium --spec cypress/tests/api/api-users.spec.ts
yarn cypress run --browser /usr/bin/chromium --spec cypress/tests/ui/auth.spec.ts
yarn cypress run --component --browser /usr/bin/chromium --spec src/components/SignInForm.cy.tsx
```

Preserve the existing database around Cypress mutations and do not run it concurrently with
database-mutating unit tests. External auth-provider, Percy, and Cypress Cloud workflows require
their own configuration; do not invent credentials or claim they were verified by local tests.

Report meaningful test counts and behavior. Keep failed, skipped, expected-failure, disabled, and
unrun outcomes separate. A zero-test run is not evidence. Diagnose baseline failures without
silently fixing unrelated code or disabling checks to make a PR look green.
