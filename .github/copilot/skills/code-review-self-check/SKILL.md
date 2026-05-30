---
name: code-review-self-check
description: 'Self-review code for common quality issues before PR. Analyzes modified files for pitfalls: implicit any, missing error handling, raw HTML in React, hardcoded secrets, wrong status codes, improper imports. Use when: review my code, self-review checklist, check my code, pre-PR review, what is wrong with my code, code quality check.'
applyTo:
  - "src/**/*.ts"
  - "src/**/*.tsx"
  - "infra/**/*.bicep"
---

# Code Review Self-Check

Analyze your code changes for common quality issues before creating a PR.

## When to Use

Use this skill before opening a PR:
- "Review my code"
- "Self-review checklist"
- "Check my code quality"
- "Pre-PR review"
- "What's wrong with my code?"
- "Code review checklist"

**This skill analyzes actual code patterns** — it's not a yes/no checklist. It scans modified files for specific anti-patterns and provides line-level feedback.

---

## Review Process

### Step 1: Identify Changed Files

First, I'll identify what you've changed:

```bash
# Get modified files
git diff --name-only main...HEAD
# or
git status --short
```

**Domain detection:** API code (src/api/), React code (src/web/), Infrastructure (infra/)

---

### Step 2: Scan for Domain-Specific Issues

I'll scan each file for common pitfalls specific to that domain.

---

## API Code Pitfalls (TypeScript + Express)

**Scanning:** `src/api/src/routes/*.ts`, `src/api/src/models/*.ts`

### 🔴 Critical Issues (Must Fix)

#### Using `any` Outside Catch Blocks
**Pattern:** `any` type annotation anywhere except `catch (err: any)`

```typescript
// ❌ BAD
function processData(data: any) { ... }
const result: any = await fetchData();

// ✅ GOOD
function processData(data: TodoItem) { ... }
const result: TodoItem = await fetchData();
// Only OK in catch:
catch (err: any) { ... }
```

**Fix:** Add explicit types. See [docs/api-standards.md](../../../../docs/api-standards.md) for typing patterns.

---

#### Missing Try/Catch in Async Route Handlers
**Pattern:** Async route handler without try/catch block

```typescript
// ❌ BAD
router.get("/:id", async (req, res) => {
    const item = await getItem(req.params.id);
    res.json(item);
});

// ✅ GOOD
router.get("/:id", async (req, res): Promise<void> => {
    try {
        const item = await getItem(req.params.id);
        res.json(item);
    } catch (err: any) {
        if (err.code === 404) return res.status(404).send();
        console.error("Error:", err);
        res.status(500).json({ error: "Internal server error" });
    }
});
```

**Fix:** Wrap all async operations in try/catch. See [docs/api-standards.md](../../../../docs/api-standards.md).

---

#### Returning 500 Without Checking 404 First
**Pattern:** `res.status(500)` without checking `err.code === 404`

```typescript
// ❌ BAD
catch (err: any) {
    res.status(500).json({ error: "Internal server error" });
}

// ✅ GOOD
catch (err: any) {
    if (err.code === 404) return res.status(404).send();
    console.error("Error:", err);
    res.status(500).json({ error: "Internal server error" });
}
```

**Why:** Cosmos DB throws 404 as an exception. Check it before defaulting to 500.

**Fix:** Always check `err.code === 404` first. See [docs/api-standards.md](../../../../docs/api-standards.md) error handling section.

---

#### Exposing Raw Error Messages
**Pattern:** `res.json({ error: err.message })` or similar

```typescript
// ❌ BAD
catch (err: any) {
    res.status(500).json({ error: err.message });
}

// ✅ GOOD
catch (err: any) {
    if (err.code === 404) return res.status(404).send();
    console.error("Error:", err);
    res.status(500).json({ error: "Internal server error" });
}
```

**Why:** Exposes internal implementation details and potential security info.

**Fix:** Return generic error message. Log details server-side only.

---

#### Hardcoded Secrets or Connection Strings
**Pattern:** Direct string values for connections, keys, URLs

```typescript
// ❌ BAD
const connectionString = "mongodb://...";
const apiKey = "abc123xyz";

// ✅ GOOD
import config from "../config";
const connectionString = config.get("DATABASE_URL");
```

**Fix:** Use environment variables via config module. See [AGENTS.md](../../../../AGENTS.md) Non-Negotiable Rule #3.

