import SwiftUI
import UIKit

// MARK: - Reading parameters sent from Dart

extension Dictionary where Key == String, Value == Any {
  func string(_ key: String) -> String? {
    guard let value = self[key] as? String, !value.isEmpty else { return nil }
    return value
  }

  func bool(_ key: String) -> Bool? {
    (self[key] as? NSNumber)?.boolValue
  }

  func double(_ key: String) -> Double? {
    (self[key] as? NSNumber)?.doubleValue
  }

  func int(_ key: String) -> Int? {
    (self[key] as? NSNumber)?.intValue
  }

  /// Colors are sent from Dart as 32-bit ARGB integers.
  func color(_ key: String) -> Color? {
    uiColor(key).map { Color($0) }
  }

  func uiColor(_ key: String) -> UIColor? {
    guard let argb = (self[key] as? NSNumber)?.int64Value else { return nil }
    return UIColor(argb: argb)
  }

  func maps(_ key: String) -> [[String: Any]] {
    self[key] as? [[String: Any]] ?? []
  }
}

extension UIColor {
  convenience init(argb: Int64) {
    let value = UInt32(truncatingIfNeeded: argb)
    self.init(
      red: CGFloat((value >> 16) & 0xFF) / 255,
      green: CGFloat((value >> 8) & 0xFF) / 255,
      blue: CGFloat(value & 0xFF) / 255,
      alpha: CGFloat((value >> 24) & 0xFF) / 255
    )
  }
}

// MARK: - Shared value types

extension ControlSize {
  init(name: String?) {
    switch name {
    case "mini": self = .mini
    case "small": self = .small
    case "large": self = .large
    case "extraLarge":
      if #available(iOS 17.0, *) {
        self = .extraLarge
      } else {
        self = .large
      }
    default: self = .regular
    }
  }
}

/// A shape that can be described from Dart: `capsule`, `circle` or `rect`
/// (continuous rounded rectangle with `cornerRadius`).
struct GlassShape: Shape {
  var kind: String
  var cornerRadius: CGFloat

  init(kind: String?, cornerRadius: Double?) {
    self.kind = kind ?? "capsule"
    self.cornerRadius = CGFloat(cornerRadius ?? 16)
  }

  func path(in rect: CGRect) -> Path {
    switch kind {
    case "circle":
      return Circle().path(in: rect)
    case "rect":
      return RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).path(in: rect)
    default:
      return Capsule(style: .continuous).path(in: rect)
    }
  }
}

// MARK: - Liquid Glass with graceful fallback

extension View {
  /// Applies a Liquid Glass effect on iOS 26+, a material on older systems.
  @ViewBuilder
  func liquidGlass(
    variant: String?,
    tint: Color?,
    interactive: Bool,
    in shape: GlassShape
  ) -> some View {
    if #available(iOS 26.0, *) {
      let base: Glass = variant == "clear" ? .clear : .regular
      glassEffect(base.tint(tint).interactive(interactive), in: shape)
    } else {
      background(
        shape
          .fill(variant == "clear" ? .ultraThinMaterial : .regularMaterial)
          .overlay(shape.fill(tint ?? .clear).opacity(0.35))
      )
    }
  }

  /// `.glass` / `.glassProminent` on iOS 26+, `.bordered` / `.borderedProminent` below.
  @ViewBuilder
  func glassButtonStyle(prominent: Bool) -> some View {
    if #available(iOS 26.0, *) {
      if prominent {
        buttonStyle(.glassProminent)
      } else {
        buttonStyle(.glass)
      }
    } else {
      if prominent {
        buttonStyle(.borderedProminent)
      } else {
        buttonStyle(.bordered)
      }
    }
  }

  @ViewBuilder
  func optionalTint(_ color: Color?) -> some View {
    if let color {
      tint(color)
    } else {
      self
    }
  }

  @ViewBuilder
  func optionalForeground(_ color: Color?) -> some View {
    if let color {
      foregroundStyle(color)
    } else {
      self
    }
  }
}
