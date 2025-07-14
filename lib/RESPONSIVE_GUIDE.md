# ResponsiveScaler Documentation

## Overview

The ResponsiveScaler system provides automatic scaling of UI elements based on screen width, allowing your Flutter app to look great on both mobile and desktop/web platforms.

## Key Features

- ✅ **Automatic Scaling**: Text, icons, and spacing scale based on screen width
- ✅ **Center & Constrain**: Content centers and constrains on wide screens
- ✅ **Mobile Preserved**: Mobile layouts remain unchanged (scale factor 1.0)
- ✅ **Easy Integration**: Drop-in replacement for existing widgets
- ✅ **Flexible Configuration**: Customizable max width and scaling behavior

## Scale Factors by Screen Width

| Screen Width | Device Type | Scale Factor | Example Font 16px becomes |
|--------------|-------------|--------------|---------------------------|
| 0-600px      | Mobile      | 1.0          | 16px (unchanged)          |
| 600-900px    | Tablet      | 1.0-1.2      | 16px-19.2px              |
| 900-1400px   | Desktop     | 1.2-1.5      | 19.2px-24px              |
| 1400px+      | Large       | 1.5          | 24px                     |

## Basic Usage

### 1. Wrap Your Screen with ResponsiveScaler

```dart
import 'responsive_scaler.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ResponsiveScaler(
      maxWidth: 1200, // Optional: constrains content width on large screens
      child: Scaffold(
        // Your existing content
        body: MyContent(),
      ),
    );
  }
}
```

### 2. Use Responsive Widgets

Replace standard widgets with responsive versions:

#### Text → RText
```dart
// Before
Text(
  'Hello World',
  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
)

// After  
RText(
  'Hello World',
  fontSize: 18,
  fontWeight: FontWeight.bold,
)
```

#### Icon → RIcon
```dart
// Before
Icon(Icons.star, size: 24, color: Colors.amber)

// After
RIcon(Icons.star, size: 24, color: Colors.amber)
```

#### SizedBox → RSpacing
```dart
// Before
const SizedBox(height: 16)
const SizedBox(width: 12)

// After
RSpacing.height(16)
RSpacing.width(12)
```

#### EdgeInsets → RPadding
```dart
// Before
Padding(
  padding: const EdgeInsets.all(16),
  child: child,
)

// After
Padding(
  padding: RPadding.all(context, 16),
  child: child,
)
```

### 3. Manual Scaling with Context Extensions

```dart
// Get scale factor
double scale = context.scaleFactor;

// Scale any value manually
double scaledFont = context.scaleFont(16);
double scaledIcon = context.scaleIcon(24);
double scaledSpacing = context.scaleSpacing(12);
double scaledDimension = context.scaleDimension(100);

// Device type checks
bool isMobile = context.isMobile;    // <= 600px
bool isTablet = context.isTablet;    // 600-900px  
bool isDesktop = context.isDesktop;  // > 900px

// Screen width
double width = context.screenWidth;
```

## Advanced Usage

### Custom Container with Responsive Properties

```dart
Container(
  width: context.scaleDimension(200),
  height: context.scaleDimension(100),
  padding: RPadding.all(context, 16),
  margin: RPadding.symmetric(context, horizontal: 20, vertical: 10),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(context.scaleSpacing(12)),
    boxShadow: [
      BoxShadow(
        blurRadius: context.scaleSpacing(8),
        offset: Offset(0, context.scaleSpacing(4)),
      ),
    ],
  ),
  child: RText(
    'Responsive Container',
    fontSize: 16,
    fontWeight: FontWeight.w600,
  ),
)
```

### Responsive Grid Layout

```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: context.isMobile ? 2 : context.isTablet ? 3 : 4,
    crossAxisSpacing: context.scaleSpacing(12),
    mainAxisSpacing: context.scaleSpacing(12),
  ),
  itemBuilder: (context, index) => MyGridItem(),
)
```

### Conditional Layout Based on Screen Size

```dart
if (context.isMobile) {
  return Column(children: widgets);
} else {
  return Row(children: widgets);
}
```

## Migration Guide

### Step 1: Add ResponsiveScaler to Screens

Wrap your main screens:
- AdminScreen ✅ (already applied)
- UserScreen ✅ (already applied)  
- UserTransactionHistoryScreen ✅ (already applied)

### Step 2: Convert Existing Widgets

Replace these widgets systematically:

| Original | Responsive Alternative |
|----------|----------------------|
| `Text()` | `RText()` |
| `Icon()` | `RIcon()` |
| `SizedBox()` | `RSpacing()` |
| `EdgeInsets.all()` | `RPadding.all(context, )` |
| `EdgeInsets.symmetric()` | `RPadding.symmetric(context, )` |

### Step 3: Update Dimensions

For any hardcoded dimensions:

```dart
// Before
Container(width: 200, height: 100)

// After  
Container(
  width: context.scaleDimension(200),
  height: context.scaleDimension(100)
)
```

## Configuration Options

### ResponsiveScaler Parameters

```dart
ResponsiveScaler(
  maxWidth: 1200,           // Max content width on large screens (default: 1200)
  enableScaling: true,      // Enable/disable scaling (default: true)
  child: YourWidget(),
)
```

### Custom Scale Factors

To modify scale factors, edit the `_calculateScaleFactor()` method in `responsive_scaler.dart`:

```dart
double _calculateScaleFactor(double screenWidth) {
  if (screenWidth <= 600) return 1.0;        // Mobile: no scaling
  if (screenWidth <= 900) return 1.1;        // Tablet: 10% larger
  if (screenWidth <= 1400) return 1.3;       // Desktop: 30% larger  
  return 1.4;                                 // Large: 40% larger
}
```

## Best Practices

1. **Apply ResponsiveScaler at Screen Level**: Wrap entire screens, not individual widgets
2. **Use Responsive Widgets Consistently**: Replace all Text/Icon/SizedBox widgets for consistency
3. **Test on Multiple Screen Sizes**: Verify layout works on mobile, tablet, and desktop
4. **Don't Over-Scale**: Keep mobile experience as the baseline (scale factor 1.0)
5. **Consider Content Hierarchy**: Scale headers more than body text if needed

## Troubleshooting

### Common Issues

**Text too small on desktop:**
- Ensure you're using `RText` instead of `Text`
- Check that ResponsiveScaler wraps the screen

**Layout breaks on mobile:**
- Mobile should have scale factor 1.0 (unchanged)
- Verify responsive widgets don't break existing constraints

**Content too wide on desktop:**
- Set appropriate `maxWidth` on ResponsiveScaler
- Consider using `Center` widget for very wide screens

## Example Implementation

See `responsive_example.dart` for a complete working example demonstrating:
- ResponsiveScaler setup
- RText, RIcon, RSpacing usage
- Device type detection
- Responsive grid layouts
- Scale factor information display

This system ensures your app looks professional on all screen sizes while preserving the carefully optimized mobile experience!
