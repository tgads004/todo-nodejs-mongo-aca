---
name: feature-factory
description: 'End-to-end feature development workflow orchestrating seven subagents: codebase exploration, story writing, spec writing, backend/frontend implementation, acceptance testing, and quality validation with human approval gates. Use when: build a feature, ship a feature, implement end-to-end, run the full chain, feature factory, complete feature workflow, full development pipeline.'
argument-hint: 'A rough feature idea or requirement (e.g., "add ability to filter todo items by priority")'
user-invocable: true
---

# Feature Factory

Orchestrated end-to-end feature development workflow using seven specialized subagents with human approval checkpoints.

## When to Use

Invoke this skill when the user asks to:
- **Build a feature** from idea to implementation
- **Ship a feature** with full quality gates
- **Run the full chain** or **feature factory**
- **Implement end-to-end** with story, spec, code, and tests
- Execute the **complete feature workflow**

This skill is **NOT** for:
- Quick code changes or bug fixes (use relevant builder directly)
- Exploration only (use codebase-researcher)
- Changing existing implementations without new features

## Workflow Overview

```
1. Explore Codebase
   ↓
2. Write User Story
   ↓
3. ⚠️  HUMAN APPROVAL: Story ⚠️
   ↓
4. Write Technical Spec
   ↓
5. ⚠️  HUMAN APPROVAL: Spec ⚠️
   ↓
6. Build Backend + Unit Tests
   ↓
7. Build Frontend + Component Tests
   ↓
8. Write Acceptance Tests
   ↓
9. Validate Implementation
   ↓
10. [Loop if Critical Gaps Found]
   ↓
11. ⚠️  HUMAN APPROVAL: Final Review ⚠️
```

---

## Step-by-Step Execution

### Step 1: Explore the Codebase

**Agent:** `codebase-researcher`

**Objective:** Understand the current architecture, patterns, and relevant files before making any changes.

**Prompt:**
```
Explore the codebase to understand how [feature area] works. 
Identify:
- Existing patterns we should follow
- Files that will need changes
- Current architecture and conventions
- Any risks or constraints
```

**Output:** Exploration findings summarizing architecture, patterns, and recommendations.

---

### Step 2: Write User Story

**Agent:** `story-writer`

**Objective:** Transform the rough feature idea and exploration findings into a clear, testable user story with acceptance criteria.

**Prompt:**
```
Write a user story for this feature:
[User's feature description]

Use these exploration findings:
[Output from codebase-researcher]
```

**Output:** User story with:
- User story statement (As a... I want... So that...)
- Acceptance criteria (Given/When/Then)
- Edge cases and constraints
- Out-of-scope items
- Open questions

---

### Step 3: ⚠️ HUMAN APPROVAL CHECKPOINT — Story ⚠️

**Present the user story to the human and ask:**

> Here is the user story for **[feature name]**:
> 
> [Display story in formatted markdown]
> 
> **Please review and respond:**
> 1. ✅ **Approved** — Continue to technical spec
> 2. ✏️ **Changes Requested** — Describe what to modify
> 3. ❌ **Rejected** — Stop the workflow

#### Handle Outcomes:

**If Approved (✅):**
- Proceed to Step 4 (Write Technical Spec)

**If Changes Requested (✏️):**
- Collect the human's feedback
- Re-invoke `story-writer` with:
  ```
  Revise the user story based on this feedback:
  [Human's feedback]
  
  Original story:
  [Previous story]
  
  Exploration findings:
  [Original findings]
  ```
- Return to this checkpoint (repeat until approved or rejected)

**If Rejected (❌):**
- **STOP THE WORKFLOW**
- Summarize what was explored and documented:
  > The feature workflow has been stopped. Here's what we created:
  > - ✅ Codebase exploration findings
  > - ✅ Draft user story
  > 
  > The approved exploration findings are saved and can be used if you decide to resume later with a different approach.
- Do not proceed to technical spec

---

### Step 4: Write Technical Spec

**Agent:** `spec-writer`

**Objective:** Design the technical approach, API contracts, file changes, and implementation details.

**Prompt:**
```
Write a technical specification for this approved user story:
[Approved story]

Use these exploration findings:
[Output from codebase-researcher]
```

**Output:** Technical brief with:
- Files to modify/create
- API contracts (endpoints, request/response types)
- Data model changes
- Frontend components and state management
- Infrastructure changes (if any)
- Security considerations
- Risks and dependencies

---

### Step 5: ⚠️ HUMAN APPROVAL CHECKPOINT — Spec ⚠️

**Present the technical spec to the human and ask:**

> Here is the technical specification for **[feature name]**:
> 
> [Display spec in formatted markdown]
> 
> **Please review and respond:**
> 1. ✅ **Approved** — Continue to implementation
> 2. ✏️ **Changes Requested** — Describe what to modify
> 3. ❌ **Rejected** — Stop the workflow

