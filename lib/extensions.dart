import 'package:flutter/material.dart';

// Color extensions for the app
extension ColorExtensions on Color {
  /// Creates a copy of this color with the given values.
  /// Similar to withOpacity but allows setting any value.
  Color withValues({int? red, int? green, int? blue, double? alpha}) {
    return Color.fromRGBO(
      red ?? ((r * 255.0).round() & 0xff),
      green ?? ((g * 255.0).round() & 0xff),
      blue ?? ((b * 255.0).round() & 0xff),
      alpha ?? a,
    );
  }
}

// This forces the extension to be loaded even if the analyzer thinks it's unused
// It's a no-op function that can be called from anywhere
void registerExtensions() {
  // Do nothing, just makes sure the file is imported and used
}
