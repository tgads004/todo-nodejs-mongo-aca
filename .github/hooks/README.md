# GitHub Copilot Hooks

Automated quality gates and policy enforcement for the todo-nodejs-mongo-aca project.

## Available Hooks

### pre-commit.json

**Purpose:** Enforce "Non-Negotiable Rules" from [AGENTS.md](../../AGENTS.md) before allowing git commits.

**Trigger:** Intercepts `git commit` commands (via `PreToolUse` event)

**Checks Performed:**
1. ✅ TypeScript compilation (`npm run build`) in `src/api/` and `src/web/`
2. ✅ Linting with zero warnings (`npm run lint`) in both services
3. ✅ API tests (`npm test` in `src/api/`)
4. ✅ Secrets scan (checks staged files for connection strings, API keys)
5. ✅ File naming conventions (route files plural, model files singular)

**Behavior:**
- **BLOCKS** commit if any critical check fails
- **WARNS** (but allows) if naming conventions violated
- Displays specific failure messages with fix commands
- Can be bypassed with `git commit --no-verify` (not recommended)

**Example Output (Failure):**
```
🔍 Running pre-commit quality checks...
  Checking TypeScript compilation (API)...
  Checking linting (API)...

❌ Pre-commit check FAILED!

  ❌ Linting (API)
     Lint failed in src/api - zero warnings required
     src/routes/items.ts:45:10 - error TS2345: Argument of type 'any' is not assignable
     Fix: cd src/api && npm run lint

To bypass this check (not recommended):
  git commit --no-verify
```

**Example Output (Success):**
```
🔍 Running pre-commit quality checks...
  Checking TypeScript compilation (API)...
  Checking TypeScript compilation (Web)...
  Checking linting (API)...
  Checking linting (Web)...
  Running API tests...
  Scanning for hardcoded secrets...
  Checking file naming conventions...

✅ Pre-commit checks passed!
```

---

### package-change-alert.json

**Purpose:** Automatically detect package.json changes and remind developers to install dependencies. Prevents runtime errors caused by outdated node_modules.

**Trigger:** After file edit operations (via `PostToolUse` event)

**Detects Changes In:**
- `src/api/package.json`
- `src/web/package.json`

**Behavior:**
- **NON-BLOCKING** — Always allows the edit to complete (exit code 0)
- **INFORMATIONAL** — Displays a reminder message with installation instructions
- **SMART** — Only triggers when package.json files in src/api/ or src/web/ are modified
- **EFFICIENT** — Ignores root package.json and non-package.json files

**Supported Tools:**
- `replace_string_in_file`
- `multi_replace_string_in_file`
- `create_file`

**Example Output (API package.json modified):**
```
📦 PACKAGE.JSON CHANGED — Dependencies may need updating
Changes have been saved.

📄 src/api/package.json modified

💡 Don't forget to install dependencies:
   cd src/api && npm install

Or use the Azure Developer CLI to restore all services:
   azd restore

⚠️  If dev servers are running, restart them to pick up new dependencies:
   • API: Stop and re-run 'Start API' task or npm run start

🤖 Would you like me to run the install commands for you?
```

**Example Output (Both services modified):**
```
📦 PACKAGE.JSON CHANGED — Dependencies may need updating
Changes have been saved.

📄 src/api/package.json modified
📄 src/web/package.json modified

💡 Don't forget to install dependencies:
   cd src/api && npm install
   cd src/web && npm install

Or use the Azure Developer CLI to restore all services:
   azd restore

⚠️  If dev servers are running, restart them to pick up new dependencies:
   • API: Stop and re-run 'Start API' task or npm run start
   • Web: Stop and re-run 'Start Web' task or npm run dev

🤖 Would you like me to run the install commands for you?
```

**Why This Matters:**
- Prevents "Cannot find module" errors at runtime
- Reduces confusion when new dependencies are added
- Reminds developers to restart dev servers after dependency changes
- Ensures consistency between package.json and node_modules

---

### post-edit.json

**Purpose:** Automatically format and lint TypeScript files after Copilot edits them. Ensures code style consistency without manual intervention.

**Trigger:** After file edit operations (via `PostToolUse` event)

