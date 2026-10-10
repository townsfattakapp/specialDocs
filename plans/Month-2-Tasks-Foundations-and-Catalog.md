# Month 2: Core Foundations, IAM, Store Zones, Catalog & Cart Pricing (Weeks 5–8)

**Objective:** Implement production-grade Identity & Access Management, Merchant & Store GIS Zones, Master Catalog with Typesense real-time search, Bulk Product Importer, and the Cart / Dynamic Quotation engine.  
**Acceptance Gate 2:** The frozen Flutter Customer app successfully authenticates via OTP, searches the Typesense catalog, adds items to cart, and receives an accurate checkout quotation matching the Laravel reference implementation byte-for-byte in the Staging environment.

---

## Week 5: Identity & Access Service (`iam-service`) & Passport JWT Emulation

### Detailed Tasks by Role

#### ARCH (Principal Architect & Project Lead)
- **`M2-W5-ARCH-01` Cryptographic Key Compatibility Proof:** Author test script signing tokens in Node.js and verifying via Laravel CLI (`php artisan passport:keys`), and vice versa.
- **`M2-W5-ARCH-02` Anti-Abuse Rate Limiting Architecture:** Implement Redis sliding window rate limiter: maximum 3 OTP requests per phone number per 10 minutes; maximum 10 requests per IP per 10 minutes. Return HTTP 429 Too Many Requests with `{ errors: [{ code: "auth-004", message: "Too many OTP requests. Please wait." }] }`.

#### BE-1 (Senior Backend Engineer 1 — Auth & Edge Lead)
- **`M2-W5-BE1-01` Customer Phone OTP Authentication Pipeline:** Implement `POST /api/v1/auth/request-otp` and `POST /api/v1/auth/verify-phone`. Validate 10-digit Indian phone (`/^[6-9]\d{9}$/`). Store SHA-256 hashed OTP in Redis (`otp:customer:${phone}`, TTL: 300s). Dispatch SMS via MSG91 Flow API.
- **`M2-W5-BE1-02` Passport RSA Keypair Token Emulation:** Load Laravel Passport's RSA private/public keys. Issue RS256-signed JWTs with standard claims (`aud: "2"`, `scopes: ["customer"]`). Implement Fastify Passport strategy verifying both legacy Laravel and Node.js tokens.
- **`M2-W5-BE1-03` Vendor & Delivery Man Password Authentication:** Implement `POST /api/v1/auth/login` verifying email/phone and Bcrypt password against `fattakse_iam.vendors` and `delivery_men`. Issue scoped Bearer JWTs.
- **`M2-W5-BE1-04` Customer Profile & Address Book Endpoints:** Implement `GET /api/v1/customer/info`, `POST /api/v1/customer/address/add`, `GET /api/v1/customer/address/list`, `DELETE /api/v1/customer/address/delete`.

#### BE-2 (Senior Backend Engineer 2 — Catalog & Search)
- **`M2-W5-BE2-01` Catalog User Context Integration:** Implement Fastify user context decorator (`@CurrentUser()`) allowing catalog endpoints to extract customer zone preferences and auth state for personalized catalog pricing.

#### BE-3 (Senior Backend Engineer 3 — Commerce & Notifications)
- **`M2-W5-BE3-01` Setup `notify-service` Base SMS & Push Dispatcher:** Implement HTTP client in `notify-service` for MSG91 / Fast2SMS with exponential backoff and dead-letter queue for failed OTP deliveries. Scaffold Firebase Cloud Messaging (FCM HTTP v1) client.

#### FE-1 (Senior Frontend Engineer 1 — Admin Control Plane)
- **`M2-W5-FE1-01` Admin Staff Authentication & Session:** Build `/login` in `admin-react`. Store JWT in memory with httpOnly secure refresh cookie. Setup Axios interceptor auto-refreshing tokens on HTTP 401.

#### FE-2 (Senior Frontend Engineer 2 — Merchant & Dark Store)
- **`M2-W5-FE2-01` Vendor Portal Authentication Flow:** Build merchant and dark store manager login screen in `vendor-react` supporting both email/password and phone OTP with automatic redirect to role-specific dashboard.

