# Month 5: Production Provisioning, Final Rehearsal, Cutover & Hypercare (Weeks 17–20)

**Objective:** Provision the target production infrastructure, execute the final dress rehearsal, perform the zero-downtime production cutover during the scheduled 15-minute maintenance window, validate live operational health, and execute post-launch hypercare stabilization.  
**Acceptance Gate 5:** The greenfield Node.js microservices platform is live in production, serving real traffic from frozen Flutter apps and React SPAs with zero data loss, sub-200ms latency, and 0% critical error rates.

---

## Week 17: Production Cluster Provisioning & Historical Pre-Sync

### Detailed Tasks by Role

#### ARCH (Principal Architect & Project Lead)
- **`M5-W17-ARCH-01` Provision Production Infrastructure Topology:**
  - Setup target cloud/VPS infrastructure running Docker Compose:
    - 8 Node.js/TypeScript microservices containers.
    - API Gateway / Fastify edge router container.
    - Production MySQL 8.0 instance configured with 8 logical databases.
    - Production Redis 7.2 cluster with persistence (AOF + RDB enabled).
    - Production Typesense 28.0 cluster.
    - React Admin & Vendor SPAs hosted on high-performance Nginx web servers.
- **`M5-W17-ARCH-02` Setup Production SSL & Nginx Reverse Proxy:**
  - Configure Let's Encrypt automated SSL certificates for:
    - `api.fattakse.in` (API Gateway & mobile client ingress).
    - `admin.fattakse.in` (React Admin Control Plane).
    - `vendor.fattakse.in` (React Dark Store & Merchant Portal).
    - `ws.fattakse.in` (Socket.IO fulfillment cluster).

#### BE-1 (Senior Backend Engineer 1 — Auth & Edge)
- **`M5-W17-BE1-01` Verify Third-Party Production Credentials & Secrets:**
  - Configure production secrets in Doppler / Infisical / `.env.production`:
    - Live Razorpay API key & secret (`rzp_live_*`).
    - MSG91 DLT templates and transactional SMS sender ID.
    - Firebase Cloud Messaging (FCM) production service account JSON.
    - Mapbox API tokens for rider distance calculation.
- **`M5-W17-BE1-02` Production Edge Rate Limiting & Security Firewalls:**
  - Deploy Fail2ban and Fastify rate limiters on edge gateway.
  - Whitelist engineering pod IPs and configure strict CORS headers for `admin.fattakse.in` and `vendor.fattakse.in`.

#### BE-2 (Senior Backend Engineer 2 — Catalog & Search)
- **`M5-W17-BE2-01` Production Typesense Index Schema Initialization:**
  - Initialize production Typesense collections (`items`, `stores`, `categories`) with synonyms, typo tolerance, and Tirora geopoint indexing.
- **`M5-W17-BE2-02` Production Observability & Sentry Integration:**
  - Configure Sentry error tracking, OpenTelemetry distributed tracing, and Pino structured logging across all production services.
  - Ensure zero PII (customer passwords, OTPs, raw payment card data) is logged.

#### BE-3 (Senior Backend Engineer 3 — Commerce & Inventory Lead)
- **`M5-W17-BE3-01` Production Redis BullMQ Cluster Verification:**
  - Initialize production Redis BullMQ queues: `orders`, `notifications`, `payouts`, `inventory-sync`.
  - Configure dead-letter queues (DLQ) with automatic retry policies (exponential backoff: 3 retries).
- **`M5-W17-BE3-02` Production Webhook Listener Smoke Test:**
  - Verify Razorpay webhook endpoint (`POST /api/v1/payments/razorpay/webhook`) on production gateway responds with HTTP 200 to test pings.
- **`M5-W17-BE3-03` Production Redpanda / Kafka Cluster Verification:**
  - Provision production Redpanda / Kafka broker container with persistent NVMe volume storage.
  - Initialize production topics with retention policies: `fattakse.orders.lifecycle` (30 days), `fattakse.finance.transactions` (90 days), `fattakse.riders.telemetry` (7 days).
  - Configure consumer group lag exporter and alerting thresholds in Prometheus/Grafana.

#### FE-1 (Senior Frontend Engineer 1 — Admin Control Plane)
- **`M5-W17-FE1-01` Admin Production Static Asset Deployment:**
  - Configure Nginx container to serve `admin-react` production build with Brotli/Gzip compression, caching headers (`Cache-Control: max-age=31536000` for hashed assets), and HTML5 history fallback.
- **`M5-W17-FE1-02` Production Admin Environment Verification:**
  - Verify that `admin.fattakse.in` loads cleanly over HTTPS and connects to `api.fattakse.in`.