**Actions Performed:**
1. ✅ Detects edited TypeScript files in `src/api/` and `src/web/`
2. ✅ Runs `npm run lint --fix` on each edited file
3. ✅ Fixes auto-fixable issues (indentation, semicolons, imports)
4. ✅ Reports unfixable issues (non-blocking)

**Behavior:**
- **NON-BLOCKING** — Always allows the edit to complete
- **SILENT** — Only shows output if formatting occurs
- **SMART** — Only processes .ts/.tsx files in src/ directories
- **EFFICIENT** — Runs lint on specific files, not entire codebase

**Example Output (Success):**
```
🎨 Auto-formatting edited files...
  Formatting: src/api/src/routes/items.ts
    ✅ Formatted successfully
  Formatting: src/web/src/components/todoItemListPane.tsx
    ✅ Formatted successfully

✅ Auto-formatted 2 file(s)
```

**Example Output (Unfixable Issues):**
```
🎨 Auto-formatting edited files...
  Formatting: src/api/src/routes/users.ts
    ⚠️  Unfixable issues found

⚠️  Some files have unfixable lint issues:
  src/api/src/routes/users.ts
    error TS2345: Argument of type 'any' is not assignable

  Run lint manually to see full errors:
    cd src/api && npm run lint
    cd src/web && npm run lint
```

**What Gets Auto-Fixed:**
- Missing semicolons
- Incorrect indentation
- Trailing whitespace
- Import organization (if configured in ESLint)
- Consistent quotes (single vs double)

**What Cannot Be Auto-Fixed:**
- Type errors (`any` usage, missing types)
- Unused variables/imports (requires manual removal)
- Logic errors or wrong function signatures

---

### pre-deploy.json

**Purpose:** Validate infrastructure and configuration before Azure deployments. Prevents broken deployments by catching issues early.

**Trigger:** Before deployment commands (via `PreToolUse` event)

**Intercepted Commands:**
- `azd up` — Provision + deploy
- `azd provision` — Infrastructure only
- `azd deploy` — Code only
- `az deployment` — Direct Bicep/ARM deployments

**Validation Checks:**
1. ✅ Azure CLI installed and authenticated (`az account show`)
2. ✅ Bicep files compile without errors (`az bicep build`)
3. ✅ Active azd environment configured (`azd env list`)
4. ✅ Recommended environment variables set (`AZURE_LOCATION`, `AZURE_SUBSCRIPTION_ID`)
5. ✅ No hardcoded secrets in `infra/` files
6. ✅ Required tags present in Bicep resources
7. ✅ Azure resource providers registered (Container Apps, Cosmos DB, ACR, Key Vault)

**Behavior:**
- **BLOCKS** deployment if critical checks fail (auth, Bicep errors, secrets)
- **WARNS** (but allows) if recommendations missing (env vars, tags, providers)
- **BYPASSES** preview/dry-run commands (`--preview`, `--what-if`)
- Provides specific fix commands for each failure

**Example Output (Blocked):**
```
🔍 Running pre-deployment validation for: azd up (provision + deploy)

  Checking Azure CLI authentication...
  Validating Bicep files...
  Checking azd environment...
  Checking required environment variables...
  Scanning for hardcoded secrets in infrastructure...

❌ Pre-deployment validation FAILED!

  ❌ Azure CLI Authentication
     Not logged in to Azure CLI
     Fix: az login

  ❌ Bicep Validation
     Bicep compilation failed
     infra/main.bicep:45:10 - Error: Property 'invalidProp' not recognized
     Fix: Fix Bicep syntax errors. Run: az bicep build --file infra/main.bicep

To preview changes without validation:
  azd provision --preview

To bypass validation (not recommended):
  Run the command directly in terminal (not through Copilot)
```

**Example Output (Success with Warnings):**
```
🔍 Running pre-deployment validation for: azd provision (infrastructure only)

  Checking Azure CLI authentication...
    ✅ Logged in as: user@example.com
  Validating Bicep files...
    ✅ All Bicep files valid (5 files)
  Checking azd environment...
    ✅ azd environment configured
  Checking required environment variables...
  Scanning for hardcoded secrets in infrastructure...
  Checking required tags in Bicep resources...
  Checking Azure resource providers...
    ✅ All required resource providers registered

⚠️  Pre-deployment warnings (non-blocking):

  ⚠️  Environment Variables
     Recommended variable not set: AZURE_LOCATION
     Fix: azd env set AZURE_LOCATION <value>

  ⚠️  Bicep Resource Tags
     No tags found in main.bicep - consider adding tags for cost tracking
     Fix: Add tags object to resources, including 'azd-env-name' and 'Owner'
     See: docs/infrastructure.md

✅ Pre-deployment validation passed!

Deployment type: azd provision (infrastructure only)
Ready to deploy to Azure.
```