---

### 🟡 Should Fix (Quality Issues)

#### Inconsistent Request Typing
**Pattern:** `Request` without generic parameters

```typescript
// ❌ BAD
router.get("/:id", async (req: Request, res): Promise<void> => {
    const id = req.params.id; // Type is 'any'
});

// ✅ GOOD
interface PathParams {
    id: string;
}
router.get("/:id", async (req: Request<PathParams>, res): Promise<void> => {
    const id = req.params.id; // Type is 'string'
});
```

**Fix:** Use `Request<PathParams, ResBody, ReqBody, QueryParams>` generics.

---

#### Not Using Cosmos Factory Functions
**Pattern:** Direct Cosmos client access instead of factory functions

```typescript
// ❌ BAD
const container = cosmosClient.database("db").container("items");

// ✅ GOOD
import { getListsContainer } from "../models/cosmos";
const container = getListsContainer();
```

**Fix:** Use factory functions from `models/cosmos.ts`. See [docs/architecture.md](../../../../docs/architecture.md).

---

#### Wrong Status Codes
**Pattern:** Returning 200 for resource creation, or wrong codes

```typescript
// ❌ BAD
router.post("/", async (req, res) => {
    const newItem = await createItem(req.body);
    res.status(200).json(newItem); // Wrong!
});

// ✅ GOOD
router.post("/", async (req, res) => {
    const newItem = await createItem(req.body);
    res.status(201).json(newItem); // Created
});
```

**Fix:** 201 for POST (created), 204 for DELETE (no content), 404 for not found, 500 for errors.

---

#### Relative Imports for Packages
**Pattern:** `import express from '../../../node_modules/express'`

```typescript
// ❌ BAD
import { Request } from "../../../node_modules/express";

// ✅ GOOD
import { Request } from "express";
```

**Fix:** Use absolute imports for packages, relative for project files.

---

### 🔵 Nice to Have (Suggestions)

#### Missing Return Type Annotations
**Pattern:** Exported functions without explicit return types

```typescript
// 🔵 COULD IMPROVE
export async function getItem(id: string) { ... }

// ✅ BETTER
export async function getItem(id: string): Promise<TodoItem> { ... }
```

**Fix:** Add explicit return types to exported functions.

---

## React Code Pitfalls (TypeScript + Fluent UI)

**Scanning:** `src/web/src/components/*.tsx`, `src/web/src/pages/*.tsx`

### 🔴 Critical Issues (Must Fix)

#### Using Raw HTML Elements
**Pattern:** `<div>`, `<button>`, `<input>`, `<span>` instead of Fluent UI

```tsx
// ❌ BAD
<div className="container">
    <button onClick={handleClick}>Save</button>
    <input type="text" value={name} />
</div>

// ✅ GOOD
<Stack tokens={{ padding: 10 }}>
    <PrimaryButton onClick={handleClick}>Save</PrimaryButton>
    <TextField value={name} />
</Stack>
```

**Fix:** Use Fluent UI components exclusively. See [docs/ui-components.md](../../../../docs/ui-components.md).

**Exception:** `<div>` is OK only as a wrapper for Fluent UI components when needed.

---

#### Not Using FC<Props> Pattern
**Pattern:** Function components without typed Props interface

```tsx
// ❌ BAD
const MyComponent = (props) => { ... }
const MyComponent = ({ item, onSave }) => { ... }

// ✅ GOOD
interface MyComponentProps {
    item: TodoItem;
    onSave: (item: TodoItem) => void;
}
const MyComponent: FC<MyComponentProps> = ({ item, onSave }) => { ... }
```

**Fix:** Always use `FC<Props>` with explicit interface. See [docs/web-standards.md](../../../../docs/web-standards.md).

---

#### Direct State Mutation
**Pattern:** Setting state directly instead of dispatching actions

```tsx
// ❌ BAD
setState(newValue);
items[0].name = "Updated"; // Direct mutation

// ✅ GOOD
dispatch(updateItem(itemId, { name: "Updated" }));
```

**Fix:** Use action creators + reducers. See [docs/web-standards.md](../../../../docs/web-standards.md).

---

#### Hardcoded API URLs
**Pattern:** Direct URL strings instead of config

```tsx
// ❌ BAD
const response = await fetch("http://localhost:3100/api/lists");

// ✅ GOOD
import config from "../config";
const response = await fetch(`${config.API_BASE_URL}/lists`);
```

