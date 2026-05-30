---
name: feature-complete-checklist
description: 'Pre-commit verification checklist for production-ready features. Use when asking: Is my feature complete? Ready to commit? Pre-commit checklist? Can I commit this? Feature ready for review? Validates standards compliance, tests, builds, and code quality before committing.'
applyTo:
  - "src/**/*.ts"
  - "src/**/*.tsx"
  - "infra/**/*.bicep"
---

# Feature Completion Checklist

Pre-commit verification to ensure features are production-ready before committing.

## When to Use

Ask this skill when you want to verify a feature is complete:
- "Is my feature complete?"
- "Ready to commit?"
- "Can I commit this?"
- "Pre-commit checklist"
- "Feature ready for review?"

**This skill verifies — it does NOT make changes.** If items fail, it will point you to relevant docs or commands to fix them.

---

## Checklist

I'll walk through each item. Answer honestly — this catches issues before PR review.

### 1. Standards Compliance

**Did you read the relevant standards documents before coding?**

Required reading (depends on what you built):
- [AGENTS.md](../../../../AGENTS.md) — Global instructions (always required)
- [docs/architecture.md](../../../../docs/architecture.md) — For understanding system structure
- [docs/api-standards.md](../../../../docs/api-standards.md) — If you touched API code
- [docs/web-standards.md](../../../../docs/web-standards.md) — If you touched React components
- [docs/testing-standards.md](../../../../docs/testing-standards.md) — If you wrote tests
- [docs/infrastructure.md](../../../../docs/infrastructure.md) — If you modified Bicep
- [docs/auth-standards.md](../../../../docs/auth-standards.md) — If you touched authentication
- [docs/ui-components.md](../../../../docs/ui-components.md) — If you created UI components

❌ **If NO:** Stop and read them now. They contain file naming, TypeScript rules, error handling patterns, and test requirements.

---

### 2. Pattern Matching

**Did you find and match patterns from 2-3 existing files in the codebase?**

Instead of coding from scratch or copying from the internet, you should have:
- Opened 2-3 similar files (e.g., for a new route, opened `lists.ts` and `items.ts`)
- Matched their structure, naming, error handling, and typing patterns
- Followed the same conventions consistently

❌ **If NO:** Find similar examples now:
- **API routes:** Look in `src/api/src/routes/`
- **React components:** Look in `src/web/src/components/`
- **Bicep modules:** Look in `infra/` and `infra/app/`

---

### 3. Production Code Quality

**Is the production code implemented following project patterns?**

Verify these from [AGENTS.md](../../../../AGENTS.md) "Non-Negotiable Rules":
- ✅ All code is TypeScript (no `.js` files)
- ✅ Strict typing (no `any` except in `catch (err: any)` blocks)
- ✅ No hardcoded secrets/connection strings
- ✅ CORS configuration not loosened (if API)
- ✅ Proper error handling (try/catch, 404 vs 500)
- ✅ Followed existing file structure

❌ **If NO:** Fix violations before committing.

---

### 4. Tests Written

**Did you add tests covering happy path + edge cases?**

**For API changes:**
- ✅ Added `describe` block to `src/api/src/routes/routes.spec.ts`
- ✅ At minimum: happy path test + 404 case
- ✅ Created helper functions at bottom of test file
- ✅ Tests clean up data in `afterAll` hook

**For Web changes:**
- ℹ️ Web tests not yet implemented — focus on TypeScript strict types and lint compliance

**For Infrastructure:**
- ℹ️ Bicep validation via `az bicep build` (Step 6)

❌ **If NO (API):** Add tests now. See [docs/testing-standards.md](../../../../docs/testing-standards.md) for patterns.

---

### 5. Build Passes

**Does `npm run build` pass with zero errors?**

Run these commands:

```bash
# For API changes
cd src/api
npm run build

# For Web changes
cd src/web
npm run build
```

Expected: Clean compilation, no TypeScript errors.

❌ **If FAILS:** Fix all TypeScript errors. Never use `@ts-ignore` or `any` to bypass them.

---

### 6. Lint Passes

**Does `npm run lint` pass with zero warnings?**

Run these commands:

```bash
# For API changes
cd src/api
npm run lint

# For Web changes
cd src/web
npm run lint
```

Expected: No warnings, no errors.

❌ **If FAILS:** Fix lint errors properly. **Never suppress warnings** — that's a non-negotiable rule from [AGENTS.md](../../../../AGENTS.md).

---

### 7. Tests Pass

**Does `npm test` pass with expected coverage? (API only)**

```bash
cd src/api
npm test
```

Expected:
- All tests pass
- Every new route handler has a test
- Minimum coverage: happy path + 404 case