**What This Prevents:**
- ❌ Deploying without Azure authentication
- ❌ Deploying Bicep with syntax errors
- ❌ Deploying without configured environment
- ❌ Accidentally committing secrets in infrastructure
- ❌ Missing resource providers causing runtime failures

---

### standards-check.json

**Purpose:** Warn about project-specific patterns that ESLint cannot detect — semantics, architectural conventions, and framework-specific requirements from [AGENTS.md](../../AGENTS.md) and [/docs/](../../docs/).

**Trigger:** After any file create/edit operation (`PostToolUse` event)

**Applies To:** TypeScript files in `src/**/*.ts` and `src/**/*.tsx`

**Checks Performed:**
1. ⚠️ API routes use `Request<>` generics (not untyped `req`)
2. ⚠️ Async route handlers have `try/catch` blocks
3. ⚠️ Exported React components use `FC<Props>` type annotation
4. ⚠️ No raw HTML elements — use Fluent UI equivalents
5. ⚠️ No `any` type outside `catch (err: any)` blocks
6. ⚠️ Test files with `beforeAll` data creation have `afterAll` cleanup

**Behavior:**
- **WARNS only** — never blocks (always exits 0)
- Injects warning details into Copilot context via `systemMessage`
- Reports file name, line number, violating code, and fix example
- Supports per-file opt-out: `// standards-check: disable`

**Example Output:**
```
⚠️  STANDARDS CHECK — 3 violation(s) found
These are warnings only. Changes have been saved.

📄 src/api/src/routes/users.ts
  Line 45: Async route handler is missing a try/catch block
  Code: router.get('/:id', async (req, res) => {
  Fix:  try { /* handler */ } catch (err: any) { res.status(500).json({ error: 'Internal server error' }) }
  Ref:  docs/api-standards.md — Route Handler Pattern

📄 src/web/src/components/userCard.tsx
  Line 12: Exported component missing FC<Props> type annotation
  Code: export const UserCard = ({ user }) => {
  Fix:  const UserCard: FC<UserCardProps> = ({ user }) => { ... }
  Ref:  docs/web-standards.md — Component Pattern

  Line 28: Raw HTML <div> — replace with a Fluent UI component
  Code: <div className="card-container">
  Fix:  Use: <Stack> <DefaultButton> <PrimaryButton> <TextField> <Text> ...
  Ref:  docs/ui-components.md

To disable per file add:  // standards-check: disable
```

**What This Enforces:**
- ✅ All async route handlers have error handling
- ✅ Request types are explicit and documented
- ✅ React components follow the established FC<Props> pattern
- ✅ Fluent UI is used consistently (no raw HTML)
- ✅ TypeScript strict mode intent (no `any` leakage)
- ✅ Test data is cleaned up

---

### test-coverage-api.json

**Purpose:** Ensure new API route handlers have corresponding integration tests — close the feedback loop between route creation and test coverage.

**Trigger:** After any file create/edit operation on route files (`PostToolUse` event)

**Applies To:** TypeScript route files in `src/api/src/routes/*.ts` (excludes `*.spec.ts` and `common.ts`)

**Checks Performed:**
1. 🔍 Extract all route handlers from edited files: `router.get(...)`, `router.post(...)`, `router.put(...)`, `router.delete(...)`, `router.patch(...)`
2. 🧪 Map route file to test describe block (`lists.ts` → "Todo List Routes", `items.ts` → "Todo Item Routes")
3. ✅ Check if `routes.spec.ts` contains test cases for each HTTP method and path
4. ⚠️ Warn if coverage gaps detected

**Behavior:**
- **WARNS only** — never blocks (always exits 0)
- Injects gap details into Copilot context via `systemMessage`
- Reports missing tests by file and route
- Offers to generate test skeleton following [docs/testing-standards.md](../../docs/testing-standards.md)

