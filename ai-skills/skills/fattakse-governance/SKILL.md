---
name: fattakse-governance
description: >-
  Enforces architectural invariants, non-negotiable compliance rules, and code quality
  standards across all services in the Fattakse modernization monorepo. Use whenever
  designing microservices, reviewing code, changing API Gateway routes, or modifying database schemas.
---

# Fattakse Modernization Architecture Governance Skill

This skill provides the mandatory governance guardrails and checklist for any agent or engineer writing or reviewing code in the Fattakse ecosystem.

## 1. Architectural Guardrails (Non-Negotiable)

1. **Live Production is strictly READ-ONLY:**
   - Production VPS `145.223.19.105` must never be touched directly with write commands.
   - The legacy Laravel monolith (`towns_fattakse_in`) is the executable reference implementation.

2. **Frozen Mobile Clients (Zero App-Store Disruption):**
   - Flutter Customer (`1.0.18`), Vendor (`1.0.5`), and Rider (`1.0.1`) are compiled binaries.
   - The Fastify API Gateway must emulate legacy response structures, header normalizations, and Passport RSA JWT claims without requiring mobile app updates.

3. **Dual-Channel Consumer Architecture:**
   - Flutter mobile apps: 100% tobacco-free (Google Play & Apple App Store compliant).
   - React User Web Storefront (`apps/user-web` at `fattakse.in`): Full-catalog storefront (groceries, food, dark-store FMCG, and COTPA 2003 18+ age-gated Paan Corner products) to maximize AOV.

4. **Single-Writer Database Ownership:**
   - 8 isolated databases (`fattakse_iam`, `fattakse_store`, `fattakse_catalog`, `fattakse_inventory`, `fattakse_order`, `fattakse_fleet`, `fattakse_finance`, `fattakse_notify`).
   - Zero cross-service SQL joins.

5. **Hybrid Asynchronous Messaging:**
   - Redpanda / Apache Kafka (`kafkajs`) for replayable, persistent domain events (`fattakse.orders.lifecycle`, `fattakse.riders.telemetry`, `fattakse.inventory.adjustments`, `fattakse.finance.transactions`).
   - Transactional Outbox pattern on all producers; Idempotency check (`processed_events`) on all consumers.
   - Redis 7.2 BullMQ strictly for delayed timers (e.g. 3-min SLA, 10-min OTP).

6. **Hyper POS Retired (ADR-0004):**
   - Offline retail walk-in counter POS tables and routes are decommissioned.
   - Dark store operations use native digital Pick & Pack in `vendor-react`.

---

## 2. Code Review & PR Acceptance Checklist

Before approving or marking any task complete, verify this checklist:

- [ ] Does this change preserve frozen Flutter client compatibility? (Check error envelope `{ errors: [...] }` and pagination shape).
- [ ] Are mobile requests verified to be 100% tobacco-free?
- [ ] Does any database query cross microservice boundary? (If yes, reject and refactor to gRPC or Kafka event).
- [ ] Is event publishing done via `outbox_events` table within transaction?
- [ ] Does the Kafka consumer verify event idempotency via `processed_events`?
- [ ] Are all financial ledger amounts stored as atomic integers (in paise) to eliminate floating-point drift?
- [ ] Are unit tests and OpenAPI specs updated and passing?

For detailed architectural reference, consult [`references/architectural_invariants.md`](./references/architectural_invariants.md).
