# Architectural Invariants Reference

This document provides deep-dive context into the architectural decisions and system invariants of the Fattakse modernization platform.

## 1. Domain Service Boundaries

| Service | Logical DB | Primary Responsibilities |
|---|---|---|
| `api-gateway` | — | Reverse proxy, header normalization (`zoneId`, `lat`, `lng`), Passport RSA JWT auth verification, tobacco firewall. |
| `iam-service` | `fattakse_iam` | Customers, Admins, Vendors, Riders credentials, Passport JWT token emulation, OTP generation, RBAC. |
| `store-service` | `fattakse_store` | Store metadata, operating hours, delivery polygons (PostGIS), commissions. |
| `catalog-service` | `fattakse_catalog` | Item taxonomy, multi-variant options, addons, categories, Typesense CDC search indexing. |
| `inventory-service`| `fattakse_inventory`| Tirora dark-store stock ledger, multi-owner allocation (Evolw-owned vs seller-deposited), urgent withdrawals, reservations. |
| `order-service` | `fattakse_order` | Order state machine, cart pricing engine (Tirora GST formulas), checkout idempotency, Razorpay/Cashfree webhooks. |
| `fleet-service` | `fattakse_fleet` | Rider live telemetry, geospatial geofencing, broadcast & dispatch engine. |
| `finance-service` | `fattakse_finance` | Split payments, vendor settlements, rider earnings, Tirora town-level P&L ledger. |
| `notify-service` | `fattakse_notify` | Push notifications (Firebase FCM), SMS/WhatsApp dispatch (Twilio/Gupshup). |

## 2. Invariant Database Enforcements
- Financial records (`orders.order_amount`, `transactions.amount`, `wallet_balances`) must be stored in minor units (`BIGINT` paise: ₹1.00 = 100 paise) to prevent float truncation.
- Timestamps must be recorded in UTC (`timestamptz`), with application rendering converting to Indian Standard Time (IST, UTC+05:30).
- Soft deletes are implemented using `deleted_at IS NULL` indexes to allow historical audits.