**Example Output:**
```
⚠️  TEST COVERAGE GAP — 2 route(s) without tests
These are warnings only. Changes have been saved.

📄 src/api/src/routes/lists.ts
  Missing test for: POST /archive
  Missing test for: PUT /:listId/restore

💡 Would you like me to generate test skeletons for these routes?
   See: docs/testing-standards.md for test conventions
```

**What This Enforces:**
- ✅ Every route handler has at least one integration test
- ✅ Test coverage is maintained as routes evolve
- ✅ Testing standards are applied consistently
- ✅ Tests are discoverable in `routes.spec.ts`

**Why This Matters:**
Routes without tests create blind spots in the API. This hook closes the loop between feature development and quality assurance, making it **impossible to forget** to write tests.

---

### package-change-alert.json

**Purpose:** Remind developers to install dependencies after `package.json` modifications — preventing "works on my machine" issues from stale dependencies.

**Trigger:** After any file create/edit operation on package.json files (`PostToolUse` event)

**Applies To:** `src/api/package.json` and `src/web/package.json`

**Checks Performed:**
1. 📦 Detect changes to package.json in api/ or web/ directories
2. 🔍 Identify which service(s) were affected
3. 💡 Provide specific install commands for each service
4. ⚠️ Remind to restart dev servers if running

**Behavior:**
- **INFORMS only** — never blocks (always exits 0)
- Injects friendly reminder into Copilot context via `systemMessage`
- Provides multiple installation options (npm install, azd restore)
- Includes dev server restart instructions
- Offers to run install commands automatically (requires confirmation)

**Example Output:**
```
📦 PACKAGE.JSON CHANGED — Dependencies may need updating
Changes have been saved.

📄 src/api/package.json modified

💡 Don't forget to install dependencies:
   cd src/api && npm install

Or use the Azure Developer CLI to restore all services:
   azd restore

⚠️  If dev servers are running, restart them to pick up new dependencies:
   • API: Stop and re-run 'Start API' task or npm run start

🤖 Would you like me to run the install commands for you?
```

**What This Enforces:**
- ✅ Dependencies are never forgotten after package.json changes
- ✅ Dev environments stay in sync with package declarations
- ✅ "Works on my machine" issues are prevented
- ✅ Multiple installation paths are suggested (npm, azd)

**Why This Matters:**
Forgetting to run `npm install` after adding dependencies is a common mistake that leads to runtime errors and wasted debugging time. This hook makes dependency management **frictionless and foolproof**.

---

## How Hooks Work

Hooks are **deterministic runtime enforcers** that run automatically at specific lifecycle events:

| Event | When It Runs | Example Use |
|-------|-------------|-------------|
| `PreToolUse` | Before any tool invocation | Block dangerous commands, validate inputs |
| `PostToolUse` | After tool completes | Auto-format code, run cleanup |
| `SessionStart` | Agent session begins | Inject context, load env vars |

**Hooks vs Skills:**
- **Skills** (build-with-tests, code-review-self-check) are *assistants* — they guide and suggest
- **Hooks** are *guardians* — they enforce and block

---

## Testing Hooks

### Test the Pre-Commit Hook

1. **Trigger a failure:**
   ```powershell
   # Introduce a lint error
   # (add 'any' type in src/api/src/routes/items.ts)
   
   # Try to commit
   git add .
   git commit -m "test: trigger hook"
   
   # Expected: Hook blocks commit, shows lint error
   ```

2. **Trigger success:**
   ```powershell
   # Fix the error
   cd src/api
   npm run lint --fix
   
   # Commit again
   git add .
   git commit -m "test: hook should pass"
   
   # Expected: Hook allows commit
   ```

3. **Bypass hook:**
   ```powershell
   # Force commit despite failures
   git commit -m "test: bypass" --no-verify
   
   # Expected: Commit succeeds (not recommended in practice)
   ```

### Test the Post-Edit Hook

1. **Trigger auto-format:**
   ```
   Ask Copilot: "Add a new route handler to src/api/src/routes/items.ts that gets an item by ID"
   
   # Watch for auto-format output after edit:
   # 🎨 Auto-formatting edited files...
   #   Formatting: src/api/src/routes/items.ts
   #     ✅ Formatted successfully
   ```

