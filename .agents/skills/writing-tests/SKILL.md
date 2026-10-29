---
name: writing-tests
description: Write or improve TypeScript and React tests for jr-coa/cypress-realworld-app-demo using Vitest, Cypress component tests, API tests, and UI tests. Use when adding regression coverage, testing changed behavior, or fixing flaky tests. Applies deterministic fixtures, meaningful assertions, cleanup, negative-path coverage, and sequential shared-database execution.
---

# Write project tests

This repository is TypeScript/React/Express with Vitest and Cypress. The supplied Go testing
principles were adapted to these tools; do not introduce Go files, `cmp.Diff`, `t.Parallel`,
Ent/protobuf fixtures, or a new testing library to reproduce the source project's syntax.

Read the affected code and nearby existing tests before choosing a test level. Use
[cloud-development](../cloud-development/SKILL.md) for tools, servers, database preservation,
browser access, and the current Cypress binary limitation. Use the
[project-specific examples](examples.md) as starting points, not as tests to copy wholesale.

## Choose the narrowest meaningful level

| Behavior                                                               | Existing runner and location                                                            |
| ---------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| Pure utility, date/money behavior, or model transformation             | Vitest: `src/utils/__tests__/*.test.ts`.                                                |
| Database utility behavior                                              | Vitest: `src/__tests__/*.test.ts`, with the existing seed helpers and serial execution. |
| React component/form interaction with controlled dependencies          | Cypress component: `src/**/*.cy.tsx`.                                                   |
| HTTP validation, auth/session, response shape, or persistence contract | Cypress API: `cypress/tests/api/*.spec.ts`.                                             |
| Routing and a workflow through the real frontend/backend               | Cypress UI: `cypress/tests/ui/*.spec.ts`.                                               |

Use existing project dependencies and helpers. Do not add a new HTTP server test framework or
pretend a mocked component test verifies the live API. Playwright MCP can provide meaningful
browser inspection and artifacts, but it does not mean the repository's Cypress suite ran.

## Shape tests around observable behavior

1. Name the concrete trigger and expected outcome. A regression case should fail for the bug
   and pass for the corrected behavior; do not settle for a test that never reaches that path.
2. Use `it.each`/`test.each` when cases share setup and an expected shape. Use separate named tests
   when setup or the contract differs substantially. Do not require every test to fit one table.
3. Prefer readable fixed values and existing seed records over random users or values selected
   by array position in an unrelated case. Give important fixtures names. Seed Faker explicitly
   if generated variability is necessary, and do not assert on its incidental output.
4. Use Vitest's `toEqual`, `toMatchObject`, `toThrow`, `rejects`, and call assertions, or Cypress's
   Chai assertions, as appropriate. Compare the full relevant result when practical. Multiple
   assertions are useful for distinct contracts; do not enforce a single-assertion wrapper.
5. Assert stable error/status behavior rather than incidental library text unless that text is
   itself the user-facing contract. Setup/precondition failures should fail clearly and must not
   be caught as though they were the expected action failure.
6. Cover meaningful rejection, invalid-input, empty/missing-data, and boundary behavior affected
   by the change. When code handles a dependency failure, exercise that failure and assert the
   caller's behavior, not just that an arbitrary error string was produced.
7. Check both return values and side effects where relevant: ownership, persisted records,
   authorization, disabled/loading UI, error display, or prevention of a duplicate mutation.
8. Add tests when they substantiate a behavior or risk. Do not create tests for reversible,
   low-impact edits that merely mirror implementation, or require a case for every `if` regardless
   of whether it adds useful coverage.

## Preserve state and clean up

The database helpers write the tracked `data/database.json`. `vite.config.ts` deliberately sets
`test.fileParallelism: false`; do not remove it or add concurrent database cases. Seed with
`seedDatabase()` in each appropriate unit case or `cy.task("db:seed")` in existing Cypress setup.
A new seed per case does not create an independent physical database.

Preserve the developer's database before the whole run and restore only changes caused by tests.
The cloud helper `bash /workspace/.tools/rwa-unit.sh` does this and preserves the test exit status.
Do not run database-mutating unit tests and API/UI tests concurrently. Preserve intentional fixture
edits; do not reset them to make status look clean. Never commit runtime test mutations by accident.

Restore fake timers, mocked functions, globals, and stubbed environment values in `afterEach` or
the appropriate framework cleanup. Stop XState interpreters/actors and close listeners/resources
you create. Do not stop unrelated services. Isolate browser storage/session state using the
existing Cypress setup, and register intercepts before the action that causes the request.

## Make asynchronous tests deterministic

- Await promises and use `await expect(promise).rejects...` for expected failures. Do not leave
  unhandled work running after the test completes.
- Use `vi.useFakeTimers()`, `vi.setSystemTime()`, and explicit timer advancement for time-based
  unit behavior, restoring real timers afterward. Synchronize on callbacks/events for concurrent
  work rather than hoping a background task has run.
- In Cypress, use `cy.intercept(...).as(...)`, `cy.wait("@alias")`, and retryable `.should(...)`
  assertions. Prefer selectors and visible state to `cy.wait(1000)` or arbitrary sleeps.
- Do not assert tight real-world durations or use process-wide counters as a proxy for work
  performed by one component. A generous runner timeout is a safety bound, not the success claim.
- If a real integration dependency requires waiting, use observable readiness, a reasonable
  deadline, and a documented reason. Demo video pacing is not a test synchronization technique.

## Prove the test is meaningful

Map the changed behavior to a named case and ensure its setup reaches the relevant action.
Assert a successful path when necessary to make a no-call or rejection assertion meaningful.
Use actual state/output assertions rather than reproducing the implementation in the test.

For a bug fix, show that the new case fails against the buggy behavior when practical. Do not
blindly revert a working tree, discard user edits, or leave a temporary mutation behind to do so.
Use a safe controlled comparison or a well-established reproducer. Do not weaken an assertion,
skip a failing case, or add retries solely to manufacture a green run.

## Run and report

Activate the prepared environment, then use a focused existing target where it proves the change:

```bash
source /workspace/.tools/rwa-env.sh
cd "$RWA_REPO_DIR"
yarn exec -- vitest --run src/utils/__tests__/transactionUtils.test.ts
```

For database unit coverage, use the preserving wrapper:

```bash
bash /workspace/.tools/rwa-unit.sh
```

For Cypress, follow the cloud skill to install/verify the desktop binary, prepare the display,
start required services, and preserve the database before selecting a relevant spec. Use local
execution without Cloud recording unless the user selected and configured that workflow:

```bash
yarn cypress run --component --browser /usr/bin/chromium --spec src/components/SignInForm.cy.tsx
yarn cypress run --browser /usr/bin/chromium --spec cypress/tests/api/api-users.spec.ts
yarn cypress run --browser /usr/bin/chromium --spec cypress/tests/ui/auth.spec.ts
```

Report the exact command, named behavior covered, and passed/failed/skipped/unrun outcomes. Verify
that the intended tests executed; a zero-test run is not evidence. The original prepared commit
had 44 passing unit tests and 10 repository-defined skips; do not treat that historical count as
the result of a new run. A missing Cypress executable is a concrete environment gap, not a passing
test or a reason to disable assertions. Broaden checks only when the change or an unresolved
failure warrants it.
