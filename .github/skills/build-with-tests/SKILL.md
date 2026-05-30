---
name: build-with-tests
description: Four-step workflow for building production features with integrated testing. Guides through reading standards, finding patterns, implementing with tests, and running quality gates.
applyTo:
  - "src/**/*.ts"
  - "src/**/*.tsx"
  - "infra/**/*.bicep"
when: |
  User asks to: implement feature, build endpoint, create component, 
  add functionality, extend API, build new route, create service,
  add Bicep resource, implement user story
---

# Build Production Features with Tests

Four-step workflow for production-ready features following project standards.

## Workflow

```
1. Read Standards → 2. Find Patterns → 3. Implement + Test → 4. Quality Gates
```

---

## Step 1: Read Standards Before Writing Code

**Always start here.**

<!-- ### Read Global Instructions
1. Open [AGENTS.md](../../../../AGENTS.md) and read in full
2. Note the "Non-Negotiable Rules"
3. Identify which [/docs/](../../../../docs/) files apply -->

### Read Domain-Specific Standards

| Building... | Read These |
|-------------|------------|
| **API endpoint** | [architecture.md](../../../../docs/architecture.md) → [api-standards.md](../../../../docs/api-standards.md) → [testing-standards.md](../../../../docs/testing-standards.md) |
| **React component** | [architecture.md](../../../../docs/architecture.md) → [web-standards.md](../../../../docs/web-standards.md) → [ui-components.md](../../../../docs/ui-components.md) |
| **Authentication** | [auth-standards.md](../../../../docs/auth-standards.md) → [api-standards.md](../../../../docs/api-standards.md) |
| **Bicep resource** | [infrastructure.md](../../../../docs/infrastructure.md) → [architecture.md](../../../../docs/architecture.md) |
| **Cosmos model** | [api-standards.md](../../../../docs/api-standards.md) → [architecture.md](../../../../docs/architecture.md) |

**Why this matters:** Standards contain file naming, TypeScript rules, error handling, and test patterns. Reading first prevents rework.

---

## Step 2: Find and Match Existing Patterns

**Never write from scratch. Find 2-3 similar examples first.**

### For API Endpoints
```
1. Look in: src/api/src/routes/
2. Open 2-3 similar route files (lists.ts, items.ts)
3. Match the pattern:
   - Request typing with generics
   - Async handler with try/catch
   - Cosmos DB factory function usage
   - Error handling (404 vs 500)
   - Response structure
```

### For React Components
```
1. Look in: src/web/src/components/
2. Open 2-3 similar components
3. Match the pattern:
   - FC<Props> with typed interface
   - Fluent UI components (no raw HTML)
   - State via TodoContext + reducers
   - Action creators for API calls
```

### For Infrastructure
```
1. Look in: infra/ and infra/app/
2. Check main.bicep for AVM patterns
3. Match the pattern:
   - Parameter conventions
   - Resource naming (abbreviations.json)
   - Managed identity assignments
   - Required tags
```

**Why this matters:** Consistency. Your codebase has established patterns — match them instead of inventing new approaches.

---

## Step 3: Implement Production Code + Tests Together

**Write tests alongside code. Not strict TDD, but integrated development.**

### Implementation Flow

```
A. Scaffold production file
B. Write first function/route
C. Add test for that function (happy path)
D. Continue with next function
E. Add edge case tests
F. Complete with full coverage
```
**Note:** Web tests not yet implemented. Focus on TypeScript strict types and lint compliance.

**Why this matters:** Writing tests alongside code catches issues early and ensures completeness.

---

## Step 4: Run Quality Gates

Run `npm run build && npm run lint && npm test` (API) or `npm run build && npm run lint` (web) — then do a quick `npm run dev` smoke test for UI changes.

<!-- ### API Changes
```bash
cd src/api
npm run build   # TypeScript compilation
npm run lint    # Zero warnings required
npm test        # Must pass with coverage
```

### Web Changes
```bash
cd src/web
npm run build   # TypeScript compilation
npm run lint    # Zero warnings required
npm run dev     # Visual smoke test in browser
```

### Infrastructure Changes
```bash
az bicep build -f infra/main.bicep  # Validation
azd provision --preview             # Dry run
```

**Never suppress lint warnings. Fix all errors properly.**

---

## Key Principles

### Critical Rules (Never Skip)
1. Read [AGENTS.md](../../../../AGENTS.md) + relevant [/docs/](../../../../docs/) before coding
2. Match patterns from 2-3 existing files in the codebase
3. Write tests alongside code (not after)
4. Run build + lint + test before finishing

### Common Mistakes to Avoid
- Copying code from internet instead of matching codebase patterns
- Writing all code first, then adding tests as afterthought
- Suppressing lint errors to "make it pass"
- Skipping the standards docs because "I know TypeScript"

**Why this matters:** Consistency and quality are enforced by following these principles, not bypassed.

---

## Example Walkthrough

**User:** "Add a user preferences endpoint with GET and PUT"

**Workflow:**
1. **Read:** [architecture.md](../../../../docs/architecture.md), [api-standards.md](../../../../docs/api-standards.md), [testing-standards.md](../../../../docs/testing-standards.md)
2. **Find:** Open `lists.ts` and `items.ts` — study the route handler pattern
3. **Implement:**
   - Create `src/api/src/routes/preferences.ts` (routes)
   - Create `src/api/src/models/userPreferences.ts` (interface + factory)
   - Update `src/api/src/models/cosmos.ts` (container accessor)
   - Add tests to `routes.spec.ts` (GET + PUT + 404 cases)
4. **Quality Gates:**
   - `npm run build && npm run lint && npm test`
   - Fix any errors, never suppress

---

## Scope Boundaries

### This Workflow Covers
- Feature implementation
- Test writing
- Quality validation (build, lint, test)

### This Workflow Stops At
- Git commits/branching (different skill)
- PR creation (different skill)
- Deployment orchestration (handled by azd)

**When to abbreviate:** Trivial fixes (still run lint). Never skip for new features, business logic, or infrastructure.

---

## Related Documentation

- [AGENTS.md](../../../../AGENTS.md) — Global agent instructions
- [docs/api-standards.md](../../../../docs/api-standards.md) — API patterns, error handling, TypeScript rules
- [docs/web-standards.md](../../../../docs/web-standards.md) — React patterns, state management
- [docs/testing-standards.md](../../../../docs/testing-standards.md) — Test structure, coverage requirements
- [docs/infrastructure.md](../../../../docs/infrastructure.md) — Bicep conventions, managed identity
- [docs/ui-components.md](../../../../docs/ui-components.md) — Fluent UI usage rules -->

**All detailed conventions live in /docs/ — this skill orchestrates the workflow only.**