**Fix:** Use `config.API_BASE_URL` from `src/web/src/config/index.ts`.

---

### 🟡 Should Fix (Quality Issues)

#### Service Calls Not Through Action Creators
**Pattern:** Direct service calls in components instead of action creators

```tsx
// ❌ BAD
const handleSave = async () => {
    const result = await listService.createList(newList);
    setLists([...lists, result]);
};

// ✅ GOOD
const handleSave = () => {
    dispatch(createList(newList));
};
```

**Fix:** Call action creators from `src/web/src/actions/`. They handle service calls + state updates.

---

#### Missing Loading/Error States
**Pattern:** No loading spinner or error display

```tsx
// ❌ BAD
const MyComponent: FC = () => {
    return <div>{data.name}</div>;
};

// ✅ GOOD
const MyComponent: FC = () => {
    if (isLoading) return <Spinner label="Loading..." />;
    if (error) return <MessageBar messageBarType={MessageBarType.error}>{error}</MessageBar>;
    return <div>{data.name}</div>;
};
```

**Fix:** Handle loading and error states. See [docs/web-standards.md](../../../../docs/web-standards.md).

---

#### Using Popup Auth Instead of Redirect
**Pattern:** `loginPopup()` instead of `loginRedirect()`

```tsx
// ❌ BAD
await instance.loginPopup(loginRequest);

// ✅ GOOD
await instance.loginRedirect(loginRequest);
```

**Fix:** Use redirect flow only (popup is unreliable). See [docs/auth-standards.md](../../../../docs/auth-standards.md).

---

## Infrastructure Pitfalls (Bicep)

**Scanning:** `infra/**/*.bicep`

### 🔴 Critical Issues (Must Fix)

#### Missing Required Tags
**Pattern:** Resources without `azd-env-name` tag

```bicep
// ❌ BAD
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
    name: storageAccountName
    location: location
    // Missing tags
}

// ✅ GOOD
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
    name: storageAccountName
    location: location
    tags: union(tags, { 'azd-service-name': serviceName })
}
```

**Fix:** Always include `tags` parameter. See [docs/infrastructure.md](../../../../docs/infrastructure.md).

---

#### Hardcoded Resource Names
**Pattern:** Direct string literals instead of parameters

```bicep
// ❌ BAD
name: 'my-storage-account-prod'

// ✅ GOOD
name: '${abbrs.storageStorageAccounts}${resourceToken}'
```

**Fix:** Use `abbreviations.json` + `resourceToken` pattern. See [docs/infrastructure.md](../../../../docs/infrastructure.md).

---

### 🟡 Should Fix (Quality Issues)

#### Not Using AVM Modules
**Pattern:** Defining resources inline instead of using Azure Verified Modules

```bicep
// ❌ COULD IMPROVE
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
    // 50 lines of configuration
}

// ✅ BETTER
module cosmosAccount 'br/public:avm/res/document-db/database-account:0.8.1' = {
    name: 'cosmos-deployment'
    params: { ... }
}
```

**Fix:** Use AVM modules where available. See [docs/infrastructure.md](../../../../docs/infrastructure.md).

---

## Testing Pitfalls (Jest + Supertest)

**Scanning:** `src/api/src/**/*.spec.ts`

### 🔴 Critical Issues (Must Fix)

#### Test Data Not Cleaned Up
**Pattern:** Missing `afterAll` hook or incomplete cleanup

```typescript
// ❌ BAD
describe("Items Route", () => {
    it("creates item", async () => {
        const res = await createItem(testItem);
        expect(res.statusCode).toEqual(201);
    });
    // No cleanup!
});

// ✅ GOOD
describe("Items Route", () => {
    const testIds: string[] = [];
    
    it("creates item", async () => {
        const res = await createItem(testItem);
        testIds.push(res.body.id);
        expect(res.statusCode).toEqual(201);
    });
    
    afterAll(async () => {
        for (const id of testIds) {
            await deleteItem(id);
        }
    });
});
```

**Fix:** Always clean up in `afterAll`. See [docs/testing-standards.md](../../../../docs/testing-standards.md).

---

#### Missing 404 Test Cases
**Pattern:** Testing only happy path for GET endpoints