2. **Verify formatting applied:**
   ```powershell
   # Check git diff - should show consistent formatting
   git diff src/api/src/routes/items.ts
   
   # Verify no lint errors
   cd src/api
   npm run lint
   ```

3. **Test with multiple files:**
   ```
   Ask Copilot: "Update the TodoItem interface in src/api/src/models/todoItem.ts and add a new component in src/web/src/components/newComponent.tsx"
   
   # Expected: Both files auto-formatted after edit
   ```

4. **Test with non-fixable issues:**
   ```
   Ask Copilot: "Add a function that uses 'any' type in src/api/src/routes/items.ts"
   
   # Expected: Hook warns about unfixable issues but doesn't block
   ```

### Test the Pre-Deploy Hook

1. **Test without Azure login:**
   ```powershell
   # Logout of Azure (if logged in)
   az logout
   
   # Try deployment through Copilot
   Ask Copilot: "Run azd provision"
   
   # Expected: Hook blocks with "Not logged in to Azure CLI"
   ```

2. **Test with Bicep error:**
   ```powershell
   # Introduce syntax error in infra/main.bicep
   # (add invalid property)
   
   # Try deployment
   Ask Copilot: "Deploy to Azure with azd up"
   
   # Expected: Hook blocks with Bicep validation error
   ```

3. **Test successful validation:**
   ```powershell
   # Ensure logged in
   az login
   
   # Try deployment
   Ask Copilot: "Run azd provision --preview"
   
   # Expected: Hook allows (--preview bypasses validation)
   
   # Or run real deployment
   Ask Copilot: "Run azd provision"
   
   # Expected: Hook validates and allows if all checks pass
   ```

4. **Test manual override:**
   ```powershell
   # Run directly in terminal (bypasses hook)
   azd provision --preview
   
   # Expected: Runs without validation
   ```

### Test the Standards Check Hook

1. **Trigger a route without try/catch:**
   ```
   Ask Copilot: "Add a GET /users route to src/api/src/routes/items.ts without try/catch"
   
   # Expected: Hook warns after edit:
   # ⚠️  STANDARDS CHECK — 1 violation(s) found
   # Line N: Async route handler is missing a try/catch block
   ```

2. **Trigger an untyped React component:**
   ```
   Ask Copilot: "Add a new component export to src/web/src/components/todoListMenu.tsx"
   # (ensure it is created as `export const X = (props) =>` without FC<>)
   
   # Expected: Hook warns about missing FC<Props>
   ```

3. **Test per-file opt-out:**
   ```powershell
   # Add at top of file:
   # // standards-check: disable
   
   # Edit the file
   # Expected: Hook produces no warnings for that file
   ```

4. **Simulate hook input manually:**
   ```powershell
   $testInput = @'
   {
     "tool": {
       "name": "replace_string_in_file",
       "parameters": { "filePath": "D:\\path\\to\\your\\src\\api\\src\\routes\\items.ts" }
     }
   }
   '@
   $testInput | pwsh -NoProfile -File .github/hooks/scripts/standards-check.ps1
   ```

### Test the Test Coverage Hook

1. **Test with existing route (should pass silently):**
   ```
   Ask Copilot: "Edit the GET / route in src/api/src/routes/lists.ts"
   
   # Expected: Hook runs silently (route has tests)
   ```

2. **Test with new route (should warn):**
   ```
   Ask Copilot: "Add a POST /archive endpoint to src/api/src/routes/lists.ts"
   
   # Expected: Hook warns about missing test for POST /archive
   # Message includes offer to generate test skeleton
   ```

3. **Test with non-route file (should ignore):**
   ```
   Ask Copilot: "Edit src/api/src/models/todoList.ts"
   
   # Expected: Hook exits silently (not a route file)
   ```

4. **Simulate hook input manually:**
   ```powershell
   $testInput = @'
   {
     "tool": {
       "name": "replace_string_in_file",
       "parameters": { "filePath": "D:\\path\\to\\your\\src\\api\\src\\routes\\lists.ts" }
     }
   }
   '@
   $testInput | pwsh -NoProfile -File .github/hooks/scripts/test-coverage-check.ps1
   ```