❌ **If FAILS:** Fix failing tests. If coverage is low, add edge case tests.

---

### 8. Test Cleanup

**Does your test code clean up properly?**

Check `src/api/src/routes/routes.spec.ts`:
- ✅ Added `afterAll` hook to delete test data?
- ✅ Test data uses unique identifiers (won't conflict with production)?
- ✅ No test data left in database after test run?

❌ **If NO:** Add cleanup code. See [docs/testing-standards.md](../../../../docs/testing-standards.md) for pattern.

---

### 9. No Hardcoded Secrets

**Did you avoid hardcoding secrets or connection strings?**

Check your code for:
- ❌ Database connection strings
- ❌ API keys
- ❌ Passwords or tokens
- ❌ Azure subscription IDs or resource names

All secrets must come from:
- ✅ Environment variables (loaded from `.env` via `azd`)
- ✅ Azure Key Vault references
- ✅ Config files (never committed)

❌ **If FOUND:** Remove immediately. Use environment variables. See [docs/infrastructure.md](../../../../docs/infrastructure.md).

---

### 10. Naming Conventions

**Did you follow the project naming conventions?**

Check these from [docs/api-standards.md](../../../../docs/api-standards.md) and [docs/web-standards.md](../../../../docs/web-standards.md):

| Type | Convention | Example |
|------|-----------|---------|
| **API route file** | Plural resource name | `items.ts`, `users.ts` |
| **Model file** | Singular resource name | `todoItem.ts`, `user.ts` |
| **React component** | PascalCase + descriptive | `TodoItemDetailPane.tsx` |
| **Test file** | Same name + `.spec.ts` | `routes.spec.ts` |
| **Helper functions** | camelCase | `createList()`, `getItem()` |

❌ **If NO:** Rename files/functions to match conventions.

---

### 11. Error Handling

**Does error handling match the standards?**

**For API** (see [docs/api-standards.md](../../../../docs/api-standards.md)):
- ✅ Try/catch in all async route handlers
- ✅ Check `err.code === 404` before returning 500
- ✅ Never expose raw error details to clients
- ✅ Return proper status codes (200, 201, 404, 500)

**For Web** (see [docs/web-standards.md](../../../../docs/web-standards.md)):
- ✅ Handle loading states
- ✅ Handle error states
- ✅ Display user-friendly error messages

❌ **If NO:** Add proper error handling before committing.

---

### 12. TypeScript Strict Types

**Are all TypeScript types explicit?**

Verify:
- ✅ No implicit `any` types
- ✅ `any` used ONLY in `catch (err: any)` blocks
- ✅ Explicit return types on exported functions
- ✅ Props interfaces for React components (`FC<Props>`)
- ✅ Request generics for Express routes

❌ **If NO:** Add explicit types. Enable strict mode checking via `npm run build`.

---

## Visual Smoke Test (Web Only)

**If you changed React components, did you manually test in a browser?**

```bash
cd src/web
npm run dev
# Open browser to http://localhost:5173
# Click through your changes
```

Verify:
- ✅ UI renders correctly
- ✅ Interactions work (buttons, forms, navigation)
- ✅ No console errors
- ✅ Fluent UI components used (no raw HTML)

❌ **If NO:** Test now before committing.

---

## Summary

### ✅ Ready to Commit

If ALL items above passed, your feature is production-ready:
- Standards followed
- Patterns matched
- Code quality verified
- Tests passing
- Build clean
- Lint clean

**Next steps:**
1. Stage your changes: `git add .`
2. Commit with descriptive message: `git commit -m "feat: description"`
3. Push and create PR

---

### ❌ Not Ready Yet

If ANY items failed, **do not commit yet**. Fix the failing items first:

| Failed Item | Fix It |
|-------------|--------|
| Standards not read | Read [AGENTS.md](../../../../AGENTS.md) + relevant [/docs/](../../../../docs/) |
| No pattern matching | Find 2-3 similar files, refactor to match |
| Build fails | Fix TypeScript errors, add types |
| Lint fails | Fix warnings properly, never suppress |
| Tests fail | Fix broken tests, add missing coverage |
| No tests | Add tests following [docs/testing-standards.md](../../../../docs/testing-standards.md) |
| Hardcoded secrets | Move to environment variables |
| Wrong naming | Rename following conventions in docs |
| Bad error handling | Add try/catch, proper status codes |
| Implicit types | Add explicit types everywhere |

---

## Related

- [build-with-tests](../build-with-tests/SKILL.md) — The implementation workflow (write code + tests)
- [AGENTS.md](../../../../AGENTS.md) — Global non-negotiable rules
- [docs/](../../../../docs/) — All detailed standards and conventions

**This skill verifies the work from build-with-tests before you commit it.**
