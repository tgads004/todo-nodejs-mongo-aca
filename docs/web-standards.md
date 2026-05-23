# Web Standards

Standards and conventions for the React frontend located in `src/web/`.

## File Organization

```
src/web/src/
├── App.tsx                    # Root component — sets up providers and router
├── App.css / index.css        # Global CSS (keep minimal; prefer Fluent UI theming)
├── index.tsx                  # React DOM entry point
├── react-app-env.d.ts         # Global type augmentations
├── setupTests.ts              # Test setup (if unit tests are added)
├── reportWebVitals.ts         # Web Vitals integration
├── @types/
│   └── window.d.ts            # Augmentation of the Window interface
├── actions/
│   ├── actionCreators.ts      # Generic action creator helper types
│   ├── common.ts              # Action type constants
│   ├── itemActions.ts         # TodoItem async action creators
│   └── listActions.ts         # TodoList async action creators
├── components/
│   ├── telemetry.tsx          # App Insights telemetry wrapper component
│   ├── telemetryContext.ts    # Telemetry React context
│   ├── telemetryWithAppInsights.tsx  # HOC for App Insights page tracking
│   ├── todoContext.ts         # Application state context (AppContext)
│   ├── todoItemDetailPane.tsx # Detail pane for a selected TodoItem
│   ├── todoItemListPane.tsx   # List pane for TodoItems within a list
│   └── todoListMenu.tsx       # Sidebar list of TodoLists
├── config/
│   └── index.ts               # Runtime config (reads VITE_ env vars)
├── layout/
│   ├── header.tsx             # Top navigation bar
│   ├── layout.tsx             # Main layout shell
│   └── sidebar.tsx            # Left sidebar shell
├── models/
│   ├── applicationState.ts   # ApplicationState interface + getDefaultState()
│   ├── index.ts               # Re-exports
│   ├── todoItem.ts            # TodoItem interface
│   └── todoList.ts            # TodoList interface
├── pages/
│   └── homePage.tsx           # Home page (main app view)
├── reducers/
│   ├── index.ts               # Root reducer (combines all reducers)
│   ├── listsReducer.ts        # Reducer for the todo lists array
│   ├── selectedItemReducer.ts # Reducer for the currently selected item
│   └── selectedListReducer.ts # Reducer for the currently selected list
├── services/
│   ├── itemService.ts         # API calls for TodoItems
│   ├── listService.ts         # API calls for TodoLists
│   ├── restService.ts         # Abstract base REST service (axios)
│   └── telemetryService.ts    # App Insights event helpers
└── ux/
    ├── styles.ts              # Shared Fluent UI style objects
    └── theme.ts               # Fluent UI custom theme (DarkTheme)
```

**Rules:**
- New reusable components go in `src/web/src/components/`.
- New page-level components go in `src/web/src/pages/`.
- New model interfaces go in `src/web/src/models/`.
- New service classes go in `src/web/src/services/`.

## TypeScript Conventions

- The web app uses TypeScript **5.x** with strict mode enabled (`tsconfig.json`).
- All source files must be `.ts` or `.tsx`. No plain `.js`.
- JSX files must use the `.tsx` extension.
- Use `interface` for React component props. Use `type` for union types and aliases.
- Avoid `any`. Use `unknown` when the type is genuinely unknown and narrow with type guards.
- Import React explicitly only when using JSX features not covered by the automatic JSX transform. The project uses `@vitejs/plugin-react-swc` with the automatic runtime.

```typescript
// Good — typed props interface
interface TodoItemProps {
    item: TodoItem;
    onSave: (item: TodoItem) => void;
}

const TodoItemDetail: FC<TodoItemProps> = ({ item, onSave }) => { ... };
```

## Component Conventions

