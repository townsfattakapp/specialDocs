# Month 5 Task Prompts: Production Provisioning, Cutover Night & Hypercare (Weeks 17–20)

This document contains production-grade, copy-pasteable execution prompts for each task in Month 5.

---

## Table of Contents
- [Week 17 Prompts](#week-17-production-cluster-provisioning--historical-pre-sync)
- [Week 18 Prompts](#week-18-dress-rehearsal-3-full-simulated-maintenance-window)
- [Week 19 Prompts](#week-19-production-cutover-night-0200-am-ist)
- [Week 20 Prompts](#week-20-post-launch-hypercare-optimization--legacy-archival)

---

## Week 17: Production Cluster Provisioning & Historical Pre-Sync

### `[M5-W17-ARCH-01]` Provision Production Infrastructure Topology
**Assignee:** ARCH (Principal Architect & Project Lead)  
**Target Files:** `docker-compose.prod.yml`, `infra/nginx/nginx.conf`

```text
You are acting as the Principal Architect (ARCH) for the Fattakse platform modernization (Evolw Technologies Private Limited).

TASK: M5-W17-ARCH-01 - Provision Production Infrastructure Topology

CONTEXT:
We must provision the production Docker Compose cluster on the Hostinger production server ahead of cutover, running in parallel with the live Laravel monolith until cutover night.

REQUIREMENTS:
1. Author docker-compose.prod.yml:
   - 8 Node.js Fastify microservices with resource limits (cpus: 1.0, mem_limit: 512m each).
   - apps/api-gateway on port 3000.
   - MySQL 8.0 configured with 8 logical databases and tuned buffer pools (innodb_buffer_pool_size = 4G).
   - Redis 7.2.4 with AOF persistence.
   - Redpanda / Kafka v24.2.x C++ broker with persistent NVMe volume.
   - Typesense 28.0 cluster with persistent data volume.
   - Nginx edge ingress container terminating SSL.
2. Ensure healthcheck directives exist for every container.
3. Verify cluster boots and stabilizes with CPU < 10% and RAM < 8GB under baseline idle state.

DEFINITION OF DONE:
- docker compose -f docker-compose.prod.yml up -d boots all production containers healthy.
- Terminus health endpoints return HTTP 200 across all 8 services.
```

---

### `[M5-W17-BE3-03]` Production Redpanda / Kafka Cluster Verification
**Assignee:** BE-3 (Senior Backend Engineer 3 — Commerce & Inventory Lead)  
**Target Files:** `infra/kafka/init-topics.sh`

```text
You are acting as Senior Backend Engineer 3 (BE-3) for the Fattakse platform modernization.

TASK: M5-W17-BE3-03 - Production Redpanda / Kafka Cluster Verification

CONTEXT:
We implement ADR-0010: Hybrid Asynchronous Architecture. Production Redpanda/Kafka must be initialized with durable retention and partition settings before cutover.

REQUIREMENTS:
1. Author infra/kafka/init-topics.sh using rpk CLI:
   - fattakse.orders.lifecycle (3 partitions, cleanup.policy=delete, retention.ms=2592000000 [30 days]).
   - fattakse.finance.transactions (3 partitions, retention.ms=7776000000 [90 days]).
   - fattakse.riders.telemetry (6 partitions, retention.ms=604800000 [7 days]).
   - fattakse.inventory.adjustments (3 partitions, retention.ms=2592000000 [30 days]).
   - fattakse.catalog.events (3 partitions, retention.ms=604800000 [7 days]).
2. Configure Prometheus exporter (rpk status) to expose consumer group lag metrics to Grafana.
3. Test topic publish and consumer read: assert sub-millisecond p99 latency.

DEFINITION OF DONE:
- All topics created with verified partitions and retention policies.
- Prometheus scraper reports 0 errors.
```

---

### `[M5-W17-DATA-01]` Pre-Sync Historical Data (Initial Load)
**Assignee:** DATA (Database Architect & ETL Data Engineer)  
**Target Files:** `etl/stage3_presync.py`

```text
You are acting as the Database Architect (DATA) for the Fattakse platform modernization.

TASK: M5-W17-DATA-01 - Pre-Sync Historical Data (Initial Load)

CONTEXT:
To minimize the maintenance window to < 15 minutes, we pre-sync all historical production data up to T_cutover minus 48 hours while the live Laravel monolith continues serving live traffic.

REQUIREMENTS:
1. Take a consistent logical snapshot of production database:
   `mysqldump --single-transaction --quick --lock-tables=false fattakse_prod > backup_presync.sql`
2. Run etl/stage3_presync.py:
   - Extract and transform all historical records (users, items, past orders, wallets) into the 8 production domain databases.
   - Bulk index products into the production Typesense 28.0 cluster.
3. Record high-water mark timestamp T_presync = NOW() to track mutations for cutover night.

DEFINITION OF DONE:
- Historical database loaded into production MySQL 8.0.
- Typesense search returns complete product catalog.
```

---

## Week 18: Dress Rehearsal 3 (Full Simulated Maintenance Window)

### `[M5-W18-ARCH-01]` Execute Full Dry Run Simulation
**Assignee:** ARCH (Principal Architect & Project Lead)  
**Target Files:** `docs/modernization/reports/rehearsal3_log.md`

```text
You are acting as the Principal Architect (ARCH) for the Fattakse platform modernization.

TASK: M5-W18-ARCH-01 - Execute Full Dry Run Simulation

CONTEXT:
Dress Rehearsal 3 is the final dry run executed with all 8 engineering pod members present at 02:00 AM IST to simulate cutover night conditions to the exact second.

REQUIREMENTS:
1. Convene team on live voice bridge at 01:45 AM IST.
2. Execute sequence:
   - 02:00 AM: Simulated maintenance mode engaged.
   - 02:02 AM: Queue drain confirmed.
   - 02:04 AM: Delta sync script executed on 48h simulated delta.
   - 02:08 AM: Delta sync completes.
   - 02:10 AM: Financial invariant verification script executes and asserts 0.00 INR discrepancy.
   - 02:12 AM: Upstream Nginx pointer switched.
   - 02:13 AM: QA smoke test executed.
   - 02:15 AM: Maintenance mode lifted.
3. Record exact clock timestamps of each step in docs/modernization/reports/rehearsal3_log.md.

DEFINITION OF DONE:
- Dry run completes in under 15 minutes.
- Every team member signs off on their exact operational duties.
```

---

### `[M5-W18-ARCH-02]` Test 60-Second Rollback Trigger
**Assignee:** ARCH (Principal Architect & Project Lead)  
**Target Files:** `scripts/emergency-rollback-to-laravel.sh`

```text
You are acting as the Principal Architect (ARCH) for the Fattakse platform modernization.

TASK: M5-W18-ARCH-02 - Test 60-Second Rollback Trigger

CONTEXT:
If an unforeseen critical issue occurs during cutover, we must have a battle-tested emergency rollback script that restores production to the Laravel monolith within 60 seconds with zero data loss.

REQUIREMENTS:
1. Author scripts/emergency-rollback-to-laravel.sh:
   - Step 1: Re-point Nginx upstream back to Laravel PHP-FPM:
     `ln -sfn /etc/nginx/sites-available/laravel.conf /etc/nginx/sites-enabled/default && nginx -s reload`
   - Step 2: Lift maintenance mode on Laravel:
     `php artisan up`
   - Step 3: Restart Laravel queue supervisors:
     `sudo supervisorctl start fattakse-worker:*`
   - Step 4: Run reverse-delta sync if any orders were placed on Node.js during the window.
2. Execute rollback drill in rehearsal environment: time elapsed from trigger to full Laravel availability must be < 60 seconds.

DEFINITION OF DONE:
- Rollback executes cleanly in < 60 seconds.
- Laravel handles mobile requests immediately with zero downtime.
```

---

## Week 19: PRODUCTION CUTOVER NIGHT (02:00 AM IST)

### `[M5-W19-ARCH-02]` Formal Go/No-Go Decision Authority
**Assignee:** ARCH (Principal Architect & Cutover Incident Commander)  
**Target Files:** `docs/modernization/reports/cutover_decision.md`

```text
You are acting as the Cutover Incident Commander (ARCH) for the Fattakse platform modernization.

TASK: M5-W19-ARCH-02 - Formal Go/No-Go Decision Authority

CONTEXT:
At 02:11 AM IST on Cutover Night, you hold sole executive decision authority to declare Go or No-Go based on automated checks.

REQUIREMENTS:
1. At 02:10 AM IST, inspect output from DATA lead's scripts/verify_financial_invariants.py:
   - Proof 1: Customer Wallets Delta === 0.00 INR.
   - Proof 2: Rider Collected Cash Delta === 0.00 INR.
   - Proof 3: Merchant Payable Delta === 0.00 INR.
   - Proof 4: Double-entry debit/credit delta === 0.00 INR.
2. Decision Protocol:
   - If ALL proofs equal 0.00 INR and delta migration took < 6 minutes:
     -> Command: "GO FOR CUTOVER. PROCEED TO NGINX SWITCH."
   - If ANY proof shows discrepancy > 0.00 INR or fatal errors:
     -> Command: "NO-GO. TRIGGER EMERGENCY ROLLBACK SCRIPT IMMEDIATELY."
3. Record decision timestamp and cryptographic hash in docs/modernization/reports/cutover_decision.md.

DEFINITION OF DONE:
- Formal Go/No-Go announced with zero ambiguity on operational bridge.
```

---

### `[M5-W19-BE1-01]` Execute Edge Ingress Route Switch (02:12 AM)
**Assignee:** BE-1 (Senior Backend Engineer 1 — Auth & Edge Lead)  
**Target Files:** `/etc/nginx/conf.d/fattakse_ingress.conf`

```text
You are acting as Senior Backend Engineer 1 (BE-1) for the Fattakse platform modernization.

TASK: M5-W19-BE1-01 - Execute Edge Ingress Route Switch (02:12 AM)

CONTEXT:
Upon ARCH's "GO" command, BE-1 switches the live Nginx ingress pointer from Laravel PHP-FPM to the Node.js Fastify API Gateway.

REQUIREMENTS:
1. SSH into production host 145.223.19.105.
2. Execute atomic configuration swap:
   ```bash
   sudo ln -sfn /etc/nginx/conf.d/microservices_upstream.conf /etc/nginx/conf.d/active_upstream.conf
   sudo nginx -t && sudo nginx -s reload
   ```
3. Verify that requests to api.fattakse.in/health return HTTP 200 from Fastify gateway.
4. Confirm existing TLS connections are maintained without dropped packets.

DEFINITION OF DONE:
- Nginx reload completes in < 500ms.
- Traffic flows directly to Node.js microservices.
```

---

### `[M5-W19-DATA-01]` Place Laravel Monolith in Maintenance Mode (02:00 AM)
**Assignee:** DATA (Database Architect & Migration Operator)  
**Target Files:** Remote execution on `145.223.19.105`

```text
You are acting as the Migration Operator (DATA) for the Fattakse platform modernization.

TASK: M5-W19-DATA-01 - Place Laravel Monolith in Maintenance Mode (02:00 AM)

CONTEXT:
At exactly 02:00 AM IST, the live database must be frozen to prevent new mutations while the final delta ETL script executes.

REQUIREMENTS:
1. SSH into production VPS 145.223.19.105 at 01:59 AM IST.
2. At exactly 02:00:00 AM IST, execute:
   ```bash
   cd /var/www/towns_fattakse_in
   php artisan down --message="Scheduled Maintenance: Modernizing Fattakse to serve you faster! Back in 15 minutes." --retry=60
   sudo supervisorctl stop fattakse-worker:*
   ```
3. Verify that mobile app requests receive HTTP 503 maintenance screen.
4. Confirm zero active background queue jobs running: `sudo supervisorctl status`.

DEFINITION OF DONE:
- Laravel is in read-only maintenance mode.
- Queue workers stopped completely.
```

---

### `[M5-W19-DATA-02]` Execute Final Delta Migration Script (02:04 AM)
**Assignee:** DATA (Database Architect & Migration Operator)  
**Target Files:** `etl/stage3_cutover_delta_sync.py`

```text
You are acting as the Migration Operator (DATA) for the Fattakse platform modernization.

TASK: M5-W19-DATA-02 - Execute Final Delta Migration Script (02:04 AM)

CONTEXT:
This script captures all database records modified since the pre-sync (orders, wallet top-ups, customer signups) and updates the production microservice schemas.

REQUIREMENTS:
1. At 02:04 AM IST, trigger:
   `python3 etl/stage3_cutover_delta_sync.py --since="T_presync"`
2. Script processes delta chunks:
   - Upserts newly created/modified users and addresses.
   - Upserts final order statuses and payment transactions.
   - Updates inventory ledger balances.
3. Monitor execution timer: Must complete in < 4 minutes.
4. On completion, immediately trigger scripts/verify_financial_invariants.py.

DEFINITION OF DONE:
- Delta migration completes in < 4 minutes with 0 errors.
- Hand off output to ARCH for Go/No-Go decision.
```

---

### `[M5-W19-QA-01]` Production Smoke Test Verification (02:13 AM)
**Assignee:** QA (SDET / Automation Engineer)  
**Target Files:** `qa/e2e/production_smoke_test.spec.ts`

```text
You are acting as the SDET / Automation Engineer (QA) for the Fattakse platform modernization.

TASK: M5-W19-QA-01 - Production Smoke Test Verification (02:13 AM)

CONTEXT:
Before lifting maintenance mode for the general public, QA executes a real, live end-to-end transaction on production.

REQUIREMENTS:
1. Using test mobile phone and whitelisted IP:
   - Step 1: Open Flutter Customer app. Log in with real phone OTP (+91).
   - Step 2: Search catalog on Typesense -> add test item to cart.
   - Step 3: Verify checkout quote (GST, delivery fee).
   - Step 4: Place order via Cash on Delivery.
   - Step 5: Verify order ticket appears in Tirora Dark Store KDS (vendor.fattakse.in).
   - Step 6: Verify proximity dispatch pings test rider app.
   - Step 7: Complete delivery using customer OTP.
2. Confirm all 7 steps succeed within 90 seconds.
3. Report: "PRODUCTION SMOKE TEST 100% SUCCESSFUL" to ARCH on bridge.

DEFINITION OF DONE:
- Complete live order placed and delivered on production with zero errors.
```

---

## Week 20: Post-Launch Hypercare, Optimization & Legacy Archival

### `[M5-W20-ARCH-03]` Decommission & Archive Legacy Laravel Monolith
**Assignee:** ARCH (Principal Architect & Project Lead)  
**Target Files:** `scripts/archive_legacy_monolith.sh`

```text
You are acting as the Principal Architect (ARCH) for the Fattakse platform modernization.

TASK: M5-W20-ARCH-03 - Decommission & Archive Legacy Laravel Monolith

CONTEXT:
Following 7 consecutive days of stable production operation (> 99.95% availability, zero financial disputes), we formally decommission and archive the legacy Laravel monolith.

REQUIREMENTS:
1. Author scripts/archive_legacy_monolith.sh:
   - Take final cold mysqldump of legacy database:
     `mysqldump --single-transaction fattakse_prod | gzip > /cold-archive/fattakse_prod_legacy_final_2027.sql.gz`
   - Compute and store SHA-256 checksum of archive dump.
   - Upload cold archive to encrypted long-term object storage (S3 Glacier / Wasabi).
   - Stop and disable legacy PHP 8.2-FPM and Laravel supervisor services:
     `sudo systemctl stop php8.2-fpm && sudo systemctl disable php8.2-fpm`
   - Archive /var/www/towns_fattakse_in into tar.gz and remove from live Nginx configs.
2. Confirm that only the Node.js Fastify microservices cluster, Redpanda, Redis, and Typesense are consuming system resources.

DEFINITION OF DONE:
- Legacy monolith is completely archived with verified cryptographic checksums.
- Zero legacy processes running on production host.
```

---

### `[M5-W20-DATA-01]` Daily Financial Reconciliation Audits
**Assignee:** DATA (Database Architect & ETL Data Engineer)  
**Target Files:** `scripts/daily_financial_reconciliation.py`

```text
You are acting as the Database Architect (DATA) for the Fattakse platform modernization.

TASK: M5-W20-DATA-01 - Daily Financial Reconciliation Audits

CONTEXT:
During the 14-day hypercare stabilization window, an automated daily financial audit script must run every night at 23:59 IST comparing bank deposits against ledger balances.

REQUIREMENTS:
1. Author scripts/daily_financial_reconciliation.py:
   - Fetch daily Razorpay settlement report via Razorpay Settlements API.
   - Sum total captured customer payments in fattakse_finance.payments.
   - Sum total COD cash deposited by riders in delivery_man_wallets.
   - Sum total merchant payouts disbursed in vendor_wallets.
   - Assert: (Captured Payments + Cash Deposited) - (Merchant Payouts + Rider Fees + Gateway Fees) === Platform Net Margin.
2. Compute discrepancy delta: Assert Delta === 0.00 INR.
3. Automatically email daily reconciliation summary to Evolw executive management.

DEFINITION OF DONE:
- Script runs nightly via cron.
- Generates 14 consecutive daily reports with 0.00 INR discrepancy.
```
