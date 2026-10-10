# Fattakse — Risk Register & Decision Log (Parallel Greenfield Microservices)

**Document Version:** 2.0.0  
**Status:** Active Governance Document  
**Author:** Principal Software Architect & DevOps Lead  

---

## 1. Architectural Risk Register

| ID | Risk Description | Severity | Probability | Impact | Mitigation Strategy | Contingency / Fallback |
|---|---|---|---|---|---|---|
| **R-01** | **Live Data Divergence During 5-Month Build** (Production data continues changing continuously) | **CRITICAL** | High | High | 3-Stage ETL Migration Pipeline. Rehearsal 1 (Month 3) and Rehearsal 2 (Month 4) execute delta backfills and verify invariant checksums. | Pre-sync historical data prior to cutover; 15-minute maintenance window delta ETL. |
| **R-02** | **Flutter API Contract Drift** (Mobile app crashes or fails JSON parsing after cutover) | **CRITICAL** | Medium | High | API Gateway compatibility facade; custom exception filter emitting `{ errors: [{ code, message }] }`; automated JSON schema diffing. | Immediate 60-second Nginx route reversal back to Laravel monolith. |
| **R-03** | **Active Mobile Session Invalidation** (Mobile customers, vendors, and riders logged out en masse) | **CRITICAL** | Medium | High | `iam-service` loads Laravel Passport RSA keypair and emulates Passport JWT claims, validating existing active bearer tokens seamlessly. | Retain Laravel auth endpoint active or reissue tokens transparently via refresh tokens. |
| **R-04** | **Microservices Network Latency Overhead** (Inter-service HTTP hops adding latency to checkout) | **HIGH** | Medium | Medium | In-cluster Fastify HTTP/gRPC; asynchronous BullMQ event bus; Redis caching of store profiles and delivery zones. | Optimize connection pooling and colocate containers on the same Docker bridge network. |
| **R-05** | **Staffing Deficit or Scope Creep** (Team unable to finish 8 microservices in 5 months) | **HIGH** | Medium | High | Strict scope enforcement: Hyper POS permanently excluded; Parcel and Rental verticals frozen; dedicated 8 FTE engineering pod. | Fallback to 4 macro-services (`iam-store`, `catalog-search`, `order-inventory-fleet`, `finance`) if headcount drops below 6. |
| **R-06** | **Concurrent Inventory Overselling** (Multiple customers checkout last item simultaneously) | **HIGH** | Medium | High | Enforce atomic stock decrement inside MySQL ACID transaction in `inventory-service` with pessimistic row-locking (`SELECT ... FOR UPDATE`). | Immediate customer notification of stock depletion and automated refund trigger. |
| **R-07** | **Cutover Maintenance Window Overrun** (Delta ETL migration takes longer than 15 minutes) | **HIGH** | Medium | Medium | Incremental chunking and indexing on `updated_at`; dress rehearsals in Months 3 & 4 validate exact runtime. | Extend maintenance window by 10 minutes or abort cutover with zero data loss. |

---

## 2. Key Architectural Decision Records (ADRs)

### ADR-0004: Target Backend Framework Selection
- **Status:** APPROVED
- **Context:** Transition from PHP 8.2 Laravel monolith to modern TypeScript backend.
- **Decision:** Adopt **Node.js 22 LTS with TypeScript 5.6+, NestJS 11+, and Fastify HTTP engine**.
- **Rationale:** NestJS provides enterprise dependency injection and clean architecture. Fastify delivers 2.5x throughput over Express. TypeScript provides end-to-end type safety.

### ADR-0005: Architecture Strategy — Parallel Greenfield Microservices over Incremental Strangler Fig
- **Status:** APPROVED
- **Context:** Production is active and must not be disrupted by developmental changes.
- **Decision:** Build a **greenfield microservices platform in parallel** in isolated environments, maintaining the Laravel monolith as the reference implementation until a complete replacement cutover in Month 5.
- **Rationale:** Avoids brittle dual-write proxies, network hops, and production risk during development. Allows clean domain boundaries and dedicated databases without compromising live business operations.

### ADR-0006: Permanent Retirement of Hyper POS
- **Status:** APPROVED
- **Context:** Business model is 100% online quick-commerce (Tirora dark store) and restaurant food delivery; walk-in counter retail is permanently excluded.
- **Decision:** Decommission `Hyper-POS-Fattakse`, purge all 7 POS database tables, eliminate POS outbox relay endpoints and HMAC bridge jobs.
- **Rationale:** Eliminates thousands of lines of fragile synchronization code and allows the team to focus entirely on digital quick-commerce.

### ADR-0007: Three-Stage ETL Data Migration Pipeline
- **Status:** APPROVED
- **Context:** Live production data changes continuously throughout the 5-month development timeline.
- **Decision:** Implement a 3-Stage ETL pipeline: Stage 1 (Base Mapping), Stage 2 (Dress Rehearsals on fresh production copies in Months 3 & 4), and Stage 3 (Delta sync during a 15-minute maintenance window in Month 5).
- **Rationale:** Guarantees zero data loss, verifies financial invariants to the exact paisa, and ensures a predictable cutover.

