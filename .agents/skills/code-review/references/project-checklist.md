# Review checklist for this fork

Use relevant items to investigate evidence; do not mechanically create a comment for each item.

## React, routing, and XState

- Trace the affected route, component props, machine events, transitions, and invoked services.
  Check both successful and rejected operations, loading/disabled states, and cleanup of actors,
  subscriptions, timers, and event handlers.
- Confirm that stale responses or repeated actions cannot apply state to the wrong user or
  transaction. Prefer behavior demonstrated by a focused test over assumed scheduling.
- Check labels, keyboard operation, errors, and loading feedback for the changed interaction.
  Reuse existing `data-test` selectors and router/context wrappers in tests.
- Preserve supported viewport behavior when changing layouts. A screenshot proves what was
  rendered; an assertion or interaction must establish the behavior being claimed.

## Express, sessions, and API contracts

- Trace route registration, validation, authentication/session state, authorization/ownership,
  response status/shape, and callers in `src/machines/` and `src/utils/`.
- Verify that validation or ownership checks protect reads and mutations before accessing data.
  Inspect unauthorized, invalid-input, missing-object, and failed-dependency paths when affected.
- Preserve cookie/session and CORS behavior unless the requested change intentionally alters it.
  Localhost assumptions and remote-preview routing must be assessed separately.
- Do not expose credential values, password hashes, private user fields, or internal errors through
  changed responses or logs. Support an actual finding with the relevant reachable path.

## Models, money, and the JSON database

- Check model/API compatibility and expected seed-data shape. This project uses lowdb and
  `data/database.json`, not a Go/SQL/protobuf migration stack.
- Inspect monetary units and boundaries, date/timezone behavior, pagination, privacy, ownership,
  ordering, and soft-deletion semantics when the change touches them.
- Verify the mutation and observable persisted result. A return-value assertion alone may miss
  an incorrect write; an unconditional no-call assertion may exercise no relevant path.
- Explain intentional fixture changes. Do not include database mutations left by a test run or
  replace custom ignored provider configuration as incidental cleanup.

## Tests and asynchronous behavior

- Match each material behavior claim to a meaningful test, functional check, or an explicit gap.
  For a bug fix, make sure the reproducing case reaches the changed path and can fail for the bug.
- Cover meaningful negative/boundary behavior without testing every implementation branch or
  writing shallow tests merely to increase counts.
- Vitest database tests share a file: keep file parallelism disabled and avoid concurrent cases.
  Restore developer data around the whole run. Do not run mutating unit/API/UI suites together.
- Use fake clocks or observable events instead of arbitrary sleeps or tight wall-clock assertions.
  In Cypress, wait for aliased requests or retryable UI assertions.
- Check cleanup of mocks, fake timers, environment stubs, actors, and browser sessions.

## Tooling, docs, and review scope

- Read the actual current package/CI commands. Type-check/build/lint/unit outcomes, Cypress runs,
  and Playwright inspection are distinct evidence.
- Preserve frozen-lockfile installation, TLS and artifact verification, and actual test assertions.
  Missing optional credentials/binaries do not imply a code defect or a passed check.
- Review changed startup instructions and skill references for correct fork, `develop` base,
  paths, versions, service binding, and publication claims. Do not invent preview or editor URLs.
- Inspect all files in the requested diff, including relevant untracked files for a local review.
  Do not repair, stage, or comment on unrelated user changes as part of a read-only review.
- Before a requested posted review, verify current SHA/anchors, existing comments, selected event,
  and actual permission. Review submission, approval, merging, and publishing are separate actions.
