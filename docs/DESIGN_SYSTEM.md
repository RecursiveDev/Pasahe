# Design System

This document outlines the design system and coding standards for the application's frontend. The goal is to establish a consistent, modern, and accessible user interface.

## 1. Color Palette

The color palette is designed to be clear, accessible, and modern. All primary color combinations meet WCAG 2.1 AA contrast ratios.

### Primary Palette

| Name      | Hex       | Usage                               |
| :-------- | :-------- | :---------------------------------- |
| **Primary** | `#0052CC` | Interactive elements, active states |
| **Neutral** | `#F4F5F7` | Backgrounds, borders, separators  |
| **Text**    | `#172B4D` | Primary text content                |

### Secondary/Accent Palette

These colors should be used purposefully to convey specific meanings to the user.

| Name      | Hex       | Usage                                     |
| :-------- | :-------- | :---------------------------------------- |
| **Success** | `#00875A` | Success messages, confirmations, validity |
| **Error**   | `#DE350B` | Error messages, destructive actions     |
| **Warning** | `#FFAB00` | Warnings, alerts                          |
| **Info**    | `#00B8D9` | Informational messages, highlights      |


## 2. Typography

A consistent typography scale is essential for readability and a clear visual hierarchy.

- **Font Family:** Roboto, sans-serif

### Typographic Scale

| Element         | Font Size (rem/px) | Font Weight | Line Height |
| :-------------- | :----------------- | :---------- | :---------- |
| **Heading 1 (H1)** | `2.5rem` (40px)    | 700 (Bold)  | 1.2         |
| **Heading 2 (H2)** | `2rem` (32px)      | 700 (Bold)  | 1.2         |
| **Heading 3 (H3)** | `1.5rem` (24px)    | 600 (Semi-Bold) | 1.3         |
| **Body**        | `1rem` (16px)      | 400 (Regular) | 1.5         |
| **Caption**     | `0.875rem` (14px)  | 400 (Regular) | 1.4         |
| **Button**      | `1rem` (16px)      | 500 (Medium) | 1           |

## 3. UI Primitives

UI primitives provide the foundational styles for spacing, borders, and shadows, ensuring a consistent and harmonious layout.

### Spacing

A consistent spacing scale based on a 4px grid is used for margins, padding, and positioning elements.

| Name      | Size  |
| :-------- | :---- |
| `space-1` | 4px   |
| `space-2` | 8px   |
| `space-3` | 12px  |
| `space-4` | 16px  |
| `space-5` | 24px  |
| `space-6` | 32px  |
| `space-7` | 48px  |
| `space-8` | 64px  |

### Border Radius

Standardized border-radius values create a consistent look for elements like buttons, inputs, and cards.

| Name           | Value | Usage                  |
| :------------- | :---- | :--------------------- |
| `border-radius-sm` | 4px   | Small components, tags |
| `border-radius-md` | 8px   | Buttons, inputs, cards |
| `border-radius-lg` | 16px  | Modals, larger panels  |
| `border-radius-full` | 9999px| Circular elements      |

### Shadows

Subtle shadows are used to create depth and elevation for interactive elements.

| Name         | Value                                   | Usage                                  |
| :----------- | :-------------------------------------- | :------------------------------------- |
| `shadow-sm`  | `0 1px 2px rgba(0, 0, 0, 0.05)`           | Subtle elevation for hovered elements  |
| `shadow-md`  | `0 4px 6px rgba(0, 0, 0, 0.1)`            | Default shadow for cards and modals    |
| `shadow-lg`  | `0 10px 15px rgba(0, 0, 0, 0.1)`          | Emphasized elevation for focused items |

## 4. Responsiveness

A mobile-first responsive strategy ensures a seamless user experience across all devices. The layout should be fluid and adapt to different screen sizes using the following breakpoints.

### Breakpoints

| Name    | Min-Width | Target Devices      |
| :------ | :-------- | :------------------ |
| `sm`    | 640px     | Small tablets, landscape phones |
| `md`    | 768px     | Tablets             |
| `lg`    | 1024px    | Laptops, small desktops |
| `xl`    | 1280px    | Large desktops      |

## 5. Frontend Coding Standards

To maintain a high level of code quality, consistency, and readability, the following coding standards are to be enforced across the Flutter codebase.

### Formatter: Dart Formatter

