# Month 4: Integration, Acceptance, Contract Diffing & Migration Rehearsals (Weeks 13–16)

**Objective:** Execute automated contract diffing between the Laravel reference monolith and the new microservices platform, perform two full production data migration rehearsals, execute high-concurrency load testing, and achieve full operational readiness.  
**Acceptance Gate 4:** 100% of automated contract diffing tests pass; Migration Rehearsals 1 & 2 complete within the approved 15-minute maintenance window; financial invariant proofs show 0.00 INR discrepancy across all ledgers; k6 load test passes at 1,500 req/sec.

---

## Week 13: Automated Contract Diffing Suite & Flutter E2E Testing

### Detailed Tasks by Role

#### ARCH (Principal Architect & Project Lead)
- **`M4-W13-ARCH-01` Zero-Breaking-Change Contract Audit:**
  - Audit all 431 legacy route mappings in `apps/gateway/src/routes/v1/`.
  - Certify that every response schema matches the Laravel monolith byte-for-byte in keys, data types, and status codes.
  - Review automated contract diff reports from QA daily and enforce blocking fixes for any regression.
- **`M4-W13-ARCH-02` Mobile Backward Compatibility Certification:**
  - Audit header normalization (`zoneId`, `latitude`, `longitude`, `Authorization`, `X-App-Version`).
  - Verify that no Flutter app updates are required for production cutover. Sign off on Flutter Customer `1.0.18`, Vendor `1.0.5`, and Rider `1.0.1` compatibility.

#### BE-1 (Senior Backend Engineer 1 — Auth & Edge)
- **`M4-W13-BE1-01` Resolve Auth & Customer Contract Diff Discrepancies:**
  - Inspect QA diff reports for `/api/v1/auth/*` and `/api/v1/customer/*`.
  - Fix Passport RSA JWT signature validation, token expiry timestamps, and user profile response envelopes.
  - Ensure customer address array and wallet balance formats match legacy JSON byte-for-byte.
- **`M4-W13-BE1-02` Gateway Error Array Envelope Standardization:**
  - Standardize all error responses to strictly follow the legacy format:
    ```json
    {
      "errors": [
        { "code": "validation-001", "message": "The phone field is required." }
      ]
    }
    ```
  - Ensure no raw Fastify or microservice HTTP errors leak through the edge proxy.

#### BE-2 (Senior Backend Engineer 2 — Catalog & Search)
- **`M4-W13-BE2-01` Resolve Catalog & Typesense Diff Discrepancies:**
  - Inspect QA diff reports for `/api/v1/items/*`, `/api/v1/categories/*`, and `/api/v1/search/*`.
  - Fix pagination envelopes: verify `"total_size"`, `"limit": "10"`, `"offset": "1"` format and stringified numbers where legacy Laravel emitted strings.
  - Ensure zone-based pricing and multi-tax decimal outputs (`tax: 5.00`, `tax_type: "percent"`) match legacy behavior.
- **`M4-W13-BE2-02` Store Profile & Configuration Route Alignment:**
  - Ensure `/api/v1/stores/details/*` returns full legacy store metadata including opening/closing hours, minimum order values, delivery time estimates, and rating arrays.

#### BE-3 (Senior Backend Engineer 3 — Commerce & Inventory Lead)
- **`M4-W13-BE3-01` Resolve Order & Checkout Diff Discrepancies:**
  - Inspect QA diff reports for `/api/v1/orders/*`, `/api/v1/customer/order/place`, and `/api/v1/vendor/orders/*`.
  - Verify exact match of order detail objects: item add-ons, variations, coupon discounts, delivery tips, and tax breakdowns.
- **`M4-W13-BE3-02` WebSocket Fulfillment Event Compatibility:**
  - Verify Socket.IO events (`order_placed`, `order_status_update`, `rider_assigned`, `live_location_update`) match the payloads expected by Flutter mobile listeners and React portals.

#### FE-1 (Senior Frontend Engineer 1 — Admin Control Plane)
- **`M4-W13-FE1-01` Admin SPA API Contract Integration Testing:**
  - Point `admin-react` staging builds to the Staging API Gateway.
  - Test all 20 core administrative views against live microservices endpoints.
  - Fix any request payload discrepancies in zone polygon management, catalog item approval, and coupon configuration.