#### DATA (Database Architect & ETL Data Engineer)
- **`M2-W5-DATA-01` Seed IAM Database & Verify Token Hashes:** Seed `fattakse_iam` with 50 customers, 1 super admin, 5 dark store staff, and 10 delivery riders. Verify that legacy Bcrypt password hashes validate correctly in Node.js.

#### QA (SDET / Automation Engineer)
- **`M2-W5-QA-01` Automated Auth Contract Tests:** Run automated test asserting byte-for-byte schema match between Laravel and Node.js on `/api/v1/auth/*` and `/api/v1/customer/*`. Assert exact `{ errors: [{ code, message }] }` error serialization.

---

## Week 6: Store & Merchant Operations Service (`store-service`) & Spatial GIS

### Detailed Tasks by Role

#### ARCH (Principal Architect & Project Lead)
- **`M2-W6-ARCH-01` Spatial GIS Engine Architecture:** Establish MySQL Spatial reference system (SRID 0 / 4326). Mandate that all zone queries use Kysely raw SQL with spatial indexing (`SPATIAL INDEX(coordinates)`).

#### BE-1 (Senior Backend Engineer 1 — Auth & Edge Lead)
- **`M2-W6-BE1-01` Spatial Delivery Zone Engine (`ST_Contains`):** Implement `GET /api/v1/zone/list` and `GET /api/v1/zone/check`. Query `fattakse_store.zones` using `ST_Contains(coordinates, ST_SRID(POINT(?, ?), 0))`. Cache active polygon boundaries in Redis (`zones:active`) with 1-hour TTL.
- **`M2-W6-BE1-02` Store Profiles & Operating Schedules:** Implement `GET /api/v1/stores/details/{id}`, `GET /api/v1/stores/get-stores`. Compute real-time store operational status (`is_open: boolean`) based on daily opening/closing slot arrays in `store_configs.schedule_order` and holiday override calendars.
- **`M2-W6-BE1-03` System Configuration Endpoints:** Implement `GET /api/v1/config`, `/configurations/get-external` returning active verticals (`quick`, `food`), currency symbol (`₹`), delivery fee tiers, and maintenance mode status.

#### BE-2 (Senior Backend Engineer 2 — Catalog & Search)
- **`M2-W6-BE2-01` Store-to-Catalog Filtering Link:** Implement internal gRPC/HTTP endpoint allowing `catalog-service` to resolve active store IDs in a given `zoneId`.

#### BE-3 (Senior Backend Engineer 3 — Commerce & Core)
- **`M2-W6-BE3-01` Multi-Vertical Module Routing Foundation:** Implement module routing rules in `order-service` ensuring that cart and order placement differentiate `moduleId = 1` (Quick Grocery) from `moduleId = 2` (Restaurant Food).

#### FE-1 (Senior Frontend Engineer 1 — Admin Control Plane)
- **`M2-W6-FE1-01` Merchant Management Screen (`/stores`):** Build store table with search, zone filter, KYC document approval modal, commission percentage setup, and active status toggle.
- **`M2-W6-FE1-02` Mapbox Delivery Zone Editor (`/zones`):** Build interactive Mapbox polygon drawing interface allowing operations staff to draw, adjust, and save Tirora delivery zone boundaries visually.

#### FE-2 (Senior Frontend Engineer 2 — Merchant & Dark Store)
- **`M2-W6-FE2-01` Store Settings & Operational Hours:** Build `/settings` in `vendor-react` allowing store managers to configure daily opening hours and temporary holiday closures.

#### DATA (Database Architect & ETL Data Engineer)
- **`M2-W6-DATA-01` Spatial GIS Migration Script:** Ensure legacy MySQL polygon WKT strings in `zones.coordinates` transform cleanly into MySQL 8.0 `POLYGON` spatial datatypes with spatial index.

#### QA (SDET / Automation Engineer)
- **`M2-W6-QA-01` Spatial Boundary Verification Tests:** Test 100 coordinates along Tirora zone boundaries; verify 100% containment match between Laravel Eloquent Spatial and Node.js Kysely.

