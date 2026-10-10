# Fattakse — Mobile & Web API Contract Inventory (`/api/v1/*`)

**Document Version:** 2.0.0  
**Scope:** 431 Route Definitions in `routes/api/v1/api.php`  
**Client Consumers:** Flutter Customer App (`1.0.18`), Flutter Vendor App (`1.0.5`), Flutter Rider App (`1.0.1`), Next.js Web Storefront  
**Routing Architecture:** API Gateway / Edge Router -> 8 Microservices  
**Author:** Principal API Architect  

---

## 1. API Route Group Clusters & Target Microservice Ownership

| Functional Group | Prefix / Pattern | Route Count | Auth Middleware | Target Microservice |
|---|---|---|---|---|
| **Authentication & IAM** | `/api/v1/auth/*` | 38 | Public / Guest | `iam-service` |
| **Customer Profile & Address**| `/api/v1/customer/*` | 52 | `auth:api` (Customer) | `iam-service` |
| **Catalog, Items & Search** | `/api/v1/items/*`, `/categories/*`, `/master-products/*` | 74 | Public / Zone | `catalog-service` |
| **Stores & Merchants** | `/api/v1/stores/*` | 26 | Public / Zone | `store-service` |
| **Cart & Quotation** | `/api/v1/cart/*`, `/checkout/*` | 18 | `auth:api` (Customer) | `order-service` |
| **Orders & Native Tracking** | `/api/v1/order/*` | 36 | `auth:api` (Customer) | `order-service` |
| **Payments & Razorpay** | `/api/v1/payment/razorpay/*` | 8 | Public / Signature | `finance-service` |
| **Vendor Operations** | `/api/v1/vendor/*` | 68 | `auth:api` (Vendor) | `order-service` / `inventory-service` |
| **Delivery Man & Fleet** | `/api/v1/delivery-man/*` | 54 | `auth:api` (Rider) | `fleet-service` |
| **System Configurations** | `/api/v1/config/*`, `/configurations/*` | 14 | Public | `store-service` |
| **Notifications & Messaging**| `/api/v1/message/*`, `/notifications/*` | 16 | `auth:api` | `notify-service` |
| **Hyper POS / Legacy (RETIRED)**| `/api/v1/pos/*`, `/erp/*` | 27 | HMAC / Secret | **DECOMMISSIONED (NO MIGRATION)** |

---

## 2. Core Route Specifications by Microservice

### 2.1 Identity & Access Service (`iam-service`)
- `POST /api/v1/auth/request-otp`: Request 6-digit SMS OTP for customer mobile number.
- `POST /api/v1/auth/verify-phone`: Validate OTP, issue Passport OAuth2 JWT token.
- `POST /api/v1/auth/login`: Email/Password login for vendor and rider accounts.
- `POST /api/v1/auth/token-refresh`: Refresh expiring bearer access tokens.
- `GET /api/v1/customer/info`: Return logged-in customer profile, wallet balance, and loyalty points.
- `POST /api/v1/customer/address/add`: Save customer delivery address with spatial latitude and longitude.

### 2.2 Catalog & Search Service (`catalog-service`)
- `GET /api/v1/categories`: Return hierarchical product categories filtered by active `zoneId`.
- `GET /api/v1/items/search`: Search products via Typesense fuzzy query, filtering by category, brand, rating, and stock.
- `GET /api/v1/items/details/{id}`: Detailed item specifications, allergen badges, nutritional info, and unit pricing.

### 2.3 Store & Merchant Service (`store-service`)
- `GET /api/v1/stores/details/{id}`: Store profile, operational hours, rating, and menu list.
- `GET /api/v1/config`: System settings, active currency, currency symbol direction, maintenance mode.

### 2.4 Order & Checkout Service (`order-service`)
- `POST /api/v1/cart/sync`: Synchronize client-side cart items with server; return item availability and price deltas.
- `POST /api/v1/checkout/get-quote`: Calculate dynamic cart quotation:
  - Subtotal
  - Indian GST breakdown (CGST, SGST) based on product HSN codes
  - Delivery distance fee
  - Platform processing fee
  - Coupon discount deductions
- `POST /api/v1/order/place`: Atomically place order with idempotency token and stock lock.
- `GET /api/v1/customer/order/list`: Historical and active orders for customer.
- `GET /api/v1/customer/order/track`: Real-time order tracking with `order_status`, live rider GPS coordinates, and `fulfilment_stage`.
- `POST /api/v1/customer/order/cancel`: Customer order cancellation within grace window.

### 2.5 Inventory Service (`inventory-service`)
- `POST /api/v1/vendor/inventory/withdraw-request`: Tirora seller urgent stock withdrawal request.
- `GET /api/v1/vendor/items`: Store menu and stock availability toggle.

### 2.6 Fleet & Delivery Service (`fleet-service`)
- `GET /api/v1/delivery-man/order/current`: Active assigned orders for rider.
- `POST /api/v1/delivery-man/order/update-status`: Accept, pick up, or complete order.
- `POST /api/v1/delivery-man/record-location`: Stream rider GPS coordinates for map tracking.
- `POST /api/v1/delivery-man/order/complete-delivery`: Doorstep 18+ ID check verification and delivery OTP entry.

### 2.7 Payment & Finance Service (`finance-service`)
- `POST /api/v1/payment/razorpay/verify`: Cryptographic signature verification of Razorpay capture.
- `POST /api/v1/payment/razorpay/webhook`: Idempotent processing of gateway payment events.

---

## 3. Explicitly Decommissioned Endpoints (Hyper POS & ERP)

The following 27 endpoints in `routes/api/v1/api.php` will **NOT be migrated to Node.js** and will return HTTP 410 Gone / 404 Not Found upon cutover:
- `/api/v1/pos/order/place` (walk-in counter till order creation)
- `/api/v1/pos/control-plane/*` (POS terminal registration, HMAC key sync)
- `/api/v1/erp/*` & `/api/v1/erp-sync/*` (physical shop ERP file connectors)
- `/api/v1/pos/marketplace/ingest` (legacy order relay to physical cashiers)
