# Month 3 Task Prompts: Transactions, Fulfillment, Fleet, Finance & Frontends (Weeks 9–12)

This document contains production-grade, copy-pasteable execution prompts for each task in Month 3.

---

## Table of Contents
- [Week 9 Prompts](#week-9-inventory-service-inventory-service--multi-owner-stock)
- [Week 10 Prompts](#week-10-order-engine--native-dark-store-fulfillment-order-service)
- [Week 11 Prompts](#week-11-fleet-dispatch-websockets-fleet-service--payments-finance-service)
- [Week 12 Prompts](#week-12-full-react-spas-feature-completion--staging-verification)

---

## Week 9: Inventory Service (`inventory-service`) & Multi-Owner Stock

### `[M3-W9-ARCH-01]` Concurrency Chaos Testing & Invariants
**Assignee:** ARCH (Principal Architect & Project Lead)  
**Target Files:** `tests/chaos/stock_concurrency_race.ts`

```text
You are acting as the Principal Architect (ARCH) for the Fattakse platform modernization (Evolw Technologies Private Limited).

TASK: M3-W9-ARCH-01 - Concurrency Chaos Testing & Invariants

CONTEXT:
During flash sales or peak evening rush, multiple customers attempt to purchase the last unit of stock simultaneously. The system must guarantee zero overselling and zero negative stock (Risk R-06).

REQUIREMENTS:
1. Author tests/chaos/stock_concurrency_race.ts.
2. Initialize a test item in fattakse_inventory.stocks with current_stock = 1, reserved_stock = 0.
3. Fire 100 concurrent asynchronous checkout reservation requests against inventory-service via Promise.all().
4. Invariants to assert:
   - Exactly 1 request succeeds with HTTP 200 OK.
   - Exactly 99 requests receive HTTP 400 with { errors: [{ code: "stock-depleted-001", message: "Item is out of stock" }] }.
   - Database assert: current_stock === 1, reserved_stock === 1. Under no circumstances can reserved_stock exceed current_stock.
   - No MySQL deadlocks or unhandled exceptions occur.

DEFINITION OF DONE:
- Script executes 100 concurrent requests; invariants hold 100% of the time across 10 repeated runs.
```

---

### `[M3-W9-BE3-01]` Atomic Stock Reservation Engine
**Assignee:** BE-3 (Senior Backend Engineer 3 — Commerce & Inventory Lead)  
**Target Files:** `apps/inventory-service/src/stock/reservation.engine.ts`, `apps/inventory-service/src/stock/stock.controller.ts`

```text
You are acting as Senior Backend Engineer 3 (BE-3) for the Fattakse platform modernization.

TASK: M3-W9-BE3-01 - Atomic Stock Reservation Engine

CONTEXT:
When an order is submitted, inventory-service must atomically lock and reserve stock. If the customer does not complete payment within 15 minutes, the reservation must automatically expire.

REQUIREMENTS:
1. Implement reservation.engine.ts in inventory-service.
2. Use Kysely inside a MySQL ACID transaction:
   ```typescript
   await db.transaction().execute(async (trx) => {
     const stock = await trx
       .selectFrom('stocks')
       .select(['id', 'current_stock', 'reserved_stock'])
       .where('item_id', '=', itemId)
       .where('store_id', '=', storeId)
       .where('owner_type', '=', ownerType)
       .where('owner_id', '=', ownerId)
       .forUpdate()
       .executeTakeFirst();

     const available = stock.current_stock - stock.reserved_stock;
     if (available < requestedQty) {
       throw new StockDepletedException('Insufficient stock available');
     }

     await trx
       .updateTable('stocks')
       .set({ reserved_stock: stock.reserved_stock + requestedQty })
       .where('id', '=', stock.id)
       .execute();
   });
   ```
3. Delayed Auto-Release: Enqueue a delayed BullMQ job (release-abandoned-stock, delay: 15 * 60 * 1000). If payment is not confirmed within 15 minutes, job decrements reserved_stock back to available.
4. Expose internal endpoint POST /internal/inventory/reserve.

DEFINITION OF DONE:
- Unit tests verify pessimistic locking, successful reservation, and automatic expiration after delay.
```

---

### `[M3-W9-BE3-02]` Multi-Owner Stock Ledger (Tirora Dark Store)
**Assignee:** BE-3 (Senior Backend Engineer 3 — Commerce & Inventory Lead)  
**Target Files:** `apps/inventory-service/src/owners/owner-ledger.service.ts`

```text
You are acting as Senior Backend Engineer 3 (BE-3) for the Fattakse platform modernization.

TASK: M3-W9-BE3-02 - Multi-Owner Stock Ledger (Tirora Dark Store)

CONTEXT:
In Tirora, the central dark store houses both items purchased directly by Evolw Technologies (owner_type: 'evolw') and consignment stock deposited by local partner merchants (owner_type: 'seller'). These must be tracked separately for accounting and settlement purposes.

REQUIREMENTS:
1. Model fattakse_inventory.stocks table:
   - Fields: id, item_id, store_id, owner_type (enum: 'evolw', 'seller'), owner_id (null for evolw, merchant_id for seller), current_stock, reserved_stock, rack_location, bin_location, updated_at.
   - Unique index: UNIQUE(item_id, store_id, owner_type, owner_id).
2. Implement stock allocation priority:
   - When customer orders an item available from both Evolw and Seller, prioritize based on store fulfillment config (e.g. FIFO by batch arrival or Evolw-first).
3. Record all stock movements in stock_ledger_entries (audit trail of inbound, sold, damaged, and returned goods).

DEFINITION OF DONE:
- System tracks stock independently by owner.
- Financial audit query can cleanly report total inventory value belonging to Evolw vs. consignment partners.
```

---

### `[M3-W9-BE3-03]` Urgent Seller Stock Withdrawal Workflow
**Assignee:** BE-3 (Senior Backend Engineer 3 — Commerce & Inventory Lead)  
**Target Files:** `apps/inventory-service/src/withdrawals/withdrawal.controller.ts`, `apps/inventory-service/src/withdrawals/withdrawal.service.ts`

```text
You are acting as Senior Backend Engineer 3 (BE-3) for the Fattakse platform modernization.

TASK: M3-W9-BE3-03 - Urgent Seller Stock Withdrawal Workflow

CONTEXT:
Partner merchants who deposited goods in the Tirora dark store may urgently need their stock back (e.g., to sell in their physical shop). They can request withdrawal through vendor-react, but active customer reservations must be protected.

REQUIREMENTS:
1. Implement POST /api/v1/vendor/inventory/withdraw-request:
   - Accept: { item_id: number, quantity: number, reason: string }.
   - Calculate withdrawable_quantity = current_stock - reserved_stock.
   - If requested quantity > withdrawable_quantity, reject with HTTP 400 { errors: [{ code: "stock-004", message: "Stock is currently reserved for active customer orders" }] }.
   - Create withdrawal record in stock_withdrawal_requests with status = 'pending'.
2. Implement state machine: pending -> approved -> picked -> handed_over.
   - Upon approved: Dark store manager approves in admin-react.
   - Upon handed_over: Deduct quantity from current_stock and log return in ledger.

DEFINITION OF DONE:
- Withdrawal request is created only for unreserved inventory.
- Ledger accurately records stock reduction upon physical handover.
```

---

## Week 10: Order Engine & Native Dark Store Fulfillment (`order-service`)

### `[M3-W10-BE3-01]` Canonical Order Placement API (`POST /api/v1/order/place`)
**Assignee:** BE-3 (Senior Backend Engineer 3 — Commerce & Orders Lead)  
**Target Files:** `apps/order-service/src/orders/order.controller.ts`, `apps/order-service/src/orders/order.service.ts`

```text
You are acting as Senior Backend Engineer 3 (BE-3) for the Fattakse platform modernization.

TASK: M3-W10-BE3-01 - Canonical Order Placement API (POST /api/v1/order/place)

CONTEXT:
This is the central checkout transaction. It must validate idempotency, reserve inventory atomically, persist order details, and emit the domain event to Redpanda/Kafka.

REQUIREMENTS:
1. Implement POST /api/v1/order/place:
   - Validate header X-Idempotency-Key in Redis. If key exists, return cached response; otherwise set key with 24h TTL.
2. Transaction execution:
   - Open MySQL transaction in fattakse_order.
   - Call inventory-service.reserveStock() for all items.
   - Insert into orders: customer_id, store_id, order_amount, delivery_charge, payment_method ('razorpay' | 'cash_on_delivery'), order_status ('pending' for Razorpay, 'confirmed' for COD), otp (random 4 digits).
   - Insert into order_details: snapshot item names, unit prices, add-ons.
   - Write ORDER_CREATED event into outbox_events table.
   - Commit transaction.
3. OutboxRelay background worker reads outbox_events and publishes to Kafka topic fattakse.orders.lifecycle with key = order.id.
4. If payment is Razorpay, call Razorpay Orders API to generate razorpay_order_id.
5. Return legacy Flutter response shape with order_id and payment details.

DEFINITION OF DONE:
- Order and lines persist cleanly in MySQL.
- ORDER_CREATED event is delivered to Kafka topic with order.id partition key.
- Concurrency test passes with zero duplicate orders.
```

---

### `[M3-W10-FE2-01]` Native Dark Store Picker Display (`/picker/queue`)
**Assignee:** FE-2 (Senior Frontend Engineer 2 — Merchant & Web Storefront)  
**Target Files:** `apps/vendor-react/src/pages/picker/PickerQueue.tsx`, `apps/vendor-react/src/pages/picker/ItemPickModal.tsx`

```text
You are acting as Senior Frontend Engineer 2 (FE-2) for the Fattakse platform modernization.

TASK: M3-W10-FE2-01 - Native Dark Store Picker Display (/picker/queue)

CONTEXT:
Hyper POS is retired (ADR-0006). Tirora dark store staff fulfill 100% of orders digitally using this pick-and-pack workflow on handheld tablets.

REQUIREMENTS:
1. Build /picker/queue in vendor-react:
   - High-contrast visual order cards sorted by delivery SLA urgency (green: > 15m remaining, yellow: < 10m, red flashing: < 5m).
   - Tap "Start Picking" -> transition order to processing.
2. Build ItemPickModal.tsx:
   - Displays items with rack/bin locations (e.g. "Rack A3, Bin 12").
   - Barcode Scanner Integration: Support USB/Bluetooth handheld barcode scanner via keyboard input buffer and device camera via @zxing/library.
   - Scan matches item barcode -> item card turns green with audio success beep.
3. Bagging & Sealing Workflow:
   - Prompt picker: "Enter number of bags (e.g. 2)".
   - Generate unique QR bag seal token.
   - Advance order to handover status and display "Ready for Rider Handover".

DEFINITION OF DONE:
- Picker can complete an order by scanning items without touching the mouse.
- Bag seal QR renders cleanly for rider handover.
```

---

### `[M3-W10-FE2-03]` Full-Catalog Web Storefront Checkout & Paan Integration (`user-web`)
**Assignee:** FE-2 (Senior Frontend Engineer 2 — Merchant & Web Storefront)  
**Target Files:** `apps/user-web/src/pages/Checkout.tsx`, `apps/user-web/src/pages/Cart.tsx`

```text
You are acting as Senior Frontend Engineer 2 (FE-2) for the Fattakse platform modernization.

TASK: M3-W10-FE2-03 - Full-Catalog Web Storefront Checkout & Paan Integration (user-web)

CONTEXT:
user-web at fattakse.in is a full-catalog storefront selling groceries, food, dark store essentials, AND paan corner products in a single unified basket (ADR-0009).

REQUIREMENTS:
1. Build Cart.tsx and Checkout.tsx in user-web:
   - Display unified cart items with quantity steppers.
   - If cart contains any tobacco/paan item: Display statutory COTPA warning badge: "Contains 18+ Regulated Products. Physical Photo ID Required at Doorstep Handover."
2. Checkout Flow:
   - Select delivery address or pin location on map.
   - Fetch real-time quotation from /api/v1/checkout/get-quote.
   - Payment selection: Razorpay Checkout modal (UPI, Cards, NetBanking) or Cash on Delivery (COD).
3. On order placement: Redirect to /order/track/:id with live stepper.

DEFINITION OF DONE:
- Customer can place a combined basket containing snacks and cigarettes.
- Razorpay payment modal opens and completes test payment cleanly.
```

---

## Week 11: Fleet Dispatch, WebSockets (`fleet-service`) & Payments (`finance-service`)

### `[M3-W11-BE1-01]` Razorpay Webhook & Payment Verification
**Assignee:** BE-1 (Senior Backend Engineer 1 — Payments & Finance Lead)  
**Target Files:** `apps/finance-service/src/payments/razorpay.controller.ts`, `apps/finance-service/src/payments/razorpay.service.ts`

```text
You are acting as Senior Backend Engineer 1 (BE-1) for the Fattakse platform modernization.

TASK: M3-W11-BE1-01 - Razorpay Webhook & Payment Verification

CONTEXT:
Payment callbacks from Razorpay must be verified cryptographically via HMAC-SHA256 signatures to prevent fraudulent order confirmations.

REQUIREMENTS:
1. Implement POST /api/v1/payment/razorpay/verify:
   - Verify generated_signature === HmacSHA256(order_id + "|" + razorpay_payment_id, secret).
   - If valid: Mark payment status 'captured' in fattakse_finance.payments and transition order to 'confirmed'.
2. Implement POST /api/v1/payment/razorpay/webhook:
   - Verify header X-Razorpay-Signature against raw request payload.
   - Handle events: payment.captured, payment.failed, refund.processed.
   - Idempotency guard: If payment_id already processed, return HTTP 200 immediately.
3. Write test with forged HMAC signature; verify it throws HTTP 400 Bad Request.

DEFINITION OF DONE:
- Valid Razorpay webhook payload processes idempotently.
- Forged signature is rejected with HTTP 400.
```

---

### `[M3-W11-BE1-04]` Kafka Order Completion Ledger Consumer
**Assignee:** BE-1 (Senior Backend Engineer 1 — Payments & Finance Lead)  
**Target Files:** `apps/finance-service/src/consumers/order-ledger.consumer.ts`

```text
You are acting as Senior Backend Engineer 1 (BE-1) for the Fattakse platform modernization.

TASK: M3-W11-BE1-04 - Kafka Order Completion Ledger Consumer

CONTEXT:
When an order is delivered, finance-service must post double-entry ledger entries, compute platform commission, credit the merchant, credit the rider, and withhold statutory 1% GST TCS (ADR-0010).

REQUIREMENTS:
1. Create order-ledger.consumer.ts in finance-service:
   - Subscribe to Kafka topic fattakse.orders.lifecycle with consumer group finance-ledger-group.
   - Handle event ORDER_DELIVERED.
2. In a MySQL transaction in fattakse_finance:
   - Verify event idempotency against idempotency_keys.
   - Create balanced double-entry accounting records in account_transactions:
     - Debit: Cash / Gateway Clearing Account.
     - Credit: Merchant Payable (order amount minus commission minus TCS).
     - Credit: Platform Revenue (commission + customer delivery fee + platform fee).
     - Credit: Rider Payable (rider delivery fee earned).
     - Credit: Statutory Taxes Payable (1% GST TCS under CGST/SGST Section 52).
3. Update vendor and rider wallet balances atomically.

DEFINITION OF DONE:
- Debit totals equal credit totals to the exact paisa (0.00 INR variance).
- Replaying the same Kafka event does not double-credit wallets.
```

---

### `[M3-W11-BE3-01]` Fleet Proximity Dispatch Engine
**Assignee:** BE-3 (Senior Backend Engineer 3 — Fleet Lead)  
**Target Files:** `apps/fleet-service/src/dispatch/dispatch.service.ts`

```text
You are acting as Senior Backend Engineer 3 (BE-3) for the Fattakse platform modernization.

TASK: M3-W11-BE3-01 - Fleet Proximity Dispatch Engine

CONTEXT:
Orders packed in the dark store or ready in restaurant kitchens must be dispatched to the optimal nearby delivery rider.

REQUIREMENTS:
1. Implement dispatch.service.ts in fleet-service.
2. Trigger on order handover or food prep completion:
   - Query active online riders in fattakse_fleet.delivery_men with is_online = 1 and is_active = 1.
   - Filter riders within 3km radius using spatial distance or Haversine formula.
   - Exclude riders with active orders exceeding cash-in-hand limits (₹5,000).
   - Score candidates based on distance, battery level, and current shift duration.
3. Assign candidate rider:
   - Dispatch FCM push notification to Rider app with 30-second accept countdown timer.
   - If rider accepts within 30s: Assign order, emit ORDER_DISPATCHED event to Kafka.
   - If timeout or rejected: Reassign to next best candidate.

DEFINITION OF DONE:
- Proximity algorithm assigns nearest available rider in < 500ms.
- Reassignment cascade triggers cleanly on rejection.
```

---

### `[M3-W11-BE3-02]` Kafka Rider Telemetry Stream & Live GPS
**Assignee:** BE-3 (Senior Backend Engineer 3 — Fleet Lead)  
**Target Files:** `apps/fleet-service/src/telemetry/telemetry.controller.ts`, `apps/fleet-service/src/telemetry/telemetry-stream.service.ts`

```text
You are acting as Senior Backend Engineer 3 (BE-3) for the Fattakse platform modernization.

TASK: M3-W11-BE3-02 - Kafka Rider Telemetry Stream & Live GPS

CONTEXT:
Dozens of delivery riders send GPS coordinates every 2–3 seconds while on delivery. Writing these pings directly to MySQL would saturate disk I/O. We stream them through Kafka and broadcast via WebSockets.

REQUIREMENTS:
1. Implement POST /api/v1/delivery-man/record-location:
   - Accept: { latitude: number, longitude: number, speed: number, battery: number }.
   - Publish immediately to Kafka topic fattakse.riders.telemetry with key = rider.id.
2. In telemetry-stream.service.ts:
   - Kafka consumer reads telemetry pings.
   - If rider has an active order: Broadcast live coordinate to Socket.IO room order:${activeOrderId} using Redis adapter.
   - Only commit periodic checkpoints (e.g., every 60 seconds or on order arrival) to MySQL delivery_man_histories.
3. Customer app listening to Socket.IO sees live rider marker movement smoothly on map.

DEFINITION OF DONE:
- Telemetry ingestion responds in < 10ms with zero database write locks.
- Customer map receives WebSocket coordinate updates in real-time.
```

---

## Week 12: Full React SPAs Feature Completion & Staging Verification

### `[M3-W12-FE1-02]` Tirora Town-Level P&L View (`/finance/town-pnl`)
**Assignee:** FE-1 (Senior Frontend Engineer 1 — Admin Control Plane)  
**Target Files:** `apps/admin-react/src/pages/finance/TownPnlDashboard.tsx`

```text
You are acting as Senior Frontend Engineer 1 (FE-1) for the Fattakse platform modernization.

TASK: M3-W12-FE1-02 - Tirora Town-Level P&L View (/finance/town-pnl)

CONTEXT:
Company leadership needs to track the financial profitability of Tirora operations separately from corporate expenses (aligned with Evolw Technologies business model).

REQUIREMENTS:
1. Build /finance/town-pnl in admin-react.
2. Display financial breakdown for selected date range:
   - Total Town GMV (Gross Merchandise Value).
   - Evolw-Owned Dark Store Margins (MRP vs cost price).
   - Merchant Commission Revenue (8%–15% take rate).
   - Restaurant Food Commission Revenue (15%–25% take rate).
   - Customer Delivery Fees Collected.
   - Platform Processing Fees (₹5 per order).
   - Deductions: Rider Payouts, Delivery Subsidies, Razorpay Gateway Fees (2%), Dark Store Warehouse Fixed Costs.
   - Net Town Contribution Margin (₹ and %).
3. Add export button generating CSV statement for company accountants.

DEFINITION OF DONE:
- Dashboard calculates net margin matching finance-service ledger queries.
- Date filters (Today, Yesterday, This Week, This Month) update instantly.
```

---

### `[M3-W12-QA-01]` Playwright Full Order Lifecycle E2E Automation
**Assignee:** QA (SDET / Automation Engineer)  
**Target Files:** `qa/e2e/gate3_full_order_lifecycle.spec.ts`, `playwright.config.ts`

```text
You are acting as the SDET / Automation Engineer (QA) for the Fattakse platform modernization.

TASK: M3-W12-QA-01 - Playwright Full Order Lifecycle E2E Automation

CONTEXT:
Gate 3 is the pivotal transaction milestone: validating the complete order lifecycle across browsers and portals using Playwright headless browser testing from checkout through dark store picking, rider dispatch, and OTP delivery.

REQUIREMENTS:
1. Configure Playwright in playwright.config.ts supporting Chromium, WebKit, and mobile viewport emulation.
2. Author automated E2E test qa/e2e/gate3_full_order_lifecycle.spec.ts:
   - Step 1: Customer opens user-web, logs in via OTP, adds dark store items to cart, checks out via COD.
   - Step 2: Dark store picker receives order in vendor-react, marks items picked, inputs 1 bag, gets bag seal.
   - Step 3: fleet-service proximity dispatch assigns order to test rider.
   - Step 4: Rider arrives at store, staff scans rider QR to handover bag.
   - Step 5: Rider streams GPS coordinates; customer map tracks rider live.
   - Step 6: Rider arrives at customer doorstep, inputs customer 4-digit OTP, completes delivery.
   - Step 7: finance-service Kafka consumer generates balanced double-entry ledger records.
3. Assert zero manual database interventions required.
4. Execute via Playwright test runner: `pnpm exec playwright test qa/e2e/gate3_full_order_lifecycle.spec.ts --reporter=html`.

DEFINITION OF DONE:
- Playwright E2E test executes across user-web, vendor-react, and admin-react and passes 100% cleanly.
- HTML test report with trace recordings generated.
- Gate 3 sign-off checklist verified.
```