- **`M4-W13-FE1-02` Admin Token Refresh & Session Interceptor:**
  - Implement Axios/React Query interceptor for transparent JWT refresh on token expiry without disrupting active admin sessions.

#### FE-2 (Senior Frontend Engineer 2 — Merchant & Web Storefront)
- **`M4-W13-FE2-01` Vendor SPA Dark Store Picker Integration Testing:**
  - Point `vendor-react` staging builds to the Staging API Gateway.
  - Test dark store picker screen (`/orders/picker`), KDS order flow, and stock count adjustments against `order-service` and `inventory-service`.
  - Validate real-time order arrival sound notifications and visual alerts via WebSockets.
- **`M4-W13-FE2-02` Seller Stock Withdrawal Integration Verification:**
  - Verify seller stock withdrawal workflow end-to-end: merchant creates request in `vendor-react` -> dark store manager receives and approves in `admin-react` -> inventory updates.
- **`M4-W13-FE2-03` Full-Catalog Web Storefront Integration Testing (`user-web`):**
  - Point `user-web` staging build to Staging API Gateway.
  - Verify multi-category cart building (groceries + food + dark store + paan corner).
  - Verify mandatory 18+ Age Interstitial splash modal triggers with DOB declaration and COTPA 2003 statutory warnings before displaying tobacco items.
  - Verify full-basket checkout creates order and initiates payment.

#### DATA (Database Architect & ETL Data Engineer)
- **`M4-W13-DATA-01` Production Replay Traffic Payload Extraction:**
  - Extract and sanitize 5,000 real HTTP request payloads from production logs (`/storage/logs/laravel.log` and Nginx access logs on VPS `145.223.19.105`).
  - Anonymize customer PII (phone numbers, addresses, names) while preserving valid UUIDs, item IDs, and store IDs.
  - Package payloads into `qa/fixtures/production_replay_5000.json`.
- **`M4-W13-DATA-02` Rehearsal Test Database Preparation:**
  - Setup isolated staging database cluster on Staging VPS for Migration Rehearsal 1.
  - Verify automated schema migrations execute cleanly across all 8 logical MySQL databases.

#### QA (SDET / Automation Engineer)
- **`M4-W13-QA-01` Build Production Replay Diffing Engine:**
  - **Tool:** `qa/contract_diff_runner.ts`.
  - Replay 5,000 sanitized production requests against both the Laravel monolith (`145.223.19.105:8000`) and the Staging Gateway (`staging.fattakse.in/api/v1`) concurrently.
- **`M4-W13-QA-02` Automated JSON Schema & Type Diffing:**
  - Compare JSON responses across all 431 endpoints:
    - Exact key-name equivalence.
    - Primitive data type matches (string vs number vs boolean).
    - Nullability consistency and array structure compliance.
    - Output discrepancies into `qa/reports/diff_week13.json`.
- **`M4-W13-QA-03` Headless Flutter Regression Suites:**
  - Run automated Appium / Flutter Driver test suites on Customer (`1.0.18`), Vendor (`1.0.5`), and Rider (`1.0.1`) apps targeting Staging API Gateway. Verify zero app crashes and 100% flow completion.

---

## Week 14: Migration Dress Rehearsal 1 (Full Production Backup)

### Detailed Tasks by Role

#### ARCH (Principal Architect & Project Lead)
- **`M4-W14-ARCH-01` Rehearsal 1 Infrastructure Orchestration:**
  - Oversee isolated rehearsal environment setup matching target production topology.
  - Monitor server resource utilization (CPU, RAM, disk I/O, network bandwidth) during full data load.
- **`M4-W14-ARCH-02` Rehearsal 1 Post-Mortem & Performance Tuning:**
  - Review end-to-end migration execution log with DATA lead.
  - Optimize MySQL server parameters (`innodb_buffer_pool_size`, `max_allowed_packet`, `bulk_insert_buffer_size`, `innodb_flush_log_at_trx_commit = 2` during load) to reduce total ETL runtime.

#### BE-1 (Senior Backend Engineer 1 — Auth & Edge)
- **`M4-W14-BE1-01` Migrated User Authentication Verification:**
  - Point `iam-service` to the freshly migrated `fattakse_iam` database.
  - Verify that legacy bcrypt password hashes validate correctly for 100 sample users (customers, vendors, delivery riders, superadmins).
  - Test Passport RSA public key token verification against active customer sessions.
