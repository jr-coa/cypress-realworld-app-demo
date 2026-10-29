import * as React from "react";
import { addDays, format as formatDate, startOfDay } from "date-fns";
import TransactionDateRangeFilter from "./TransactionDateRangeFilter";
import { endOfDayUTC, isoStringToLocalMidnightStart } from "../utils/transactionUtils";

describe("Transaction Date Range Filter", () => {
  it("should default to ALL", () => {
    const filterDateRangeSpy = cy.spy();
    const resetDateRangeSpy = cy.spy();

    cy.mount(
      <TransactionDateRangeFilter
        filterDateRange={filterDateRangeSpy}
        dateRangeFilters={{}}
        resetDateRange={resetDateRangeSpy}
      />
    );
    cy.get("[data-test='transaction-list-filter-date-range-button']").should("contain", "ALL");
  });

  it("should render a defined date range filter", () => {
    const filterDateRangeSpy = cy.spy();
    const resetDateRangeSpy = cy.spy();
    const dateRangeFilters = {
      dateRangeStart: new Date("Jan 01 2018").toISOString(),
      dateRangeEnd: new Date("Dec 05 2030").toISOString(),
    };

    cy.mount(
      <TransactionDateRangeFilter
        filterDateRange={filterDateRangeSpy}
        dateRangeFilters={dateRangeFilters}
        resetDateRange={resetDateRangeSpy}
      />
    );
    cy.get("[data-test='transaction-list-filter-date-range-button']")
      .should(
        "contain",
        formatDate(isoStringToLocalMidnightStart(dateRangeFilters.dateRangeStart), "MMM, d yyyy")
      )
      .and(
        "contain",
        formatDate(isoStringToLocalMidnightStart(dateRangeFilters.dateRangeEnd), "MMM, d yyyy")
      );
  });

  it("should update the displayed range when date range filters change", () => {
    const filterDateRangeSpy = cy.spy();
    const resetDateRangeSpy = cy.spy();
    const dateRangeFilters = {
      dateRangeStart: new Date("Jan 01 2018").toISOString(),
      dateRangeEnd: new Date("Dec 05 2030").toISOString(),
    };
    const FilterWithUpdatedRange = () => {
      const [filters, setFilters] = React.useState<Partial<typeof dateRangeFilters>>({});

      return (
        <>
          <button data-test="set-date-range" onClick={() => setFilters(dateRangeFilters)} />
          <TransactionDateRangeFilter
            filterDateRange={filterDateRangeSpy}
            dateRangeFilters={filters}
            resetDateRange={resetDateRangeSpy}
          />
        </>
      );
    };

    cy.mount(<FilterWithUpdatedRange />);
    cy.get("[data-test='set-date-range']").click();
    cy.get("[data-test='transaction-list-filter-date-range-button']")
      .should(
        "contain",
        formatDate(isoStringToLocalMidnightStart(dateRangeFilters.dateRangeStart), "MMM, d yyyy")
      )
      .and(
        "contain",
        formatDate(isoStringToLocalMidnightStart(dateRangeFilters.dateRangeEnd), "MMM, d yyyy")
      );
  });

  it("should set a date range filter", () => {
    const filterDateRangeSpy = cy.spy();
    const resetDateRangeSpy = cy.spy();
    const dateRangeStart = startOfDay(new Date(2014, 1, 1));
    const dateRangeEnd = endOfDayUTC(addDays(dateRangeStart, 1));

    cy.mount(
      <TransactionDateRangeFilter
        filterDateRange={filterDateRangeSpy}
        dateRangeFilters={{}}
        resetDateRange={resetDateRangeSpy}
      />
    );

    // @ts-ignore
    cy.pickDateRange(dateRangeStart, dateRangeEnd);
  });
});
