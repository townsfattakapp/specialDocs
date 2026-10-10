# Month 3: Transactions, Multi-Owner Inventory, Pick/Pack Fulfillment, Fleet, Finance & Frontends (Weeks 9–12)

**Objective:** Implement the atomic inventory reservation engine, canonical order lifecycle state machine, native dark-store pick-and-pack workflow, fleet proximity dispatch with WebSockets, Razorpay payments, and achieve 100% feature parity on React SPAs.  
**Acceptance Gate 3:** A complete end-to-end order is placed from the Flutter Customer app, processed through Razorpay / COD, picked and bag-sealed in the React Vendor portal, proximity-dispatched to a rider, tracked live via WebSockets, and delivered with doorstep OTP in Staging.

---

## Week 9: Inventory Service (`inventory-service`) & Multi-Owner Stock

### Detailed Tasks by Role

#### ARCH (Principal Architect & Project Lead)
- **`M3-W9-ARCH-01` Concurrency Chaos Testing & Invariants:** Run automated load script simulating 100 concurrent checkout attempts against a single stock item with quantity = 1. Assert that exactly 1 checkout succeeds, 99 fail with out-of-stock errors, and zero negative stock is created.

#### BE-1 (Senior Backend Engineer 1 — Auth & Edge)
- **`M3-W9-BE1-01` Stock Access Control & Vendor Scoping:** Enforce tenant isolation in `inventory-service` ensuring that local merchant API tokens can only view or request withdrawals for their own `owner_id` stock.

#### BE-2 (Senior Backend Engineer 2 — Catalog & Search)
- **`M3-W9-BE2-01` Live Stock Sync with Typesense:** When an item's `current_stock` reaches 0 or is reserved completely, publish a BullMQ event updating the `in_stock: false` attribute in Typesense 28.0 in real-time.

#### BE-3 (Senior Backend Engineer 3 — Commerce & Inventory Lead)
- **`M3-W9-BE3-01` Atomic Stock Reservation Engine:**
  - **Service:** `PessimisticStockReservationEngine` in `apps/inventory-service/src/stock/reservation.engine.ts`.
  - **Technical Spec:** Execute inside MySQL ACID transaction using Kysely:
    ```sql
    SELECT current_stock, reserved_stock FROM stocks 
    WHERE item_id = ? AND store_id = ? AND owner_type = ? AND owner_id = ? 
    FOR UPDATE;
    ```
  - Verify that `(current_stock - reserved_stock) >= requested_quantity`. Increment `reserved_stock`. Reject with HTTP 400 if stock is depleted (`code: "stock-depleted-001"`).
  - **Delayed Auto-Release:** Schedule BullMQ delayed job (`release-abandoned-stock`) to release unconfirmed reservation after 15 minutes.
- **`M3-W9-BE3-02` Multi-Owner Stock Ledger (Tirora Dark Store):**
  - **Table:** `fattakse_inventory.stocks`.
  - **Technical Spec:** Track `owner_type: 'evolw'` (Evolw-owned direct inventory) vs `owner_type: 'seller'` (consignment inventory). Enforce unique constraint `(item_id, store_id, owner_type, owner_id)`.
- **`M3-W9-BE3-03` Urgent Seller Stock Withdrawal Workflow:**
  - **Endpoint:** `POST /api/v1/vendor/inventory/withdraw-request`.
  - **Technical Spec:** Compute withdrawable quantity: `withdrawable_quantity = (current_stock - reserved_stock)`.
  - Enforce approval state machine (`pending` -> `approved` -> `picked` -> `dispatched` -> `received`). Disallow withdrawal if stock is actively reserved for a customer order.
- **`M3-W9-BE3-04` Stock Damage, Expiry & Shrinkage Logging:**
  - **Endpoint:** `POST /api/v1/admin/inventory/log-shrinkage`.
  - **Technical Spec:** Record damaged, expired, or missing items in `stock_shrinkage_logs` with reason, employee ID, and physical bin location. Deduct from `current_stock`.

#### FE-1 (Senior Frontend Engineer 1 — Admin Control Plane)
- **`M3-W9-FE1-01` Dark Store Inventory Dashboard:** Build `/inventory` screen in `admin-react` showing total SKU counts, low stock alerts, expired stock warnings, and seller withdrawal approval table.

#### FE-2 (Senior Frontend Engineer 2 — Merchant & Dark Store)
- **`M3-W9-FE2-01` Dark Store Stock Management UI (`/inventory/dark-store`):** Build UI in `vendor-react` for rack/bin location assigner, barcode receiving scanner, and stock count adjustment modals.
- **`M3-W9-FE2-02` Seller Stock Withdrawal UI:** Build stock withdrawal request screen in `vendor-react` displaying only withdrawable (unreserved) inventory.

