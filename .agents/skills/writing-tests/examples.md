# TypeScript test examples

These examples use actual modules, selectors, and helpers from this repository. Extend a nearby
existing suite when its setup and purpose match. The filenames below describe the intended
location, so relative imports are shown for those locations. Keep examples in this guide rather
than adding duplicate application tests merely to install the skill.

## Parameterized utility behavior

Placement: `src/utils/__tests__/transactionUtils.test.ts`. The expected cases describe observable
pagination results; they do not recompute the implementation's offset in the assertion.

```ts
import { describe, expect, it } from "vitest";
import { getPaginatedItems } from "../transactionUtils";

describe("getPaginatedItems", () => {
  it.each([
    {
      name: "first page",
      page: 1,
      items: ["a", "b", "c"],
      expected: { totalPages: 2, data: ["a", "b"] },
    },
    {
      name: "last partial page",
      page: 2,
      items: ["a", "b", "c"],
      expected: { totalPages: 2, data: ["c"] },
    },
    {
      name: "page beyond the results",
      page: 3,
      items: ["a", "b", "c"],
      expected: { totalPages: 2, data: [] },
    },
    {
      name: "empty results",
      page: 1,
      items: [],
      expected: { totalPages: 0, data: [] },
    },
  ])("returns $name", ({ page, items, expected }) => {
    expect(getPaginatedItems(page, 2, items)).toEqual(expected);
  });
});
```

## Time-dependent utility without wall-clock waits

Placement: `src/utils/__tests__/transactionUtils.test.ts`. This tests the actual fallback for a
missing date and restores global timer state. It does not assert that real time elapsed.

```ts
import { afterEach, describe, expect, it, vi } from "vitest";
import { localDateToUTCISOString } from "../transactionUtils";

describe("localDateToUTCISOString", () => {
  afterEach(() => {
    vi.useRealTimers();
  });

  it("uses the current instant when no date is supplied", () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2026-01-15T12:30:00.000Z"));

    expect(localDateToUTCISOString(null)).toBe("2026-01-15T12:30:00.000Z");
  });
});
```

## Shared-database unit behavior

Placement: `src/__tests__/bankaccounts.test.ts`. Use the preserving unit runner from the skill.
The seed resets each case, while the runner restores the developer's original file after the
suite. Do not mark this case concurrent or re-enable file parallelism.

```ts
import { beforeEach, describe, expect, it } from "vitest";
import {
  createBankAccountForUser,
  getAllUsers,
  getBankAccountsByUserId,
  seedDatabase,
} from "../../backend/database";

describe("createBankAccountForUser", () => {
  beforeEach(() => {
    seedDatabase();
  });

  it("persists the new account for the intended user", () => {
    const owner = getAllUsers()[0];
    const previousCount = getBankAccountsByUserId(owner.id).length;
    const details = {
      bankName: "Example Bank",
      accountNumber: "1234567890",
      routingNumber: "123456789",
    };

    const created = createBankAccountForUser(owner.id, details);
    const accounts = getBankAccountsByUserId(owner.id);

    expect(created).toMatchObject({ userId: owner.id, ...details });
    expect(accounts).toHaveLength(previousCount + 1);
    expect(accounts.find((account) => account.id === created.id)).toMatchObject({
      userId: owner.id,
      ...details,
    });
  });
});
```

## Component state with a controlled clock and actor cleanup

Placement: `src/components/AlertBar.cy.tsx`. Reuse the configured `cy.mount` command and the
component's existing XState dependency. A controlled clock prevents the message's three-second
auto-hide from racing the assertion. This verifies error-message presentation, not a real API
failure or a payment workflow.

```tsx
import { interpret, type InterpreterFrom } from "xstate";
import AlertBar from "./AlertBar";
import { Severities, snackbarMachine } from "../machines/snackbarMachine";

describe("AlertBar error feedback", () => {
  let snackbarService: InterpreterFrom<typeof snackbarMachine>;

  beforeEach(() => {
    cy.clock();
    snackbarService = interpret(snackbarMachine).start();
  });

  afterEach(() => {
    snackbarService.stop();
  });

  it("shows the supplied error message", () => {
    const message = "The payment could not be completed";
    cy.mount(<AlertBar snackbarService={snackbarService} />);
    cy.then(() => {
      snackbarService.send("SHOW", { severity: Severities.error, message });
    });

    cy.get('[data-test="alert-bar-error"]').should("be.visible").and("contain.text", message);
  });
});
```

The actor is stopped in `afterEach`, and Cypress restores its clock after the test. Do not use a
real sleep to race or outlast the auto-hide behavior.

## API rejection without incidental session state

Placement: `cypress/tests/api/api-users.spec.ts` or a matching existing auth suite. This uses the
real API and clears cookies before the unauthenticated request. No seed mutation is needed for
this particular contract.

```ts
describe("GET /checkAuth without a session", () => {
  beforeEach(() => {
    cy.clearAllCookies();
  });

  it("rejects a request that has no authenticated session", () => {
    cy.request({
      method: "GET",
      url: `${Cypress.expose("apiUrl")}/checkAuth`,
      failOnStatusCode: false,
    }).then((response) => {
      expect(response.status).to.eq(401);
      expect(response.body).to.deep.equal({ error: "User is unauthorized" });
    });
  });
});
```

For authenticated API cases, use the existing `cy.database` and `cy.loginByApi` helpers with an
explicit seeded user. For mutation cases, compare the returned contract and the resulting data
when both matter; preserve the original database around the whole run.

## UI wait based on behavior

Placement: `cypress/tests/ui/auth.spec.ts`. Keep the suite's existing database seeding and cleanup.
Register the request alias before the action, and assert the visible post-login behavior.

```ts
cy.visit("/signin");
cy.intercept("POST", "http://localhost:3001/login").as("loginRequest");
cy.get('[data-test="signin-username"] input').type(seedUser.username);
cy.get('[data-test="signin-password"] input').type("s3cret");
cy.get('[data-test="signin-submit"]').click();
cy.wait("@loginRequest").its("response.statusCode").should("eq", 200);
cy.location("pathname").should("eq", "/");
cy.get('[data-test="sidenav-signout"]').should("exist");
```

Here `seedUser` must be a named, valid fixture obtained by the existing test setup, not an undefined
global copied from the guide. Adjust the visible selector for the viewport being tested. Do not
replace the alias or retryable assertion with a fixed sleep. This fragment is an integration
pattern, not a standalone runnable test file.

The existing `cy.login` command already registers and waits for its own `@loginUser` request.
When using that helper instead, assert the resulting UI without waiting a second time for an
already-consumed request alias.
