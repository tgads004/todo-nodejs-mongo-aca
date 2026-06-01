# Test Plan: Display Authenticated User's Real Name in Header

**Feature:** Display User Name in Header  
**Test Plan Created:** May 30, 2026  
**Test Status:** ⚠️ Manual Testing Only (No automated test infrastructure for frontend)

---

## Executive Summary

This test plan covers all acceptance criteria for the "Display Authenticated User's Real Name in Header" feature. Since the frontend currently has no unit test infrastructure (no Jest, no React Testing Library), this document provides:

1. **Manual test procedures** for immediate validation
2. **Future unit test specifications** for when test infrastructure is added
3. **Accessibility verification steps** per WCAG guidelines
4. **Coverage gap analysis** and recommendations

---

## Test Environment Setup

### Prerequisites

1. **Authentication configured**: Azure Entra ID app registration with valid client ID
2. **Test accounts available**:
   - Account with full display name (`name` claim)
   - Account without display name (relies on `preferred_username`)
   - Account with minimal profile data (requires `username` fallback)
   - External/B2B guest account
3. **Local development environment running**:
   ```bash
   cd src/web
   npm run dev
   ```
4. **Browser developer tools** open (Console, Network, Elements tabs)
5. **Screen reader** installed (NVDA on Windows, VoiceOver on macOS, or browser extension)

---

## Acceptance Criteria Test Coverage

### AC1: Display Name from `name` Claim

**Acceptance Criterion:**  
*Given* a user is authenticated and their Entra ID profile includes a display name,  
*When* the header renders,  
*Then* the user's display name (from the `name` claim) appears in place of "Sample User"

#### Manual Test Case: AC1-1

**Test ID:** AC1-1  
**Priority:** High  
**Test Type:** Manual

**Preconditions:**
- User account with populated `name` field in Entra ID
- Example: "John Doe"

**Test Steps:**
1. Navigate to the application URL
2. Complete the MSAL authentication flow (redirect to Entra ID and back)
3. Observe the header area after authentication completes
4. Locate the Persona component (right side of header, near Settings and Help icons)

**Expected Result:**
- Persona component displays "John Doe" (the `name` claim value)
- Text is visible and properly styled
- No console errors related to MSAL or authentication

**Actual Result:** _(To be filled during test execution)_

**Pass/Fail:** _(To be determined)_

**Notes:**
- Use browser DevTools → Application → Local Storage to inspect cached MSAL account data
- Console should show no errors or warnings related to `getUserDisplayName` function

---

### AC2: Fallback to Email/Username

**Acceptance Criterion:**  
*Given* a user is authenticated but their profile does not include a display name,  
*When* the header renders,  
*Then* their email or username (from `preferred_username` or `username` claim) appears instead

#### Manual Test Case: AC2-1

**Test ID:** AC2-1  
**Priority:** High  
**Test Type:** Manual

**Preconditions:**
- User account with NO `name` field but WITH `preferred_username` or `username`
- Example: `preferred_username` = "john.doe@contoso.com"

**Test Steps:**
1. Sign out any currently authenticated user
2. Authenticate with the test account (missing `name` claim)
3. Wait for authentication to complete
4. Observe the Persona component in the header

**Expected Result:**
- Persona displays the email address or username (e.g., "john.doe@contoso.com")
- Fallback is applied seamlessly without errors
- Layout and styling remain consistent with AC1

**Actual Result:** _(To be filled during test execution)_

**Pass/Fail:** _(To be determined)_

**Verification:**
- Open DevTools Console and execute:
  ```javascript
  // Check the accounts array in MSAL
  const msalInstance = window.msalInstance; // if exposed, or inspect localStorage
  console.log(msalInstance?.getAllAccounts());
  ```
- Confirm `name` is `null`/`undefined` but `preferred_username` or `username` exists

---

### AC3: Ultimate Fallback to "User"

**Acceptance Criterion:**  
*Given* a user is authenticated but neither display name nor email/username is available,  
*When* the header renders,  
*Then* the text "User" appears as a safe default

#### Manual Test Case: AC3-1

**Test ID:** AC3-1  
**Priority:** Medium  
**Test Type:** Manual

**Preconditions:**
- Simulated account with missing `name`, `preferred_username`, and `username` claims
- **Note:** This scenario is unlikely in production but can be simulated by mocking