---

## Week 7: Master Catalog & Real-time Typesense Search (`catalog-service`)

### Detailed Tasks by Role

#### ARCH (Principal Architect & Project Lead)
- **`M2-W7-ARCH-01` Typesense Cluster Sharding & Schema Design:** Review and approve `product_catalog_v1` Typesense schema: strict typing for `id`, `name`, `category_id`, `brand_id`, `price`, `discount_price`, `zone_ids`, `in_stock`, `rating`.

#### BE-1 (Senior Backend Engineer 1 — Auth & Edge)
- **`M2-W7-BE1-01` Admin Staff RBAC Middleware:** Implement role-based access control guards (`@Roles('ADMIN', 'SUPER_ADMIN')`, `@Permissions('CATALOG_EDIT')`) on catalog modification endpoints.

#### BE-2 (Senior Backend Engineer 2 — Catalog & Search Lead)
- **`M2-W7-BE2-01` Master Catalog & Hierarchical Categories:** Implement `GET /api/v1/categories`, `GET /api/v1/categories/childes/{id}`, `GET /api/v1/items/details/{id}`. Return hierarchical category tree, master items, variants, attributes, units, allergens, and nutrition info.
- **`M2-W7-BE2-02` Typesense Change-Data-Capture (CDC) via Kafka:** Publish catalog item and price updates to Kafka topic `fattakse.catalog.events` via transactional outbox. A dedicated `TypesenseCdcConsumer` streams events and upserts documents into Typesense in < 250ms with zero index drift.
- **`M2-W7-BE2-03` Hyperlocal Typesense Search API:** Implement `GET /api/v1/items/search`. Query Typesense 28.0 cluster with multi-field fuzzy search, filtering strictly by `store_id IN (...)` and `zone_id = ?`.
- **`M2-W7-BE2-04` Bulk CSV Product Importer & Barcode Resolution:** Implement `POST /api/v1/admin/items/import-csv` and `GET /api/v1/items/barcode-lookup`. Parse CSV files, validate HSN codes, generate unique EAN-13 barcodes for non-barcoded items, and bulk-insert.

#### BE-3 (Senior Backend Engineer 3 — Commerce & Core)
- **`M2-W7-BE3-01` Multi-Owner Stock Contract Design:** Define TypeScript DTOs and database contracts in `inventory-service` for dark store stock allocations (`owner_type: 'evolw' | 'seller'`).

#### FE-1 (Senior Frontend Engineer 1 — Admin Control Plane)
- **`M2-W7-FE1-01` Master Catalog Management Screen (`/catalog/items`):** Item listing table with image previews, category filter, stock indicators, variant builder modal, and bulk CSV upload button.
- **`M2-W7-FE1-02` Category Tree Manager (`/catalog/categories`):** Drag-and-drop category hierarchy manager with image upload.

#### FE-2 (Senior Frontend Engineer 2 — Merchant & Dark Store)
- **`M2-W7-FE2-01` Dark Store Rack & Bin UI Scaffold:** Build UI components for assigning rack/bin locations to newly imported products in `vendor-react`.

#### DATA (Database Architect & ETL Data Engineer)
- **`M2-W7-DATA-01` Catalog Data Backfill & Indexing:** Load 5,000 real Tirora catalog SKUs into `fattakse_catalog.items` and run full batch indexing into Typesense. Verify zero schema mismatch errors.

#### QA (SDET / Automation Engineer)
- **`M2-W7-QA-01` Typesense Search Relevance & Benchmark Tests:** Benchmark 200 fuzzy search queries; verify that p95 search latency is < 25ms.

---

## Week 8: Cart Management, Indian GST Engine & Checkout Quotes

### Detailed Tasks by Role

#### ARCH (Principal Architect & Project Lead)
- **`M2-W8-ARCH-01` Checkout Math Parity Audit:** Run 100 multi-item cart scenarios comparing Node.js quotation output against Laravel `Helpers::get_cart_data()`; assert exact match to the paisa (0.00 INR variance).

