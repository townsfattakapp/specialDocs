# Fattakse Modernization: Five-Month Detailed Task Execution Plan

**Company:** Evolw Technologies Private Limited (Tirora, Maharashtra — State Code: 27)  
**Strategy:** Parallel Greenfield Microservices Development & Production Replacement  
**Execution Window:** November 2026 – March 2027 (5 Months / 20 Weeks)  
**Pod Size:** 8 Dedicated Full-Time Engineers (FTEs)  

---

## 1. Engineering Pod Structure & Roles

All tasks across the 20 weeks are assigned to specific roles in the 8 FTE engineering pod:

```
+----------------------------------------------------------------------------------------------------+
|                                 8 FTE ENGINEERING POD ALLOCATION                                   |
+----------------------------------------------------------------------------------------------------+
|  1. ARCH  | Principal Architect & Project Lead       | Architecture governance, gates, cutover lead|
|  2. BE-1  | Senior Backend Engineer 1 (Auth & Edge)  | iam-service, store-service, API Gateway     |
|  3. BE-2  | Senior Backend Engineer 2 (Catalog/Search)| catalog-service, Typesense sync, pricing   |
|  4. BE-3  | Senior Backend Engineer 3 (Commerce/Core)| order-service, inventory-service, fleet     |
|  5. FE-1  | Senior Frontend Engineer 1 (Operations) | admin-react Control Plane (Vite/Tailwind)   |
|  6. FE-2  | Senior Frontend Engineer 2 (Merchant & Web)| vendor-react Dark Store / KDS & user-web Full Storefront|
|  7. DATA  | Database Architect & ETL Data Engineer   | MySQL domain schemas, 3-stage ETL pipeline  |
|  8. QA    | SDET / QA Automation Engineer            | OpenAPI diffing, Flutter E2E, k6 load tests |
+----------------------------------------------------------------------------------------------------+
```

---

## 2. Sprint Cadence & Governance Rules

1. **Sprint Cadence:** 1-week sprints (Monday morning planning, Friday afternoon demo & acceptance).
2. **Environment Rule:** Production on Hostinger VPS (`145.223.19.105`) is strictly READ-ONLY. No developer connects directly to production MySQL.
3. **Reference Implementation Rule:** When in doubt about business rules, the live Laravel monolith behavior is the executable specification.
4. **Dual-Channel Consumer Strategy & Web Mandate:** 
   - **Primary Mobile Focus (Flutter Apps):** Flutter Customer (`1.0.18`), Vendor (`1.0.5`), and Rider (`1.0.1`) apps remain the primary native channels. The Customer mobile app is kept **100% tobacco-free** to guarantee absolute compliance with Google Play Store and Apple App Store Developer Policies (zero risk of app suspension).
   - **Modernized Full-Catalog React User Web Storefront (`user-web`):** The React consumer web storefront is maintained, modernized, and kept fully operational at `fattakse.in` as a responsive mobile-first PWA. Rather than restricting web to tobacco only (which limits engagement and basket size), the web storefront sells **everything**: groceries, dark store essentials, restaurant food, snacks, **and** Paan Corner / smoking products. Customers can purchase full baskets in a single session, significantly driving up Average Order Value (AOV) while running in mobile browsers exempt from app store policies.
   - **Regulatory & Age Compliance:** Tobacco categories on `user-web` require a mandatory 18+ Age Interstitial splash modal (DOB declaration) and COTPA 2003 statutory warnings before rendering. Delivery riders perform mandatory physical 18+ photo ID checks before handing over orders containing regulated items.
5. **Event Streaming & Asynchronous Messaging Mandate:**
   - **Kafka / Redpanda Backbone:** Cross-service domain events (`fattakse.orders.lifecycle`, `fattakse.riders.telemetry`, `fattakse.inventory.adjustments`, `fattakse.finance.transactions`) must be streamed through Kafka topics with isolated consumer groups and transactional outboxes. Synchronous HTTP hops across microservices are strictly prohibited for non-blocking workflows.
   - **Redis BullMQ Scope:** Confined strictly to delayed jobs and timers (3-minute restaurant SLA timers, 10-minute phone OTP expiration, webhook retry loops).
6. **Definition of Done (DoD) per Task:**
   - 100% TypeScript type safety (zero `any`).
   - Unit & integration tests written with > 85% branch coverage.
   - Database migrations declarative and reversible via Prisma/Kysely.
   - Flutter contract compatibility verified (no breaking field changes).
   - Code peer-reviewed by at least one other engineer + signed off by ARCH.