**Test Steps:**
1. *(Developer simulation required)* Temporarily modify `getUserDisplayName` function to simulate empty claims:
   ```typescript
   // In header.tsx, temporarily override for testing
   const getUserDisplayName = (accounts: AccountInfo[]): string => {
       if (!accounts || accounts.length === 0) {
           return "User";
       }
       
       const account = accounts[0];
       // Simulate all claims missing
       return "User"; // Force fallback
   };
   ```
2. Save and let Vite hot-reload
3. Observe the header

**Expected Result:**
- Persona displays "User"
- No runtime errors or console warnings
- Application remains functional

**Actual Result:** _(To be filled during test execution)_

**Pass/Fail:** _(To be determined)_

**Revert:** Restore original `getUserDisplayName` implementation after test

---

### AC4: Pre-Authentication State (Empty Accounts Array)

**Acceptance Criterion:**  
*Given* the MSAL authentication flow has not yet completed (empty accounts array),  
*When* the header renders,  
*Then* it either shows "User" as a default or the previous hardcoded value until authentication completes without throwing errors

#### Manual Test Case: AC4-1

**Test ID:** AC4-1  
**Priority:** High  
**Test Type:** Manual

**Preconditions:**
- Fresh browser session (clear cookies, local storage, session storage)
- Application not yet authenticated

**Test Steps:**
1. Open browser in Incognito/Private mode
2. Navigate to application URL
3. **Immediately observe the header** before redirect to Entra ID
4. Note what displays in the Persona component during initial render
5. Complete authentication
6. Observe header after redirect back

**Expected Result:**
- **Before authentication:** Persona shows "User" (safe default)
- **No JavaScript errors** in console during initial render
- **After authentication:** Persona updates to actual user name (per AC1/AC2)
- No visual glitches or layout shifts

**Actual Result:** _(To be filled during test execution)_

**Pass/Fail:** _(To be determined)_

**Key Validation Points:**
- `getUserDisplayName` handles empty `accounts` array gracefully
- No `undefined` or `null` errors logged
- React does not crash or throw during initial render

---

### AC5: Visual Regression (No Styling Changes)

**Acceptance Criterion:**  
*Given* the user's identity information is displayed,  
*When* comparing the header to the previous version,  
*Then* all styling, spacing, layout, and other header components remain identical (no visual regressions)

#### Manual Test Case: AC5-1

**Test ID:** AC5-1  
**Priority:** High  
**Test Type:** Visual Regression (Manual)

**Preconditions:**
- Screenshot or visual reference of header before feature implementation
- OR: Review header with hardcoded "Sample User"

**Test Steps:**
1. Authenticate with a test account
2. Observe the header layout:
   - Logo and "ToDo" text (left side)
   - Settings icon button
   - Help icon button
   - Persona component
3. Measure spacing using browser DevTools (Elements → Computed):
   - Padding around Persona component
   - Margins between icons
   - Header height (48px per `toolStackClass`)
4. Inspect Persona component styles:
   - Size: `PersonaSize.size24`
   - Color: Should match theme
   - Font: Should match theme typography

**Expected Result:**
- Header layout identical to previous version
- All spacing matches original design
- No new margin/padding introduced by MSAL changes
- Icons remain properly aligned
- Header height: 48px (no change)
- Logo area width: 300px (no change)

**Actual Result:** _(To be filled during test execution)_

**Pass/Fail:** _(To be determined)_

**Visual Checklist:**
- ✅ Logo and "ToDo" text aligned left
- ✅ Settings icon visible and properly styled
- ✅ Help icon visible and properly styled
- ✅ Persona component visible and properly sized
- ✅ No layout shift when name loads
- ✅ No console errors or warnings

---

### AC6: Various User Types (Internal, External, B2B, Guest)

**Acceptance Criterion:**  
*Given* various user types (internal employees, external/B2B users, guest accounts),  
*When* they authenticate,  
*Then* the appropriate fallback is applied based on which claims are available in their account profile

#### Manual Test Case: AC6-1 (Internal Employee)

**Test ID:** AC6-1  
**Priority:** Medium  
**Test Type:** Manual

**Preconditions:**
- Internal employee account (e.g., john.doe@contoso.com)

**Test Steps:**
1. Authenticate with internal employee account
2. Observe Persona display name

**Expected Result:**
- Displays full name from `name` claim (e.g., "John Doe")
- Fallback not needed for standard corporate accounts

**Pass/Fail:** _(To be determined)_

---