#### Handle Outcomes:

**If Approved (✅):**
- Proceed to Step 6 (Build Backend)

**If Changes Requested (✏️):**
- Collect the human's feedback
- Re-invoke `spec-writer` with:
  ```
  Revise the technical specification based on this feedback:
  [Human's feedback]
  
  Original spec:
  [Previous spec]
  
  Approved user story:
  [Story]
  ```
- Return to this checkpoint (repeat until approved or rejected)

**If Rejected (❌):**
- **STOP THE WORKFLOW**
- Summarize what was created:
  > The feature workflow has been stopped. Here's what we created:
  > - ✅ Codebase exploration findings
  > - ✅ Approved user story
  > - ✅ Draft technical specification
  > 
  > The approved story is saved. You can resume later with a different technical approach or different implementation agent.
- Do not proceed to implementation

---

### Step 6: Build Backend

**Agent:** `backend-builder`

**Objective:** Implement backend API endpoints, models, routes, and unit tests according to the technical spec.

**Prompt:**
```
Implement the backend for this feature using the approved technical specification:
[Approved spec]
```

**Output:** Backend builder summary with:
- Files created/modified
- API contract summary (endpoints, types)
- Unit test coverage
- Any deviations from spec (with justification)

**Save the backend summary for Step 8 (Test Verifier).**

---

### Step 7: Build Frontend

**Agent:** `frontend-builder`

**Objective:** Implement React components, state management, API integration, and component tests according to the technical spec.

**Prompt:**
```
Implement the frontend for this feature using the approved technical specification and backend API contract:

**Technical Spec:**
[Approved spec]

**Backend API Contract:**
[Backend builder's API contract summary]
```

**Output:** Frontend builder summary with:
- Components created/modified
- State management changes
- API integration details
- Component test coverage (if applicable)
- Any deviations from spec (with justification)

**Save the frontend summary for Step 8 (Test Verifier).**

---

### Step 8: Write Acceptance Tests

**Agent:** `test-verifier`

**Objective:** Write integration/acceptance tests that verify all acceptance criteria from the user story.

**Prompt:**
```
Write acceptance tests for this feature:

**User Story:**
[Approved story with acceptance criteria]

**Technical Spec:**
[Approved spec]

**Backend Implementation Summary:**
[Backend builder output]

**Frontend Implementation Summary:**
[Frontend builder output]
```

**Output:** Test verifier report with:
- Acceptance tests created
- Coverage of acceptance criteria
- Test results (pass/fail)
- Any untestable criteria (with explanation)

**Save the test verifier report for Step 9 (Validator).**

---

### Step 9: Validate Implementation

**Agent:** `implementation-validator`

**Objective:** Perform comprehensive quality validation comparing implementation against story, spec, and standards.

**Prompt:**
```
Validate the implementation against the approved user story and technical specification:

**User Story:**
[Approved story]

**Technical Spec:**
[Approved spec]

**Test Verifier Report:**
[Test verifier output]

**Backend Summary:**
[Backend builder output]

**Frontend Summary:**
[Frontend builder output]
```

**Output:** Validation report grouped by severity:
- **🔴 Critical** — Blocks merge (missing acceptance criteria, security issues, data corruption risks)
- **🟡 Important** — Should fix before merge (incomplete error handling, missing edge cases)
- **🔵 Minor** — Can defer (style inconsistencies, minor optimizations)

---

### Step 10: Handle Critical Findings

**If the validator reports CRITICAL findings:**

1. **Identify the affected layer:**
   - Backend issues → Re-invoke `backend-builder`
   - Frontend issues → Re-invoke `frontend-builder`
   - Both → Re-invoke both builders sequentially

2. **Provide remediation prompt:**
   ```
   Fix these critical issues found during validation:
   
   **Critical Findings:**
   [List critical findings from validator]
   
   **Original Spec:**
   [Approved spec]
   
   **User Story:**
   [Approved story]
   ```

3. **Re-run validation pipeline:**
   - Re-invoke `test-verifier` (Step 8) with updated implementations
   - Re-invoke `implementation-validator` (Step 9)
   - Repeat until zero critical findings or human intervention requested

**If only Important or Minor findings:**
- Proceed to Step 11 (Final Human Review)
- Present findings as recommendations

---

### Step 11: ⚠️ HUMAN APPROVAL CHECKPOINT — Final Review ⚠️

**Present the validation results and ask:**