#### FE-2 (Senior Frontend Engineer 2 — Merchant & Web Storefront)
- **`M5-W17-FE2-01` Vendor Portal & Consumer Web Production Asset Deployment:**
  - Configure Nginx containers to serve `vendor-react` and `user-web` production builds with Brotli/Gzip compression and HTML5 history fallback.
  - Verify service worker caching for PWA offline resiliency in Tirora dark store warehouse and mobile browsers.
- **`M5-W17-FE2-02` Production Audio & Asset Verification:**
  - Verify audio alert chime assets load without CORS issues on dark store picker stations and web order tracking screens.

#### DATA (Database Architect & ETL Data Engineer)
- **`M5-W17-DATA-01` Pre-Sync Historical Data (Initial Load):**
  - Extract all historical records from `fattakse_prod` up to $T_{\text{cutover}} - 48\text{h}$ while the Laravel monolith continues serving live traffic.
  - Load into target production domain schemas (`fattakse_iam`, `fattakse_store`, `fattakse_catalog`, `fattakse_inventory`, `fattakse_order`, `fattakse_fleet`, `fattakse_finance`, `fattakse_notify`).
  - Run initial bulk indexing into production Typesense cluster.
- **`M5-W17-DATA-02` Automated Production Backup Schedule Setup:**
  - Configure hourly incremental WAL backups and daily full logical snapshots to encrypted offsite object storage (Wasabi / AWS S3).

#### QA (SDET / Automation Engineer)
- **`M5-W17-QA-01` Production Environment Health Check:**
  - Execute automated health checks against all production service endpoints; verify that all containers return HTTP 200 OK.
- **`M5-W17-QA-02` SSL/TLS Cipher Suite & Security Header Scan:**
  - Run SSL Labs audit and security header scan on `api.fattakse.in`; assert Grade A rating and strict HSTS headers.

---

## Week 18: Dress Rehearsal 3 (Full Simulated Maintenance Window)

### Detailed Tasks by Role

#### ARCH (Principal Architect & Project Lead)
- **`M5-W18-ARCH-01` Execute Full Dry Run Simulation:**
  - Convene all 8 engineering pod members at 02:00 AM IST for a complete rehearsal under exact production conditions on Staging.
  - Time every individual command to the second.
  - Verify team communication protocol on Slack / Discord bridge.
- **`M5-W18-ARCH-02` Test 60-Second Rollback Trigger:**
  - Simulate an unexpected critical regression 5 minutes post-cutover.
  - Trigger `./scripts/emergency-rollback-to-laravel.sh`.
  - Assert that traffic returns to Laravel within 30 seconds and zero data is corrupted.

#### BE-1 (Senior Backend Engineer 1 — Auth & Edge)
- **`M5-W18-BE1-01` Rehearsal Edge Maintenance Mode Drill:**
  - Trigger maintenance mode switch via Nginx / Fastify gateway; assert that simulated mobile client requests receive HTTP 503 maintenance envelope within 2 seconds.
- **`M5-W18-BE1-02` Rehearsal Whitelist Verification:**
  - Verify that engineering pod developer devices can bypass the maintenance mode barrier using IP whitelist / internal headers.

#### BE-2 (Senior Backend Engineer 2 — Catalog & Search)
- **`M5-W18-BE2-01` Rehearsal Typesense Live Index Sync Check:**
  - During rehearsal delta sync, assert that new items and price changes sync to Typesense without search downtime.
- **`M5-W18-BE2-02` Rehearsal Store Operating Hours Verification:**
  - Verify store open/close state logic correctly evaluates Tirora IST timezone.

#### BE-3 (Senior Backend Engineer 3 — Commerce & Inventory Lead)
- **`M5-W18-BE3-01` Rehearsal Order Queue Drain Drill:**
  - Drain simulated in-flight orders: stop Laravel queue workers, ensure zero half-processed payments or orphaned delivery tickets.
- **`M5-W18-BE3-02` Rehearsal Webhook Processing Verification:**
  - Verify Razorpay webhook delivery replay during the maintenance window transition.

#### FE-1 (Senior Frontend Engineer 1 — Admin Control Plane)
- **`M5-W18-FE1-01` Rehearsal Admin Portal Switch Drill:**
  - Practice DNS/Nginx switch of `admin.fattakse.in` from Blade to React SPA.
  - Verify immediate login availability and dashboard loading.

