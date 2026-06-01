# Technical Specification: Display Authenticated User's Real Name in Header

**Status:** ✅ Approved  
**Date:** May 30, 2026

---

## Overview
Replace the hardcoded "Sample User" text in the application header's Persona component with the authenticated user's display name dynamically retrieved from the MSAL authentication context, implementing a defensive fallback chain for missing or incomplete user profile data.

## User Story Reference
**As an** authenticated todo application user  
**I want** to see my real name displayed in the application header  
**So that** I can confirm I'm logged in with the correct account and have a personalized experience

## Current State
The header component at [src/web/src/layout/header.tsx](src/web/src/layout/header.tsx#L51) currently renders a Fluent UI `Persona` component with hardcoded text `"Sample User"`. The application already uses MSAL (`@azure/msal-react`) with a redirect-based authentication flow. User identity information is available through the `useMsal()` hook, which provides an `accounts` array containing `AccountInfo` objects with claims like `name`, `username`, and `idTokenClaims.preferred_username`.

## Data Model Changes
**None** — This feature requires no changes to data models, API contracts, or database schema. All required user identity information is already present in the MSAL authentication context.

## Process Flow

1. User completes authentication via MSAL redirect flow
2. `msalInstance.handleRedirectPromise()` processes the authentication response
3. MSAL populates the `accounts` array with user's `AccountInfo`
4. Header component renders and calls `useMsal()` hook
5. Header extracts the first account and retrieves display name using defensive fallback chain:
   - **Primary**: `account.name` (display name claim)
   - **Secondary**: `account.idTokenClaims?.preferred_username` (email/UPN)
   - **Tertiary**: `account.username` (username claim)
   - **Default**: `"User"` (safe fallback)
6. Header passes the computed name to the `Persona` component's `text` prop
7. Fluent UI Persona renders the user name with existing styling

## API Changes
**None** — This is a frontend-only feature. No backend endpoints, validation rules, or API contracts are modified.

## Frontend Changes

### Modified: `src/web/src/layout/header.tsx`

**Changes Required:**
1. Import `useMsal` hook from `@azure/msal-react`
2. Import `AccountInfo` type from `@azure/msal-browser`
3. Add helper function `getUserDisplayName(accounts: AccountInfo[]): string` that:
   - Returns `"User"` immediately if `accounts` is empty or undefined
   - Implements fallback chain: `name` → `preferred_username` → `username` → `"User"`
4. Inside `Header` component:
   - Call `const { accounts } = useMsal();`
   - Call `const displayName = getUserDisplayName(accounts);`
   - Replace hardcoded `text="Sample User"` with `text={displayName}`
5. Add accessibility: `aria-label={`Logged in as ${displayName}`}`

**Implementation Pattern:**
```typescript
import { useMsal } from '@azure/msal-react';
import type { AccountInfo } from '@azure/msal-browser';

/**
 * Extracts a display name for the authenticated user from MSAL account info.
 * Implements defensive fallback chain: name → preferred_username → username → "User"
 * @param accounts - MSAL accounts array from useMsal() hook
 * @returns Display name string (never undefined/null)
 */
const getUserDisplayName = (accounts: AccountInfo[]): string => {
    if (!accounts || accounts.length === 0) {
        return "User";
    }
    
    const account = accounts[0];
    
    return account.name 
        || account.idTokenClaims?.preferred_username 
        || account.username 
        || "User";
};

const Header: FC = (): ReactElement => {
    const { accounts } = useMsal();
    const displayName = getUserDisplayName(accounts);
    
    return (
        <Stack horizontal>
            {/* ... existing logo code ... */}
            <Stack.Item>
                <Stack horizontal styles={toolStackClass} grow={1}>
                    <IconButton aria-label="Settings" iconProps={{ iconName: "Settings", ...iconProps }} />
                    <IconButton aria-label="Help" iconProps={{ iconName: "Help", ...iconProps }} />
                    <Persona 
                        size={PersonaSize.size24} 
                        text={displayName}
                        aria-label={`Logged in as ${displayName}`}
                    />
                </Stack>
            </Stack.Item>
        </Stack>
    );
};
```

**Type Safety:**
- `AccountInfo` type is imported from `@azure/msal-browser` (already a project dependency)
- `idTokenClaims` is typed as `object` in MSAL; access `preferred_username` via optional chaining
- No `any` types; all variables explicitly typed
- Function signature uses TypeScript array type with explicit return type

**Styling:**
- **No visual changes** to Persona component size, spacing, or layout
- Existing `PersonaSize.size24` preserved
- Existing `toolStackClass` styles unchanged
- No new CSS classes or inline styles added

## Tests Required

Frontend unit tests are not currently implemented per [docs/testing-standards.md](docs/testing-standards.md).

### Manual Testing Scenarios

1. **AC #1**: Authenticate with user that has display name → Verify display name appears in header
2. **AC #2**: Authenticate with B2B user lacking display name → Verify email/username appears as fallback
3. **AC #3**: Test incomplete profile → Verify "User" appears as ultimate fallback
4. **AC #4**: Open app before auth completes → Verify no console errors and "User" displays initially
5. **AC #5**: Compare header visually → Verify layout, spacing, icon positions unchanged
6. **AC #6**: Test internal employee, external user, guest account → Verify appropriate fallback per account type
7. **AC #7**: Use screen reader (NVDA, JAWS, or Narrator) → Verify "Logged in as [name]" announcement

## Risks and Constraints

### MSAL Timing and Race Conditions
- **Issue**: On initial page load, `handleRedirectPromise()` may not have completed before Header first renders
- **Mitigation**: Defensive code handles empty array gracefully by returning `"User"`
- **Expected Behavior**: User briefly sees "User" text until MSAL completes initialization

### Multiple Accounts Edge Case
- **Decision**: Display name from first account (`accounts[0]`) only
- **Justification**: App uses redirect flow, which naturally results in single active account

### Stale Claims
- **Decision**: Accept stale claims until next authentication (industry-standard behavior)
- **Justification**: Forcing token refresh for display name updates adds complexity without meaningful UX benefit

### Performance Considerations
- `useMsal()` hook reads from MSAL context (React Context API) — no network calls
- `getUserDisplayName()` is a pure function with O(1) complexity
- No performance impact

### New Dependencies
**None** — All required dependencies are already present:
- `@azure/msal-react` (already installed)
- `@azure/msal-browser` (peer dependency)
- Fluent UI components (already used)

### Breaking Changes
**None** — This change is purely additive to the UI. No API contracts, data schemas, or component interfaces are modified.

### Accessibility Considerations
- **ARIA Label**: `aria-label={`Logged in as ${displayName}`}` added to Persona
- **Screen Reader Timing**: Name is announced when screen reader focus reaches the header region
- **Visual Focus**: Persona component is not focusable (not interactive) — accessible label is for context

## Files That Will Change

**Frontend:**
- [src/web/src/layout/header.tsx](src/web/src/layout/header.tsx) — Add `useMsal` hook, implement `getUserDisplayName` helper, replace hardcoded "Sample User"

**Total Impact**: ~10 lines changed/added; zero files deleted; zero new dependencies

## Implementation Order

1. **Modify `header.tsx`**:
   - Import `useMsal` and `AccountInfo` type
   - Add `getUserDisplayName` helper function above component
   - Call `useMsal()` hook inside `Header` component
   - Compute `displayName` using helper
   - Replace `text="Sample User"` with `text={displayName}`
   - Add `aria-label` for accessibility

2. **Verify Linting**:
   - Run `cd src/web && npm run lint`
   - Fix any ESLint errors (none expected)

3. **Verify Build**:
   - Run `cd src/web && npm run build`
   - Confirm TypeScript compilation succeeds

4. **Manual Testing**:
   - Start local development server (`npm run dev`)
   - Authenticate with test Entra ID user
   - Verify display name appears in header
   - Test fallback scenarios
   - Test screen reader announcement

5. **Visual Regression Check**:
   - Compare header layout to previous version
   - Confirm no unintended styling changes

## Acceptance Criteria Mapping

| AC | Implementation | Verification |
|---|---|---|
| **AC #1**: Display name appears when available | `account.name` is first fallback in chain | Manual test with user that has `name` claim |
| **AC #2**: Email/username appears when display name missing | `account.idTokenClaims?.preferred_username` and `account.username` in fallback chain | Manual test with B2B user lacking `name` claim |
| **AC #3**: "User" appears when all claims missing | Final fallback in chain returns `"User"` | Manual test with incomplete profile OR code inspection |
| **AC #4**: No errors when auth incomplete | `if (!accounts \|\| accounts.length === 0)` guard returns `"User"` immediately | Manual test by refreshing page during auth |
| **AC #5**: No visual regressions | No styling code modified; existing styles preserved | Side-by-side visual comparison |
| **AC #6**: Appropriate fallback per user type | Fallback chain tests availability of each claim dynamically | Manual test with different user types |
| **AC #7**: Screen reader announces name | `aria-label={`Logged in as ${displayName}`}` added to Persona | Manual test with NVDA/JAWS/Narrator |

## Code Diff Summary

**File**: `src/web/src/layout/header.tsx`

**Additions** (~9 lines):
```typescript
import { useMsal } from '@azure/msal-react';
import type { AccountInfo } from '@azure/msal-browser';

const getUserDisplayName = (accounts: AccountInfo[]): string => {
    if (!accounts || accounts.length === 0) return "User";
    const account = accounts[0];
    return account.name || account.idTokenClaims?.preferred_username || account.username || "User";
};

// Inside Header component:
const { accounts } = useMsal();
const displayName = getUserDisplayName(accounts);
```

**Modifications** (1 line):
```diff
- <Persona size={PersonaSize.size24} text="Sample User" />
+ <Persona size={PersonaSize.size24} text={displayName} aria-label={`Logged in as ${displayName}`} />
```

## Security Considerations

- **Token Exposure**: No tokens or sensitive claims are logged, stored, or exposed beyond MSAL's internal management
- **XSS Protection**: User display name is passed to Fluent UI `Persona` component's `text` prop, which internally sanitizes rendering (React's default XSS protection)
- **Data Leakage**: Display name is derived from authenticated user's own identity claims — no risk of displaying another user's information

## Rollback Plan

If critical issues are discovered post-deployment:

1. Revert [src/web/src/layout/header.tsx](src/web/src/layout/header.tsx) to previous commit
2. Restore hardcoded `text="Sample User"`
3. Redeploy web service via `azd deploy web`

**Rollback is low-risk** because:
- No database migrations or API changes to reverse
- No environment variable changes required
- Change is isolated to single component
