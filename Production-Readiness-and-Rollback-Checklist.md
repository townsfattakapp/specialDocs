# Fattakse — Production Readiness & Rollback Checklist (Parallel Greenfield Cutover)

**Document Version:** 2.0.0  
**Target Cutover Window:** Month 5 (March 2027 — 02:00 AM IST)  
**Maintenance Window Duration:** 15 Minutes  
**Status:** Mandatory Production Operations Gate  
**Author:** Principal DevOps Engineer & Site Reliability Lead  

---

## 1. Pre-Cutover Verification Gates (All Gates Mandatory)

| Gate ID | Verification Item | Target Threshold / Requirement | Verification Evidence | Status |
|---|---|---|---|---|
| **GATE-01** | **Automated Test Coverage** | > 85% branch coverage on Cart, Pricing, Stock Lock, Razorpay, and Order state machine. | CI test report with zero skipped assertions. | PENDING |
| **GATE-02** | **Flutter API Contract Match** | 100% byte-for-byte schema equivalence across 431 legacy routes. Zero breaking changes. | Automated JSON schema diff report. | PENDING |
| **GATE-03** | **Load & Concurrency Baseline** | 1,500 req/sec sustained for 30 minutes; p95 latency < 180ms; 0% 5xx errors; 0 duplicate stock deductions under 100 concurrent checkout race conditions. | k6 distributed load test summary. | PENDING |
| **GATE-04** | **ETL Rehearsal & Invariants** | Stage 2 delta migration executes in < 10 minutes on a fresh production copy. 100% reconciliation match on user balances and active orders. | Reconciliation test runbook sign-off. | PENDING |
| **GATE-05** | **Passport Token Emulation** | Existing active customer, vendor, and rider Bearer JWTs successfully validate in `iam-service` without forcing re-login. | Staging mobile auth smoke test log. | PENDING |
| **GATE-06** | **Typesense Search Parity** | All item mutations in MySQL reflect in Typesense 28.0 in < 500ms via BullMQ queue. | Real-time catalog search test log. | PENDING |
| **GATE-07** | **Hyper POS Decommission** | All 7 legacy POS tables verified non-referenced; POS cron jobs stopped; dark store pick/pack fully operational in React portal. | Production audit checklist sign-off. | PENDING |

---

## 2. Cutover Night Execution Runbook (02:00 AM IST)

```
02:00 AM : Put legacy Laravel application into READ-ONLY Maintenance Mode.
02:03 AM : Stop background queue workers on Laravel host.
02:05 AM : Execute Delta ETL Migration Script (extracts rows modified in final 2 hours).
02:10 AM : Run automated reconciliation script (asserts zero financial variance).
02:12 AM : Switch Nginx Ingress / DNS pointer to New Microservices API Gateway.
02:14 AM : Execute end-to-end smoke test (Login -> Add to Cart -> Place Test Order).
02:15 AM : Release mobile app traffic; declare greenfield production platform live!
```

---

## 3. 60-Second Emergency Rollback Runbook

If an unexplained critical regression, financial anomaly, or mobile client crash is detected during or immediately following cutover:

### 3.1 Step 1: Immediate Ingress Reversal (< 30 Seconds)
In `/etc/nginx/conf.d/fattakse.conf`, revert the API upstream pointer from the Microservices API Gateway back to the legacy Laravel monolith container:

```bash
# On Hostinger VPS (145.223.19.105):
cd /home/vishwas/Pictures/fattakseInLocal/towns_fattakse_in
./scripts/emergency-rollback-to-laravel.sh
```

*(Script executes: `sed -i 's/upstream_backend gateway:8080/upstream_backend admin:8000/g' /etc/nginx/nginx.conf && nginx -s reload`).*

### 3.2 Step 2: Disable Laravel Read-Only Mode (< 15 Seconds)
Restore Laravel write operations:

```bash
docker exec -it towns_fattakse_in_admin_1 php artisan up
```

### 3.3 Step 3: Reverse-Delta Data Synchronization (< 2 Minutes)
If any live orders or payments were captured on the Node.js platform during the brief window prior to rollback:
1. Run `./scripts/etl-reverse-sync.py` to extract new orders from `fattakse_order` and `fattakse_finance`.
2. Insert those records back into `fattakse_prod` in Laravel.
3. This guarantees **ZERO LOST ORDERS, PAYMENTS, OR DATA CORRUPTION**.

### 3.4 Step 4: Incident Analysis
1. Isolate the offending endpoint and retrieve payload traces from Sentry.
2. Verify Redis queue states and reconcile payment gateway ledger with Razorpay dashboard.
3. Convene engineering root-cause analysis (RCA) within 2 hours.
