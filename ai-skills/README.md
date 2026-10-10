# Fattakse Modernization: Upcoming Team AI Skills & Rules Suite

**Target Audience:** Upcoming Greenfield Modernization Engineering Team & AI Agents (Starting Month 1 / Next Month)  
**Location:** `towns_fattakse_in/docs/modernization/ai-skills/`  
**Purpose:** Pre-packaged rules, guardrails, and automated AI skills designed to ensure that the modernization team adheres strictly to all non-negotiable architectural invariants and workflows from Day 1.

> [!NOTE]
> This folder is archived and documented here so it does not interfere with the active development/staging cycle of the current team. When the new modernization team begins next month, they will activate this suite in their new greenfield monorepo workspace.

---

## 🚀 How the Upcoming Team Activates This Suite (Next Month)

When the upcoming engineering pod sets up their greenfield monorepo repository (`fattakse-monorepo`):

1. **Copy the Suite to the Workspace Root:**
   ```bash
   # In the root of the new greenfield repository:
   mkdir -p .agents
   cp -r /path/to/towns_fattakse_in/docs/modernization/ai-skills/* .agents/
   ```

2. **Add Customization Reference to `AGENTS.md`:**
   Add the following snippet to the new repository's `AGENTS.md`:
   ```markdown
   ## Modernization Architecture & Execution Guardrails
   All agents working on the Fattakse Modernization project must adhere to the rules and skills defined in `.agents/`:
   - Rules: `.agents/rules/`
   - Skills: `.agents/skills/`
   ```

3. **Automatic Discovery:**
   Antigravity, Claude Code, Cursor, Copilot, and human engineers will automatically discover and enforce all rules and skills.

---

## 📁 Directory Structure & Components

```
ai-skills/
├── README.md                              # This onboarding guide
├── rules/                                 # ALWAYS-ON WORKSPACE RULES
│   ├── 01-architectural-invariants.md    # Read-only prod VPS 145.223.19.105, single-writer DBs, zero POS
│   ├── 02-flutter-compatibility.md       # Frozen mobile response shapes, Passport RSA JWT emulation
│   ├── 03-dual-channel-storefront.md     # 100% tobacco-free Flutter mobile, full-catalog React web with 18+ gate
│   └── 04-kafka-and-messaging.md         # Redpanda/Kafka event streaming topics, outbox pattern, BullMQ
└── skills/                                # ON-DEMAND SPECIALIZED AGENT SKILLS
    ├── fattakse-governance/               # Master architecture guardrails & PR review checklist
    │   ├── SKILL.md
    │   └── references/architectural_invariants.md
    ├── fattakse-contract-verifier/        # Legacy /api/v1/* and Flutter compatibility verifier
    │   ├── SKILL.md
    │   ├── references/flutter_response_envelopes.md
    │   └── scripts/verify-contract.sh
    ├── fattakse-kafka-streaming/          # Redpanda/Kafka event streaming, outbox & consumer idempotency
    │   ├── SKILL.md
    │   ├── references/topic_event_schemas.md
    │   └── scripts/check-kafka-health.sh
    ├── fattakse-etl-pipeline/             # Three-stage ETL data migration & invariant proofs
    │   ├── SKILL.md
    │   ├── references/invariant_checks.md
    │   └── scripts/run-etl-invariants.sh
    └── fattakse-prompt-executor/          # 5-Month task prompt books (Weeks 1-20) execution guide
        ├── SKILL.md
        └── references/task_execution_checklist.md
```

---

## 🛡️ Summary of Rules & Guardrails

1. **01. Architectural Invariants (`rules/01-architectural-invariants.md`):**
   - Live VPS `145.223.19.105` is strictly READ-ONLY.
   - Reference Monolith (`towns_fattakse_in`) is the ground truth executable specification.
   - 8 isolated microservice databases (`fattakse_iam`, `fattakse_catalog`, etc.) with single-writer ownership; zero cross-service SQL joins.
   - Hyper POS / offline retail is permanently retired (ADR-0004); dark store fulfillment uses native digital Pick & Pack in `vendor-react`.

2. **02. Flutter Compatibility (`rules/02-flutter-compatibility.md`):**
   - Flutter mobile apps (Customer `1.0.18`, Vendor `1.0.5`, Rider `1.0.1`) are compiled binaries and cannot be updated in app stores.
   - Gateway must emulate legacy Laravel error shapes (`{ "errors": [{ "code", "message" }] }`), pagination shapes (`total_size`, stringified `limit`/`offset`), and Passport RSA JWT claims.

3. **03. Dual-Channel Storefront (`rules/03-dual-channel-storefront.md`):**
   - Flutter mobile apps must be **100% tobacco-free** for App Store & Google Play compliance.
   - React User Web App (`user-web` at `fattakse.in`) is a **full-catalog storefront** selling groceries, dark-store FMCG, restaurant food, and COTPA 2003 18+ age-gated Paan Corner tobacco products to maximize basket size and AOV.

4. **04. Kafka & Messaging (`rules/04-kafka-and-messaging.md`):**
   - Redpanda / Kafka (`kafkajs`) for replayable event streaming across 4 core topics (`fattakse.orders.lifecycle`, `fattakse.riders.telemetry`, `fattakse.inventory.adjustments`, `fattakse.finance.transactions`).
   - Transactional Outbox pattern (`outbox_events`) on all event publishing.
   - Consumer idempotency check (`processed_events`) using UUIDv7 event IDs.
   - Redis BullMQ strictly for delayed countdown timers.

---

## 🧰 Summary of Specialized Skills

| Skill Name | Purpose & Trigger | Key Assets |
|---|---|---|
| **`fattakse-governance`** | Architecture integrity, single-writer DB matrix, and PR review checklist. | [`architectural_invariants.md`](skills/fattakse-governance/references/architectural_invariants.md) |
| **`fattakse-contract-verifier`** | Verifying Gateway endpoints against frozen Flutter Dart models and legacy `/api/v1/*`. | [`flutter_response_envelopes.md`](skills/fattakse-contract-verifier/references/flutter_response_envelopes.md), [`verify-contract.sh`](skills/fattakse-contract-verifier/scripts/verify-contract.sh) |
| **`fattakse-kafka-streaming`** | Publishing/consuming domain events with outbox and idempotency. | [`topic_event_schemas.md`](skills/fattakse-kafka-streaming/references/topic_event_schemas.md), [`check-kafka-health.sh`](skills/fattakse-kafka-streaming/scripts/check-kafka-health.sh) |
| **`fattakse-etl-pipeline`** | 3-Stage ETL execution, checksum verification, and 60-second reverse-delta rollback. | [`invariant_checks.md`](skills/fattakse-etl-pipeline/references/invariant_checks.md), [`run-etl-invariants.sh`](skills/fattakse-etl-pipeline/scripts/run-etl-invariants.sh) |
| **`fattakse-prompt-executor`** | Step-by-step guidance for picking up and testing prompts from `Month-1` to `Month-5`. | [`task_execution_checklist.md`](skills/fattakse-prompt-executor/references/task_execution_checklist.md) |