### ADR-0008: Five-Month Delivery Window & 8 FTE Pod Allocation
- **Status:** APPROVED
- **Context:** Complete system replacement targeted within 5 months.
- **Decision:** Allocate a dedicated 8 FTE engineering pod (1 Lead Architect, 3 Backend, 2 Frontend, 1 Data/ETL, 1 QA/SDET) with explicit monthly Go/No-Go acceptance gates.
- **Rationale:** Sizing analysis confirms ~36 Person-Months of effort; 8 FTEs provide the necessary capacity to achieve production-grade quality.

### ADR-0009: Dual-Channel Consumer Strategy — Flutter Apps (Tobacco-Free) + Full-Catalog React User Web Storefront (Unrestricted)
- **Status:** APPROVED (Revised)
- **Context:**
  1. Google Play Store (Developer Policy > Restricted Content > Tobacco) and Apple App Store (Guideline 1.4.3) strictly ban mobile apps from facilitating tobacco, cigarette, and smoking product sales. Listing tobacco inside the Flutter Customer App would trigger immediate app store delisting and account termination.
  2. Local demand in Tirora exists for on-demand delivery from Paan Corners (cigarettes, beedis, gutkha/tobacco, lighters, rolling papers).
  3. However, a web app that **only** sells tobacco is too narrow — customers won't engage with it. If the same web app also sells groceries, dark store items, and restaurant food **alongside** paan corner products, it becomes a compelling one-stop shop that drives significantly higher Average Order Value (AOV) and repeat visits.
- **Decision:**
  1. **Flutter Mobile Apps remain the primary consumer channel** for groceries, dark store essentials, supermarkets, and restaurant food delivery. Flutter apps are **100% tobacco-free** for complete Google Play and Apple App Store compliance.
  2. **Build a full-catalog React 19 User Web Storefront (`user-web` at `fattakse.in`)** that sells **everything**: groceries, dark store items, food, AND paan corner/tobacco products. Because it runs in a mobile browser, it is completely unrestricted by App Store policies.
  3. **Tobacco category pages on the web storefront** enforce strict COTPA Act 2003 compliance: 18+ age verification interstitial with Date of Birth declaration, statutory health warnings on product cards (*"Smoking Causes Cancer"*, *"Tobacco Kills"*), and geofencing exclusion within 100 yards of educational institutions.
  4. **Mandatory doorstep 18+ physical photo ID verification** by FattakSe riders before the delivery OTP entry screen unlocks for any order containing tobacco items.
  5. **API Gateway enforces a regulated category firewall:** Flutter mobile app requests (`is_app_store_client: true`) never receive tobacco categories, paan corner stores, or smoking product SKUs. Web storefront requests receive the full unrestricted catalog.
- **Rationale:** Shields native mobile apps from App Store bans. Maximizes customer engagement and AOV by making the web storefront a full one-stop shop rather than a narrow tobacco-only site. Captures high-margin local paan corner demand legally while strictly complying with COTPA 2003 and App Store policies.

### ADR-0010: Hybrid Asynchronous Architecture — Kafka/Redpanda Event Streaming + Redis BullMQ Delayed Queues
- **Status:** APPROVED
- **Context:**
  1. Hyperlocal quick-commerce requires high-throughput, multi-consumer event choreography: a single `order.created` or `order.delivered` event must trigger notifications, fleet dispatch, dark-store bin deductions, double-entry financial ledger postings, and statutory tax withholding across separate microservices.
  2. Riders generate high-frequency GPS telemetry (sub-second pings) that would cause lock contention and disk IOPS saturation if written directly to MySQL.
  3. Financial ledgers and audit regulations require deterministic event replayability to guarantee 0.00 INR balance variance.
  4. At the same time, domain workflows need precise delayed timers (e.g., 3-minute kitchen SLA timeout, 10-minute customer OTP expiry), which Kafka cannot natively schedule.
- **Decision:**
  1. Adopt **Redpanda / Apache Kafka (Kafka API v3.x)** as the event streaming backbone for all domain events (`fattakse.orders.lifecycle`, `fattakse.riders.telemetry`, `fattakse.inventory.adjustments`, `fattakse.finance.transactions`).
  2. Adopt **Redis 7.2 with BullMQ** for scheduled/delayed job execution (SLA timeout counters, OTP expiration, external webhook retry loops).
  3. Deploy **Redpanda** in local dev and staging/production Docker Compose clusters: C++ engine provides 100% Kafka API compatibility, sub-millisecond p99 latencies, zero JVM, zero ZooKeeper, and consumes < 500MB RAM on VPS infrastructure.
  4. Standardize NestJS microservice communication via `@nestjs/microservices` (`ClientKafka`) and transactional outbox tables in MySQL.
- **Rationale:** Decouples microservice dependencies via independent consumer groups, enables instant replayability for financial auditing, absorbs rider GPS telemetry streams effortlessly, and keeps VPS RAM overhead minimal.