```typescript
// ❌ BAD
describe("GET /items/:id", () => {
    it("returns item", async () => {
        const res = await getItem(existingId);
        expect(res.statusCode).toEqual(200);
    });
});

// ✅ GOOD
describe("GET /items/:id", () => {
    it("returns item", async () => {
        const res = await getItem(existingId);
        expect(res.statusCode).toEqual(200);
    });
    
    it("returns 404 for non-existent id", async () => {
        const res = await getItem("fake-id");
        expect(res.statusCode).toEqual(404);
    });
});
```

**Fix:** Always test 404 case for GET endpoints. See [docs/testing-standards.md](../../../../docs/testing-standards.md).

---

### 🟡 Should Fix (Quality Issues)

#### Using toEqual for Primitives
**Pattern:** `.toEqual()` instead of `.toBe()` for primitives

```typescript
// 🔵 COULD IMPROVE
expect(res.statusCode).toEqual(200);

// ✅ BETTER
expect(res.statusCode).toBe(200);
```

**Fix:** Use `.toBe()` for primitives (numbers, strings, booleans), `.toEqual()` for objects.

---

## TypeScript Issues (All Code)

### 🔴 Critical Issues

#### Implicit Any Types
**Pattern:** Variables, parameters, or properties without type annotations where type can't be inferred

```typescript
// ❌ BAD
function process(data) { ... }  // Implicit any
let result;  // Implicit any

// ✅ GOOD
function process(data: TodoItem) { ... }
let result: ProcessResult;
```

**Fix:** Add explicit types everywhere. Strict mode is enabled.

---

#### Wrong Type vs Interface Usage
**Pattern:** Using `type` for component props or `interface` for type aliases

```typescript
// ❌ BAD
type MyComponentProps = { ... }  // Should be interface
interface UserId = string;  // Should be type

// ✅ GOOD
interface MyComponentProps { ... }
type UserId = string;
```

**Rule:** `interface` for component props, `type` for aliases/unions. See [docs/api-standards.md](../../../../docs/api-standards.md).

---

## Output Format

After scanning, I'll provide:

### Summary
```
🔍 Scanned X files across Y domains
🔴 Z critical issues found (must fix)
🟡 W quality issues found (should fix)
🔵 V suggestions (nice to have)
```

### Issues by Severity

#### 🔴 Critical Issues (Must Fix Before PR)
- **File:** `src/api/src/routes/items.ts:45`
  - **Issue:** Using `any` outside catch block
  - **Code:** `const data: any = req.body;`
  - **Fix:** `interface CreateItemRequest { name: string; ... }` then `const data: CreateItemRequest = req.body;`
  - **Ref:** [docs/api-standards.md](../../../../docs/api-standards.md)

#### 🟡 Should Fix
- **File:** `src/web/src/components/ItemPane.tsx:22`
  - **Issue:** Missing loading state
  - **Code:** `return <div>{item.name}</div>;`
  - **Fix:** Add `if (isLoading) return <Spinner />;` before render
  - **Ref:** [docs/web-standards.md](../../../../docs/web-standards.md)

#### 🔵 Nice to Have
- **File:** `src/api/src/models/todoItem.ts:10`
  - **Issue:** Missing explicit return type
  - **Code:** `export async function getItem(id: string) { ... }`
  - **Fix:** `export async function getItem(id: string): Promise<TodoItem> { ... }`

---

### Final Verdict

✅ **Ready for PR** — No critical issues, minor suggestions only

OR

❌ **Needs Fixes** — X critical issues must be resolved before PR

---

## Scope

### This Skill Reviews
- ✅ Code patterns and anti-patterns
- ✅ TypeScript typing issues
- ✅ Error handling correctness
- ✅ Standards compliance (from /docs/)
- ✅ Security issues (secrets, error exposure)

### This Skill Does NOT
- ⛔ Automatically fix issues (just identifies them)
- ⛔ Run lint/tests (use feature-complete-checklist)
- ⛔ Check git commit messages
- ⛔ Review code style preferences beyond standards

---

## Related

- [feature-complete-checklist](../feature-complete-checklist/SKILL.md) — Process verification (tests run, builds pass)
- [build-with-tests](../build-with-tests/SKILL.md) — Implementation workflow
- [AGENTS.md](../../../../AGENTS.md) — Non-negotiable rules
- [docs/](../../../../docs/) — All detailed standards

**Use this AFTER build-with-tests and BEFORE feature-complete-checklist for best results.**
