# UI Components

Standards for UI component usage in the React frontend (`src/web/`).

## Core Rule

**ALL UI elements MUST use Fluent UI components.** Never create custom HTML-based components when a Fluent UI equivalent exists.

## Do's and Don'ts

| Instead of... | Use Fluent UI... |
|---|---|
| `<button>` | `<Button>` |
| `<input>` | `<Input>` or `<TextField>` |
| `<select>` | `<Dropdown>` or `<Select>` |
| `<ul>` / `<li>` | `<List>` |
| `<dialog>` | `<Dialog>` |
| `<span style="...">` | `<Text>` with variant props |
| Custom spinner/loader | `<Spinner>` |
| Custom icon | `<Icon>` from `@fluentui/react-icons` |
| Custom checkbox | `<Checkbox>` |
| Custom tooltip | `<Tooltip>` |

## Import Conventions

Use the `@fluentui/react-components` v9 package (already a project dependency):

```tsx
import { Button, Input, Text, Spinner } from '@fluentui/react-components';
import { AddRegular, DeleteRegular } from '@fluentui/react-icons';
```

## Theming

- Apply the app theme via `<FluentProvider theme={...}>` at the root (already configured in `App.tsx`).
- Do **not** override Fluent UI component styles with inline `style` props or CSS class overrides unless there is no alternative.
- Prefer `makeStyles` / `useStyles` from `@fluentui/react-components` when additional styling is unavoidable.

## Layout

Use Fluent UI layout primitives instead of raw `<div>` wrappers where possible:

```tsx
import { Stack } from '@fluentui/react'; // v8 Stack (used in existing code)
// OR
import { makeStyles, tokens } from '@fluentui/react-components'; // v9 tokens for spacing/layout
```

Maintain consistency with existing component patterns found in `src/web/src/components/`.

## Non-Negotiable

- **No custom-built UI primitives** (buttons, inputs, modals, icons, spinners, etc.).
- **No third-party UI libraries** (Material UI, Ant Design, Bootstrap, etc.) alongside Fluent UI.
- New components added to `src/web/src/components/` must compose exclusively from Fluent UI building blocks.