> **Feature implementation complete!**
> 
> **Summary:**
> - ✅ User story: [link to story]
> - ✅ Technical spec: [link to spec]
> - ✅ Backend implemented: [files changed]
> - ✅ Frontend implemented: [files changed]
> - ✅ Acceptance tests: [test coverage %]
> 
> **Validation Results:**
> - 🔴 Critical: 0
> - 🟡 Important: [count]
> - 🔵 Minor: [count]
> 
> [Display important and minor findings if any]
> 
> **Next steps:**
> 1. ✅ **Approve for PR** — Feature is ready to commit
> 2. ✏️ **Address findings first** — Fix important/minor issues before PR
> 3. 🔄 **Request changes** — Modify implementation
> 4. ❌ **Reject** — Do not proceed with this implementation

#### Handle Outcomes:

**If Approved for PR (✅):**
- Summarize the complete feature:
  > **Feature ready for pull request!**
  > 
  > **What was delivered:**
  > - User story with acceptance criteria
  > - Technical specification
  > - Backend implementation with unit tests
  > - Frontend implementation with components
  > - Acceptance tests with [X]% coverage
  > - Quality validation passed
  > 
  > **Next step:** Create a pull request with this changeset.

**If Address Findings First (✏️):**
- Route to appropriate builder to fix important/minor issues
- Re-run test-verifier and implementation-validator
- Return to this checkpoint

**If Request Changes (🔄):**
- Collect feedback and route to appropriate builder or spec-writer
- Follow the loop back pattern (re-test, re-validate)
- Return to this checkpoint

**If Rejected (❌):**
- **STOP THE WORKFLOW**
- Summarize what was created and ask if the user wants to:
  - Revert all changes
  - Keep exploration and story for future use
  - Pivot to a different approach

---

## Key Principles

### Human-in-the-Loop
- **Two mandatory approval gates:** Story and Spec (before implementation starts)
- **One final review gate:** Before opening PR
- **Change handling:** Always re-invoke the appropriate agent with feedback, never improvise changes

### Quality First
- **Zero critical findings** required before final approval
- **Important findings** should be addressed but human can override
- **Minor findings** are recommendations only

### Traceability
- **Always preserve artifacts:** Story, spec, builder summaries, test reports
- **Always cite sources:** Link to files, line numbers, and previous outputs
- **Always explain loops:** When re-invoking agents, state why and what changed

### Fail Fast
- **Reject early:** If story or spec is rejected, stop immediately
- **Don't guess:** If an agent needs clarification, ask the human
- **No silent failures:** Always report when an agent cannot complete its task

---

## Common Scenarios

### Scenario: User has very vague idea
1. Run `codebase-researcher` with exploratory questions
2. Use findings to help `story-writer` ask clarifying questions
3. Iterate on story until human approves

### Scenario: User rejects technical spec
1. Stop workflow after Step 5
2. Keep approved story intact
3. Human can resume later with manual spec-writer invocation or different approach

### Scenario: Critical findings in both backend and frontend
1. Fix backend first (re-invoke `backend-builder`)
2. Then fix frontend (re-invoke `frontend-builder` with updated backend contract)
3. Re-run `test-verifier` and `implementation-validator`
4. Repeat until zero critical findings

### Scenario: Human wants to skip approval gates
**Do not allow this.** Approval gates are non-negotiable for this workflow. If the user wants faster iteration, suggest using individual agents directly instead of feature-factory.

---

## Error Handling

### If a subagent fails:
1. **Report the failure** with the agent name and error message
2. **Ask the human** whether to:
   - Retry with the same prompt
   - Retry with modified prompt
   - Skip this agent and continue (if safe)
   - Abort the workflow

### If an approval checkpoint times out:
- **Do not assume approval** or make decisions on the human's behalf
- **Wait for explicit response** (approved / changes requested / rejected)

### If the workflow is interrupted mid-execution:
- **Summarize progress** clearly:
  - Which steps were completed
  - Which artifacts were created
  - Where to resume
- **Preserve all outputs** for potential resume

---

## Tips for Success

✅ **Do:**
- Read AGENTS.md and /docs/ standards before invoking any builders
- Provide complete context to each subagent (previous outputs, findings, decisions)
- Wait for human approval at each checkpoint
- Re-run validation after fixing critical issues
- Keep the human informed of progress

❌ **Don't:**
- Skip approval checkpoints "to save time"
- Make product decisions on behalf of the human
- Proceed after rejection
- Mix multiple features in one workflow run
- Invoke agents in parallel (strict sequential execution required)

---

## Success Criteria

A feature-factory run is successful when:
1. ✅ User story is approved by human
2. ✅ Technical spec is approved by human
3. ✅ Backend is implemented with unit tests
4. ✅ Frontend is implemented with components
5. ✅ Acceptance tests pass and cover all criteria
6. ✅ Validation reports zero critical findings
7. ✅ Human approves final implementation for PR

---

**End of Feature Factory Workflow**