All Dart code MUST be formatted using the standard `dart format` command. This is the official formatter for the Dart language and ensures a single, consistent style. Most IDEs with Flutter support can be configured to format on save.

### Linter: Dart Analyze

The Dart static analyzer (`dart analyze`) will be used to identify potential errors, style issues, and other code smells. A shared `analysis_options.yaml` file should be used to configure the linter rules.

### Sample `analysis_options.yaml`

This configuration enables a strict set of rules for high-quality code. It should be placed at the root of the project.

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # --- Style Rules ---
    - always_declare_return_types
    - prefer_single_quotes
    - sort_child_properties_last
    - prefer_const_constructors
    - prefer_final_fields
    - prefer_final_locals
    - unnecessary_new
    - unnecessary_const

    # --- Error Rules ---
    - avoid_empty_else
    - avoid_relative_lib_imports
    - avoid_shadowing_type_parameters
    - no_duplicate_case_values
    - valid_regexps
```

## 6. Component Style Guide (Conceptual)

This section outlines the visual and behavioral characteristics of core UI components. These components should be built as reusable widgets using the design tokens defined above.

### Button

- **Visuals:**
  - **Background:** `Primary` color (`#0052CC`) for standard actions. `Error` color (`#DE350B`) for destructive actions.
  - **Text:** `Button` typography style. Text color should provide sufficient contrast with the background.
  - **Shape:** `border-radius-md` (8px).
  - **Elevation:** Use `shadow-sm` on hover/press to provide visual feedback.
- **Behavior:**
  - Should have clear hover, pressed, and disabled states.
  - Disabled state should have reduced opacity and ignore pointer events.

### Input

- **Visuals:**
  - **Background:** `Neutral` color (`#F4F5F7`).
  - **Text:** `Body` typography style.
  - **Shape:** `border-radius-md` (8px).
  - **Border:** A subtle border using a light shade of the `Neutral` color.
- **Behavior:**
  - **Focus:** Border should change to the `Primary` color.
  - **Error:** Border should change to the `Error` color, and an error message should be displayed below the input.

### Card

- **Visuals:**
  - **Background:** `Neutral` color (`#F4F5F7`).
  - **Shape:** `border-radius-md` (8px).
  - **Elevation:** `shadow-md` to lift the card off the background.
  - **Padding:** `space-4` (16px) internal padding.
- **Behavior:**
  - Can be used as a container for related content. Hover effects can be applied for interactive cards.

### Modal

- **Visuals:**
  - **Background:** `Neutral` color (`#F4F5F7`).
  - **Shape:** `border-radius-lg` (16px).
  - **Elevation:** `shadow-lg` to appear prominently above the main content.
  - **Overlay:** A semi-transparent dark overlay should cover the page content behind the modal.
- **Behavior:**
  - Should be dismissible by clicking the overlay or an explicit close button.
  - Should trap focus within the modal until it is closed.

### Navigation Bar

- **Visuals:**
  - **Background:** `Neutral` color (`#F4F5F7`).
  - **Elevation:** `shadow-md` to create a clear separation from the page content.
  - **Links:** `Body` typography. The active link should be highlighted with the `Primary` color.
- **Behavior:**
  - Provides primary navigation for the application. Should be responsive and adapt to different screen sizes.

## 7. Adoption Strategy

Adopting this design system should be an incremental process to avoid a high-risk rewrite. The following high-level strategy is recommended:

1.  **Phase 1: Foundation Setup**
    *   Centralize all design tokens (colors, typography, spacing, etc.) in a shared theme file.
    *   Configure the linter (`analysis_options.yaml`) and formatter to enforce the new coding standards.
    *   Run the formatter on the entire codebase to establish a consistent format baseline.

2.  **Phase 2: Build Core Components**
    *   Implement the core UI components (Button, Input, Card, etc.) as reusable Flutter widgets that consume the centralized design tokens.
    *   Write comprehensive tests for these new components to ensure they are robust and reliable.

3.  **Phase 3: Incremental Refactoring**
    *   As new features are built or existing features are updated, refactor the UI to use the new shared components instead of custom, one-off styles.
    *   Prioritize high-impact, frequently used screens for refactoring first.
    *   Avoid making purely stylistic changes in isolation; bundle them with functional updates to provide clear value.

4.  **Phase 4: Documentation and Evangelism**
    *   Maintain clear documentation for the design system and the component library.
    *   Encourage team buy-in by demonstrating the benefits of consistency, reusability, and improved development speed.