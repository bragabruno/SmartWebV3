# SmartWebV3 Design System

This package contains the shared design system and UI components for the SmartWebV3 platform.

## Overview

The design system provides a consistent set of design tokens, components, and utilities that ensure visual consistency across all SmartWebV3 applications including:
- Main orchestration platform
- Trade lead generator
- AI cold caller CRM

## Design Tokens

### Colors
- **Primary**: Blue color scale for primary actions and brand elements
- **Secondary**: Cyan color scale for secondary actions
- **Neutral**: Gray scale for text and backgrounds
- **Semantic**: Success (green), Warning (amber), Error (red), Info (blue)

### Typography
- **Font Families**: Inter for UI text, JetBrains Mono for code
- **Font Sizes**: Scale from xs (0.75rem) to 9xl (8rem)
- **Font Weights**: 100-900 scale
- **Line Heights**: Tight to loose spacing options

### Spacing
- Consistent spacing scale from 0 to 96 (0px to 24rem)
- Used for padding, margin, and gap utilities

### Other Tokens
- **Border Radius**: From none to full rounded
- **Shadows**: From subtle to dramatic elevation effects

## Components

### Basic Components
- **Button**: Primary interactive element with multiple variants
- **Input**: Text input fields with consistent styling
- **Label**: Form labels with proper accessibility
- **Badge**: Status indicators and tags
- **Card**: Container component with header, content, and footer sections
- **Separator**: Visual divider component
- **Icon**: Wrapper for Lucide React icons with size presets

### Component Variants

#### Button Variants
- `default`: Primary action button
- `secondary`: Secondary action button
- `destructive`: Dangerous actions (delete, remove)
- `outline`: Bordered button
- `ghost`: Minimal button for less prominent actions
- `link`: Text link styled as button

#### Button Sizes
- `sm`: Small button
- `default`: Standard size
- `lg`: Large button
- `icon`: Square icon-only button

## Usage

### Installation

```bash
npm install @smartwebv3/ui
```

### Import Components

```tsx
import { Button, Card, Input, Badge } from '@smartwebv3/ui'
```

### Import Styles

In your main application CSS file:
```css
@import '@smartwebv3/ui/styles';
```

### Example Usage

```tsx
import { Button, Card, CardHeader, CardTitle, CardContent } from '@smartwebv3/ui'
import { Plus } from '@smartwebv3/ui'

function LeadCard() {
  return (
    <Card>
      <CardHeader>
        <CardTitle>New Leads</CardTitle>
      </CardHeader>
      <CardContent>
        <Button>
          <Plus className="mr-2 h-4 w-4" />
          Add Lead
        </Button>
      </CardContent>
    </Card>
  )
}
```

### Using Design Tokens

```tsx
import { colors, spacing } from '@smartwebv3/ui'

// Access color values
const primaryColor = colors.primary[500]

// Use in styled components or inline styles
const customStyles = {
  padding: spacing[4],
  backgroundColor: colors.neutral[100]
}
```

### Utility Functions

The `cn` utility combines class names and handles conflicts:

```tsx
import { cn } from '@smartwebv3/ui'

<div className={cn(
  "base-classes",
  condition && "conditional-classes",
  className
)} />
```

## Customization

### Extending Components

Components are built with composition in mind:

```tsx
import { Button } from '@smartwebv3/ui'

function IconButton({ icon, children, ...props }) {
  return (
    <Button {...props}>
      {icon}
      {children}
    </Button>
  )
}
```

### Theme Customization

The design system supports light and dark themes via CSS custom properties. Theme switching is handled automatically based on the `.dark` class on the root element.

## Best Practices

1. **Consistency**: Always use design system components when available
2. **Accessibility**: Components include proper ARIA attributes and keyboard support
3. **Responsive**: Components are mobile-first and responsive by default
4. **Performance**: Components are optimized for performance with proper memoization

## Development

### Building the Package

```bash
npm run build
```

### Running Tests

```bash
npm run test
```

### Linting

```bash
npm run lint
```

## Contributing

When adding new components:
1. Follow the existing component structure
2. Include TypeScript types
3. Add proper documentation
4. Ensure accessibility compliance
5. Test across different screen sizes