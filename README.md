# Fattakse Platform Modernization: Parallel Greenfield Microservices Suite

**Operating Company:** Evolw Technologies Private Limited  
**Registered Office & Flagship Hub:** Tirora, Maharashtra (State Code: 27)  
**Business Model:** 100% Online Quick-Commerce (Dark Store) & Restaurant Delivery  
**Strategy:** Parallel Greenfield Microservices Development & Production Replacement (5 Months)  
**Status:** Approved Architectural Blueprint  

---

## Executive Overview

This directory contains the complete, canonical architectural and execution documentation for the end-to-end modernization of the Fattakse platform from its legacy PHP 8.2 / Laravel 12 monolith to a **Node.js 22 + TypeScript 5.6+ Microservices Architecture** with **React 19 + TypeScript Admin and Vendor Portals**.

### Fundamental Directives
1. **Current Production is Untouched:** The live Laravel monolith deployed on Hostinger VPS (`145.223.19.105`) continues serving customers, merchants, and riders without disruption throughout Months 1–5.
2. **Laravel as Reference Implementation:** The production application serves as the canonical reference specification for all business logic, tax rules, and API contracts.
3. **Hyper POS Permanently Retired:** Offline walk-in counter retail is excluded. All 528 POS routes, 7 POS database tables, and offline till sync jobs are decommissioned.
4. **Frozen Mobile Clients:** Flutter Customer (`1.0.18`), Vendor (`1.0.5`), and Rider (`1.0.1`) apps remain unchanged; compatibility is guaranteed via the API Gateway.
5. **Five-Month Replacement Window:** Delivered by an 8 FTE engineering pod using a 3-Stage ETL data migration pipeline.

---

## Documentation Index & Reading Guide

```
+----------------------------------------------------------------------------------------------------+
|                                    MASTER DOCUMENTATION SUITE                                      |
+----------------------------------------------------------------------------------------------------+
|  1. Target Architecture               | Target-System-Architecture.md                              |
|  2. Database Ownership & ETL Matrix   | Database-Dependency-and-Ownership-Matrix.md                |
|  3. Business Workflow Specifications  | Business-Workflow-Documentation.md                         |
|  4. Five-Month Execution Roadmap      | Five-Month-Execution-Roadmap.md                            |
|  5. Flutter Backward Compatibility    | Flutter-Backward-Compatibility-Plan.md                     |
|  6. API Contract Inventory (/api/v1)  | API-Contract-Inventory.md                                  |
|  7. Admin & Vendor Frontend Parity    | Admin-Vendor-Frontend-Parity-Matrix.md                      |
|  8. Production Cutover & Rollback     | Production-Readiness-and-Rollback-Checklist.md              |
|  9. Risk Register & ADR Decision Log  | Risk-Register-and-Decision-Log.md                          |
|  10. Current System Architecture      | Current-System-Architecture.md                             |
|  11. Granular Weekly Task Plans (W1-20)| plans/README.md                                            |
|  12. Team Execution Prompts Playbook   | plans/prompts/README.md                                    |
|  13. Upcoming Team AI Skills & Rules   | ai-skills/README.md                                        |
|  14. Modernization Certification Standard| Modernization-Certification-Framework.md                  |
+----------------------------------------------------------------------------------------------------+
```

### Granular Weekly Task Plans (plans/)
For day-by-day and week-by-week engineering task assignments across the 8 FTE pod, consult the dedicated execution documents:
- [`plans/Month-1-Tasks-Discovery-and-Scaffolding.md`](plans/Month-1-Tasks-Discovery-and-Scaffolding.md) — Weeks 1–4
- [`plans/Month-2-Tasks-Foundations-and-Catalog.md`](plans/Month-2-Tasks-Foundations-and-Catalog.md) — Weeks 5–8
- [`plans/Month-3-Tasks-Transactions-and-Fulfillment.md`](plans/Month-3-Tasks-Transactions-and-Fulfillment.md) — Weeks 9–12
- [`plans/Month-4-Tasks-Integration-and-Rehearsals.md`](plans/Month-4-Tasks-Integration-and-Rehearsals.md) — Weeks 13–16
- [`plans/Month-5-Tasks-Cutover-and-Stabilization.md`](plans/Month-5-Tasks-Cutover-and-Stabilization.md) — Weeks 17–20

### End-to-End Task Prompts Playbook (`plans/prompts/`)
Production-ready, copy-pasteable prompts engineered for AI coding assistants and developers for every single task across all 20 weeks:
- [`plans/prompts/README.md`](plans/prompts/README.md) — Prompt execution workflow and role guidelines
- [`plans/prompts/Month-1-Task-Prompts.md`](plans/prompts/Month-1-Task-Prompts.md) — Weeks 1–4 Prompts (Scaffolding, Contracts, Infra, Stage 1 ETL)
- [`plans/prompts/Month-2-Task-Prompts.md`](plans/prompts/Month-2-Task-Prompts.md) — Weeks 5–8 Prompts (IAM, Store, Catalog, Typesense CDC, Cart, Pricing)
- [`plans/prompts/Month-3-Task-Prompts.md`](plans/prompts/Month-3-Task-Prompts.md) — Weeks 9–12 Prompts (Orders, Multi-Owner Inventory, Fleet, Finance, Web SPAs)
- [`plans/prompts/Month-4-Task-Prompts.md`](plans/prompts/Month-4-Task-Prompts.md) — Weeks 13–16 Prompts (Diffing, Rehearsals 1 & 2, Streaming Load/Chaos, Hardening)
- [`plans/prompts/Month-5-Task-Prompts.md`](plans/prompts/Month-5-Task-Prompts.md) — Weeks 17–20 Prompts (Production Provisioning, Cutover Night, Hypercare)