#### Manual Test Case: AC6-2 (External B2B User)

**Test ID:** AC6-2  
**Priority:** Medium  
**Test Type:** Manual

**Preconditions:**
- External B2B user invited to tenant (e.g., partner@external.com)

**Test Steps:**
1. Authenticate with B2B user account
2. Check claims in MSAL account object (DevTools Console)
3. Observe Persona display name

**Expected Result:**
- If `name` claim exists: displays name
- If `name` missing: displays `preferred_username` (likely external email)
- If both missing: displays `username`
- If all missing: displays "User"

**Pass/Fail:** _(To be determined)_

---

#### Manual Test Case: AC6-3 (Guest Account)

**Test ID:** AC6-3  
**Priority:** Low  
**Test Type:** Manual

**Preconditions:**
- Guest account (e.g., guest_user@contoso.com)

**Test Steps:**
1. Authenticate with guest account
2. Observe Persona display name

**Expected Result:**
- Appropriate fallback applied based on available claims
- No errors or crashes
- Name displays consistently with other account types

**Pass/Fail:** _(To be determined)_

---

### AC7: Accessibility (Screen Reader Announcement)

**Acceptance Criterion:**  
*Given* a user is authenticated and their name is displayed,  
*When* assistive technology (screen readers) examines the header,  
*Then* an appropriate ARIA label or accessible text announces the logged-in user's identity (e.g., "Logged in as [name]" or "Current user: [name]")

#### Manual Test Case: AC7-1 (ARIA Label Verification)

**Test ID:** AC7-1  
**Priority:** High  
**Test Type:** Accessibility (Manual)

**Preconditions:**
- Screen reader software installed:
  - **Windows:** NVDA (free) or JAWS
  - **macOS:** VoiceOver (built-in)
  - **Browser extension:** WAVE, axe DevTools

**Test Steps:**
1. Authenticate with test account (e.g., "John Doe")
2. Enable screen reader
3. Navigate to the application header
4. Tab through header controls (Settings, Help, Persona)
5. Listen for screen reader announcement when Persona receives focus
6. Alternatively, inspect with axe DevTools or WAVE

**Expected Result:**
- Persona component announces: **"Logged in as John Doe"**
- OR similar accessible text like "Current user: John Doe"
- Announcement is clear and unambiguous
- ARIA label matches displayed text

**Actual Result:** _(To be filled during test execution)_

**Pass/Fail:** _(To be determined)_

**Technical Verification:**
1. Open DevTools → Elements
2. Inspect the Persona component
3. Verify `aria-label` attribute exists:
   ```html
   <div aria-label="Logged in as John Doe" ... >
   ```
4. Verify ARIA label updates when user changes (logout/login with different account)

---

#### Manual Test Case: AC7-2 (Keyboard Navigation)

**Test ID:** AC7-2  
**Priority:** Medium  
**Test Type:** Accessibility (Manual)

**Preconditions:**
- Authenticated user session

**Test Steps:**
1. Navigate to application
2. Press `Tab` key repeatedly to navigate through header controls
3. Observe focus indicators (visual outline)
4. Verify Persona component can receive focus
5. Verify focus order: Settings → Help → Persona (expected order)

**Expected Result:**
- Persona component is keyboard-accessible
- Focus indicator visible when Persona receives focus
- Focus order is logical (left to right)
- Tab navigation does not skip Persona component

**Pass/Fail:** _(To be determined)_

---

## Edge Cases Test Coverage

### Edge Case 1: Multiple Accounts in MSAL Cache

**Scenario:** MSAL `accounts` array contains multiple accounts

**Test Steps:**
1. Authenticate with first account
2. Add second account to MSAL cache (if multi-account flow supported)
3. Observe which name displays

**Expected Result:**
- Displays name from first account in array (`accounts[0]`)
- No errors or confusion
- Behavior is consistent

**Implementation Note:** Current code uses `accounts[0]`, which is correct.

---

### Edge Case 2: User Logs Out and Logs In with Different Account

**Scenario:** User switches accounts during session

**Test Steps:**
1. Authenticate with "John Doe"
2. Observe header displays "John Doe"
3. Logout (if logout button exists)
4. Authenticate with "Jane Smith"
5. Observe header updates to "Jane Smith"

**Expected Result:**
- Name updates immediately after re-authentication
- No stale data displayed
- MSAL cache is properly cleared on logout

---

### Edge Case 3: MSAL Initialization Delay