#### FE-2 (Senior Frontend Engineer 2 — Merchant & Web Storefront)
- **`M5-W18-FE2-01` Rehearsal Vendor Portal & Consumer Web Switch Drill:**
  - Practice DNS/Nginx switch of `vendor.fattakse.in` and `fattakse.in` from Blade to modernized React SPAs.
  - Verify dark store picker station boots to active order queue and consumer web storefront boots to full catalog immediately.

#### DATA (Database Architect & ETL Data Engineer)
- **`M5-W18-DATA-01` Measure Rehearsal 3 Delta Sync:**
  - Execute delta ETL script on 48 hours of simulated mutations.
  - Assert that delta sync completes in **< 4 minutes**.
- **`M5-W18-DATA-02` Automated Financial Reconciliation Verification:**
  - Run `scripts/verify_financial_invariants.py`: assert exact 0.00 INR variance across all customer, rider, and merchant ledgers.

#### QA (SDET / Automation Engineer)
- **`M5-W18-QA-01` Smoke Test Rehearsal Environment:**
  - Execute full Flutter app user journeys against rehearsal endpoints within 5 minutes of simulated switchover:
    - User login with OTP.
    - Cart quote calculation.
    - Order placement.
    - Vendor order acceptance.
    - Rider delivery completion.
- **`M5-W18-QA-02` Measure Total Maintenance Window Elapsed Time:**
  - Record exact clock time from maintenance onset to production release. Certify that total elapsed time is under the 15-minute SLA.

---

## Week 19: PRODUCTION CUTOVER NIGHT (Scheduled 15-Minute Window, 02:00 AM IST)

### Minute-by-Minute Operational Execution Runbook

```
+----------------------------------------------------------------------------------------------------+
|                         CUTOVER NIGHT TIMELINE (02:00 AM - 02:15 AM IST)                           |
+----------------------------------------------------------------------------------------------------+
|  01:45 AM : Pod Assembles on Bridge; Production Health Verified on Laravel Monolith.               |
|  02:00 AM : Laravel Placed in READ-ONLY Maintenance Mode. Banner Displayed on Mobile Apps.          |
|  02:02 AM : Background Queue Workers Stopped on Laravel Host.                                      |
|  02:04 AM : Final Delta ETL Migration Script Triggered (Capturing Last 2 Hours of Mutations).      |
|  02:08 AM : Delta Migration Completes (Target: < 4 Minutes).                                        |
|  02:10 AM : Automated Invariant Check Script Asserts 100% Record & Financial Ledger Match.         |
|  02:12 AM : Ingress / DNS Pointer Switched from Laravel to New Microservices API Gateway.          |
|  02:13 AM : End-to-End Production Smoke Test (Live OTP Login, Cart, Test Order Placement).         |
|  02:15 AM : Maintenance Mode Lifted; Production Declared LIVE on Node.js Microservices Platform!   |
+----------------------------------------------------------------------------------------------------+
```

### Detailed Tasks by Role

#### ARCH (Principal Architect & Cutover Incident Commander)
- **`M5-W19-ARCH-01` Master Checklist & Operational Bridge Command:**
  - Convene live cutover war room on Discord / Zoom at 01:45 AM IST.
  - Verify pre-cutover checklist gates (all 7 gates signed off).
- **`M5-W19-ARCH-02` Formal Go/No-Go Decision Authority:**
  - Call formal Go/No-Go decision at 02:11 AM IST based on financial invariant verification output.
  - If any critical invariant fails: immediately command **No-Go** and execute `./scripts/emergency-rollback-to-laravel.sh` in < 60 seconds.
- **`M5-W19-ARCH-03` Production Traffic Declaration:**
  - At 02:15 AM IST, declare production officially live on the greenfield Node.js microservices architecture!

#### BE-1 (Senior Backend Engineer 1 — Auth & Edge Lead)
- **`M5-W19-BE1-01` Execute Edge Ingress Route Switch (02:12 AM):**
  - Switch Nginx upstream pointer from Laravel PHP-FPM (`145.223.19.105:8000`) to Node.js API Gateway cluster (`145.223.19.105:3000`).
  - Reload Nginx gracefully (`nginx -s reload`) without dropping active TLS connections.
- **`M5-W19-BE1-02` Real-Time Sentry & Edge Error Monitoring:**
  - Monitor live Sentry error dashboard and Pino edge logs. Verify zero 500 Internal Server Errors on incoming mobile app requests.

#### BE-2 (Senior Backend Engineer 2 — Catalog & Search Lead)
- **`M5-W19-BE2-01` Verify Production Typesense & Store Services (02:12 AM):**
  - Verify Typesense cluster responds to live product search queries with < 20ms latency.
  - Confirm store operating hours in Tirora show open status for dark stores.
