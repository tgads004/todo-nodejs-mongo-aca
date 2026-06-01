# Feature Documentation

This directory contains comprehensive documentation for all features implemented in the todo application. Each feature is organized in its own subdirectory with standardized documentation structure.

## Directory Structure

```
docs/features/
├── README.md                          # This file - features index
└── <feature-name>/
    ├── README.md                      # Feature summary and quick links
    ├── story.md                       # User story with acceptance criteria
    ├── spec.md                        # Technical specification
    ├── test-plan.md                   # Test procedures and coverage
    ├── decisions.md                   # (Optional) Architecture decisions
    └── screenshots/                   # (Optional) Visual assets
        ├── before.png
        └── after.png
```

## Features

### ✅ Display User Name in Header
**Path:** [display-user-name-in-header/](./display-user-name-in-header/)  
**Status:** Implemented & Tested  
**Date:** May 30, 2026

Replace hardcoded "Sample User" with authenticated user's real display name from Microsoft Entra ID, with intelligent fallback handling and accessibility support.

**Quick Links:**
- [Feature Overview](./display-user-name-in-header/README.md)
- [User Story](./display-user-name-in-header/story.md)
- [Technical Spec](./display-user-name-in-header/spec.md)
- [Test Plan](./display-user-name-in-header/test-plan.md)

---

## Documentation Standards

### When to Create a Feature Folder

Create a new feature directory when:
- Implementing a new user-facing capability
- Making significant architectural changes
- Building a feature that requires approval gates
- Creating functionality that needs comprehensive testing

### Required Documents

Each feature directory **must** contain:
1. **README.md** — Feature summary, links, implementation details, and metrics
2. **story.md** — User story with acceptance criteria and context
3. **spec.md** — Technical specification with implementation details
4. **test-plan.md** — Test procedures, coverage, and results

### Optional Documents

Additional documents based on feature complexity:
- **decisions.md** — Architecture Decision Records (ADRs) for significant design choices
- **screenshots/** — Visual assets showing before/after states, mockups, or UI flows
- **api-contracts.md** — Detailed API endpoint specifications (for backend features)
- **migrations.md** — Database migration notes and rollback procedures

### Naming Conventions

**Feature Directory Names:**
- Use lowercase with hyphens (kebab-case)
- Be descriptive but concise
- Examples: `display-user-name-in-header`, `bulk-complete-items`, `offline-sync`

**Document Names:**
- Standard names: `README.md`, `story.md`, `spec.md`, `test-plan.md`
- Custom documents: Use kebab-case (e.g., `api-contracts.md`, `decisions.md`)

---

## Creating a New Feature

### 1. Use the Feature Factory Workflow

The recommended way to create a new feature is through the feature-factory orchestrated workflow:

```
Ask the agent: "Build a feature for [description]"
```

This will:
1. Explore the codebase
2. Write a user story (with approval gate)
3. Write technical spec (with approval gate)
4. Implement backend
5. Implement frontend
6. Write acceptance tests
7. Validate implementation
8. Generate all documentation

### 2. Manual Feature Creation

If creating documentation manually:

```bash
# 1. Create feature directory
mkdir docs/features/your-feature-name

# 2. Create required documents
touch docs/features/your-feature-name/README.md
touch docs/features/your-feature-name/story.md
touch docs/features/your-feature-name/spec.md
touch docs/features/your-feature-name/test-plan.md

# 3. (Optional) Add screenshots directory
mkdir docs/features/your-feature-name/screenshots
```

### 3. Update This Index

After creating a new feature, add it to the **Features** section above with:
- Feature name and path
- Status (In Progress, Implemented & Tested, Deprecated)
- Completion date
- Brief description
- Links to key documents

---

## Feature Statuses

- **✅ Implemented & Tested** — Feature is complete, tested, and deployed
- **🚧 In Progress** — Feature is under active development
- **📋 Planned** — Feature is approved but not started
- **🔄 Iterating** — Feature is being refined based on feedback
- **❌ Deprecated** — Feature has been removed or replaced
- **⏸️ On Hold** — Feature development is paused

---

## Best Practices

### Documentation Quality
- Write for future maintainers who weren't part of the original implementation
- Include code examples and specific file references with line numbers
- Document both what was done and why (rationale for design decisions)
- Keep acceptance criteria testable and measurable

### Test Coverage
- Every feature should have a test plan with manual or automated procedures
- Include test results and coverage metrics in README.md
- Document edge cases and known limitations

### Traceability
- Link between story → spec → implementation → tests
- Reference related documentation (auth-standards.md, web-standards.md, etc.)
- Include rollback procedures for safe deployment

### Maintenance
- Update feature status when changes are made
- Archive deprecated features (move to `docs/features/archived/`)
- Keep README.md up-to-date with latest metrics and links

---

## Related Documentation

- [docs/architecture.md](../architecture.md) — Overall system architecture
- [docs/api-standards.md](../api-standards.md) — Backend coding standards
- [docs/web-standards.md](../web-standards.md) — Frontend coding standards
- [docs/testing-standards.md](../testing-standards.md) — Testing requirements
- [docs/infrastructure.md](../infrastructure.md) — Deployment and infrastructure
- [AGENTS.md](../../AGENTS.md) — AI agent instructions and standards

---

**Last Updated:** May 30, 2026
