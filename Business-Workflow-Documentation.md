# Fattakse — End-to-End Business Workflow Documentation

**Document Version:** 1.0.0  
**Business Entity:** Evolw Technologies Private Limited (Tirora, Maharashtra — State Code 27)  
**Business Model:** 100% Online Hyperlocal Quick-Commerce & Restaurant Delivery Network  
**Status:** Canonical Workflow Specification  
**Author:** Principal Software Architect & Operations Lead  

---

## 1. Customer Discovery, Cart & Checkout Workflow

```
+---------------+     +---------------+     +---------------+     +---------------+
|  Customer     |     |   Hyperlocal  |     | Master Catalog|     | Dynamic Quote |
|  Enters App   | --> | Zone Check    | --> | Discovery &   | --> | & Fee Calc    |
|  (OTP Login)  |     | (Lat/Lng)     |     | Typesense     |     | (GST/Platform)|
+---------------+     +---------------+     +---------------+     +---------------+
                                                                          |
                                                                          v
+---------------+     +---------------+     +---------------+     +---------------+
| Order Created |     | Stock Reserved|     | Payment Via   |     | Idempotency   |
| & Broadcast   | <-- | (SELECT FOR   | <-- | Razorpay /    | <-- | Check         |
| to Ops        |     |  UPDATE Lock) |     | COD Confirmed |     | (Unique Key)  |
+---------------+     +---------------+     +---------------+     +---------------+
```

### 1.1 Customer Authentication
- **Entry Point:** `POST /api/v1/auth/request-otp`, `POST /api/v1/auth/verify-phone`
- **Logic:** Indian mobile number (+91) receives a 6-digit OTP via MSG91/Fast2SMS. Upon verification, user record is created/retrieved in `users`, issuing an OAuth2 Bearer token.
- **Address Book:** Customer selects address via Mapbox/Google reverse geocoding (`POST /api/v1/customer/address/add`). Hyperlocal zone ID is resolved via MySQL spatial polygon checks on `zones.coordinates`.

### 1.2 Master Catalog & Typesense Discovery
- **Entry Point:** `GET /api/v1/items/search`, `GET /api/v1/categories`
- **Logic:** Customer queries catalog for grocery or restaurant food. Query executes against Typesense 28.0 cluster (sub-15ms response time), filtering exclusively by `store.zone_id` and `store.status = 1`.

### 1.3 Cart & Dynamic Checkout Quote
- **Entry Point:** `POST /api/v1/cart/sync`, `POST /api/v1/checkout/get-quote`
- **Pricing & Fee Engine:**
  - Item base price, variant price deltas, and store-level active discounts.
  - Indian GST breakdown computed using `hsn_gst_master` (CGST 2.5% + SGST 2.5% for 5% tax bracket; CGST 9% + SGST 9% for 18% tax bracket).
  - Hyperlocal delivery fee calculated based on road distance matrix between customer address and store/dark store.
  - Platform processing fee (configurable in `business_settings`, e.g. ₹5–₹10).
  - Optional delivery tip and coupon discount codes.

### 1.4 Atomic Order Placement & Stock Reservation
- **Entry Point:** `POST /api/v1/order/place`
- **Transaction Boundary:**
  1. Verify idempotency token in `api_idempotency` table.
  2. Open MySQL ACID transaction.
  3. Lock inventory rows (`SELECT current_stock, reserved_stock FROM items WHERE id IN (...) FOR UPDATE`).
  4. Ensure `(current_stock - reserved_stock) >= requested_quantity`. Reject with HTTP 400 if stock depleted.
  5. Increment `reserved_stock`.
  6. Insert into `orders` and `order_details`.
  7. If Razorpay, initiate payment link/order. If COD, set `order_status = 'confirmed'`.
  8. Commit transaction.
  9. Publish `order.placed` event to Redis BullMQ.

---

## 2. Fattakse Quick — Tirora Dark Store Fulfillment Workflow

**Crucial Note:** Walk-in retail and physical counter checkout (Hyper POS) are **excluded**. Fulfillment is 100% digital **Pick & Pack**.

```
+---------------+     +---------------+     +---------------+     +---------------+
| Order Placed  |     | Picker Screen |     | Item Picking  |     | Bag Packing   |
| (Status:      | --> | Queue         | --> | & Barcode     | --> | & Tamper Seal |
| 'confirmed')  |     | (Vendor Portal|     | Verification  |     | (Status:      |
+---------------+     +---------------+     +---------------+     |  'packed')    |
                                                                  +---------------+
                                                                          |
                                                                          v
+---------------+     +---------------+     +---------------+     +---------------+
| Handover to   |     | Out For       |     | Doorstep 18+  |     | Order Complete|
| Assigned Rider| <-- | Delivery      | <-- | ID Check &    | <-- | & Stock Ledger|
| (Status:      |     | (Live GPS     |     | Delivery OTP  |     | Reconciled    |
|  'ready')     |     |  Tracking)    |     | Verified      |     |               |
+---------------+     +---------------+     +---------------+     +---------------+
```