### Test the Package Change Alert Hook

1. **Test with API package.json change:**
   ```
   Ask Copilot: "Add express-rate-limit to src/api/package.json"
   
   # Expected: Hook displays reminder to run npm install in src/api
   # Includes azd restore option and dev server restart reminder
   ```

2. **Test with web package.json change:**
   ```
   Ask Copilot: "Update @fluentui/react version in src/web/package.json"
   
   # Expected: Hook displays reminder to run npm install in src/web
   # Includes restart reminder for web dev server
   ```

3. **Test with both package.json files:**
   ```
   Ask Copilot: "Update TypeScript to version 5.3 in both API and Web"
   
   # Expected: Hook lists both services and provides install commands for each
   ```

4. **Test with non-package.json file (should ignore):**
   ```
   Ask Copilot: "Edit src/api/tsconfig.json"
   
   # Expected: Hook exits silently (not a package.json file)
   ```

5. **Simulate hook input manually:**
   ```powershell
   $testInput = @'
   {
     "tool": {
       "name": "replace_string_in_file",
       "parameters": { "filePath": "D:\\path\\to\\your\\src\\api\\package.json" }
     }
   }
   '@
   $testInput | pwsh -NoProfile -File .github/hooks/scripts/package-change-alert.ps1
   ```

---

## Hook Implementation Details

### File Structure
```
.github/hooks/
├── pre-commit.json              # Pre-commit quality gate
├── post-edit.json               # Post-edit auto-formatter
├── pre-deploy.json              # Pre-deploy validator
├── standards-check.json         # Standards enforcement
├── test-coverage-api.json       # Test coverage checker
├── package-change-alert.json    # Dependency change reminder
├── scripts/
│   ├── pre-commit-check.ps1     # Quality check script
│   ├── post-edit-format.ps1     # Auto-format script
│   ├── pre-deploy-check.ps1     # Deployment validator
│   ├── standards-check.ps1      # Standards enforcement
│   ├── test-coverage-check.ps1  # Test coverage checker
│   └── package-change-alert.ps1 # Dependency change reminder
└── README.md                    # This file
```

### pre-commit.json
Defines the hook trigger and command:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "type": "command",
        "command": "pwsh -NoProfile -ExecutionPolicy Bypass -File .github/hooks/scripts/pre-commit-check.ps1",
        "timeout": 60,
        "cwd": "${workspaceFolder}"
      }
    ]
  }
}
```

### pre-commit-check.ps1
PowerShell script that:
1. Reads hook input JSON from stdin
2. Detects if command is `git commit`
3. Runs quality checks (build, lint, test, secrets scan)
4. Outputs permission decision JSON to stdout
5. Exits with code 0 (allow) or 2 (block)

**Permission Decisions:**
- `allow` — Let the command proceed
- `deny` — Block the command
- `ask` — Prompt user for confirmation

### post-edit.json
Defines the hook trigger for file edits:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "type": "command",
        "command": "pwsh -NoProfile -ExecutionPolicy Bypass -File .github/hooks/scripts/post-edit-format.ps1",
        "timeout": 30,
        "cwd": "${workspaceFolder}"
      }
    ]
  }
}
```

### post-edit-format.ps1
PowerShell script that:
1. Reads hook input JSON from stdin
2. Detects file edit tools (replace_string_in_file, multi_replace_string_in_file, create_file)
3. Extracts edited file paths
4. Filters for TypeScript files in src/ directories
5. Runs `npm run lint --fix` on each file in appropriate service (api/web)
6. Reports results (formatted files, unfixable issues)
7. Always returns `allow` (non-blocking post-operation)