**Scenario:** Slow network causes delayed `handleRedirectPromise()` completion

**Test Steps:**
1. Open DevTools → Network tab
2. Throttle network to "Slow 3G"
3. Navigate to application (fresh session)
4. Observe header during authentication delay

**Expected Result:**
- Header displays "User" during delay (no crash)
- Updates to real name once authentication completes
- No visual glitches or multiple re-renders

---

### Edge Case 4: Malformed or Missing ID Token Claims

**Scenario:** ID token is valid but claims are incomplete

**Test Steps:**
1. *(Requires developer simulation or test tenant with incomplete user profiles)*
2. Authenticate with account missing standard claims
3. Observe fallback chain behavior

**Expected Result:**
- Application does not crash
- Fallback chain successfully resolves to "User"
- No `undefined` or `null` errors in console

---

## Future Unit Test Specifications

When frontend test infrastructure is added (Jest + React Testing Library), implement these unit tests:

### Unit Test File: `src/web/src/layout/header.test.tsx`

```typescript
import { render, screen } from '@testing-library/react';
import { MsalProvider } from '@azure/msal-react';
import { PublicClientApplication } from '@azure/msal-browser';
import Header from './header';

// Mock MSAL configuration
const msalConfig = {
    auth: {
        clientId: "test-client-id",
        authority: "https://login.microsoftonline.com/test-tenant-id"
    }
};

const mockPca = new PublicClientApplication(msalConfig);

describe('Header Component - User Name Display', () => {
    
    // Test AC1: Display name from 'name' claim
    it('should display user name from name claim when available', () => {
        const mockAccounts = [{
            homeAccountId: 'test-id',
            localAccountId: 'test-local-id',
            environment: 'login.windows.net',
            tenantId: 'test-tenant',
            username: 'john.doe@contoso.com',
            name: 'John Doe', // Primary claim
            idTokenClaims: {}
        }];

        // Mock useMsal hook
        jest.spyOn(require('@azure/msal-react'), 'useMsal').mockReturnValue({
            instance: mockPca,
            accounts: mockAccounts,
            inProgress: 'none'
        });

        render(
            <MsalProvider instance={mockPca}>
                <Header />
            </MsalProvider>
        );

        // Assert
        expect(screen.getByText('John Doe')).toBeInTheDocument();
        expect(screen.getByLabelText('Logged in as John Doe')).toBeInTheDocument();
    });

    // Test AC2: Fallback to preferred_username
    it('should display preferred_username when name is missing', () => {
        const mockAccounts = [{
            homeAccountId: 'test-id',
            localAccountId: 'test-local-id',
            environment: 'login.windows.net',
            tenantId: 'test-tenant',
            username: 'jane.smith@contoso.com',
            name: undefined, // No name claim
            idTokenClaims: {
                preferred_username: 'jane.smith@contoso.com'
            }
        }];

        jest.spyOn(require('@azure/msal-react'), 'useMsal').mockReturnValue({
            instance: mockPca,
            accounts: mockAccounts,
            inProgress: 'none'
        });

        render(
            <MsalProvider instance={mockPca}>
                <Header />
            </MsalProvider>
        );

        expect(screen.getByText('jane.smith@contoso.com')).toBeInTheDocument();
    });

    // Test AC2: Fallback to username
    it('should display username when name and preferred_username are missing', () => {
        const mockAccounts = [{
            homeAccountId: 'test-id',
            localAccountId: 'test-local-id',
            environment: 'login.windows.net',
            tenantId: 'test-tenant',
            username: 'bob@contoso.com', // Fallback to username
            name: undefined,
            idTokenClaims: {}
        }];

        jest.spyOn(require('@azure/msal-react'), 'useMsal').mockReturnValue({
            instance: mockPca,
            accounts: mockAccounts,
            inProgress: 'none'
        });

        render(
            <MsalProvider instance={mockPca}>
                <Header />
            </MsalProvider>
        );

        expect(screen.getByText('bob@contoso.com')).toBeInTheDocument();
    });

    // Test AC3: Ultimate fallback to "User"
    it('should display "User" when all claims are missing', () => {
        const mockAccounts = [{
            homeAccountId: 'test-id',
            localAccountId: 'test-local-id',
            environment: 'login.windows.net',
            tenantId: 'test-tenant',
            username: '', // Empty username
            name: undefined,
            idTokenClaims: {}
        }];

        jest.spyOn(require('@azure/msal-react'), 'useMsal').mockReturnValue({
            instance: mockPca,
            accounts: mockAccounts,
            inProgress: 'none'
        });

        render(
            <MsalProvider instance={mockPca}>
                <Header />
            </MsalProvider>
        );

        expect(screen.getByText('User')).toBeInTheDocument();
    });

    // Test AC4: Empty accounts array (pre-authentication)
    it('should display "User" when accounts array is empty', () => {
        jest.spyOn(require('@azure/msal-react'), 'useMsal').mockReturnValue({
            instance: mockPca,
            accounts: [], // Empty array
            inProgress: 'login'
        });

        render(
            <MsalProvider instance={mockPca}>
                <Header />
            </MsalProvider>
        );

        expect(screen.getByText('User')).toBeInTheDocument();
    });

    // Test AC5: Visual regression (component structure)
    it('should maintain header structure with all expected components', () => {
        const mockAccounts = [{
            homeAccountId: 'test-id',
            localAccountId: 'test-local-id',
            environment: 'login.windows.net',
            tenantId: 'test-tenant',
            username: 'test@contoso.com',
            name: 'Test User',
            idTokenClaims: {}
        }];

        jest.spyOn(require('@azure/msal-react'), 'useMsal').mockReturnValue({
            instance: mockPca,
            accounts: mockAccounts,
            inProgress: 'none'
        });

        const { container } = render(
            <MsalProvider instance={mockPca}>
                <Header />
            </MsalProvider>
        );

        // Verify structure
        expect(screen.getByText('ToDo')).toBeInTheDocument(); // Logo text
        expect(screen.getByLabelText('Add')).toBeInTheDocument(); // Settings icon
        expect(screen.getByLabelText('Logged in as Test User')).toBeInTheDocument(); // Persona
    });

    // Test AC7: Accessibility - ARIA label
    it('should have correct ARIA label with user name', () => {
        const mockAccounts = [{
            homeAccountId: 'test-id',
            localAccountId: 'test-local-id',
            environment: 'login.windows.net',
            tenantId: 'test-tenant',
            username: 'aria.test@contoso.com',
            name: 'ARIA Test User',
            idTokenClaims: {}
        }];

        jest.spyOn(require('@azure/msal-react'), 'useMsal').mockReturnValue({
            instance: mockPca,
            accounts: mockAccounts,
            inProgress: 'none'
        });

        render(
            <MsalProvider instance={mockPca}>
                <Header />
            </MsalProvider>
        );

        const personaElement = screen.getByLabelText('Logged in as ARIA Test User');
        expect(personaElement).toBeInTheDocument();
    });
});

// Unit tests for helper function
describe('getUserDisplayName Helper Function', () => {
    
    it('should return name claim when available', () => {
        const accounts = [{
            name: 'John Doe',
            username: 'john@contoso.com',
            idTokenClaims: { preferred_username: 'john.doe@contoso.com' }
        }];
        
        const result = getUserDisplayName(accounts);
        expect(result).toBe('John Doe');
    });

    it('should return preferred_username when name is missing', () => {
        const accounts = [{
            name: undefined,
            username: 'jane@contoso.com',
            idTokenClaims: { preferred_username: 'jane.smith@contoso.com' }
        }];
        
        const result = getUserDisplayName(accounts);
        expect(result).toBe('jane.smith@contoso.com');
    });

    it('should return username when name and preferred_username are missing', () => {
        const accounts = [{
            name: undefined,
            username: 'bob@contoso.com',
            idTokenClaims: {}
        }];
        
        const result = getUserDisplayName(accounts);
        expect(result).toBe('bob@contoso.com');
    });

    it('should return "User" when all claims are missing', () => {
        const accounts = [{
            name: undefined,
            username: '',
            idTokenClaims: {}
        }];
        
        const result = getUserDisplayName(accounts);
        expect(result).toBe('User');
    });

    it('should return "User" when accounts array is empty', () => {
        const result = getUserDisplayName([]);
        expect(result).toBe('User');
    });

    it('should return "User" when accounts is null or undefined', () => {
        expect(getUserDisplayName(null)).toBe('User');
        expect(getUserDisplayName(undefined)).toBe('User');
    });
});
```

