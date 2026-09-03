# Beverage Depot Management System — Implementation Status

Scope reference: Quotation Q-2026-001, areas 2–13.
Status legend: `[x]` done · `[~]` partial · `[ ]` not started

All 12 areas now have a working backend and a Flutter screen. 96 inventory API
routes, 4 migrations, 8 backend feature tests and 84 widget tests pass.

---

## 2. Products, units & pricing — DONE

- [x] `inventory_categories` and `inventory_brands` tables + CRUD
- [x] Product ← category_id, brand_id (legacy `category` string kept in sync)
- [x] `inventory_product_units` — bottle / pack / crate, each with a conversion
      factor to the base unit and its own barcode
- [x] `inventory_product_prices` — retail / wholesale / special per unit,
      special scoped to one customer, with an effective-from date
- [x] `inventory_price_changes` — immutable log; every price write funnels
      through one method so the log cannot be bypassed
- [x] Flutter: units & pricing screen, set price per tier with a reason,
      price history with percentage moves
- [x] Flutter: brand + category pickers on the add/edit product form, with
      inline "add new" for both

## 3. Stock control & inventory — DONE

- [x] `inventory_batches` — batch number, expiry, quantity, buying cost;
      existing stock backfilled into an OPENING batch
- [x] Stock movements ← batch_id, reason code
- [x] FEFO issuing in `StockLedger`, the one place stock quantities change;
      sales cost their lines from the batches actually consumed
- [x] `inventory_stock_counts` + lines — variance captured, nothing moves until
      the count is posted, then it is frozen
- [x] `inventory_write_offs` — damage / breakage / expiry / theft / other,
      stock removed only on approval
- [x] Flutter: batches & expiry, stock counts, write-offs with approve/reject

## 4. Purchasing & goods receiving — DONE

- [x] `inventory_suppliers` + CRUD, with a live balance from open invoices
- [x] `inventory_purchase_orders` + lines, status driven by what was received
- [x] Goods receipt against a PO, capturing batch, expiry and buying cost;
      stock lands through `StockLedger.receive()`
- [x] `inventory_supplier_invoices` + payments → supplier balance
- [x] Flutter: purchasing screen (suppliers / orders / invoices tabs),
      receive-goods sheet, pay-supplier sheet

## 5. Sales & point of sale — MOSTLY DONE

- [x] Fast sale recording, now issuing FEFO from batches
- [x] Cash / mobile money / bank / cheque, and part payment
- [x] Discount limit check against the configured maximum
- [x] Parked sales — park, resume, discard
- [x] Returns and cancellations with approval; approved returns restock
- [x] Printed / shared PDF receipt, from the sales list

## 6. Customers & credit — DONE

- [x] Customer ← credit_limit, payment_terms_days, blocked flag + reason
- [x] Credit check endpoint: warns near the limit, blocks over it
- [x] Customer statement — opening, movements, closing
- [x] Debtors ageing in 0-30 / 31-60 / 61-90 / 90+ buckets
- [x] Flutter: credit screen with a usage bar, settings sheet, statement page

## 7. Payments & daily cash — DONE

- [x] Payments by cash, mobile money, bank or cheque
- [x] Allocation across invoices — explicit, or oldest-first automatically
- [x] `inventory_cash_sessions` per staff member per day
- [x] Session expenses; closing requires an explanation when the count differs
- [x] Flutter: receive-payment sheet, session list, close-session flow

## 8. Crates & empties — DONE

- [x] `inventory_crate_types` with deposit values
- [x] `inventory_crate_movements` — append-only ledger of issued / returned /
      broken / purchased
- [x] Per-customer holdings and deposit at risk, separate from money owed
- [x] Depot-wide crate position
- [x] Flutter: crates screen (depot position / customer holdings), movement sheet

## 9. Deliveries & dispatch — DONE

- [x] `inventory_dispatches` + lines; loading issues stock out of the depot
- [x] Reconciliation records returns, derives what was sold, and compares cash
- [x] Unsold stock is received back into the depot on reconcile
- [x] Flutter: dispatch list, load-vehicle sheet, reconcile screen

## 10. Barcodes, labels & scanning — BACKEND DONE

- [x] Code generation for product units, batches and crates (check-digit format)
- [x] Resolve endpoint — matches generated labels, unit barcodes and legacy
      product barcodes, so counter scanners and manufacturer codes both work
- [x] Label print payloads with a print counter
- [x] Flutter: camera scanning UI (`mobile_scanner`), wired into POS,
      products search, goods receipt, stock counts, write-offs and dispatch
- [ ] Printable label sheet (barcode generation and resolve are wired; the
      print layout for a sheet of labels is not built)

## 11. Reports & dashboard — DONE

- [x] 12 reports: daily sales · sales detail · product profitability · stock
      valuation · stock movements · stock count variance · damages · debtors
      ageing · collections · crates position · purchases · cash reconciliation
- [x] One envelope (`columns` / `rows` / `meta`) so a single table renders all
- [x] Flutter: report gallery + viewer with a date-range picker
- [x] PDF / Excel export from the report viewer, share sheet included

## 12. Alerts & notifications — DONE

- [x] Low stock, near expiry, expired, over credit limit, overdue invoice,
      pending approvals
- [x] Alerts are keyed on type + entity, so a rebuild refreshes rather than
      duplicates and a cleared condition resolves itself
- [x] Thresholds read from settings
- [x] Flutter: alerts screen with severity filter and acknowledge

## 13. Audit trail & settings — DONE

- [x] `inventory_audit_log` — entity, action, before/after, user, timestamp;
      insert-only, written by the shared `AuditTrail` service
- [x] `inventory_settings` — depot details, invoice numbering, tax, discount
      limits, alert thresholds, seeded with defaults
- [x] Flutter: settings form (grouped, validated) + audit trail viewer

---

## Shared widgets

`lib/modules/inventory/screens/widgets/inventory_widgets.dart` holds the pieces
every screen reuses, each already following the overflow rules below:
`InvStatTile`, `InvBadge`, `InvSearchField`, `InvFilterChips`, `InvEmptyState`,
`InvSheetShell` (keyboard-aware, height-capped), `InvTextField`, `InvDateField`,
`InvPrimaryButton`, `InvTabScaffold`, `InvDataTable`, `InvKeyValueWrap`.

## Overflow rules — enforced by tests

`test/inventory_overflow_test.dart` renders every screen empty, and
`test/inventory_overflow_with_data_test.dart` renders them full of deliberately
long names and large numbers, at 280 / 320 / 360 / 411 px wide. A layout
overflow fails the build. The data pass also asserts no spinner is showing, so
a screen cannot pass by rendering nothing.

1. **Colours**: only `ThemeConstants` tokens.
2. **Surfaces**: the shared glass card (radius 20, white-20% border, blur 10).
3. **Overflow**:
   - text in a `Row` → always inside `Expanded` / `Flexible`
   - single-line labels → `AutoSizeText(maxLines: 1, minFontSize: …)`
   - numbers that must stay on one line → `FittedBox(scaleDown)`
   - label/value clusters → `InvKeyValueWrap`, which wraps instead of clipping
   - wide tables → `InvDataTable`, scrollable in both directions
   - tab strips → always `isScrollable`
   - grids → pin `mainAxisExtent` rather than trusting an aspect ratio
   - never wrap the `label:` of `ElevatedButton.icon` in a `Flexible`; the
     button already does, and two produce competing ParentData
   - screen bodies are scrollable, so a short viewport cannot overflow
4. **Loading**: screens draw cached rows immediately and only show a spinner on
   a genuinely cold start.
