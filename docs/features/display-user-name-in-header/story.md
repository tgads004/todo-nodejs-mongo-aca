# User Story: Display Authenticated User's Real Name in Header

**Status:** ✅ Approved  
**Date:** May 30, 2026

---

**As an** authenticated todo application user  
**I want** to see my real name displayed in the application header  
**So that** I can confirm I'm logged in with the correct account and have a personalized experience

## Context

The application header currently displays "Sample User" as a hardcoded placeholder in [src/web/src/layout/header.tsx](src/web/src/layout/header.tsx#L51). The app already uses MSAL (Microsoft Authentication Library) with a redirect-based flow, and user profile information is available through the `useMsal()` hook's `accounts` array. Each AccountInfo object contains multiple identity claims including `name`, `preferred_username`, `username`, and additional claims in `idTokenClaims`. The existing Fluent UI Persona component in the header will remain unchanged in layout and styling.

## Acceptance Criteria

1. **Given** a user is authenticated and their Entra ID profile includes a display name, **when** the header renders, **then** the user's display name (from the `name` claim) appears in place of "Sample User"

2. **Given** a user is authenticated but their profile does not include a display name, **when** the header renders, **then** their email or username (from `preferred_username` or `username` claim) appears instead

3. **Given** a user is authenticated but neither display name nor email/username is available, **when** the header renders, **then** the text "User" appears as a safe default

4. **Given** the MSAL authentication flow has not yet completed (empty accounts array), **when** the header renders, **then** it either shows "User" as a default or the previous hardcoded value until authentication completes without throwing errors

5. **Given** the user's identity information is displayed, **when** comparing the header to the previous version, **then** all styling, spacing, layout, and other header components remain identical (no visual regressions)

6. **Given** various user types (internal employees, external/B2B users, guest accounts), **when** they authenticate, **then** the appropriate fallback is applied based on which claims are available in their account profile

7. **Given** a user is authenticated and their name is displayed, **when** assistive technology (screen readers) examines the header, **then** an appropriate ARIA label or accessible text announces the logged-in user's identity (e.g., "Logged in as [name]" or "Current user: [name]")

## Edge Cases to Consider

- **MSAL initialization timing**: Accounts array may be empty on initial render before `handleRedirectPromise()` completes
- **Multiple accounts**: The `accounts` array could theoretically contain multiple accounts — which one should be displayed?
- **Missing or malformed claims**: Some B2B or external users may have incomplete profile data in idTokenClaims
- **Re-authentication**: User logs out and logs in with a different account — should the name update immediately?
- **Stale state**: User's name changes in Entra ID but their active session has cached claims — acceptable to show old name until next login?
- **Screen reader announcement timing**: Should the name be announced immediately on page load or when focus reaches the header?

## Out of Scope

- Displaying the user's profile picture or avatar from Microsoft Entra ID (beyond the existing Persona component behavior)
- Adding a user profile dropdown, settings menu, or account management UI
- Implementing backend token validation (exploration findings note API doesn't validate tokens currently)
- Modifying the logout button or authentication flow
- Changing the Persona component's visual styling or size
- Real-time updates to name if changed in Entra ID during an active session
- Live region announcements when the user's identity changes during a session

## Open Questions

- Should we display a loading state (e.g., skeleton or "Loading...") while MSAL authentication is completing, or is showing "User" acceptable?
- If multiple accounts exist in the `accounts` array, should we always use `accounts[0]`, or is there a preferred account selection strategy?
- Do we need to log or report to Application Insights when fallback logic is triggered (e.g., missing display name claim)?