- Use **functional components** with the `FC<Props>` type annotation.
- Prefer named exports over default exports for components (exception: page components and `App.tsx` use default exports to align with routing conventions).
- Keep components focused. Extract sub-components when a single component exceeds ~150 lines or has multiple distinct visual responsibilities.
- Do not fetch data directly inside components. Data fetching is performed via **action creators** dispatched through the context — see [State Management](#state-management).

### Fluent UI

The app uses **Fluent UI React v8** (`@fluentui/react`). When building or modifying UI:

- Use Fluent UI components as the primary building blocks. Do not introduce a second component library.
- Apply the custom dark theme (`DarkTheme` from `src/web/src/ux/theme.ts`) via the existing `<ThemeProvider>` already mounted in `App.tsx`. Do not create inline styles that hardcode colors.
- Use `mergeStyles` or `IStyle` objects from `@fluentui/react/lib/Styling` for component-level styles. Avoid long inline `style` props.
- Icon usage: icons are registered globally via `initializeIcons()` in `App.tsx`. Call icons by name string; do not import icon SVGs directly.

```typescript
// Good — using Fluent UI component + styles object
import { Stack, Text, IconButton } from '@fluentui/react';
import { mergeStyles } from '@fluentui/react/lib/Styling';

const containerStyle = mergeStyles({ padding: '8px 16px' });

// Bad — raw HTML + inline color
<div style={{ padding: '8px 16px', color: '#ffffff' }}>
```

## State Management

The app uses React's `useReducer` with a single context (`TodoContext`) defined in `src/web/src/components/todoContext.ts`. There is no Redux or external state management library.

### Pattern

```
User action (click, input)
  → action creator function (src/web/src/actions/)
    → API service call (src/web/src/services/)
      → dispatch(action) → reducer → new state → re-render
```

### Adding New State

1. Add the new field to `ApplicationState` in `src/web/src/models/applicationState.ts` and set a default in `getDefaultState()`.
2. Add action type constants to `src/web/src/actions/common.ts`.
3. Add action creator functions (async thunk-like) to the appropriate file in `src/web/src/actions/`.
4. Add a case in the relevant reducer in `src/web/src/reducers/`.
5. Consume state via `useContext(TodoContext)` in the component.

### Accessing State in Components

```typescript
import { useContext } from 'react';
import { TodoContext } from '../components/todoContext';

const MyComponent: FC = () => {
    const { state, dispatch } = useContext(TodoContext);
    const lists = state.lists;
    // ...
};
```

## API Service Layer

All API communication goes through the services in `src/web/src/services/`. The abstract base class `RestService<T>` in `restService.ts` provides `getList`, `get`, `save`, `delete` methods. Concrete services (`listService.ts`, `itemService.ts`) extend it.

- Never use `fetch` or `axios` directly in a component. Always go through a service class.
- The API base URL is read from `src/web/src/config/index.ts`, which reads `import.meta.env.VITE_API_BASE_URL`. Do not hardcode URLs.
- Services return typed promises. Callers (action creators) handle errors and dispatch failure actions.

## Telemetry

Application Insights browser telemetry is initialized in `src/web/src/components/telemetry.tsx` and wrapped around the entire app. To track custom events:

```typescript
import { useTelemetry } from '../components/telemetryContext';

const { trackEvent } = useTelemetry();
trackEvent({ name: 'todo-item-completed' });
```

Do not call `appInsights` directly from components — use the telemetry context.

## Environment Variables

All environment variables consumed by the web app are prefixed with `VITE_` and read via `import.meta.env`. They are type-declared in `src/web/src/@types/window.d.ts` or accessed directly through `src/web/src/config/index.ts`.

| Variable | Description |
|---|---|
| `VITE_API_BASE_URL` | Backend API base URL |
| `VITE_APPLICATIONINSIGHTS_CONNECTION_STRING` | App Insights connection string |

Never use `process.env` in the web app — it is a Vite project and uses `import.meta.env`.

## Build and Lint

```bash
cd src/web

# Lint (zero warnings allowed)
npm run lint

# Build (TypeScript check + Vite bundle)
npm run build

# Local dev server
npm run dev
```

The ESLint config enforces `@typescript-eslint`, `eslint-plugin-react-hooks`, and `eslint-plugin-react-refresh`. Do not disable rules without a documented reason.

## Accessibility

- All interactive Fluent UI components handle keyboard navigation by default — do not override or disable this behavior.
- All images and icon-only buttons must have an `aria-label` or `alt` text.
- Do not use color alone to communicate state (e.g., error conditions must also use text or icons).