### 2.1 Multi-Owner Inventory Model (Tirora Dark Store)
The Tirora dark store manages two distinct categories of physical stock:
1. **Fattakse-Owned Inventory:** Procured directly from distributors/wholesalers by Evolw Technologies Pvt Ltd. Evolw takes full commercial margin and bears inventory holding risk.
2. **Seller-Deposited Inventory:** Local Tirora merchants deposit stock into the dark store to enable late-night/24x7 online fulfillment. Stock ownership remains with the merchant until customer delivery.
   - System records `inventory_owner_type: 'vendor'` and `inventory_owner_id: <vendor_id>`.
   - On completion, customer funds are credited to merchant ledger minus agreed platform commission.

### 2.2 Urgent Seller Stock Withdrawal Workflow
If a local merchant urgently requires their deposited stock back at their physical store:
1. Merchant submits stock withdrawal request in the Vendor Web/App portal (`POST /api/v1/vendor/inventory/withdraw-request`).
2. System computes strictly available, unreserved stock: `withdrawable_quantity = (current_stock - reserved_stock)`.
3. Dark-store manager approves request on the admin console.
4. Staff physically picks the items; stock balance is decremented from the dark store ledger.
5. Merchant acknowledges physical receipt via signature/scan.

### 2.3 Dark Store Pick, Pack & Handover Steps
1. **Pick Queue:** Dark-store pickers view active orders sorted by SLA priority on the React Vendor portal.
2. **Item Scanning:** Picker uses a handheld Bluetooth barcode scanner or mobile camera to scan each picked item's barcode. System verifies barcode match against `items.barcode`.
3. **Item Packing:** Order items are placed into a recyclable paper/biodegradable bag. A unique QR-coded tamper-evident seal is applied to the bag.
4. **Order Status:** Updated from `picking` to `packed`, then `ready`.
5. **Rider Handover:** Proximity-dispatched FattakSe rider arrives, scans the tamper-evident bag QR code to confirm handover, advancing state to `out_for_delivery`.

---

## 3. Fattakse Food — Restaurant Fulfillment Workflow

Restaurants operate under two distinct fulfillment models:

### 3.1 Model A: Fattakse Delivery (Standard)
- Restaurant accepts order (`POST /api/v1/vendor/order/update-status` -> `processing`).
- Restaurant prepares meal and marks `food_ready`.
- Proximity-assigned FattakSe rider arrives at restaurant, picks up food parcel, and delivers to customer.

### 3.2 Model B: Restaurant-Managed Delivery
- Restaurant utilizes its own delivery staff.
- Restaurant accepts order, prepares meal, and assigns internal rider.
- Fattakse charges marketplace commission and waives delivery fleet fee.

---

## 4. Delivery, Fleet & Doorstep Completion

### 4.1 Proximity Dispatch Algorithm
- When order transitions to `confirmed` (Food) or `packed` (Quick Dark Store), the dispatch engine queries active riders (`delivery_men.is_active = 1` and `is_online = 1`) within a 3km radius.
- Rider receives push notification via FCM with a 30-second accept/reject countdown timer.
- Upon acceptance, rider navigates to store via Mapbox route optimization.

### 4.2 Doorstep 18+ Verification & Delivery OTP
- **Regulated Products / Night Deliveries:** If an order contains age-restricted items (energy drinks, specialized personal care), the Rider app prompts for physical 18+ photo ID verification prior to handing over the package.
- **Delivery Confirmation:** Customer provides a 4-digit OTP shown in their app. Rider enters OTP (`POST /api/v1/delivery-man/order/complete-delivery`).
- **State Transition:** Order is marked `delivered`.
- **Financial Ledger:** If COD, rider wallet balance is debited with cash collected; if online, Razorpay settlement record is marked eligible for merchant disbursement.

---

## 5. Financial Settlements, Unit Economics & Town-Level P&L (Tirora Hub)

Strictly adhering to Section 7 & 8 of the Evolw Technologies business model:

### 5.1 Accounting Invariant: GMV vs. Revenue vs. Contribution
The system enforces strict accounting separation across ledger entries:
- **Gross Merchandise Value (GMV):** Total customer transaction value.
- **FattakSe Recognized Revenue:**
  - *Own Inventory (Quick):* Total selling price (minus COGS = gross margin).
  - *Seller-Deposited Inventory (Quick):* Marketplace commission/service fee only (the product price is credited to the seller).
  - *Restaurant Food:* Agreed commission percentage + customer delivery fee (on FattakSe-delivered orders).
  - *Customer Fees:* Platform processing fee (e.g. ₹5) + customer delivery fee.
- **Order Contribution:** Revenue minus order-specific direct costs (actual rider payout, Razorpay payment gateway fee ~2%, platform-funded discounts, packaging material).
- **Operating Profit:** Contribution minus town fixed costs (Tirora dark-store rent, electricity, storekeeper salaries, software, marketing).