---

## Required Test Dependencies (Future)

To implement the unit tests above, add these dependencies to `src/web/package.json`:

```json
{
  "devDependencies": {
    "@testing-library/react": "^14.0.0",
    "@testing-library/jest-dom": "^6.1.5",
    "@testing-library/user-event": "^14.5.1",
    "jest": "^29.7.0",
    "jest-environment-jsdom": "^29.7.0",
    "@types/jest": "^29.5.10",
    "ts-jest": "^29.1.1"
  },
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage"
  }
}
```

Create `jest.config.js` in `src/web/`:

```javascript
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'jsdom',
  setupFilesAfterEnv: ['<rootDir>/src/setupTests.ts'],
  moduleNameMapper: {
    '\\.(css|less|scss|sass)$': 'identity-obj-proxy',
  },
  collectCoverageFrom: [
    'src/**/*.{ts,tsx}',
    '!src/**/*.d.ts',
    '!src/index.tsx',
    '!src/reportWebVitals.ts',
  ],
  testMatch: [
    '<rootDir>/src/**/__tests__/**/*.{ts,tsx}',
    '<rootDir>/src/**/*.{spec,test}.{ts,tsx}',
  ],
};
```

---

## Coverage Gap Analysis

### Current Status: ⚠️ No Automated Tests

