# Testing Standards

Standards and conventions for tests in this project. Currently, tests exist only for the API (`src/api/`). The web app does not have unit tests at this time.

## Test Stack

| Tool | Role |
|---|---|
| **Jest** | Test runner, assertions, coverage |
| **Supertest** | HTTP integration testing against the live Express app |
| **Babel** (`babel.config.js`) | Transpiles TypeScript for Jest (not `ts-jest`) |

## Test File Location

- Test files live **alongside the source they test** inside `src/api/src/`.
- File naming convention: `<name>.spec.ts`.
- Currently there is one test file: `src/api/src/routes/routes.spec.ts`.
- New test files must follow the same `*.spec.ts` naming pattern to be picked up by the Jest `testMatch` glob.

## Running Tests

```bash
cd src/api

# Run all tests with coverage
npm test

# Watch mode (useful during development)
npx jest --watch

# Run a specific file
npx jest routes.spec.ts
```

Tests **require a real Cosmos DB connection**. Set the necessary environment variables before running (see [docs/architecture.md](architecture.md#environment-variables)), or use a local emulator.

## Test Structure

Tests use `describe` blocks to group related scenarios. The top-level `describe` is the resource name; nested `describe` blocks separate the two resource types:

```typescript
describe("API", () => {
    describe("Todo List Routes", () => {
        it("can GET an array of lists", async () => { ... });
        it("can POST (create) new list", async () => { ... });
        // ...
    });

    describe("Todo Item Routes", () => {
        it("can GET an array of items", async () => { ... });
        // ...
    });
});
```

## Server Lifecycle in Tests

The Express app is started once per test suite using `beforeAll` / `afterAll`. Never start a new server per individual test:

```typescript
describe("API", () => {
    let app: Express;
    let server: Server;

    beforeAll(async () => {
        app = await createApp();
        server = app.listen(process.env.PORT || 3100);
    });

    afterAll((done) => {
        server.close(done);
    });
});
```

## Helper Functions

Repetitive HTTP calls are encapsulated as named helper functions at the bottom of the spec file (not exported). Each helper wraps a `supertest` call and returns the raw response:

```typescript
const createList = (list: Partial<TodoList>) =>
    request(app).post("/lists").send(list);

const getList = (id: string) =>
    request(app).get(`/lists/${id}`);

const deleteList = (id: string) =>
    request(app).delete(`/lists/${id}`);
```

This keeps `it` blocks focused on assertions, not HTTP plumbing.

## Test Data Hygiene

Every test that creates data **must clean up after itself**:

```typescript
it("can POST (create) new list", async () => {
    const res = await createList({ name: "POST test" });

    expect(res.statusCode).toEqual(201);
    // assertions ...

    await deleteList(res.body.id);  // always clean up
});
```

For tests that need shared setup data, use `beforeAll` / `afterAll` at the `describe` scope:

```typescript
describe("Todo Item Routes", () => {
    let testList: TodoList;

    beforeAll(async () => {
        const res = await createList({ name: "Integration test" });
        testList = res.body as TodoList;
    });

    afterAll(async () => {
        await deleteList(testList.id);
    });
    // ...
});
```

## Assertions

Use Jest's built-in matchers. Common patterns in this codebase:

```typescript
// Status code
expect(res.statusCode).toEqual(200);
expect(res.statusCode).toEqual(201);
expect(res.statusCode).toEqual(204);
expect(res.statusCode).toEqual(404);

// Body shape — allows any value for dynamic fields
expect(res.body).toMatchObject({
    name: "expected name",
    id: expect.any(String),
    createdDate: expect.any(String),
    updatedDate: expect.any(String)
});

// Array length
expect(res.body).toHaveLength(1);
expect(res.body.length).toBeGreaterThan(0);

// Exact object match after update
expect(res.body).toMatchObject({
    id: existingItem.id,
    name: "updated name"
});
```

## Coverage Expectations

- `npm test` runs with `--coverage`. Coverage output is written to `coverage/`.
- The `coverage/` directory is gitignored.
- Every new route handler or model factory function must have at least one corresponding integration test covering the happy path and the 404 case.
- Do not use `/* istanbul ignore */` comments to suppress coverage. If code cannot be reached in tests, reconsider whether it should exist.

## What to Test

| Scenario | Required |
|---|---|
| Successful GET (list) — returns 200 + array | Yes |
| Successful GET with paging (`top` / `skip`) | Yes |
| Successful GET by ID — returns 200 + object | Yes |
| GET by non-existent ID — returns 404 | Yes |
| Successful POST — returns 201 + created body + `Location` header | Yes |
| Successful PUT — returns 200 + updated body | Yes |
| Successful DELETE — returns 204 | Yes |
| DELETE of non-existent ID — returns 404 | Yes |

## Adding Tests for New Routes

When adding a new route file (e.g., `src/api/src/routes/tags.ts`):

1. Add tests to the existing `routes.spec.ts` file in a new `describe("Todo Tag Routes", ...)` block.
2. Follow the helper function pattern for HTTP calls.
3. Ensure all created test data is deleted in cleanup.
4. Run `npm test` and confirm zero failures before committing.
