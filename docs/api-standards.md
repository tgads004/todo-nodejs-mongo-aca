# API Standards

Standards and conventions for the Express REST API located in `src/api/`.

## File Organization

```
src/api/
├── config/                        # node-config JSON files (not TypeScript)
│   ├── default.json               # Base configuration values
│   └── custom-environment-variables.json  # Env var → config key mappings
└── src/
    ├── app.ts                     # Express app factory and middleware setup
    ├── index.ts                   # Server entry point (calls createApp, listens)
    ├── config/
    │   ├── appConfig.ts           # TypeScript interfaces for configuration
    │   ├── applicationInsightsTransport.ts  # Winston → App Insights transport
    │   ├── index.ts               # Config loading entry point (getConfig())
    │   └── observability.ts       # Application Insights SDK initialization
    ├── models/
    │   ├── cosmos.ts              # Cosmos DB client init + container accessors
    │   ├── todoItem.ts            # TodoItem type + createTodoItem factory
    │   ├── todoList.ts            # TodoList type + createTodoList factory
    │   └── sampleData.ts         # Seed data
    └── routes/
        ├── common.ts              # Shared types (PagingQueryParams, etc.)
        ├── lists.ts               # /lists route handler
        ├── items.ts               # /lists/:listId/items route handler
        └── routes.spec.ts         # Integration tests (Jest + Supertest)
```

**Rules:**
- New route files go in `src/api/src/routes/`.
- New model types and factory functions go in `src/api/src/models/`.
- New configuration interfaces go in `src/api/src/config/appConfig.ts`.
- Never place business logic directly in `app.ts` or `index.ts`.

## TypeScript Conventions

- Target is **ES2020**, module system is **CommonJS** (see `tsconfig.json`).
- All source files must be `.ts`. No `.js` files inside `src/`.
- Use explicit return types on exported functions and route handlers.
- Use `any` **only** in `catch` blocks: `catch (err: any)`.
- Prefer TypeScript `type` aliases for plain data shapes (e.g., `TodoList`, `TodoItem`). Use `interface` for contracts implemented by classes.
- Use `import type` when importing only for type information.

```typescript
// Good — explicit return type, typed path params
router.get("/:listId", async (req: Request<TodoListPathParams>, res): Promise<void> => {
    // ...
});

// Bad — implicit any, no path param typing
router.get("/:listId", async (req, res) => {
    // ...
});
```

## Route Handler Pattern

Every route handler must follow this structure:

```typescript
router.METHOD("/path", async (req: Request<PathParams, ResBody, ReqBody, QueryParams>, res) => {
    try {
        // 1. Extract and validate inputs
        // 2. Access Cosmos DB via container accessor function
        // 3. Handle not-found (resource === undefined) → 404
        // 4. Return appropriate status + JSON body
    } catch (err: any) {
        if (err.code === 404) {
            return res.status(404).send();
        }
        console.error("Error description:", err);
        res.status(500).json({ error: "Internal server error" });
    }
});
```

**Rules:**
- All route handlers are `async`.
- Always wrap in `try/catch`. Never let an unhandled promise rejection propagate.
- Check `err.code === 404` in the catch block before falling through to 500 — Cosmos DB throws with a numeric `code` property for not-found responses.
- Never expose raw error details, stack traces, or internal field names in API responses. Use generic messages like `"Internal server error"`.
- Set the `Location` header on 201 responses (resource creation).

### HTTP Status Code Reference

| Scenario | Status |
|---|---|
| Successful read | 200 |
| Resource created | 201 (+ `Location` header) |
| Resource not found | 404 |
| Unhandled server error | 500 |

## Request Typing

Use the four generic parameters on Express `Request`:

```typescript
type PathParams = { listId: string; itemId: string };
type ResBody = TodoItem;
type ReqBody = TodoItem;
type QueryParams = PagingQueryParams;

router.put("/:listId/:itemId", async (req: Request<PathParams, ResBody, ReqBody, QueryParams>, res) => { ... });
```

`PagingQueryParams` is defined in `src/api/src/routes/common.ts` and should be reused for any paginated endpoint:

```typescript
export type PagingQueryParams = {
    top?: string;
    skip?: string;
};
```

Always parse `top` and `skip` as integers with a default fallback:

```typescript
const skip = req.query.skip ? parseInt(req.query.skip) : 0;
const top  = req.query.top  ? parseInt(req.query.top)  : 20;
```

## Cosmos DB Access

- Never instantiate `CosmosClient` directly in a route file. Always call the container accessor functions from `src/api/src/models/cosmos.ts`:
  - `getTodoListContainer()` — returns the `TodoList` Cosmos container
  - `getTodoItemContainer()` — returns the `TodoItem` Cosmos container

- Use parameterized queries to prevent injection:

```typescript
// Good — parameterized
const query = `SELECT * FROM c WHERE c.listId = @listId OFFSET ${skip} LIMIT ${top}`;
const { resources } = await container.items.query({
    query,
    parameters: [{ name: "@listId", value: req.params.listId }]
}).fetchAll();

// Bad — string interpolation of user input
const query = `SELECT * FROM c WHERE c.listId = '${req.params.listId}'`;
```

- For point reads (by id + partition key), use `container.item(id, partitionKey).read()` instead of a query.
- Check for `resource === undefined` after a `.read()` call — Cosmos DB returns `undefined` (not an error) when an item doesn't exist under certain SDK configurations.

## Model Factory Functions

Every model must have a factory function that populates system-managed fields (`id`, `createdDate`, `updatedDate`, partition key). Callers should never build raw objects:

```typescript
// Good — use factory
const list = createTodoList(req.body.name, req.body.description);

// Bad — manual object construction
const list: TodoList = { id: req.body.id, name: req.body.name, ... };
```

Factory functions use `randomUUID()` from Node's built-in `crypto` module for ID generation. Never use `Math.random()` or external UUID libraries.

## CORS Configuration

CORS is configured centrally in `src/api/src/app.ts`. Do not add or modify CORS headers anywhere else. The allowed `methods` list must include all HTTP verbs the API uses:

```typescript
app.use(cors({
    origin: originList(),
    methods: ["GET", "HEAD", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
}));
```

In production (`NODE_ENV` anything other than `"development"`), `originList()` returns an explicit array of allowed origins. Adding `"*"` to this list in non-development environments is forbidden.

## Logging

Use `console.error()` for error logging in route handlers (it is captured by the Application Insights transport). Do not use `console.log()` for error conditions. Do not log request bodies, Cosmos DB documents, or any data that may contain PII.

## OpenAPI / Swagger

The API exposes a Swagger UI at `/` powered by `openapi.yaml` (root of `src/api/`). When adding or modifying routes:

1. Update `openapi.yaml` to reflect the new or changed operation.
2. Ensure path parameters, request bodies, and response schemas match the TypeScript types.

## Build and Lint

```bash
cd src/api

# Lint (must pass with zero errors)
npm run lint

# Build (runs lint first via prebuild hook)
npm run build

# Start (runs build first via prestart hook)
npm run start
```

The ESLint configuration enforces `@typescript-eslint` rules. Lint errors block the build — fix them, do not suppress with `// eslint-disable` comments unless absolutely unavoidable, and always add an explanatory comment when doing so.