| Gap | Impact | Recommendation | Priority |
|-----|--------|---------------|----------|
| **No frontend unit test infrastructure** | All acceptance criteria can only be tested manually | Install Jest + React Testing Library per specifications above | **High** |
| **No E2E test framework** | Cannot automate full authentication flow | Consider Playwright or Cypress for E2E tests | Medium |
| **No visual regression tooling** | AC5 (visual regression) requires manual inspection | Consider Percy, Chromatic, or BackstopJS | Low |
| **No accessibility automation** | AC7 tested manually with screen readers | Integrate axe-core with Jest (jest-axe) | Medium |
| **Manual testing bottleneck** | Regression testing is time-consuming and error-prone | Prioritize unit test infrastructure installation | **High** |

### Immediate Action Items

1. **Install test dependencies** (30 minutes)
   - Add packages listed in "Required Test Dependencies" section
   - Create `jest.config.js`
   - Update `setupTests.ts` to import `@testing-library/jest-dom`

2. **Implement unit tests** (2-3 hours)
   - Create `src/web/src/layout/header.test.tsx`
   - Implement all test cases from "Future Unit Test Specifications"
   - Run `npm test` to verify all pass

3. **Add accessibility testing** (1 hour)
   - Install `jest-axe`
   - Add automated accessibility checks to unit tests
   - Verify ARIA labels programmatically

4. **Set up CI/CD integration** (1 hour)
   - Add `npm test` to GitHub Actions workflow
   - Require tests to pass before merge
   - Track coverage over time

---

## Manual Testing Execution Report

### Test Execution Summary

| Test ID | Acceptance Criterion | Status | Pass/Fail | Notes |
|---------|---------------------|--------|-----------|-------|
| AC1-1 | Display name from `name` claim | 🔲 Not Run | - | Requires manual execution |
| AC2-1 | Fallback to email/username | 🔲 Not Run | - | Requires manual execution |
| AC3-1 | Ultimate fallback to "User" | 🔲 Not Run | - | Requires developer simulation |
| AC4-1 | Pre-authentication state | 🔲 Not Run | - | Requires manual execution |
| AC5-1 | Visual regression check | 🔲 Not Run | - | Requires manual execution |
| AC6-1 | Internal employee account | 🔲 Not Run | - | Requires manual execution |
| AC6-2 | External B2B user account | 🔲 Not Run | - | Requires manual execution |
| AC6-3 | Guest account | 🔲 Not Run | - | Requires manual execution |
| AC7-1 | ARIA label verification | 🔲 Not Run | - | Requires screen reader |
| AC7-2 | Keyboard navigation | 🔲 Not Run | - | Requires manual execution |

**Legend:**  
🔲 Not Run | ✅ Pass | ❌ Fail | ⚠️ Partial Pass

### Test Execution Instructions

1. **Assign tester**: Designate QA engineer or developer for manual testing
2. **Prepare test accounts**: Create or identify test accounts for each scenario
3. **Execute tests**: Follow test steps for each test case
4. **Record results**: Fill in "Actual Result" and "Pass/Fail" columns
5. **Log defects**: Create GitHub issues for any failures
6. **Update status**: Mark each test ID as ✅ Pass, ❌ Fail, or ⚠️ Partial Pass

---

## Acceptance Criteria Coverage Summary