#### DATA (Database Architect & ETL Data Engineer)
- **`M3-W9-DATA-01` Seed Multi-Owner Stock Fixtures:** Seed `fattakse_inventory` with 500 SKUs divided equally between Evolw-owned inventory and 3 local Tirora merchant deposit accounts.

#### QA (SDET / Automation Engineer)
- **`M3-W9-QA-01` Inventory Concurrency & SLA Tests:** Validate that stock reservations expire automatically via Redis BullMQ delayed job after 15 minutes if the customer abandons the Razorpay payment window.

---

## Week 10: Order Engine & Native Dark Store Fulfillment (`order-service`)

### Detailed Tasks by Role

#### ARCH (Principal Architect & Project Lead)
- **`M3-W10-ARCH-01` Order State Machine Formal Verification:** Audit order transition table ensuring zero illegal state jumps (e.g. `pending` directly to `delivered`). Verify transactional outbox event emission on every state transition.

#### BE-1 (Senior Backend Engineer 1 — Auth & Edge)
- **`M3-W10-BE1-01` Order Security & Ownership Guards:** Enforce ownership checks on all `/api/v1/customer/order/*` endpoints ensuring customers can never inspect or cancel another user's order.

#### BE-2 (Senior Backend Engineer 2 — Catalog & Search)
- **`M3-W10-BE2-01` Order Line Snapshot Persistence:** Ensure that when an order is created, item name, image, variant attributes, and unit price are snapshotted permanently into `order_details` so future catalog edits never alter historical invoices.

#### BE-3 (Senior Backend Engineer 3 — Commerce & Orders Lead)
- **`M3-W10-BE3-01` Canonical Order Placement API (`POST /api/v1/order/place`):**
  - **Transaction Sequence:**
    1. Validate `X-Idempotency-Key` in Redis.
    2. Open MySQL ACID transaction.
    3. Call `inventory-service.reserveStock()` via internal RPC.
    4. Insert into `orders` and `order_details`.
    5. If Razorpay, initiate payment order; if COD, set `order_status = 'confirmed'`.
    6. Commit transaction.
    7. Write event to `outbox_events`; OutboxRelay publishes `ORDER_CREATED` event to Kafka topic `fattakse.orders.lifecycle` (key = `order.id`).
- **`M3-W10-BE3-02` Order Lifecycle State Machine:**
  - Enforce valid transitions: `pending` -> `confirmed` -> `processing` -> `handover` -> `picked_up` -> `delivered`.
  - Handle customer cancellations (`POST /api/v1/customer/order/cancel`): allow cancellation only if order is in `pending` or `confirmed` status; immediately release reserved stock.
- **`M3-W10-BE3-03` Fulfilment Stage Serialization:**
  - In `GET /api/v1/customer/order/track`, append exact `fulfilment_stage` object:
    ```json
    { "code": "picking", "label": "Picking your items", "step": 2 }
    ```
- **`M3-W10-BE3-04` Restaurant Kitchen Acceptance Workflow:**
  - Implement `POST /api/v1/vendor/order/update-status` for restaurant food orders with accept/reject SLA timer (3 minutes) and auto-cancellation logic.

#### FE-1 (Senior Frontend Engineer 1 — Admin Control Plane)
- **`M3-W10-FE1-01` Live Dispatch Board (`/orders`):** Build live order control center in `admin-react` showing active orders, SLA breach warnings, manual rider reassignments, and cancellation modals.

#### FE-2 (Senior Frontend Engineer 2 — Merchant & Web Storefront)
- **`M3-W10-FE2-01` Native Dark Store Picker Display (`/picker/queue`):** Build high-contrast picker queue in `vendor-react`:
  1. Orders sorted by delivery SLA urgency.
  2. Handheld Bluetooth barcode scanner / camera scanner support to scan each item before marking picked.
  3. Bag packaging workflow: prompt for number of bags and generate unique tamper-evident QR seal tokens.
- **`M3-W10-FE2-02` Kitchen Display Screen (KDS) (`/kitchen/live-orders`):** Build restaurant kitchen view with high-contrast order cards, audio bell chimes on new orders, prep countdown timer, and "Ready for Pickup" button.
- **`M3-W10-FE2-03` Full-Catalog Web Storefront Checkout & Paan Integration (`user-web`):** Connect `user-web` storefront at `fattakse.in` to `order-service` and `finance-service` for unified multi-category cart checkout (groceries, dark store essentials, food, and paan corner items) with dynamic delivery quote, statutory COTPA warning banners on regulated items, and Razorpay/COD payment flows.