### 5.2 Decoupling Customer Delivery Fee from Actual Rider Payout
The system never assumes customer delivery fee equals rider cost:
- `orders.delivery_charge`: What the customer was billed (e.g. ₹25).
- `order_transactions.delivery_fee_earned`: What the rider is paid based on distance/waiting time (e.g. ₹35).
- `order_transactions.delivery_subsidy`: The gap (e.g. ₹10) funded by FattakSe from product margin/commission.

### 5.3 Weekly Seller & Restaurant Settlement Schedule
- **Cycle:** Monday 00:00 to Sunday 23:59 sales are reconciled on Monday; disbursements processed on Tuesday/Wednesday.
- **Itemized Settlement Statement:**
  - Opening balance
  - Completed orders gross value
  - Less: Agreed commission/service fee
  - Less: Approved customer refunds / damaged item adjustments
  - Less: Statutory GST TCS (1%) and TDS withholding
  - Net payable amount + bank UTR reference.

### 5.4 Tirora Town-Level P&L View
The admin control plane provides a town-filtered dashboard for Tirora aggregating:
$$\text{Town Contribution} = (\text{Own Margins} + \text{Seller Fees} + \text{Food Commissions} + \text{Customer Fees}) - (\text{Rider Costs} + \text{Gateway Fees} + \text{Refunds})$$
This allows the operations manager to immediately determine the exact order volume required for the Tirora dark store to achieve operational break-even.

---

## 6. Paan Corner & Regulated Smoking/Tobacco — Dual-Channel Consumer Strategy

### 6.0 Why a Full-Catalog Web Storefront (Not Tobacco-Only)
A web app that **only** sells cigarettes and tobacco won't attract enough repeat traffic — customers won't bother opening it for a single-category purchase. But a web storefront where customers can order their regular groceries, dark store essentials, restaurant food, **and** paan corner tobacco products in a single session creates a compelling one-stop shopping experience. This drives significantly higher Average Order Value (AOV) and positions the web app as a genuine alternative channel — not a narrow niche tool.

### 6.1 Dual-Channel Architecture

```
                         FLUTTER CUSTOMER APP                    REACT USER WEB STOREFRONT
                         (townsfattakappin_ios_android_user)      (user-web at fattakse.in)
                         +-------------------------------+       +-------------------------------+
                         |  Grocery ✓  Dark Store ✓      |       |  Grocery ✓  Dark Store ✓      |
                         |  Food ✓     Supermarket ✓     |       |  Food ✓     Supermarket ✓     |
                         |  Tobacco ✗  (BLOCKED by       |       |  Tobacco ✓  Paan Corner ✓     |
                         |              API Gateway for  |       |  (COTPA 2003 age-gate on      |
                         |              App Store safety) |       |   tobacco category pages)     |
                         +-------------------------------+       +-------------------------------+
                                        |                                       |
                                        v                                       v
                         +--------------------------------------------------------------+
                         |          API GATEWAY — REGULATED CATEGORY FIREWALL            |
                         |  if (client == flutter_app) { exclude tobacco categories }    |
                         |  if (client == web_storefront) { serve full catalog }          |
                         +--------------------------------------------------------------+
```

### 6.2 App Store Regulatory Immunity
1. **Zero Tobacco on Flutter Apps:** The API Gateway inspects `X-Software-Id` / `User-Agent` headers. Requests from the Flutter Customer App (`is_app_store_client: true`) automatically exclude all items in tobacco/smoking categories and all stores with `store_type = 'paan_corner'`. This provides 100% immunity from Google Play and Apple App Store bans.
2. **Full Catalog on Web Storefront:** The React User Web Storefront (`user-web`) at `fattakse.in` receives the complete unrestricted catalog — groceries, dark store, food, **and** paan corner/tobacco products. Since it runs in a mobile browser, it is exempt from all App Store content policies.

### 6.3 COTPA Act 2003 Compliance Rules (Web Storefront Tobacco Pages)
1. **Mandatory 18+ Age Interstitial:** When a web customer navigates to any tobacco category or paan corner store page, a mandatory interstitial requires: *"I am 18 years of age or older. I understand tobacco products are harmful to health."* with explicit Date of Birth (DOB) entry before the product catalog is rendered.
2. **Statutory Warnings:** Standard Indian statutory warnings (*"Smoking Causes Cancer"*, *"Tobacco Kills"*) are rendered directly on tobacco product display cards.
3. **100-Yard Educational Exclusion Zone:** Onboarding of Paan Corners situated within 100 yards (91.4 meters) of any school, college, or educational institution in Tirora is strictly prohibited by GIS geofencing in `store-service`.
4. **Doorstep Physical ID Verification:** When delivering any order containing tobacco items, the Rider app displays an unskippable prompt:
   - *"Mandatory 18+ Check: Inspect customer's physical government photo ID (Aadhaar / Voter ID / Driving License) before handing over package."*
   - Rider must confirm verification before the 4-digit customer delivery OTP entry field unlocks.
   - If customer is underage or refuses ID check: Rider taps *"Underage Customer - Abort Delivery"*; tobacco items return to the Paan Corner; order is cancelled without refund of delivery fee.

