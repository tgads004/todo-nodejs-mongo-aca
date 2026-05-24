# Authorization Standards

All authentication and authorization in this application is handled exclusively by **Microsoft Entra External ID** via the **MSAL (Microsoft Authentication Library)**. No other auth methods (Basic Auth, API keys, custom JWT issuance, session cookies, etc.) are permitted.

## Non-Negotiable Rules

1. **MSAL only.** All user authentication flows MUST use MSAL. Never introduce alternative auth libraries or roll custom auth logic.
2. **No other auth methods.** Do not add Basic Auth, API key schemes, OAuth providers other than Entra ID, or any other authentication mechanism.
3. **API validates tokens.** Every protected Express route MUST validate the Bearer token from the `Authorization` header using Entra ID token validation middleware. Unauthenticated requests must be rejected with `401 Unauthorized`.
4. **No secrets in source.** Client IDs, tenant IDs, and client secrets must come from environment variables — never hardcoded.

## Frontend (React / MSAL)

- Use `@azure/msal-browser` and `@azure/msal-react` for all auth flows.
- Wrap the app in `MsalProvider` at the root (`src/web/src/index.tsx`).
- Use the `useMsal` hook or `AuthenticatedTemplate` / `UnauthenticatedTemplate` components to guard UI.
- Acquire tokens silently with `acquireTokenSilent`; fall back to `acquireTokenPopup` or `acquireTokenRedirect` on interaction-required errors.
- Store the MSAL configuration (clientId, authority, redirectUri) in `src/web/src/config/index.ts`, sourced from environment variables via Vite (`import.meta.env`).

## Routing Structure

When wiring MSAL into the React app, the provider and route hierarchy in `App.tsx` must follow this exact order:

1. `MsalProvider` is the outermost wrapper — it must wrap `BrowserRouter`
2. `/login` renders `LoginPage` directly, without `Layout` — it is a public route that must not import from any service file or trigger any API calls
3. All other routes render inside `AuthenticatedTemplate` wrapping `Layout`
4. `UnauthenticatedTemplate` redirects to `/login` using react-router `Navigate`
5. `Layout`, its existing child routes, and its `useEffect` calls must never be modified for auth concerns — the guard sits above it in `App.tsx`

```tsx
<MsalProvider instance={msalInstance}>
  <BrowserRouter>
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route path="/*" element={
        <>
          <AuthenticatedTemplate><Layout /></AuthenticatedTemplate>
          <UnauthenticatedTemplate><Navigate to="/login" replace /></UnauthenticatedTemplate>
        </>
      } />
    </Routes>
  </BrowserRouter>
</MsalProvider> 
```

## Backend (Express / Token Validation)

- Use `@azure/msal-node` or a standards-compliant JWT validation library (e.g., `passport-azure-ad` or `jwks-rsa` + `jsonwebtoken`) to validate incoming Bearer tokens on every protected route.
- Validation must verify: signature (via JWKS), `iss` (issuer), `aud` (audience), and token expiry.
- Attach a token validation middleware in `src/api/src/app.ts` before any protected route handler.
- Return `401 Unauthorized` for missing or invalid tokens; never expose token validation error details in the response body.
- Configuration (tenantId, clientId/audience) must be loaded via `getConfig()` from `src/api/src/config/index.ts`.

## Environment Variables

| Variable | Where used |
|---|---|
| `AZURE_CLIENT_ID` | Both — Entra app registration client ID |
| `AZURE_TENANT_ID` | API — Entra tenant for token issuer validation |
| `VITE_AZURE_CLIENT_ID` | Web — exposed to Vite build |
| `VITE_AZURE_AUTHORITY` | Web — External ID authority URL (`https://<tenant>.ciamlogin.com/<tenantId>`) |
| `VITE_REDIRECT_URI` | Web — post-login redirect URI |
