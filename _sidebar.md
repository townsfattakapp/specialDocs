* [🏠 Overview](README.md)
* [🏛️ Target Architecture](Target-System-Architecture.md)
* [🔍 Current Architecture Audit](Current-System-Architecture.md)

* **Data & Business Workflows**
  * [🗄️ Database Ownership Matrix](Database-Dependency-and-Ownership-Matrix.md)
  * [💼 Business Workflow Specs](Business-Workflow-Documentation.md)

* **Mobile & Portals Parity**
  * [📱 Flutter Compatibility Plan](Flutter-Backward-Compatibility-Plan.md)
  * [📋 API Contract Inventory (/api/v1)](API-Contract-Inventory.md)
  * [🖥️ Admin & Vendor Frontend Parity](Admin-Vendor-Frontend-Parity-Matrix.md)

* **Governance & Certification**
  * [📅 Five-Month Delivery Roadmap](Five-Month-Execution-Roadmap.md)
  * [🚀 Production Readiness & Rollback](Production-Readiness-and-Rollback-Checklist.md)
  * [⚖️ Risk Register & ADR Decision Log](Risk-Register-and-Decision-Log.md)
  * [🏆 Launch-Gate Certification Standard](Modernization-Certification-Framework.md)

* **Detailed Monthly Task Plans**
  * [📋 Plans Overview & Pod Roles](plans/README.md)
  * [Month 1: Discovery & Scaffolding](plans/Month-1-Tasks-Discovery-and-Scaffolding.md)
  * [Month 2: Core Foundations & Catalog](plans/Month-2-Tasks-Foundations-and-Catalog.md)
  * [Month 3: Transactions & Fulfillment](plans/Month-3-Tasks-Transactions-and-Fulfillment.md)
  * [Month 4: Integration & Rehearsals](plans/Month-4-Tasks-Integration-and-Rehearsals.md)
  * [Month 5: Cutover & Stabilization](plans/Month-5-Tasks-Cutover-and-Stabilization.md)

* **Execution Prompts Playbook**
  * [⚡ Prompts Guide](plans/prompts/README.md)
  * [Month 1 Task Prompts (W1–W4)](plans/prompts/Month-1-Task-Prompts.md)
  * [Month 2 Task Prompts (W5–W8)](plans/prompts/Month-2-Task-Prompts.md)
  * [Month 3 Task Prompts (W9–W12)](plans/prompts/Month-3-Task-Prompts.md)
  * [Month 4 Task Prompts (W13–W16)](plans/prompts/Month-4-Task-Prompts.md)
  * [Month 5 Task Prompts (W17–W20)](plans/prompts/Month-5-Task-Prompts.md)

* **Upcoming Team AI Skills**
  * [🤖 AI Skills & Guardrails](ai-skills/README.md)
  * **Always-on Rules**
    * [01. Architectural Invariants](ai-skills/rules/01-architectural-invariants.md)
    * [02. Flutter Compatibility](ai-skills/rules/02-flutter-compatibility.md)
    * [03. Dual-Channel Storefront](ai-skills/rules/03-dual-channel-storefront.md)
    * [04. Kafka & Messaging](ai-skills/rules/04-kafka-and-messaging.md)
  * **On-demand Agent Skills**
    * [Governance Skill](ai-skills/skills/fattakse-governance/SKILL.md)
      * [Architecture Invariants Reference](ai-skills/skills/fattakse-governance/references/architectural_invariants.md)
    * [Contract Verifier Skill](ai-skills/skills/fattakse-contract-verifier/SKILL.md)
      * [Flutter Response Envelopes](ai-skills/skills/fattakse-contract-verifier/references/flutter_response_envelopes.md)
      * [Verification Script ↗](https://github.com/townsfattakapp/specialDocs/blob/main/ai-skills/skills/fattakse-contract-verifier/scripts/verify-contract.sh)
    * [Kafka Streaming Skill](ai-skills/skills/fattakse-kafka-streaming/SKILL.md)
      * [Topic Event Schemas](ai-skills/skills/fattakse-kafka-streaming/references/topic_event_schemas.md)
      * [Kafka Health Script ↗](https://github.com/townsfattakapp/specialDocs/blob/main/ai-skills/skills/fattakse-kafka-streaming/scripts/check-kafka-health.sh)
    * [ETL Pipeline Skill](ai-skills/skills/fattakse-etl-pipeline/SKILL.md)
      * [ETL Invariant Checks](ai-skills/skills/fattakse-etl-pipeline/references/invariant_checks.md)
      * [ETL Invariants Script ↗](https://github.com/townsfattakapp/specialDocs/blob/main/ai-skills/skills/fattakse-etl-pipeline/scripts/run-etl-invariants.sh)
    * [Prompt Executor Skill](ai-skills/skills/fattakse-prompt-executor/SKILL.md)
      * [Task Execution Checklist](ai-skills/skills/fattakse-prompt-executor/references/task_execution_checklist.md)