### Upcoming Team AI Skills & Rules Suite (`ai-skills/`)
Pre-packaged guardrails and automated skills for the upcoming greenfield team starting next month:
- [`ai-skills/README.md`](ai-skills/README.md) — Onboarding and activation guide for the new modernization team
- `ai-skills/rules/` — Strict invariants (Read-only prod, frozen Flutter compatibility, dual-channel storefront, Kafka streaming)
- `ai-skills/skills/` — On-demand runbooks for governance, contract verification, Kafka streaming, ETL pipeline, and prompt execution

### Detailed Document Summaries

1. [`Target-System-Architecture.md`](Target-System-Architecture.md)  
   Comprehensive architecture specification: 8 microservices (`iam`, `store`, `catalog`, `inventory`, `order`, `fleet`, `finance`, `notify`) + API Gateway, NestJS/Fastify runtime, Redis BullMQ event bus, Transactional Outbox pattern, and environment isolation topology.

2. [`Database-Dependency-and-Ownership-Matrix.md`](Database-Dependency-and-Ownership-Matrix.md)  
   Mapping of all 264 legacy MySQL tables into 8 isolated logical databases (`fattakse_iam`, `fattakse_catalog`, etc.). Enforces single-writer rule, eliminates cross-service joins, purges 7 POS tables, and defines the **Three-Stage ETL Data Migration Pipeline** with invariant proofs.

3. [`Business-Workflow-Documentation.md`](Business-Workflow-Documentation.md)  
   Canonical workflows aligned with Evolw Technologies business model: Tirora dark-store multi-owner inventory (Evolw-owned vs. seller-deposited), urgent seller stock withdrawals, digital pick & pack, dual-model food delivery (Model A vs Model B), doorstep 18+ ID checks, and Tirora town-level P&L tracking.

4. [`Five-Month-Execution-Roadmap.md`](Five-Month-Execution-Roadmap.md)  
   Detailed 20–22 week delivery plan (November 2026 – March 2027) with week-by-week workstreams, resource allocation (8 FTE engineering pod), and monthly Go/No-Go acceptance gates.

5. [`Flutter-Backward-Compatibility-Plan.md`](Flutter-Backward-Compatibility-Plan.md)  
   Specification for preserving frozen mobile clients: API Gateway request header normalization (`zoneId`, `latitude`, `longitude`), error response standard (`errors: [{code, message}]`), pagination shape, and **Passport RSA JWT token emulation** to prevent active user logouts.

6. [`API-Contract-Inventory.md`](API-Contract-Inventory.md)  
   Complete catalog of 431 legacy `/api/v1/*` routes mapped through the Gateway to target microservices, with explicit retirement of 27 POS/ERP endpoints.

7. [`Admin-Vendor-Frontend-Parity-Matrix.md`](Admin-Vendor-Frontend-Parity-Matrix.md)  
   Mapping 1,419 legacy Blade routes to two React 19 SPAs (`admin-react` Operations Control Plane and `vendor-react` Dark Store Picker / Kitchen Display), plus the modernized full-catalog Consumer Web Storefront (`user-web` at `fattakse.in`) with integrated 18+ Paan Corner compliance, component architecture, and security standards.

8. [`Production-Readiness-and-Rollback-Checklist.md`](Production-Readiness-and-Rollback-Checklist.md)  
   Mandatory pre-cutover gates (Gate 1 through Gate 7), 15-minute scheduled maintenance window runbook (02:00 AM IST), and **60-second emergency rollback runbook** with reverse-delta ETL sync guaranteeing zero data loss.

9. [`Risk-Register-and-Decision-Log.md`](Risk-Register-and-Decision-Log.md)  
   Architectural risk matrix with severities, probabilities, and mitigations. Approved Architectural Decision Records (ADR-0004 through ADR-0010).


10. [`Current-System-Architecture.md`](Current-System-Architecture.md)  
    Comprehensive baseline audit of the existing Laravel monolith, Redis 14-queue priority tiers, Reverb WebSockets, Typesense 28.0, and Hostinger VPS deployment (`145.223.19.105`).

11. [`Modernization-Certification-Framework.md`](Modernization-Certification-Framework.md)  
    Canonical release governance and Launch-Gate Certification standard (derived from Fattakse Food Module certification protocols): binary `CERTIFIED` vs `NOT CERTIFIED` status, commit & container image SHA tracking, category & persona coverage matrix, zero-tolerance financial invariant proofs (0.00 INR), and Cutover Night Go/No-Go decision tree.