- **`M5-W19-BE2-02` Edge Response Cache Warm-Up:**
  - Warm up Redis edge cache for homepage categories and popular dark store items.

#### BE-3 (Senior Backend Engineer 3 — Commerce & Inventory Lead)
- **`M5-W19-BE3-01` Verify Live Order & Payment Event Listeners (02:12 AM):**
  - Verify Razorpay webhook listener is active and receiving live pings.
  - Confirm BullMQ workers for `order-service` and `inventory-service` are consuming jobs.
- **`M5-W19-BE3-02` Live Stock Reservation Verification:**
  - Monitor MySQL transactional locks on `fattakse_inventory.stocks` during smoke test order placements.

#### FE-1 (Senior Frontend Engineer 1 — Admin Control Plane)
- **`M5-W19-FE1-01` Admin Production DNS/Nginx Switch (02:14 AM):**
  - Switch `admin.fattakse.in` Nginx virtual host to serve `admin-react` SPA.
  - Verify staff login, active dark store view, and live orders dashboard.
- **`M5-W19-FE1-02` Admin Post-Cutover UI Verification:**
  - Verify zone polygons, vendor lists, and inventory tables load cleanly without console errors.

#### FE-2 (Senior Frontend Engineer 2 — Merchant & Web Storefront)
- **`M5-W19-FE2-01` Vendor & Consumer Web Production DNS/Nginx Switch (02:14 AM):**
  - Switch `vendor.fattakse.in` and `fattakse.in` Nginx virtual hosts to serve `vendor-react` and `user-web` SPAs.
  - Verify Tirora dark store picker station loads the live order queue screen and `fattakse.in` loads the full-catalog storefront.
- **`M5-W19-FE2-02` Audio & WebSocket Live Ping Verification:**
  - Confirm dark store picker sound alert plays upon test order arrival and order tracking live updates ping cleanly.

#### DATA (Database Architect & Migration Operator)
- **`M5-W19-DATA-01` Place Laravel Monolith in Maintenance Mode (02:00 AM):**
  - SSH to VPS `145.223.19.105`.
  - Execute: `php artisan down --message="Scheduled Maintenance: We are modernizing Fattakse to serve you faster! Back in 15 minutes."`.
  - Stop queue workers: `sudo supervisorctl stop fattakse-worker:*`.
- **`M5-W19-DATA-02` Execute Final Delta Migration Script (02:04 AM):**
  - Run `./etl/stage3_cutover_delta_sync.py --since="2 hours ago"`.
  - Capture all mutations since pre-sync. Verify delta load completes in < 4 minutes.
- **`M5-W19-DATA-03` Execute Automated Financial Invariant Verification (02:10 AM):**
  - Run `./scripts/verify_financial_invariants.py`.
  - Assert 100% record match and 0.00 INR ledger variance across all wallets.
  - Issue cryptographic checksum sign-off to ARCH.

#### QA (SDET / Automation Engineer)
- **`M5-W19-QA-01` Production Smoke Test Verification (02:13 AM):**
  - Execute real smoke test journey on live production:
    1. Login via real customer mobile number (+91) with live SMS OTP.
    2. Search real catalog item on Typesense.
    3. Add item to cart and verify checkout quotation.
    4. Place real test order via COD.
    5. Verify order ticket arrives in Tirora Dark Store React Vendor portal.
    6. Confirm delivery with rider test app using delivery OTP.
- **`M5-W19-QA-02` Issue Final Production Smoke Sign-Off (02:14 AM):**
  - Confirm to ARCH that all 6 smoke steps succeeded with zero errors.

---

## Week 20: Post-Launch Hypercare, Optimization & Legacy Archival

### Detailed Tasks by Role

#### ARCH (Principal Architect & Project Lead)
- **`M5-W20-ARCH-01` 24x7 Hypercare Incident Command:**
  - Coordinate 24x7 engineering on-call rotations for the first 7 days post-cutover.
  - Hold daily standup reviewing system performance, error logs, and business KPIs.
- **`M5-W20-ARCH-02` Formal Project Acceptance Sign-Off:**
  - Review 7-day stability metrics (availability > 99.95%, p95 latency < 150ms, zero financial disputes).
  - Obtain formal stakeholder sign-off from executive leadership.
- **`M5-W20-ARCH-03` Decommission & Archive Legacy Laravel Monolith:**
  - Take cold snapshot of legacy MySQL database `fattakse_prod_legacy_cold_archive.sql.gz`.
  - Stop legacy PHP-FPM service, archive monolith codebase, and delete obsolete cron jobs.