- **`M4-W14-BE1-02` Customer Address & Profile Data Integrity:**
  - Verify that customer addresses, default coordinates, and notification preferences query cleanly without null pointer exceptions.

#### BE-2 (Senior Backend Engineer 2 — Catalog & Search)
- **`M4-W14-BE2-01` Production Rehearsal Typesense Bulk Re-Indexing:**
  - Execute `catalog-service` bulk indexing script against the migrated `fattakse_catalog` database.
  - Index all 10,000+ catalog items into Typesense 28.0 cluster.
  - Benchmark indexing duration (target: < 60 seconds) and assert 100% search document count match.
- **`M4-W14-BE2-02` Category Hierarchy & Store Linkage Validation:**
  - Validate parent-child category trees and store-item association records in `fattakse_store` and `fattakse_catalog`.

#### BE-3 (Senior Backend Engineer 3 — Commerce & Inventory Lead)
- **`M4-W14-BE3-01` Historical Order History Retrieval Verification:**
  - Query past order history for 50 customer accounts across multiple years.
  - Verify order line items, transaction statuses, delivery addresses, and discount records load with 100% fidelity.
- **`M4-W14-BE3-02` Multi-Owner Stock Ledger Verification Post-Migration:**
  - Verify `fattakse_inventory.stocks` balances across all dark store items:
    - Confirm Evolw-owned inventory is correctly assigned `owner_type = 'evolw'`.
    - Confirm local Tirora merchant consignment inventory is correctly assigned `owner_type = 'seller'` with corresponding `owner_id`.

#### FE-1 (Senior Frontend Engineer 1 — Admin Control Plane)
- **`M4-W14-FE1-01` Admin Control Plane Regression on Rehearsal Data:**
  - Log in to `admin-react` pointing to the rehearsal environment.
  - Verify full operational views: Order history table, customer list, vendor management, catalog management, and town-level analytics for Tirora.
  - Confirm financial reports show identical revenue and commission totals as the legacy Laravel admin.

#### FE-2 (Senior Frontend Engineer 2 — Merchant & Web Storefront)
- **`M4-W14-FE2-01` Vendor Portal Regression on Rehearsal Data:**
  - Log in to `vendor-react` as Tirora dark store manager and 3 partner vendor accounts.
  - Verify stock inventory view, item pricing, and historical payout balances match legacy merchant portal records.
- **`M4-W14-FE2-02` Consumer Web Storefront Rehearsal Verification (`user-web`):**
  - Log in and browse `user-web` on rehearsal data.
  - Verify full-catalog browsing (groceries, food, dark store, paan corner), 18+ age verification splash modal on tobacco items, and dynamic checkout quotation.

#### DATA (Database Architect & ETL Data Engineer)
- **`M4-W14-DATA-01` Obtain Fresh Sanitized Production Backup:**
  - Take a full mysqldump of `fattakse_prod` from Hostinger VPS (`145.223.19.105`).
  - Restore onto isolated rehearsal staging database server (`fattakse_rehearsal_legacy`).
- **`M4-W14-DATA-02` Execute Full Stage 2 ETL Migration:**
  - **Script:** `etl/stage2_full_migration.py`.
  - Transform all 264 legacy tables into the 8 target microservice schemas (`fattakse_iam`, `fattakse_store`, `fattakse_catalog`, `fattakse_inventory`, `fattakse_order`, `fattakse_fleet`, `fattakse_finance`, `fattakse_notify`).
  - Exclude permanently purged POS tables (`pos_*`, `hyper_pos_*`).
- **`M4-W14-DATA-03` Benchmark Migration Duration & Resource Utilization:**
  - Record exact extraction, transformation, and load times:
    - Total elapsed time (target: < 12 minutes).
    - CPU, RAM, and disk I/O metrics on the database server.
    - Optimize batch insert sizes (`INSERT ... VALUES (...)` in 1,000-row chunks) and disable secondary index rebuilds until load completion.
- **`M4-W14-DATA-04` Automated Record-Count Integrity Check:**
  - Run `scripts/verify_record_counts.py`: verify that total user accounts, orders, products, and store records in target schemas match legacy counts exactly.