#### BE-1 (Senior Backend Engineer 1 — Auth & Edge)
- **`M2-W8-BE1-01` Gateway Header & Session Validation on Checkout:** Verify that customer auth tokens and delivery address coordinates are validated prior to passing requests to `order-service`.
- **`M2-W8-BE1-02` API Gateway Regulated Category Firewall:** Configure gateway policy ensuring Flutter Customer App requests (`is_app_store_client: true`) never receive tobacco categories/stores, while allowing browser requests from `user-web` to receive the full unrestricted catalog including paan corner items for App Store safety and maximum basket AOV.

#### BE-2 (Senior Backend Engineer 2 — Catalog & Search)
- **`M2-W8-BE2-01` Cart Synchronization Endpoint (`POST /api/v1/cart/sync`):** Accept cart line items, validate item existence and active status. Enforce that grocery items and restaurant food cannot be mixed in the same cart. Return updated line items with current prices and out-of-stock flags.

#### BE-3 (Senior Backend Engineer 3 — Commerce Lead)
- **`M2-W8-BE3-01` Indian GST & HSN Calculator Engine:** Match item `hsn_code` against `fattakse_catalog.hsn_gst_master`. Compute intraday CGST + SGST (2.5% + 2.5% for 5% goods; 9% + 9% for 18% goods) for Maharashtra State Code 27.
- **`M2-W8-BE3-02` Distance Matrix Delivery Fee Engine:** Compute road distance using Mapbox Matrix API between store coordinates and customer address. Apply base delivery charge (e.g. ₹20 for first 2km) + per-km curve from `business_settings`.
- **`M2-W8-BE3-03` Dynamic Checkout Quotation API (`POST /api/v1/checkout/get-quote`):** Compute subtotal, item discounts, store coupon deductions, GST tax breakdown, delivery fee, and platform processing fee (₹5). Enforce store-level **minimum order value**; reject with HTTP 400 if subtotal < minimum order.

#### FE-1 (Senior Frontend Engineer 1 — Admin Control Plane)
- **`M2-W8-FE1-01` Pricing & Fee Configuration Screens (`/settings`):** Build UI for delivery fee distance curves, platform fees, minimum order thresholds, and surge pricing multipliers.

#### FE-2 (Senior Frontend Engineer 2 — Merchant & Web Storefront)
- **`M2-W8-FE2-01` Item Availability Toggle Screen (`/menu/availability`):** Build quick item 86-ing / out-of-stock toggle in `vendor-react` for restaurant rush hours.
- **`M2-W8-FE2-02` Full-Catalog Consumer Web Storefront Scaffolding (`user-web`):** Scaffold/modernize mobile-first React 19 PWA (`user-web` at `fattakse.in`) supporting full catalog discovery (groceries, food, dark store, paan corner), multi-store browsing, and an integrated 18+ Age Interstitial modal with DOB declaration and COTPA 2003 statutory warnings when entering the Paan Corner category.

#### DATA (Database Architect & ETL Data Engineer)
- **`M2-W8-DATA-01` GST & Tax Setup Validation:** Seed `hsn_gst_master` with standard grocery, dairy, and food HSN codes; write automated verification script ensuring correct GST percentage calculation.

#### QA (SDET / Automation Engineer)
- **`M2-W8-QA-01` Flutter Mobile Client Staging Integration:** Point frozen Flutter Customer app to Staging Gateway. Execute user journey: Login with OTP -> Select Tirora address -> Search catalog via Typesense -> Add items to cart -> View checkout quote. Verify zero app crashes and exact visual parity.

---

## Gate 2 Acceptance Criteria Sign-Off Checklist
- [ ] Customer phone OTP authentication operational with Passport RSA JWT validation.
- [ ] MySQL spatial GIS delivery zone resolution verified.
- [ ] Typesense 28.0 catalog search responding in < 25ms with sub-second change-data-capture.
- [ ] Bulk CSV product import and barcode lookup operational.
- [ ] Checkout quotation calculates Indian GST, delivery fees, and platform fees matching Laravel to 0.00 INR discrepancy.
- [ ] Frozen Flutter Customer app runs successfully against Staging environment.