#### BE-1 (Senior Backend Engineer 1 — Auth & Edge)
- **`M5-W20-BE1-01` Real-Time Edge Triage & Hotfixes:**
  - Monitor edge gateway error logs, rate limit metrics, and TLS certificate renewal automation.
  - Triage and deploy hotfixes for any edge auth anomalies within 2 hours.
- **`M5-W20-BE1-02` API Gateway Route Optimization:**
  - Audit Fastify route performance; optimize JSON serialization for top 10 most requested endpoints.

#### BE-2 (Senior Backend Engineer 2 — Catalog & Search)
- **`M5-W20-BE2-01` Typesense Live Search Telemetry Tuning:**
  - Analyze live user search queries in Tirora. Add common Hindi/English phonetic typos and synonyms.
  - Optimize Typesense memory usage and caching based on real query patterns.
- **`M5-W20-BE2-02` Catalog Database Query Optimization:**
  - Audit live MySQL slow query log; refine composite indexes on `fattakse_catalog` tables.

#### BE-3 (Senior Backend Engineer 3 — Commerce & Inventory Lead)
- **`M5-W20-BE3-01` Redis BullMQ Concurrency Tuning:**
  - Calibrate BullMQ worker concurrency across order processing, SMS, and rider notification queues based on real daily traffic curves.
- **`M5-W20-BE3-02` Razorpay Auto-Refund Queue Monitoring:**
  - Verify automated instant refunds for cancelled orders execute cleanly with zero stuck jobs.

#### FE-1 (Senior Frontend Engineer 1 — Admin Control Plane)
- **`M5-W20-FE1-01` Admin Operations Telemetry & Staff Feedback:**
  - Gather operational feedback from Tirora dispatchers and store managers using `admin-react`.
  - Deploy minor UI/UX optimizations for order filtering, dark store inventory audits, and refund processing.
- **`M5-W20-FE1-02` Admin Performance Monitoring:**
  - Monitor Core Web Vitals and frontend error logs via Sentry.

#### FE-2 (Senior Frontend Engineer 2 — Merchant & Web Storefront)
- **`M5-W20-FE2-01` Dark Store Picker Workflow Micro-Optimizations:**
  - Observe dark store pickers during peak evening hours (18:00 - 21:00 IST).
  - Optimize barcode scanner focus retention, audio chime volume, and one-tap bagging confirmation in `vendor-react`.
- **`M5-W20-FE2-02` Merchant Portal Payout & Stock UI Polish:**
  - Polish seller stock withdrawal history view and daily earnings summary screens.
- **`M5-W20-FE2-03` Consumer Web Storefront Monitoring & Core Web Vitals Polish (`user-web`):**
  - Monitor web checkout conversions, Core Web Vitals (LCP < 2.5s), and COTPA age verification flow on `user-web`.

#### DATA (Database Architect & ETL Data Engineer)
- **`M5-W20-DATA-01` Daily Financial Reconciliation Audits:**
  - Run automated daily reconciliation scripts comparing Razorpay bank settlements against `fattakse_finance` ledger records for the first 14 consecutive days.
  - Assert zero discrepancy ($\Delta = 0.00\text{ INR}$).
- **`M5-W20-DATA-02` Database Maintenance Automation:**
  - Configure automated weekly table optimization (`OPTIMIZE TABLE`), dead tuple vacuuming, and log rotation.

#### QA (SDET / Automation Engineer)
- **`M5-W20-QA-01` Post-Launch Telemetry & SLA Compliance Report:**
  - Compile full 7-day post-launch telemetry report:
    - Average p95 API response time.
    - Total orders processed vs error rate.
    - Zero Flutter mobile crashes.
- **`M5-W20-QA-02` Automated Synthetic Production Monitor:**
  - Deploy automated synthetic user journey test running every 30 minutes to verify end-to-end platform health.

---

## Gate 5 Final Acceptance Criteria Sign-Off Checklist
- [ ] Cutover executed cleanly within the 15-minute maintenance window.
- [ ] Delta ETL migration completed with 0.00 INR financial discrepancy.
- [ ] All 3 frozen Flutter mobile apps (Customer, Vendor, Rider) operating normally without forced updates or crashes.
- [ ] React Admin Control Plane, Vendor/Picker Portals, and Consumer Web Storefront (`user-web`) operating normally.
- [ ] Kafka / Redpanda event streaming operating healthy with zero message drops and < 50ms consumer group lag.
- [ ] System availability > 99.95% over the first 7 consecutive days of production.
- [ ] Zero critical Sentry errors; average API p95 latency < 180ms.
- [ ] Legacy Laravel monolith successfully decommissioned and archived.