#### QA (SDET / Automation Engineer)
- **`M4-W14-QA-01` Staging Sanity Tests Post-Rehearsal:**
  - Point Staging microservices to the newly migrated database schemas.
  - Assert that all catalog items, past orders, and user logins function cleanly.
- **`M4-W14-QA-02` End-to-End Flutter Checkout Smoke Test on Migrated Data:**
  - Run mobile test order placing journey using existing migrated user account and delivery address.

---

## Week 15: Concurrency, Load & Security Penetration Testing

### Detailed Tasks by Role

#### ARCH (Principal Architect & Project Lead)
- **`M4-W15-ARCH-01` Load Profile Definition & Distributed Cluster Scaling:**
  - Architect distributed k6 load testing cluster capable of generating sustained 1,500 req/sec.
  - Define SLA limits: p95 latency < 180ms, p99 latency < 350ms, error rate < 0.01%.
- **`M4-W15-ARCH-02` Bottleneck Analysis & Circuit Breaker Tuning:**
  - Monitor service-to-service communication under heavy load.
  - Tune Fastify gateway circuit breakers, Redis connection limits, and MySQL max connections.

#### BE-1 (Senior Backend Engineer 1 — Auth & Edge)
- **`M4-W15-BE1-01` Security & RBAC Penetration Audit:**
  - Test JWT tampering, forged signatures, expired tokens, and cross-tenant privilege escalation (e.g. Vendor A attempting to access Vendor B's orders).
  - Verify that rate limiters on `/api/v1/auth/login` and `/api/v1/auth/verify-phone` reject brute-force attacks cleanly with HTTP 429.
- **`M4-W15-BE1-02` Edge Gateway High-Concurrency Tuning:**
  - Profile Fastify edge gateway under 1,500 req/sec; optimize JSON serialization using `fast-json-stringify` schemas across all hot routes.

#### BE-2 (Senior Backend Engineer 2 — Catalog & Search)
- **`M4-W15-BE2-01` Catalog & Search Load Optimization:**
  - Benchmark Typesense 28.0 cluster under 1,000 search queries/sec.
  - Implement Redis query result caching for top 100 frequent search queries and homepage category carousels (TTL: 60 seconds).
- **`M4-W15-BE2-02` MySQL Catalog Query Plan Audit:**
  - Run `EXPLAIN ANALYZE` on complex catalog queries (store-specific item listings with add-ons and variations).
  - Add composite indexes on `(store_id, status, category_id)` to eliminate table scans.

#### BE-3 (Senior Backend Engineer 3 — Commerce & Inventory Lead)
- **`M4-W15-BE3-01` High-Concurrency Stock Lock Stress Testing:**
  - Stress test `inventory-service` pessimistic locking (`SELECT ... FOR UPDATE` via Kysely) under 200 concurrent checkout attempts against the last 5 available units.
  - Verify zero deadlocks, zero negative stock balances, and zero double-allocation errors.
- **`M4-W15-BE3-02` Redis BullMQ Queue Throughput Tuning:**
  - Tune BullMQ worker concurrency across delayed SLA timers, OTP expiries, and webhook retry queues.
  - Verify queue drain rate > 200 jobs/sec with zero stranded jobs.
- **`M4-W15-BE3-03` Kafka Consumer Lag & Offset Replay Drill:**
  - Benchmark Kafka / Redpanda broker under sustained 5,000 events/sec.
  - Measure consumer lag across `finance-ledger-group`, `fleet-dispatch-group`, and `notify-group`; assert consumer lag < 50ms at p95.
  - Execute offset reset drill: reset `finance-ledger-group` offset to `--to-offset 0` in staging and assert idempotent double-entry ledger reconstruction with 0.00 INR balance drift.

#### FE-1 (Senior Frontend Engineer 1 — Admin Control Plane)
- **`M4-W15-FE1-01` Admin SPA Production Bundle Optimization:**
  - Audit React bundle sizes; implement code-splitting and dynamic imports (`React.lazy`) across routes.
  - Target: Initial gzipped JS bundle < 250KB.
  - Implement virtualized tables (`react-window`) for orders and inventory grids to handle 10,000+ rows smoothly at 60 FPS.
- **`M4-W15-FE1-02` Lighthouse & Core Web Vitals Audit:**
  - Achieve Lighthouse performance score > 90 on desktop admin views.

#### FE-2 (Senior Frontend Engineer 2 — Merchant & Web Storefront)
- **`M4-W15-FE2-01` Vendor SPA High-Frequency WebSocket Stress Test:**
  - Test dark store picker display and KDS screens under sustained 5 orders/second live arrival.
  - Verify browser memory footprint remains stable over 4 hours without memory leaks.
- **`M4-W15-FE2-02` Vendor PWA Offline & Reconnect Handling:**
  - Ensure dark store picker app handles intermittent Wi-Fi drops cleanly: buffers state locally and reconnects WebSocket transparently without data loss.

#### DATA (Database Architect & ETL Data Engineer)
- **`M4-W15-DATA-01` Database Connection Pool & IOPS Profiling:**
  - Profile MySQL connection pools (Kysely and Prisma) across all 8 microservices under peak load.
  - Calibrate pool sizes (min: 5, max: 20 per container) to avoid connection saturation.
- **`M4-W15-DATA-02` Slow Query Log Capture & Index Optimization:**
  - Enable MySQL slow query log (`long_query_time = 0.2`).
  - Identify and optimize any queries exceeding 200ms execution time during load test.

#### QA (SDET / Automation Engineer)
- **`M4-W15-QA-01` Distributed k6 Peak Traffic Simulation:**
  - **Script:** `loadtest/k6_peak_traffic_simulation.js`.
  - **Load Profile:** 1,500 requests/second sustained over 30 minutes, simulating high-traffic Tirora quick-commerce flash sales:
    - 70% Catalog browsing and Typesense search.
    - 15% Cart synchronization and checkout quotations.
    - 10% Live rider GPS location streaming via WebSockets.
    - 5% Order placement and stock reservation.
- **`M4-W15-QA-02` Concurrency Race Chaos Test:**
  - Simulate 200 concurrent checkout requests attempting to purchase the last 5 available units of a popular grocery SKU.
  - Assert that exactly 5 orders succeed.
  - Assert that 195 orders receive clean out-of-stock messages.
  - Assert zero negative stock balances and zero orphaned transactions.

---

## Week 16: Migration Dress Rehearsal 2 (Delta Sync & Financial Proofs)

### Detailed Tasks by Role

#### ARCH (Principal Architect & Project Lead)
- **`M4-W16-ARCH-01` Finalize Cutover Window Runbook:**
  - Author comprehensive minute-by-minute operational runbook for Month 5 cutover night.
  - Define step-by-step responsibilities, time windows, and communication channels.
- **`M4-W16-ARCH-02` Review & Certify Financial Invariant Proofs:**
  - Formally review mathematical reconciliation reports from DATA and QA.
  - Certify that the delta ETL process is mathematically verified, zero-data-loss, and achieves $\Delta = 0.00\text{ INR}$.

#### BE-1 (Senior Backend Engineer 1 — Auth & Edge)
- **`M4-W16-BE1-01` Maintenance Mode Edge Switch Middleware:**
  - Implement maintenance mode middleware in Fastify edge gateway:
    - When maintenance flag is active, return HTTP 503 with legacy maintenance JSON payload for mobile apps.
    - Whitelist engineering pod IP addresses for post-cutover smoke testing.
- **`M4-W16-BE1-02` Edge DNS & Ingress Routing Switch Automation:**
  - Script Nginx upstream switch configuration (`scripts/switch_upstream_to_microservices.sh`) for rapid cutover execution.

#### BE-2 (Senior Backend Engineer 2 — Catalog & Search)
- **`M4-W16-BE2-01` Typesense Delta Sync Daemon Verification:**
  - Verify that catalog items created or modified during the delta window are automatically picked up by BullMQ and indexed into Typesense within 5 seconds.
- **`M4-W16-BE2-02` Multi-Tenant Store & Zone Configuration Verification:**
  - Verify Tirora zone polygons, delivery radius constraints, and store operational schedules post-delta sync.

#### BE-3 (Senior Backend Engineer 3 — Commerce & Inventory Lead)
- **`M4-W16-BE3-01` Live Order State Machine Drain Validation:**
  - Test order state drain procedure: simulate active pending/accepted orders during cutover window.
  - Verify all active orders transition cleanly to delivery or cancel state before database freeze.
- **`M4-W16-BE3-02` Razorpay Webhook Replay & Idempotency Check:**
  - Replay 100 payment webhook events through `finance-service`.
  - Verify idempotency keys prevent duplicate wallet credits or duplicate payment records.

#### FE-1 (Senior Frontend Engineer 1 — Admin Control Plane)
- **`M4-W16-FE1-01` Admin Maintenance Mode Banner & Read-Only Lock:**
  - Verify that `admin-react` displays clear maintenance countdown banner to staff 30 minutes prior to scheduled cutover.
  - Verify admin UI transitions to read-only during maintenance window.
- **`M4-W16-FE1-02` Production Deployment Pipeline Verification:**
  - Verify GitHub Actions CI/CD pipeline builds and deploys production static assets to Nginx edge server cleanly.

#### FE-2 (Senior Frontend Engineer 2 — Merchant & Web Storefront)
- **`M4-W16-FE2-01` Vendor Portal & Consumer Web Maintenance Mode Display:**
  - Verify `vendor-react` and `user-web` display clear maintenance banners to dark store staff, partner merchants, and web customers.
  - Ensure active picking lists in dark store are completed before maintenance window starts.
- **`M4-W16-FE2-02` Production Deployment Pipeline Verification:**
  - Verify automated build and containerization of `vendor-react` and `user-web` for production hosting.

#### DATA (Database Architect & ETL Data Engineer)
- **`M4-W16-DATA-01` Execute Incremental Delta Migration Rehearsal:**
  - 1. Restore production snapshot at timestamp $T_0$.
  - 2. Simulate 4 hours of production mutations (orders, user registrations, stock adjustments).
  - 3. Execute `etl/stage2_delta_sync.py` capturing only records modified where `updated_at >= T_0`.
  - 4. Measure delta sync duration: **Target < 3 minutes**.
- **`M4-W16-DATA-02` Automated Financial Invariant Proof Script:**
  - **Script:** `scripts/verify_financial_invariants.py`.
  - **Mathematical Proofs:**
    $$\begin{aligned}
    \sum \text{orders.order\_amount} &= \sum \text{order\_transactions.amount} \\
    \sum \text{wallets.balance} (\text{Legacy}) &= \sum \text{wallets.balance} (\text{New}) \\
    \sum \text{dm\_wallets.collected\_cash} (\text{Legacy}) &= \sum \text{dm\_wallets.collected\_cash} (\text{New}) \\
    \sum \text{vendor\_wallets.total\_earning} (\text{Legacy}) &= \sum \text{vendor\_wallets.total\_earning} (\text{New})
    \end{aligned}$$
  - **Tolerance:** Exactly 0.00 INR discrepancy across all accounts.

#### QA (SDET / Automation Engineer)
- **`M4-W16-QA-01` Post-Delta Regression & Contract Verification:**
  - Run automated contract diff test suite against the delta-migrated rehearsal database.
  - Verify 0 broken foreign keys, 0 schema mismatches, and 0 missing order records.
- **`M4-W16-QA-02` Formal Gate 4 Sign-Off:**
  - Compile Gate 4 audit report and verify that all 6 Gate 4 acceptance criteria have been achieved.

---

## Gate 4 Acceptance Criteria Sign-Off Checklist
- [ ] 100% of automated contract diffing tests pass across 431 legacy routes.
- [ ] Headless Flutter regression tests passing on Customer, Vendor, and Rider apps.
- [ ] Migration Rehearsal 1 executed full migration in < 12 minutes.
- [ ] Migration Rehearsal 2 executed delta sync in < 3 minutes with 0.00 INR financial discrepancy.
- [ ] k6 load test sustained 1,500 req/sec with p95 latency < 180ms and zero concurrency overselling errors.
- [ ] Security audit verified zero RBAC vulnerabilities or unauthenticated endpoints.
- [ ] Consumer Web Storefront (`user-web`) rehearsal validated with full-catalog browsing and 18+ COTPA age-gating.
- [ ] Kafka / Redpanda event streaming verified under load with < 50ms consumer lag and verified financial offset replay.

