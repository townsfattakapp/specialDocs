# Task Execution & Sign-Off Checklist Reference

Every developer or AI agent completing an assigned task must verify every item before committing or closing the task.

## 1. Safety & Environment
- [ ] No changes or writes attempted on live production VPS `145.223.19.105`.
- [ ] No secrets or un-sanitized PII introduced to local git tracking.
- [ ] Working in the proper target branch / directory.

## 2. Code Quality & Standards
- [ ] TypeScript compilation (`tsc --noEmit`) passes with zero errors.
- [ ] ESLint / Prettier rules pass without warnings.
- [ ] All database queries restricted to the service's designated logical database.
- [ ] Domain events use explicit Zod schemas and transactional outbox.

## 3. Client & Domain Compatibility
- [ ] If changing an API route, verify that the frozen Flutter response envelope `{ errors: [...] }` and pagination shape are strictly maintained.
- [ ] Tobacco/Paan Corner items are completely masked from mobile responses.
- [ ] COTPA 18+ verification is enforced for web consumer storefront (`user-web`).

## 4. Test Suite Pass
- [ ] Unit tests for new domain services pass (`pnpm test`).
- [ ] Automated verification script from prompt file executed and passed.