#### DATA (Database Architect & ETL Data Engineer)
- **`M3-W10-DATA-01` Order Lifecycle Index Tuning:** Add composite indexes on `fattakse_order.orders (store_id, order_status, created_at)` to support sub-10ms queries for active kitchen and dark-store queues.

#### QA (SDET / Automation Engineer)
- **`M3-W10-QA-01` Order State Machine Property Tests:** Test all valid and invalid order status transitions; verify that canceled orders immediately release reserved stock back into available inventory.

---

## Week 11: Fleet Dispatch, WebSockets (`fleet-service`) & Payments (`finance-service`)

### Detailed Tasks by Role

#### ARCH (Principal Architect & Project Lead)
- **`M3-W11-ARCH-01` WebSocket Scaling Architecture:** Configure Socket.IO Redis adapter in `fleet-service` allowing horizontal clustering of WebSocket nodes without losing rider GPS broadcast state.

#### BE-1 (Senior Backend Engineer 1 — Payments & Finance Lead)
- **`M3-W11-BE1-01` Razorpay Webhook & Payment Verification:** Implement `POST /api/v1/payment/razorpay/verify` and `POST /api/v1/payment/razorpay/webhook`. Validate HMAC-SHA256 signatures, record payments idempotently in `fattakse_finance.payments`, and mark orders `confirmed`.
- **`M3-W11-BE1-02` Decoupled Delivery Fee Accounting:** In `order_transactions`, record `orders.delivery_charge` (customer paid), `order_transactions.delivery_fee_earned` (paid to rider), and `order_transactions.delivery_subsidy` (platform covered).
- **`M3-W11-BE1-03` Cash on Delivery (COD) & Rider Wallets:** Track cash collected by riders; enforce maximum cash-in-hand limit (e.g. ₹5,000); block new order assignments if limit exceeded until cash is deposited.
- **`M3-W11-BE1-04` Kafka Order Completion Ledger Consumer:** Implement consumer group `finance-ledger-group` listening to `fattakse.orders.lifecycle`. Upon receiving `ORDER_DELIVERED`, idempotently post balanced double-entry accounting records, calculate merchant net payout, credit rider wallet, and log 1% GST TCS withholding without blocking checkout threads.

#### BE-2 (Senior Backend Engineer 2 — Catalog Support)
- **`M3-W11-BE2-01` Regulated Item Age-Restriction Flag:** Ensure catalog items marked `is_age_restricted: true` pass metadata flags through `order-service` to `fleet-service` triggering mandatory 18+ photo ID checks.

#### BE-3 (Senior Backend Engineer 3 — Fleet Lead)
- **`M3-W11-BE3-01` Fleet Proximity Dispatch Engine:** When an order transitions to `confirmed` (Food) or `packed` (Quick Dark Store), query active riders within 3km of store coordinates. Coordinate food prep time by delaying dispatch until estimated kitchen completion. Send FCM push notification with 30-second accept timer.
- **`M3-W11-BE3-02` Kafka Rider Telemetry Stream & Live GPS:** Ingest rider GPS coordinates from Rider app (`POST /api/v1/delivery-man/record-location`), stream directly to Kafka topic `fattakse.riders.telemetry` (key = `rider_id`), and forward to Socket.IO Redis adapter for real-time map broadcast, eliminating per-ping MySQL writes.
- **`M3-W11-BE3-03` Doorstep 18+ ID Check & Delivery OTP:** Implement `POST /api/v1/delivery-man/order/complete-delivery`. Require physical 18+ photo ID verification checkbox on age-restricted items and validate 4-digit customer delivery OTP.

#### FE-1 (Senior Frontend Engineer 1 — Admin Control Plane)
- **`M3-W11-FE1-01` Fleet Oversight & Live Rider Map (`/fleet/riders`):** Build live Mapbox map in `admin-react` showing real-time rider locations, active orders, battery levels, and shift statuses.
- **`M3-W11-FE1-02` Financial Ledger & Settlement Screen (`/finance/ledger`):** Build financial dashboard showing daily GMV, Razorpay fees, gross margins, and rider payout approvals.

#### FE-2 (Senior Frontend Engineer 2 — Merchant & Web Storefront)
- **`M3-W11-FE2-01` Handover QR Scanner Screen:** Build rider handover confirmation scanner in `vendor-react` where store staff scan the assigned rider's mobile QR code to release the packed bag.
- **`M3-W11-FE2-02` Web Storefront Live Order Tracking (`user-web`):** Build live order tracking view in `user-web` with real-time Socket.IO rider updates, delivery OTP display, and doorstep 18+ photo ID check alert banner (if order contains paan corner items).

