/// Visual style of a [LiquidGlassButton].
enum LiquidGlassButtonStyle {
  /// Translucent glass (`.buttonStyle(.glass)`).
  glass,

  /// Tinted, opaque-ish glass for primary actions (`.buttonStyle(.glassProminent)`).
  prominent,
}

/// Native SwiftUI control sizes.
enum LiquidGlassControlSize { mini, small, regular, large, extraLarge }

/// Glass material variant.
enum LiquidGlassVariant {
  /// The default, adaptive glass.
  regular,

  /// Highly transparent glass for media-rich backgrounds.
  clear,
}

/// Shape of a glass surface or button.
class LiquidGlassShape {
  const LiquidGlassShape._(this.kind, [this.cornerRadius]);

  /// Fully rounded ends.
  const LiquidGlassShape.capsule() : this._('capsule');

  /// A circle (or ellipse, if the widget isn't square).
  const LiquidGlassShape.circle() : this._('circle');

  /// A continuous ("squircle") rounded rectangle.
  const LiquidGlassShape.rect({double cornerRadius = 16})
    : this._('rect', cornerRadius);

  final String kind;
  final double? cornerRadius;

  @override
  bool operator ==(Object other) =>
      other is LiquidGlassShape &&
      other.kind == kind &&
      other.cornerRadius == cornerRadius;

  @override
  int get hashCode => Object.hash(kind, cornerRadius);
}
