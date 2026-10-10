---
name: fattakse-prompt-executor
description: >-
  Executes weekly modernization tasks from the Fattakse 5-month prompt books
  (Month-1-Task-Prompts.md through Month-5-Task-Prompts.md).
  Use whenever picking up a new modernization task ID (e.g. M1-W2-BE1-01), implementing assigned features,
  or running task verification suites.
---

# Fattakse Task Prompt Executor Skill

This skill guides AI coding agents and software engineers in systematically locating, executing, testing, and signing off on tasks from the **5-Month Prompt Playbook**.

## 1. Task Execution Lifecycle

### Step 1: Identify Task ID and Month
Prompt books are located in:
[`towns_fattakse_in/docs/modernization/plans/prompts/`](file:///home/vishwas/Pictures/fattakseInLocal/towns_fattakse_in/docs/modernization/plans/prompts/):
- `Month-1-Task-Prompts.md` (Weeks 1–4)
- `Month-2-Task-Prompts.md` (Weeks 5–8)
- `Month-3-Task-Prompts.md` (Weeks 9–12)
- `Month-4-Task-Prompts.md` (Weeks 13–16)
- `Month-5-Task-Prompts.md` (Weeks 17–20)

### Step 2: Extract Task Context & Boundaries
Locate the task block by header (e.g., `### Task M1-W2-BE1-01`).
Carefully read:
- **Role:** (`ARCH`, `BE-1`, `BE-2`, `BE-3`, `FE-1`, `FE-2`, `DATA`, `QA`).
- **Target Files / Directory:** The exact path in the monorepo where changes belong.
- **Reference Monolith:** The corresponding legacy Laravel files providing the business rules.
- **Invariants:** Relevant constraints (Flutter error format, tobacco firewall, Redpanda event streaming, etc.).

### Step 3: Implement Code Cleanly
1. Respect the single-writer database ownership rule.
2. Store monetary values as atomic integer paise (`BIGINT`).
3. For event publishing, always write to `outbox_events` within the transaction.
4. For event consumers, check and insert `processed_events` for idempotency.
5. In web apps, follow React 19 + TypeScript + TailwindCSS conventions.

### Step 4: Run Automated Verification
Execute the commands specified in the **Verification & Definition of Done** section of the prompt.
Ensure all linters, type checks, and tests pass with 0 errors.

Consult [`references/task_execution_checklist.md`](./references/task_execution_checklist.md) for the mandatory pre-commit checklist.
