# Month 2 Task Prompts: Core Foundations, IAM, Store Zones, Catalog & Pricing (Weeks 5–8)

This document contains production-grade, copy-pasteable execution prompts for each task in Month 2.

---

## Table of Contents
- [Week 5 Prompts](#week-5-identity--access-service-iam-service--passport-jwt-emulation)
- [Week 6 Prompts](#week-6-store--merchant-operations-service-store-service--spatial-gis)
- [Week 7 Prompts](#week-7-master-catalog--real-time-typesense-search-catalog-service)
- [Week 8 Prompts](#week-8-cart-management-indian-gst-engine--checkout-quotes)

---

## Week 5: Identity & Access Service (`iam-service`) & Passport JWT Emulation

### `[M2-W5-ARCH-01]` Cryptographic Key Compatibility Proof
**Assignee:** ARCH (Principal Architect & Project Lead)  
**Target Files:** `scripts/verify_passport_keys.ts`

```text
You are acting as the Principal Architect (ARCH) for the Fattakse platform modernization (Evolw Technologies Private Limited).

TASK: M2-W5-ARCH-01 - Cryptographic Key Compatibility Proof

CONTEXT:
Active mobile customers, vendors, and riders have valid Laravel Passport tokens stored in their SQLite / SecureStorage on their phones. We must validate existing Laravel tokens and sign new tokens in Node.js that are mutually verifiable without forcing logouts (ADR-0003 / Risk R-03).

REQUIREMENTS:
1. Locate Laravel Passport RSA keys: oauth-public.key and oauth-private.key in storage/ or config/.
2. Author scripts/verify_passport_keys.ts:
   - Load oauth-private.key using Node.js crypto / jsonwebtoken.
   - Issue a test JWT with claims matching Laravel Passport: { "aud": "2", "jti": "...", "iat": ..., "nbf": ..., "exp": ..., "sub": "101", "scopes": ["customer"] }.
   - Sign using RS256 algorithm.
   - Verify the signature using oauth-public.key.
   - Execute a shell call to php -r to verify the same token using Laravel's Passport verifier.
3. Validate that an actual token extracted from a live customer session can be decoded and verified by Node.js jsonwebtoken library using oauth-public.key.

DEFINITION OF DONE:
- Bi-directional token verification script passes with exit code 0.
- Token claims match Laravel Passport specification exactly.
```

---

### `[M2-W5-BE1-01]` Customer Phone OTP Authentication Pipeline
**Assignee:** BE-1 (Senior Backend Engineer 1 — Auth & Edge Lead)  
**Target Files:** `apps/iam-service/src/auth/customer-auth.controller.ts`, `apps/iam-service/src/auth/customer-auth.service.ts`

```text
You are acting as Senior Backend Engineer 1 (BE-1) for the Fattakse platform modernization.

TASK: M2-W5-BE1-01 - Customer Phone OTP Authentication Pipeline

CONTEXT:
Customers log in to the Flutter mobile app and React User Web Storefront using Indian 10-digit mobile phone numbers and SMS OTPs.

REQUIREMENTS:
1. Implement POST /api/v1/auth/request-otp:
   - Accept body: { "phone": string }.
   - Validate format: 10-digit Indian mobile number (/^[6-9]\d{9}$/).
   - Generate secure 4-digit or 6-digit numeric OTP.
   - Store SHA-256 hashed OTP in Redis with key otp:customer:${phone} and TTL: 300 seconds (5 minutes).
   - In dev mode (APP_ENV=local), log OTP to console or set fixed OTP 1234.
   - In staging/production, publish SMS dispatch event to notify-service via BullMQ or MSG91 Flow API.
   - Return legacy Laravel response: { "message": "OTP sent successfully", "is_phone_verified": 0 }.
2. Implement POST /api/v1/auth/verify-phone:
   - Accept body: { "phone": string, "otp": string }.
   - Fetch hash from Redis, verify timing-safe match.
   - Upsert customer in fattakse_iam.users.
   - Issue Passport-emulated Bearer JWT token.
   - Return response: { "token": "<JWT>", "is_phone_verified": 1, "user_id": number }.
3. Handle rate limits: reject requests exceeding 3 OTP requests in 10 minutes with HTTP 429.

DEFINITION OF DONE:
- Integration test covers: valid OTP login, invalid OTP (HTTP 400), expired OTP, and rate limit triggers.
```

---

### `[M2-W5-BE1-02]` Passport RSA Keypair Token Emulation
**Assignee:** BE-1 (Senior Backend Engineer 1 — Auth & Edge Lead)  
**Target Files:** `apps/iam-service/src/passport/passport-jwt.service.ts`, `packages/common/src/guards/jwt-auth.guard.ts`

```text
You are acting as Senior Backend Engineer 1 (BE-1) for the Fattakse platform modernization.

TASK: M2-W5-BE1-02 - Passport RSA Keypair Token Emulation

CONTEXT:
We must issue tokens that the frozen Flutter apps recognize as standard Laravel Passport tokens, and we must decode existing bearer tokens sent by active devices.

REQUIREMENTS:
1. Create passport-jwt.service.ts in iam-service:
   - Load RSA private key (PASSPORT_PRIVATE_KEY) and public key (PASSPORT_PUBLIC_KEY) from environment variables.
   - Issue tokens with standard Passport claims:
     - iss: "https://fattakse.in"
     - aud: "2"
     - sub: String(user.id)
     - scopes: user.role === 'customer' ? ['customer'] : ['vendor']
     - exp: Math.floor(Date.now() / 1000) + (365 * 24 * 60 * 60) (1 year long-lived token)
2. In packages/common/src/guards/jwt-auth.guard.ts:
   - Implement Fastify preHandler hook extracting Bearer <token>.
   - Verify token signature using PASSPORT_PUBLIC_KEY.
   - Attach user context to request: req.user = { id: sub, role, scopes }.
3. Write unit tests ensuring tokens generated by Node.js have identical structure to tokens generated by Laravel Passport.

DEFINITION OF DONE:
- Auth guard successfully authenticates a token signed with the legacy keypair.
- Guard rejects tampered or expired tokens with HTTP 401.
```

---

### `[M2-W5-BE1-03]` Vendor & Delivery Man Password Authentication
**Assignee:** BE-1 (Senior Backend Engineer 1 — Auth & Edge Lead)  
**Target Files:** `apps/iam-service/src/auth/vendor-auth.controller.ts`, `apps/iam-service/src/auth/vendor-auth.service.ts`

```text
You are acting as Senior Backend Engineer 1 (BE-1) for the Fattakse platform modernization.

TASK: M2-W5-BE1-03 - Vendor & Delivery Man Password Authentication

CONTEXT:
Vendors and riders log in with email/phone and password. Legacy passwords were saved using PHP's password_hash(..., PASSWORD_BCRYPT).

REQUIREMENTS:
1. Implement POST /api/v1/auth/vendor/login and POST /api/v1/auth/delivery-man/login.
2. Accept: { "email": string, "password": string } or { "phone": string, "password": string }.
3. Verify password against fattakse_iam.users using bcrypt.compare:
   - Support standard cost 10/12 Bcrypt hashes starting with $2y$ or $2b$.
4. Check account status: if status === 0 (inactive/suspended), return HTTP 403 Forbidden with { errors: [{ code: "auth-002", message: "Account is pending approval or inactive" }] }.
5. Issue scoped Bearer token (scopes: ['vendor'] or ['delivery_man']).
6. Return legacy response shape with user details and store_id association.

DEFINITION OF DONE:
- Unit tests verify login with legacy Laravel Bcrypt password hash.
- Inactive vendor accounts are blocked cleanly.
```

---

## Week 6: Store & Merchant Operations Service (`store-service`) & Spatial GIS

### `[M2-W6-BE1-01]` Spatial Delivery Zone Engine (`ST_Contains`)
**Assignee:** BE-1 (Senior Backend Engineer 1 — Auth & Edge Lead)  
**Target Files:** `apps/store-service/src/zones/zones.service.ts`, `apps/store-service/src/zones/zones.controller.ts`

```text
You are acting as Senior Backend Engineer 1 (BE-1) for the Fattakse platform modernization.

TASK: M2-W6-BE1-01 - Spatial Delivery Zone Engine (ST_Contains)

CONTEXT:
Fattakse operates hyperlocal deliveries within specific geographic boundaries (Tirora, Maharashtra). The app sends customer GPS coordinates, and the backend must determine which delivery zone contains the customer.

REQUIREMENTS:
1. Implement GET /api/v1/zone/check?lat={latitude}&lng={longitude}:
   - Validate lat/lng are valid float coordinates.
   - Execute spatial query in Kysely against fattakse_store.zones:
     ```sql
     SELECT id, name, minimum_shipping_charge, per_km_shipping_charge
     FROM zones
     WHERE status = 1 
       AND ST_Contains(coordinates, ST_SRID(POINT(lng, lat), 0))
     LIMIT 1;
     ```
   - Return matching zone object or HTTP 404 if outside delivery service area: { errors: [{ code: "zone-001", message: "Service not available in this location" }] }.
2. Implement GET /api/v1/zone/list:
   - Return all active zones with serialized GeoJSON coordinates.
3. Cache active zones in Redis (zones:active) with 1-hour TTL and invalidate on zone update.

DEFINITION OF DONE:
- Spatial query correctly resolves Tirora center coordinates (21.4089, 79.9322) to Zone 1.
- Coordinates outside Tirora return HTTP 404 with standard error format.
```

---

### `[M2-W6-BE1-02]` Store Profiles & Operating Schedules
**Assignee:** BE-1 (Senior Backend Engineer 1 — Auth & Edge Lead)  
**Target Files:** `apps/store-service/src/stores/stores.service.ts`, `apps/store-service/src/stores/stores.controller.ts`

```text
You are acting as Senior Backend Engineer 1 (BE-1) for the Fattakse platform modernization.

TASK: M2-W6-BE1-02 - Store Profiles & Operating Schedules

CONTEXT:
The platform supports multiple store types (dark stores, supermarkets, restaurants, paan corners). Stores have daily operating hours and holiday schedules that determine if a customer can place an order.

REQUIREMENTS:
1. Implement GET /api/v1/stores/get-stores?zone_id={zoneId}&module_id={moduleId}:
   - Query stores in given zone and vertical (Quick vs Food).
   - Compute is_open dynamically: compare current Indian Standard Time (Asia/Kolkata) against store's active day slots in schedule_order.
   - Return store cards: id, name, logo, cover_photo, address, rating, delivery_time, minimum_order, is_open.
2. Implement GET /api/v1/stores/details/{id}:
   - Return full profile, banner, schedules, KYC verified badge, and commission settings.
3. Write test validating store status at 02:00 AM (closed) vs 14:00 PM (open).

DEFINITION OF DONE:
- Response matches legacy Laravel /api/v1/stores/* JSON shape.
- Operating hour calculations respect Asia/Kolkata timezone.
```

---

### `[M2-W6-FE1-02]` Mapbox Delivery Zone Editor (`/zones`)
**Assignee:** FE-1 (Senior Frontend Engineer 1 — Admin Control Plane)  
**Target Files:** `apps/admin-react/src/pages/zones/ZoneEditor.tsx`

```text
You are acting as Senior Frontend Engineer 1 (FE-1) for the Fattakse platform modernization.

TASK: M2-W6-FE1-02 - Mapbox Delivery Zone Editor (/zones)

CONTEXT:
Operations managers need to visually draw and edit delivery zone boundary polygons on a map in admin-react.

REQUIREMENTS:
1. In admin-react, build /zones/edit/:id and /zones/create using mapbox-gl and @mapbox/mapbox-gl-draw.
2. Map loads centered on Tirora, Maharashtra (21.4089° N, 79.9322° E).
3. Features:
   - Polygon drawing mode with draggable vertices.
   - Coordinate preview (GeoJSON Polygon coordinates).
   - Form fields: Zone Name, Minimum Shipping Charge (₹), Per-KM Rate (₹), Maximum COD Amount (₹).
   - Save button sending GeoJSON to store-service POST /api/v1/admin/zone/store.
4. Add polygon validation: prevent self-intersecting polygons and alert user.

DEFINITION OF DONE:
- Manager can draw a polygon around Tirora and save without errors.
- Polygon renders correctly on subsequent edit view.
```

---

## Week 7: Master Catalog & Real-time Typesense Search (`catalog-service`)

### `[M2-W7-BE2-01]` Master Catalog & Hierarchical Categories
**Assignee:** BE-2 (Senior Backend Engineer 2 — Catalog & Search Lead)  
**Target Files:** `apps/catalog-service/src/items/items.service.ts`, `apps/catalog-service/src/categories/categories.service.ts`

```text
You are acting as Senior Backend Engineer 2 (BE-2) for the Fattakse platform modernization.

TASK: M2-W7-BE2-01 - Master Catalog & Hierarchical Categories

CONTEXT:
The catalog organizes thousands of products into departments, categories, and subcategories, supporting variants (e.g. 500g vs 1kg) and nutrition info.

REQUIREMENTS:
1. Implement GET /api/v1/categories?zone_id={zoneId}:
   - Query root categories (parent_id IS NULL) with active products in the customer's zone.
   - Return: id, name, image, banner_image, module_id.
2. Implement GET /api/v1/categories/childes/{id}:
   - Return subcategories for given parent ID.
3. Implement GET /api/v1/items/details/{id}:
   - Return complete product details: name, description, images, unit_type, price, discount, discount_type, available_time_starts, available_time_ends, attributes, choice_options, variations, add_ons.
4. Preserve exact field naming to match Flutter customer models.

DEFINITION OF DONE:
- Category tree queries execute in < 20ms using indexed parent_id queries.
- Product details match legacy Flutter DTO expectations.
```

---

### `[M2-W7-BE2-02]` Typesense Change-Data-Capture (CDC) via Kafka
**Assignee:** BE-2 (Senior Backend Engineer 2 — Catalog & Search Lead)  
**Target Files:** `apps/catalog-service/src/search/typesense-cdc.consumer.ts`, `apps/catalog-service/src/outbox/`

```text
You are acting as Senior Backend Engineer 2 (BE-2) for the Fattakse platform modernization.

TASK: M2-W7-BE2-02 - Typesense Change-Data-Capture (CDC) via Kafka

CONTEXT:
When items are added, updated, or marked out of stock in MySQL, Typesense 28.0 must be updated immediately (< 250ms) to ensure search results reflect accurate stock and prices.

REQUIREMENTS:
1. Whenever catalog items change in MySQL, write event to outbox_events table in the same transaction.
2. Outbox relay publishes to Kafka topic fattakse.catalog.events with key = item_id.
3. Implement TypesenseCdcConsumer in catalog-service listening to fattakse.catalog.events:
   - On ITEM_CREATED / ITEM_UPDATED: Fetch item with current store associations and upsert into Typesense product_catalog_v1 collection.
   - On ITEM_DELETED / ITEM_OUT_OF_STOCK: Update in_stock flag or delete from index.
4. Measure latency from MySQL transaction commit to Typesense document upsert.

DEFINITION OF DONE:
- Document upserts in Typesense within 250ms of MySQL write.
- Automated test verifies index state matches database state after 50 rapid item updates.
```

---

### `[M2-W7-BE2-03]` Hyperlocal Typesense Search API
**Assignee:** BE-2 (Senior Backend Engineer 2 — Catalog & Search Lead)  
**Target Files:** `apps/catalog-service/src/search/search.controller.ts`, `apps/catalog-service/src/search/search.service.ts`

```text
You are acting as Senior Backend Engineer 2 (BE-2) for the Fattakse platform modernization.

TASK: M2-W7-BE2-03 - Hyperlocal Typesense Search API

CONTEXT:
The Flutter app calls /api/v1/items/search to search groceries, vegetables, and restaurant dishes. Search must be fast, typo-tolerant, and filtered by the customer's delivery zone.

REQUIREMENTS:
1. Implement GET /api/v1/items/search?name={query}&zone_id={zoneId}&store_id={storeId}&limit=20&offset=0:
   - Execute Typesense multi-search query against product_catalog_v1.
   - Query parameters:
     - q: name
     - query_by: name,description,category_name
     - filter_by: zone_ids:=[{zoneId}] && in_stock:true
     - num_typos: 2 (auto typo-tolerance)
     - per_page: limit
     - page: (offset / limit) + 1
2. Transform Typesense response into legacy Flutter format:
   ```json
   {
     "total_size": 42,
     "limit": "20",
     "offset": "0",
     "products": [...]
   }
   ```
3. Target search execution time: < 25ms.

DEFINITION OF DONE:
- Benchmark 50 realistic queries (e.g. "atta", "milk", "lays", "paneer"); p95 latency < 25ms.
- Typos like "milkk" correctly return "Milk" products.
```

---

## Week 8: Cart Management, Indian GST Engine & Checkout Quotes

### `[M2-W8-BE1-02]` API Gateway Regulated Category Firewall
**Assignee:** BE-1 (Senior Backend Engineer 1 — Auth & Edge)  
**Target Files:** `apps/api-gateway/src/middleware/category-firewall.middleware.ts`

```text
You are acting as Senior Backend Engineer 1 (BE-1) for the Fattakse platform modernization.

TASK: M2-W8-BE1-02 - API Gateway Regulated Category Firewall

CONTEXT:
We implement ADR-0009: Dual-Channel Consumer Strategy. Google Play and Apple App Store strictly prohibit tobacco and cigarette facilitation on mobile apps. The Flutter Customer App must remain 100% tobacco-free, while the React User Web Storefront (user-web) receives the full catalog including paan corner items.

REQUIREMENTS:
1. Create category-firewall.middleware.ts in api-gateway:
   - Inspect incoming request headers: X-Software-Id, User-Agent.
   - Detect client:
     - If request originates from Flutter app (X-Software-Id present, or mobile user agent without web session): mark is_app_store_client = true.
     - If request originates from browser (user-web at fattakse.in): mark is_app_store_client = false.
2. In downstream requests and response filters:
   - If is_app_store_client is true: Gateway strips all stores with store_type = 'paan_corner' and strips all items in tobacco/smoking categories.
   - If is_app_store_client is false: Gateway returns complete unrestricted catalog.
3. Write automated tests asserting that Flutter headers never receive tobacco items, while web headers receive the full catalog.

DEFINITION OF DONE:
- Flutter client receives 0 tobacco items under any query.
- Web client receives full catalog.
```

---

### `[M2-W8-BE3-01]` Indian GST & HSN Calculator Engine
**Assignee:** BE-3 (Senior Backend Engineer 3 — Commerce Lead)  
**Target Files:** `apps/order-service/src/checkout/gst-calculator.service.ts`

```text
You are acting as Senior Backend Engineer 3 (BE-3) for the Fattakse platform modernization.

TASK: M2-W8-BE3-01 - Indian GST & HSN Calculator Engine

CONTEXT:
Evolw Technologies is based in Tirora, Maharashtra (State Code: 27). Tax calculations must comply with Indian GST laws matching HSN codes for grocery and food delivery.

REQUIREMENTS:
1. Implement gst-calculator.service.ts in order-service.
2. Maintain fattakse_catalog.hsn_gst_master with tax rates:
   - 0% GST (Fresh milk, unpackaged vegetables, fresh bread).
   - 5% GST (Packaged staples, edible oils, restaurant food items: 2.5% CGST + 2.5% SGST).
   - 12% GST (Processed food, dairy products like butter/ghee: 6% CGST + 6% SGST).
   - 18% GST (Snacks, beverages, dark store FMCG, platform fee: 9% CGST + 9% SGST).
3. Intrastate Tax Logic:
   - Store and customer both in Maharashtra (State Code 27) -> Split evenly into CGST and SGST.
4. Calculate line-item tax and aggregated tax breakdown. Match legacy Laravel calculation to the exact paisa (0.00 INR discrepancy).

DEFINITION OF DONE:
- Unit test suite verifies 20 mixed basket scenarios against Laravel reference calculations with 0.00 INR variance.
```

---

### `[M2-W8-BE3-03]` Dynamic Checkout Quotation API (`POST /api/v1/checkout/get-quote`)
**Assignee:** BE-3 (Senior Backend Engineer 3 — Commerce Lead)  
**Target Files:** `apps/order-service/src/checkout/quotation.controller.ts`, `apps/order-service/src/checkout/quotation.service.ts`

```text
You are acting as Senior Backend Engineer 3 (BE-3) for the Fattakse platform modernization.

TASK: M2-W8-BE3-03 - Dynamic Checkout Quotation API (POST /api/v1/checkout/get-quote)

CONTEXT:
Before placing an order, the Flutter app and web storefront request a dynamic checkout quotation calculating discounts, GST, distance delivery charges, and platform fees.

REQUIREMENTS:
1. Implement POST /api/v1/checkout/get-quote.
2. Accept body:
   ```json
   {
     "store_id": 1,
     "items": [{ "id": 101, "quantity": 2, "variant": "500g" }],
     "address_id": 45,
     "coupon_code": "WELCOME50"
   }
   ```
3. Execution sequence:
   - Validate store is active and open.
   - Enforce Minimum Order Value: if subtotal < store.minimum_order, return HTTP 400 with { errors: [{ code: "order-001", message: "Minimum order amount is ₹150" }] }.
   - Fetch real-time item prices and calculate item discounts.
   - Apply coupon discount if valid.
   - Calculate road distance between store lat/lng and customer address using Mapbox Matrix API (fallback to Haversine).
   - Apply delivery fee curve: base fee (₹20 for first 2km) + ₹8/km thereafter.
   - Compute GST using gst-calculator.service.ts.
   - Add platform processing fee (₹5 flat).
4. Return quotation matching Flutter schema.

DEFINITION OF DONE:
- API calculates and returns subtotal, tax, delivery fee, platform fee, and final payable amount in < 150ms.
- 0.00 INR variance against Laravel Helpers::get_cart_data().
```

---

### `[M2-W8-FE2-02]` Full-Catalog Consumer Web Storefront Scaffolding (`user-web`)
**Assignee:** FE-2 (Senior Frontend Engineer 2 — Merchant & Web Storefront)  
**Target Files:** `apps/user-web/vite.config.ts`, `apps/user-web/src/App.tsx`, `apps/user-web/src/components/AgeGateModal.tsx`

```text
You are acting as Senior Frontend Engineer 2 (FE-2) for the Fattakse platform modernization.

TASK: M2-W8-FE2-02 - Full-Catalog Consumer Web Storefront Scaffolding (user-web)

CONTEXT:
We maintain user-web as a responsive React 19 PWA hosted at fattakse.in. It sells everything (groceries, food, dark store items, and paan corner smoking products). Tobacco products require a mandatory 18+ COTPA age-verification gate.

REQUIREMENTS:
1. Scaffold apps/user-web using Vite 6 + React 19 + TypeScript + Tailwind CSS v4.
2. Implement responsive mobile-first storefront layout:
   - Top bar: Location address selector, search input, cart floating badge.
   - Unified category banner navigation: Grocery & Staples, Fresh Fruits & Veg, Restaurant Food, Snacks & Drinks, Paan Corner (18+).
3. Build AgeGateModal.tsx component:
   - Triggers when navigating to /paan or viewing any tobacco SKU.
   - Requires user to confirm: "I am 18 years or older" and enter Date of Birth (DOB).
   - Displays statutory health warnings: "Smoking Causes Cancer" and COTPA 2003 warning banners.
   - Stores age verification affirmation in secure session storage.
4. Wire TanStack Query to API Gateway endpoints (/api/v1/items/search, /api/v1/stores).

DEFINITION OF DONE:
- user-web runs locally on port 5175.
- Navigating to Paan Corner triggers 18+ modal before rendering products.
- Non-tobacco categories browse seamlessly without age gate.
```

---

### `[M2-W8-QA-01]` Flutter Mobile Client Staging Integration
**Assignee:** QA (SDET / Automation Engineer)  
**Target Files:** `qa/e2e/flutter_staging_test.sh`

```text
You are acting as the SDET / Automation Engineer (QA) for the Fattakse platform modernization.

TASK: M2-W8-QA-01 - Flutter Mobile Client Staging Integration

CONTEXT:
Gate 2 requires certifying that the frozen Flutter Customer app (v1.0.18) runs against the new staging microservices without crashing or failing JSON deserialization.

REQUIREMENTS:
1. Configure DNS / proxy routing: staging-api.fattakse.in points to Node.js Fastify API Gateway.
2. Launch Flutter Customer app on Android Emulator and iOS Simulator pointed to staging-api.fattakse.in.
3. Execute complete end-to-end user journey:
   - Login via phone OTP.
   - Select saved Tirora address.
   - Browse categories and search items via Typesense.
   - Add 3 items to cart.
   - Open checkout screen and verify quotation calculations.
4. Verify Android Logcat and iOS syslog: assert 0 type cast exceptions, 0 unhandled promise rejections, and exact visual parity with production.

DEFINITION OF DONE:
- Flutter app completes user journey without crashes.
- Gate 2 checklist signed off.
```