### pre-deploy.json
Defines the hook trigger for deployment commands:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "type": "command",
        "command": "pwsh -NoProfile -ExecutionPolicy Bypass -File .github/hooks/scripts/pre-deploy-check.ps1",
        "timeout": 120,
        "cwd": "${workspaceFolder}"
      }
    ]
  }
}
```

### pre-deploy-check.ps1
PowerShell script that:
1. Reads hook input JSON from stdin
2. Detects Azure deployment commands (`azd up`, `azd provision`, `azd deploy`, `az deployment`)
3. Skips validation for preview commands (`--preview`, `--what-if`)
4. Runs 7 validation checks:
   - Azure CLI authentication
   - Bicep file compilation
   - azd environment configuration
   - Environment variables (recommended)
   - Secrets scan in infra/ files
   - Required tags in Bicep
   - Azure resource providers
5. Reports failures (blocking) and warnings (non-blocking)
6. Returns `deny` if critical checks fail, `allow` if passed

### standards-check.json
Defines the hook trigger for file edits:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "type": "command",
        "command": "pwsh -NoProfile -ExecutionPolicy Bypass -File .github/hooks/scripts/standards-check.ps1",
        "timeout": 30,
        "cwd": "${workspaceFolder}"
      }
    ]
  }
}
```

### standards-check.ps1
PowerShell script that:
1. Reads hook input JSON from stdin
2. Detects file edit tools (replace_string_in_file, multi_replace_string_in_file, create_file)
3. Filters for TypeScript/TSX files in `src/`
4. Classifies each file as API route, React component, or test
5. Runs 6 targeted checks:
   - API routes: `Request<>` generics on async handlers
   - API routes: `try/catch` in async route handlers
   - React: `FC<Props>` type annotation on exported components
   - React: No raw HTML elements (Fluent UI required)
   - All TypeScript: No `any` outside catch blocks
   - Tests: `afterAll` cleanup when `beforeAll` creates data
6. Injects warnings into AI context via `systemMessage`
7. Always exits 0 (non-blocking — warns, never blocks)

**Supported per-file opt-out:** `// standards-check: disable`

