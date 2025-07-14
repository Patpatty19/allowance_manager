import 'package:flutter/material.dart';

/// A widget that provides responsive scaling for mobile and desktop screens.
/// Automatically scales font sizes, icon sizes, and spacing based on screen width.
class ResponsiveScaler extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final bool enableScaling;

  const ResponsiveScaler({
    Key? key,
    required this.child,
    this.maxWidth,
    this.enableScaling = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final scaleFactor = _calculateScaleFactor(screenWidth);
        
        // If maxWidth is specified and screen is wide, center and constrain the content
        if (maxWidth != null && screenWidth > 800) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth!,
              ),
              child: enableScaling 
                ? _ScaledContent(
                    scaleFactor: scaleFactor,
                    child: child,
                  )
                : child,
            ),
          );
        }
        
        // For full-screen or mobile/tablet screens, use full width with optional scaling
        return enableScaling 
            ? _ScaledContent(
                scaleFactor: scaleFactor,
                child: child,
              )
            : child;
      },
    );
  }

  double _calculateScaleFactor(double screenWidth) {
    // Mobile: 0-600px (scale factor 1.0)
    if (screenWidth <= 600) return 1.0;
    
    // Tablet: 600-900px (scale factor 1.0-1.1)
    if (screenWidth <= 900) {
      return 1.0 + (screenWidth - 600) / 300 * 0.1;
    }
    
    // Desktop: 900-1400px (scale factor 1.1-1.2)
    if (screenWidth <= 1400) {
      return 1.1 + (screenWidth - 900) / 500 * 0.1;
    }
    
    // Large desktop: 1400-1920px (scale factor 1.2-1.3)
    if (screenWidth <= 1920) {
      return 1.2 + (screenWidth - 1400) / 520 * 0.1;
    }
    
    // Ultra-wide: 1920px+ (scale factor 1.3)
    return 1.3;
  }
}

class _ScaledContent extends StatelessWidget {
  final double scaleFactor;
  final Widget child;

  const _ScaledContent({
    required this.scaleFactor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaleData(
      scaleFactor: scaleFactor,
      child: child,
    );
  }
}

/// InheritedWidget that provides the current scale factor to descendant widgets
class ResponsiveScaleData extends InheritedWidget {
  final double scaleFactor;

  const ResponsiveScaleData({
    Key? key,
    required this.scaleFactor,
    required Widget child,
  }) : super(key: key, child: child);

  static ResponsiveScaleData? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ResponsiveScaleData>();
  }

  @override
  bool updateShouldNotify(ResponsiveScaleData oldWidget) {
    return scaleFactor != oldWidget.scaleFactor;
  }
}

/// Extension methods for responsive scaling
extension ResponsiveScaling on BuildContext {
  double get scaleFactor {
    final scaleData = ResponsiveScaleData.of(this);
    return scaleData?.scaleFactor ?? 1.0;
  }
  
  double get screenWidth => MediaQuery.of(this).size.width;
  
  bool get isMobile => screenWidth <= 600;
  bool get isTablet => screenWidth > 600 && screenWidth <= 900;
  bool get isDesktop => screenWidth > 900;
  
  /// Scale font size responsively
  double scaleFont(double fontSize) => fontSize * scaleFactor;
  
  /// Scale icon size responsively
  double scaleIcon(double iconSize) => iconSize * scaleFactor;
  
  /// Scale spacing/padding responsively
  double scaleSpacing(double spacing) => spacing * scaleFactor;
  
  /// Scale dimension (width/height) responsively
  double scaleDimension(double dimension) => dimension * scaleFactor;
}

/// Responsive Text widget that automatically scales font size
class RText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextStyle? style;

  const RText(
    this.text, {
    Key? key,
    required this.fontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scaledFontSize = context.scaleFont(fontSize);
    
    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(
        fontSize: scaledFontSize,
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Responsive Icon widget that automatically scales icon size
class RIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;

  const RIcon(
    this.icon, {
    Key? key,
    required this.size,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scaledSize = context.scaleIcon(size);
    
    return Icon(
      icon,
      size: scaledSize,
      color: color,
    );
  }
}

/// Responsive SizedBox that automatically scales dimensions
class RSpacing extends StatelessWidget {
  final double? width;
  final double? height;

  const RSpacing({
    Key? key,
    this.width,
    this.height,
  }) : super(key: key);

  const RSpacing.width(this.width, {Key? key}) : height = null, super(key: key);
  const RSpacing.height(this.height, {Key? key}) : width = null, super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width != null ? context.scaleSpacing(width!) : null,
      height: height != null ? context.scaleSpacing(height!) : null,
    );
  }
}

/// Responsive EdgeInsets that automatically scales padding
class RPadding {
  static EdgeInsets all(BuildContext context, double value) {
    return EdgeInsets.all(context.scaleSpacing(value));
  }
  
  static EdgeInsets symmetric(BuildContext context, {double? horizontal, double? vertical}) {
    return EdgeInsets.symmetric(
      horizontal: horizontal != null ? context.scaleSpacing(horizontal) : 0,
      vertical: vertical != null ? context.scaleSpacing(vertical) : 0,
    );
  }
  
  static EdgeInsets only(
    BuildContext context, {
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return EdgeInsets.only(
      left: left != null ? context.scaleSpacing(left) : 0,
      top: top != null ? context.scaleSpacing(top) : 0,
      right: right != null ? context.scaleSpacing(right) : 0,
      bottom: bottom != null ? context.scaleSpacing(bottom) : 0,
    );
  }
  
  static EdgeInsets fromLTRB(BuildContext context, double left, double top, double right, double bottom) {
    return EdgeInsets.fromLTRB(
      context.scaleSpacing(left),
      context.scaleSpacing(top),
      context.scaleSpacing(right),
      context.scaleSpacing(bottom),
    );
  }
}
