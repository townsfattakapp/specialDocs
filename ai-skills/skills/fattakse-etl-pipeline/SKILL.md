---
name: fattakse-etl-pipeline
description: >-
  Executes, verifies, and audits the Three-Stage ETL Data Migration Pipeline from legacy MySQL
  to the 8 isolated microservice databases, including reverse-delta sync for zero-loss rollback.
  Use whenever running migration scripts, checking data consistency, or validating rehearsal cuts.
---

# Fattakse ETL Data Migration Pipeline Skill

This skill governs the migration of data from the legacy MySQL monolith to the greenfield microservices suite, guaranteeing zero data loss and mathematical consistency.

## 1. The Three-Stage ETL Strategy

1. **Stage 1: Static & Structural Entities (Month 1 & 2):**
   - Tables: Zones, business modules, store accounts, categories, items, addons, variations, banners.
   - Run in offline background mode without touching live production writes.

2. **Stage 2: Core User & Historical Balances (Month 3 & 4):**
   - Tables: Customers, addresses, delivery men, historical orders, reviews, wallet transactions, coupon logs.
   - Transforms legacy plain amounts into atomic integer paise (`BIGINT`).

3. **Stage 3: Cutover Night Delta Sync (Month 5 - 02:00 AM IST):**
   - Scheduled 15-minute maintenance window.
   - Extracts delta: `SELECT * FROM ... WHERE updated_at > :rehearsal_watermark`.
   - Ingests into target databases and runs mathematical invariant checks in < 10 minutes.

4. **Reverse-Delta Standby (60-Second Rollback Guarantee):**
   - If Gate 7 smoke testing fails during cutover night, a reverse ETL worker replicates new transactions back to legacy MySQL before rolling back DNS, guaranteeing zero customer data loss.

## 2. Invariant Proof Verification

Never sign off on an ETL migration run without verifying all invariant checks:
- **Order Integrity:** Sum of item prices matches `order_amount` exactly.
- **Ledger Invariant:** Sum of vendor credits + rider payouts + platform fees == customer captured total.
- **Foreign Key Integrity:** Zero orphaned items, categories, or order details.

Run the automated invariant verification script:
```bash
bash .agents/skills/fattakse-etl-pipeline/scripts/run-etl-invariants.sh
```

Consult [`references/invariant_checks.md`](./references/invariant_checks.md) for individual SQL validation queries.