### test-coverage-api.json
Defines the hook trigger for route edits:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "type": "command",
        "command": "pwsh -NoProfile -ExecutionPolicy Bypass -File .github/hooks/scripts/test-coverage-check.ps1",
        "timeout": 30,
        "cwd": "${workspaceFolder}"
      }
    ]
  }
}
```

### test-coverage-check.ps1
PowerShell script that:
1. Reads hook input JSON from stdin
2. Detects file edit tools (create_file, replace_string_in_file, multi_replace_string_in_file)
3. Filters for API route files in `src/api/src/routes/*.ts` (excludes `*.spec.ts`, `common.ts`)
4. Extracts route handlers using regex: `router.(get|post|put|delete|patch)("path", ...)`
5. Maps route files to test describe blocks (`lists.ts` → "Todo List Routes", `items.ts` → "Todo Item Routes")
6. Checks if `routes.spec.ts` contains test cases for each route (method + path)
7. Reports missing tests with file name and route signature
8. Offers to generate test skeletons following [docs/testing-standards.md](../../docs/testing-standards.md)
9. Always exits 0 (non-blocking — warns, never blocks)

### package-change-alert.json
Defines the hook trigger for package.json edits:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "type": "command",
        "command": "pwsh -NoProfile -ExecutionPolicy Bypass -File .github/hooks/scripts/package-change-alert.ps1",
        "timeout": 15,
        "cwd": "${workspaceFolder}"
      }
    ]
  }
}
```

### package-change-alert.ps1
PowerShell script that:
1. Reads hook input JSON from stdin
2. Detects file edit tools (create_file, replace_string_in_file, multi_replace_string_in_file)
3. Filters for `package.json` files in `src/api/` or `src/web/` directories
4. Identifies which service(s) were affected (api, web, or both)
5. Builds a friendly reminder message with specific install commands
6. Provides multiple installation options (npm install per service, azd restore for all)
7. Includes dev server restart instructions for affected services
8. Offers to run install commands automatically (requires user confirmation)
9. Always exits 0 (non-blocking — informational only)

---

## Integration with Project Standards

These hooks enforce and automate the standards defined in [AGENTS.md](../../AGENTS.md) and [/docs/](../../docs/):

| Hook | Purpose | Enforces |
|------|---------|----------|
| **pre-commit** | Quality gate before commits | TypeScript compilation, lint (zero warnings), API tests, secrets scan, file naming |
| **post-edit** | Auto-format after edits | Consistent code style, indentation, semicolons |
| **pre-deploy** | Validate before Azure deployments | Azure auth, Bicep validation, environment config, secrets scan, resource providers |
| **standards-check** | Warn about semantic violations after edits | Request<> generics, try/catch, FC<Props>, no raw HTML, no stray `any`, test cleanup |
| **test-coverage-api** | Warn about missing route tests | Every route has integration test, testing standards applied consistently |
| **package-change-alert** | Remind to install dependencies after package.json changes | Dependencies always in sync, dev environments up to date, prevents "works on my machine" |

**Workflow with Skills:**
1. **During development:** 
   - Use [build-with-tests](../skills/build-with-tests/SKILL.md) skill to implement features
   - **post-edit hook** auto-formats your code as you work ✨
   - **package-change-alert hook** reminds you to install dependencies after package.json changes 📦
2. **Before committing:** 
   - Use [code-review-self-check](../skills/code-review-self-check/SKILL.md) skill to scan for anti-patterns
   - **standards-check hook** warns about semantic violations as you edit 🔍
   - **test-coverage-api hook** alerts if new routes lack tests 🧪
3. **At commit time:** 
   - **pre-commit hook** runs quality gates automatically 🛡️
4. **Before deploying:**
   - **pre-deploy hook** validates infrastructure and Azure config 🚀
5. **Before PR:** 
   - Use [feature-complete-checklist](../skills/feature-complete-checklist/SKILL.md) skill for final verification

**The Complete Agent Factory:**
- **📚 Standards:** AGENTS.md + /docs/ — Reference documentation
- **🤖 Assistants:** build-with-tests, code-review-self-check, feature-complete-checklist — Guide development
- **🛡️ Guardians:** pre-commit (blocks bad commits), post-edit (auto-fixes style), pre-deploy (validates Azure), standards-check (warns on violations), test-coverage-api (ensures tests exist), package-change-alert (reminds to install deps) — Enforce automatically

---

## Troubleshooting

### Hook not running?
- Ensure VS Code Copilot is updated
- Check `.github/hooks/` is in workspace root
- Verify PowerShell is available on PATH

### Post-edit hook not formatting?
- Check that edited file is in `src/` and is `.ts` or `.tsx`
- Verify `npm run lint` works manually in the service directory
- Check hook output in Copilot debug logs

### Pre-commit hook runs but always allows?
- Check that script is detecting git commit commands
- Add debug output to `pre-commit-check.ps1`

### Hook timeout?
- Increase `timeout` in hook JSON (pre-commit: 60s, post-edit: 30s, pre-deploy: 120s)
- Consider moving slow checks (tests) to CI/CD

### False positive on secrets scan?
- Add file pattern exceptions to script (line ~100 in pre-commit, line ~180 in pre-deploy)
- Secrets in `.env`, `config/default.json`, `*.example` are already excluded

### Pre-deploy hook blocks legitimate deployment?
- Run `azd provision --preview` to bypass validation and see what would deploy
- Check Azure CLI login: `az account show`
- Validate Bicep manually: `az bicep build --file infra/main.bicep`
- Run directly in terminal to bypass hook (not recommended)

### Azure resource providers warning?
- Register providers: `az provider register --namespace Microsoft.App`
- Wait 5-10 minutes for registration to complete
- Re-run deployment

---

## Related Documentation

- [VS Code Copilot Hooks Documentation](https://code.visualstudio.com/docs/copilot/customization/hooks)
- [AGENTS.md](../../AGENTS.md) — Project standards and non-negotiable rules
- [docs/infrastructure.md](../../docs/infrastructure.md) — Bicep and Azure deployment standards
- [agent-customization skill](c:\Users\tgads\AppData\Local\Programs\Microsoft VS Code\f6cfa2ea24\resources\app\extensions\copilot\assets\prompts\skills\agent-customization\SKILL.md) — Creating hooks, skills, and instructions
- [feature-complete-checklist skill](../skills/feature-complete-checklist/SKILL.md) — Manual pre-commit verification

---

**These hooks create a self-enforcing quality system** — once active, the agent (and you) cannot:
- 🛡️ Commit code that violates standards (pre-commit)
- ✨ Leave poorly formatted code (post-edit)
- 🚀 Deploy broken infrastructure (pre-deploy)
- 🔍 Ignore semantic violations (standards-check)
- 🧪 Forget to write tests for new routes (test-coverage-api)
- 📦 Miss dependency installations (package-change-alert)