| Criterion | Test Cases | Manual Coverage | Automated Coverage (Future) | Status |
|-----------|-----------|----------------|---------------------------|--------|
| **AC1**: Display name from `name` claim | AC1-1, Unit Tests | ✅ Full | ✅ Full | Ready to test |
| **AC2**: Fallback to email/username | AC2-1, Unit Tests | ✅ Full | ✅ Full | Ready to test |
| **AC3**: Ultimate fallback to "User" | AC3-1, Unit Tests | ✅ Full | ✅ Full | Ready to test |
| **AC4**: Pre-authentication state | AC4-1, Unit Tests | ✅ Full | ✅ Full | Ready to test |
| **AC5**: Visual regression | AC5-1 | ✅ Manual Only | ⚠️ Partial (structure only) | Ready to test |
| **AC6**: Various user types | AC6-1, AC6-2, AC6-3 | ✅ Full | ✅ Full | Ready to test |
| **AC7**: Accessibility | AC7-1, AC7-2, Unit Tests | ✅ Full | ✅ Full (with jest-axe) | Ready to test |

**Overall Coverage:**  
- ✅ **100% manual test coverage** for all acceptance criteria
- ⚠️ **0% automated test coverage** (no test infrastructure installed)
- 🎯 **100% potential automated coverage** (when test infrastructure is added)

---

## Recommendations

### Short-Term (Next Sprint)

1. **Execute manual tests** using this test plan
2. **Document any defects** found during manual testing
3. **Validate accessibility** with real screen readers (NVDA, VoiceOver)

### Medium-Term (Next 2-4 Weeks)

1. **Install Jest + React Testing Library** per specifications in this document
2. **Implement unit tests** for this feature (copy from "Future Unit Test Specifications")
3. **Add test script** to CI/CD pipeline
4. **Establish coverage baseline** (target: 80%+ for new components)

### Long-Term (Next Quarter)

1. **Add E2E test framework** (Playwright or Cypress) for full authentication flows
2. **Integrate visual regression testing** (Percy, Chromatic) for AC5 automation
3. **Implement automated accessibility testing** (jest-axe, axe-core)
4. **Establish testing policy**: All new components require unit tests before merge

---

## Appendix A: Accessibility Testing Tools

### Screen Readers
- **Windows:** [NVDA (Free)](https://www.nvaccess.org/download/)
- **macOS:** VoiceOver (built-in, press Cmd+F5)
- **Linux:** Orca

### Browser Extensions
- **axe DevTools**: [Chrome](https://chrome.google.com/webstore/detail/axe-devtools/lhdoppojpmngadmnindnejefpokejbdd) | [Firefox](https://addons.mozilla.org/en-US/firefox/addon/axe-devtools/)
- **WAVE**: [Chrome](https://chrome.google.com/webstore/detail/wave-evaluation-tool/jbbplnpkjmmeebjpijfedlgcdilocofh) | [Firefox](https://addons.mozilla.org/en-US/firefox/addon/wave-accessibility-tool/)
- **Lighthouse**: Built into Chrome DevTools (Audits tab)

### Command-Line Tools
- **axe-core CLI**: `npm install -g @axe-core/cli`
- **pa11y**: `npm install -g pa11y`

---

## Appendix B: MSAL Account Object Structure

For reference, here's a typical MSAL `AccountInfo` object structure:

```typescript
interface AccountInfo {
    homeAccountId: string;
    environment: string;
    tenantId: string;
    username: string; // Usually email address
    localAccountId: string;
    name?: string; // Display name (may be undefined)
    idTokenClaims?: {
        aud?: string;
        iss?: string;
        iat?: number;
        exp?: number;
        name?: string;
        preferred_username?: string;
        oid?: string;
        sub?: string;
        tid?: string;
        // ... other claims
    };
}
```

**Key Claims for This Feature:**
1. `account.name` — Primary display name (may be `undefined`)
2. `account.idTokenClaims?.preferred_username` — Email address (fallback)
3. `account.username` — Username (secondary fallback)
4. If all are missing/empty → "User" (ultimate fallback)

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | May 30, 2026 | Test Verifier Agent | Initial test plan creation |

---

## Approval Signatures

| Role | Name | Signature | Date |
|------|------|-----------|------|
| QA Lead | _(Pending)_ | | |
| Product Owner | _(Pending)_ | | |
| Development Lead | _(Pending)_ | | |

---

**END OF TEST PLAN**