#### DATA (Database Architect & ETL Data Engineer)
- **`M3-W11-DATA-01` Double-Entry Ledger Verification:** Verify that every completed order generates balanced double-entry accounting records in `account_transactions`.

#### QA (SDET / Automation Engineer)
- **`M3-W11-QA-01` Razorpay Webhook Security & Idempotency Tests:** Send duplicate, delayed, and tampered Razorpay webhook payloads; verify that valid payloads execute exactly once and forged signatures are rejected with HTTP 400.

---

## Week 12: Full React SPAs Feature Completion & Staging Verification

### Detailed Tasks by Role

#### ARCH (Principal Architect & Project Lead)
- **`M3-W12-ARCH-01` Full End-to-End Walkthrough:** Execute complete order lifecycle across Customer App -> React Vendor Portal -> Rider App -> React Admin Portal.
- **`M3-W12-ARCH-02` Code Freeze on Month 3 Features:** Tag repository at `v0.9.0-rc1` for Month 4 integration testing.

#### BE-1 (Senior Backend Engineer 1 — Auth & Finance)
- **`M3-W12-BE1-01` Weekly Settlement Generator API:** Implement batch calculation service in `finance-service` generating Monday–Sunday settlement statements with GST TCS (1%) and TDS (1%) withholdings for sellers and restaurants.

#### BE-2 (Senior Backend Engineer 2 — Catalog)
- **`M3-W12-BE2-01` Catalog Image CDN Optimization:** Wire image delivery to local WebP optimization pipeline reducing product card image weights by > 65%.

#### BE-3 (Senior Backend Engineer 3 — Commerce)
- **`M3-W12-BE3-01` Order Cancellation Refund Evaluation:** Implement automated refund evaluation in `order-service`: if paid via Razorpay and canceled prior to preparation, initiate automated gateway refund via Razorpay Refund API.

#### FE-1 (Senior Frontend Engineer 1 — Admin Control Plane)
- **`M3-W12-FE1-01` Operations Dashboard Complete (`/dashboard`):** Deliver live KPI tiles (GMV, active orders, pending approvals, rider online ratio, average delivery time).
- **`M3-W12-FE1-02` Tirora Town-Level P&L View (`/finance/town-pnl`):** Build town-filtered dashboard for Tirora aggregating own-inventory margins, seller commissions, food commissions, customer fees minus direct rider costs, gateway fees, and dark store fixed costs.
- **`M3-W12-FE1-03` Business Settings & Role Permissions (`/settings`, `/roles`):** Enforce fine-grained RBAC permissions across all operational tabs.

#### FE-2 (Senior Frontend Engineer 2 — Merchant & Dark Store)
- **`M3-W12-FE2-01` Vendor Financial Statements (`/finance/statements`):** Build vendor settlement page showing weekly gross sales, itemized commission deductions, approved refunds, statutory GST TCS/TDS withholdings, and net payout statements.
- **`M3-W12-FE2-02` Mobile Browser Optimization for Pickers:** Optimize picker queue UI for handheld mobile and tablet touchscreens with fast touch response and high-contrast buttons.

#### DATA (Database Architect & ETL Data Engineer)
- **`M3-W12-DATA-01` Audit Historical Ledger Mappings:** Verify that all historical orders, payments, and discounts from Laravel map cleanly into the new double-entry financial tables.

#### QA (SDET / Automation Engineer)
- **`M3-W12-QA-01` Execute Gate 3 Full Regression:** Run automated regression suite across all 8 microservices and verify zero regressions against Gate 3 criteria.

---

## Gate 3 Acceptance Criteria Sign-Off Checklist
- [ ] Atomic stock reservation operational with zero overselling under concurrency chaos tests.
- [ ] Multi-owner inventory tracking (Evolw vs. Seller) and urgent seller stock withdrawal workflow verified.
- [ ] Dark store Pick-and-Pack queue operational in React Vendor portal with barcode verification.
- [ ] Proximity fleet dispatch, WebSocket GPS tracking, and delivery OTP completion functioning end-to-end.
- [ ] Razorpay webhook cryptographic verification and COD rider ledger operational.
- [ ] Full feature parity demonstrated on React Admin and Vendor SPAs, and Full-Catalog Consumer Web Storefront (`user-web`) with integrated 18+ Paan Corner ordering.