7. **Mandatory Modernization Toolchain, Runtime & Observability Platform:**
   - **Core Runtime & Data:** Node.js 22 LTS, React 19, **MySQL 8.4 LTS** (single-writer schemas), **Docker** (containerization), **Nginx** (ingress, TLS 1.3, rate-limiting, 60s cutover switch), **Redis 7.2 / BullMQ** (delayed timers, caching), **Typesense 28.0** (search engine), **Redpanda / Kafka** (event log).
   - **Code & Project Management:** **GitHub + GitHub Actions** (CI/CD workflows), **GitHub Projects** (8 FTE sprint Kanban boards).
   - **Quality & Security Gates:** **SonarQube Community Build** (Quality Gate > 80%), **Gitleaks** (secrets scan), **Trivy** (Docker image & dependency CVE scan), **OWASP ZAP** (DAST penetration testing).
   - **Testing Frameworks:** **Testcontainers** (disposable MySQL/Redis/Kafka containers in Vitest), **Playwright** (browser E2E for Admin/Vendor/User-Web), **Bruno** (git-friendly `/api/v1/*` API regression suites), **k6** (1,500 req/s load & concurrency testing).
   - **Observability & Reliability:** **Prometheus + Grafana** (metrics & alerting), **Grafana Loki** (log aggregation), **OpenTelemetry** (distributed tracing with correlation IDs), **Sentry** (exception and crash monitoring), **Uptime Kuma** (synthetic monitoring & public status at `status.fattakse.in`).
   - **Disaster Recovery, Hygiene & Docs:** **Restic + Off-site Storage** (encrypted snapshots to Wasabi / S3 Glacier), **Renovate** (automated dependency update PRs), **OpenAPI 3.1** (contracts), **MkDocs Material** (documentation site).

---

## 3. Master Plan Index

| Month | Theme & Objectives | Plan Document |
|---|---|---|
| **Month 1 (Weeks 1–4)** | Discovery, Architecture, Contract Freezing, Scaffolding, Dev Environments | [`Month-1-Tasks-Discovery-and-Scaffolding.md`](Month-1-Tasks-Discovery-and-Scaffolding.md) |
| **Month 2 (Weeks 5–8)** | Core Foundations, IAM, Store Zones, Catalog, Typesense Sync, Cart & Pricing | [`Month-2-Tasks-Foundations-and-Catalog.md`](Month-2-Tasks-Foundations-and-Catalog.md) |
| **Month 3 (Weeks 9–12)** | Transactions, Multi-Owner Inventory, Pick/Pack Fulfillment, Fleet, Finance, SPAs | [`Month-3-Tasks-Transactions-and-Fulfillment.md`](Month-3-Tasks-Transactions-and-Fulfillment.md) |
| **Month 4 (Weeks 13–16)** | Integration, E2E Testing, Flutter Contract Diffing, Rehearsals 1 & 2, Hardening | [`Month-4-Tasks-Integration-and-Rehearsals.md`](Month-4-Tasks-Integration-and-Rehearsals.md) |
| **Month 5 (Weeks 17–20)** | Production Provisioning, Dress Rehearsal 3, Cutover Night (02:00 AM IST), Hypercare | [`Month-5-Tasks-Cutover-and-Stabilization.md`](Month-5-Tasks-Cutover-and-Stabilization.md) |

---

## 4. Engineering Team Task Prompts Playbook

For ready-to-execute, copy-pasteable prompts designed for software engineers and autonomous AI coding agents for each task, consult the **[`prompts/`](prompts/README.md)** playbook:

| Month | Prompt Playbook | Description |
|---|---|---|
| **Month 1** | [`prompts/Month-1-Task-Prompts.md`](prompts/Month-1-Task-Prompts.md) | Weeks 1–4 Task Execution Prompts (Discovery, Monorepo, Dev Infra, Contracts) |
| **Month 2** | [`prompts/Month-2-Task-Prompts.md`](prompts/Month-2-Task-Prompts.md) | Weeks 5–8 Task Execution Prompts (IAM, Store GIS, Catalog, Typesense, Pricing) |
| **Month 3** | [`prompts/Month-3-Task-Prompts.md`](prompts/Month-3-Task-Prompts.md) | Weeks 9–12 Task Execution Prompts (Orders, Inventory, Fleet, Finance, Web SPAs) |
| **Month 4** | [`prompts/Month-4-Task-Prompts.md`](prompts/Month-4-Task-Prompts.md) | Weeks 13–16 Task Execution Prompts (Contract Diffing, Rehearsals 1 & 2, Load) |
| **Month 5** | [`prompts/Month-5-Task-Prompts.md`](prompts/Month-5-Task-Prompts.md) | Weeks 17–20 Task Execution Prompts (Production Provisioning, Rehearsal 3, Cutover, Hypercare) |
