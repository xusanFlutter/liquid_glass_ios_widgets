import Flutter
import UIKit

/// A native `UITabBar`, which adopts the Liquid Glass design on iOS 26.
///
/// UIKit is used instead of SwiftUI because a standalone SwiftUI tab bar
/// can't exist without `TabView` owning the content.
final class GlassTabBarPlatformView: NSObject, FlutterPlatformView, UITabBarDelegate {
  private let container = UIView()
  private let tabBar = UITabBar()
  private let channel: FlutterMethodChannel
  private var lastReportedSize: CGSize = .zero
  /// Symbol names and size each item's images were made from, by index.
  private var imageKeys: [String] = []
  /// Effect names from Dart's `LiquidGlassTabIconEffect`, by item index.
  private var selectedEffects: [String] = []

  init(frame: CGRect, viewId: Int64, params: [String: Any], messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "liquid_glass_ios_widgets/view_\(viewId)",
      binaryMessenger: messenger
    )
    super.init()

    container.frame = frame
    container.backgroundColor = .clear
    tabBar.frame = container.bounds
    tabBar.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    tabBar.delegate = self
    container.addSubview(tabBar)

    apply(params)

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }
      switch call.method {
      case "update":
        if let params = call.arguments as? [String: Any] {
          self.apply(params)
        }
        result(nil)
      case "snapshot":
        result(self.container.glassSnapshot())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  deinit {
    channel.setMethodCallHandler(nil)
  }

  func view() -> UIView {
    container
  }

  private func apply(_ params: [String: Any]) {
    tabBar.applyInterfaceStyle(from: params)
    let configuration = params.double("iconSize").map { UIImage.SymbolConfiguration(pointSize: CGFloat($0)) }
    let symbol = { (name: String) in UIImage(systemName: name, withConfiguration: configuration) }
    let itemParams = params.maps("items")
    selectedEffects = itemParams.map { $0.string("selectedEffect") ?? "bounce" }

    // Replacing the items replays the selection animation on the selected
    // item, so existing items are updated in place and only a change in the
    // number of items rebuilds them.
    let iconSize = params.double("iconSize").map { "\($0)" } ?? ""
    if let current = tabBar.items, current.count == itemParams.count {
      for (index, (tabItem, item)) in zip(current, itemParams).enumerated() {
        configure(tabItem, at: index, with: item, iconSize: iconSize, symbol: symbol)
      }
    } else {
      imageKeys = Array(repeating: "", count: itemParams.count)
      let items = itemParams.enumerated().map { index, item -> UITabBarItem in
        let tabItem = UITabBarItem()
        tabItem.tag = index
        configure(tabItem, at: index, with: item, iconSize: iconSize, symbol: symbol)
        return tabItem
      }
      tabBar.setItems(items, animated: false)
    }

    tabBar.tintColor = params.uiColor("tint")
    tabBar.unselectedItemTintColor = params.uiColor("unselectedTint")

    let index = params.int("selectedIndex") ?? 0
    if let items = tabBar.items, items.indices.contains(index), tabBar.selectedItem !== items[index] {
      // A selection changed from Dart animates too, except the initial one.
      let isInitial = tabBar.selectedItem == nil
      tabBar.selectedItem = items[index]
      if !isInitial {
        playSelectedEffect(on: items[index])
      }
    }

    DispatchQueue.main.async { [weak self] in
      self?.reportIntrinsicSize()
    }
  }

  /// Sets only the properties that changed, so an unchanged item is left alone.
  private func configure(
    _ tabItem: UITabBarItem,
    at index: Int,
    with item: [String: Any],
    iconSize: String,
    symbol: (String) -> UIImage?
  ) {
    let systemImage = item.string("systemImage")
    let selectedSystemImage = item.string("selectedSystemImage") ?? systemImage
    let key = [systemImage ?? "", selectedSystemImage ?? "", iconSize].joined(separator: "|")
    if imageKeys[index] != key {
      tabItem.image = systemImage.flatMap(symbol)
      tabItem.selectedImage = selectedSystemImage.flatMap(symbol)
      imageKeys[index] = key
    }
    let title = item.string("label")
    if tabItem.title != title {
      tabItem.title = title
    }
    let badge = item.string("badge")
    if tabItem.badgeValue != badge {
      tabItem.badgeValue = badge
    }
  }

  private func reportIntrinsicSize() {
    let fitting = tabBar.sizeThatFits(CGSize(width: container.bounds.width, height: 10_000))
    let size = CGSize(width: ceil(fitting.width), height: ceil(fitting.height))
    guard size.height > 0, size != lastReportedSize else { return }
    lastReportedSize = size
    channel.invokeMethod("intrinsicSize", arguments: ["width": size.width, "height": size.height])
  }

  func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    channel.invokeMethod("onTap", arguments: item.tag)
    playSelectedEffect(on: item)
  }

  /// Animates the item's icon. The tab bar draws the selected icon twice
  /// (once inside the glass lens, once underneath), so every image view
  /// showing one of the item's images is animated. SF Symbols effects
  /// (`addSymbolEffect`) don't render in tab bar buttons, so the icon's
  /// layer is animated directly.
  private func playSelectedEffect(on item: UITabBarItem) {
    let effect = selectedEffects.indices.contains(item.tag) ? selectedEffects[item.tag] : "bounce"
    guard effect != "none", let animation = CAAnimation.tabIconEffect(named: effect) else { return }
    for imageView in tabBar.descendants(of: UIImageView.self)
    where imageView.image != nil && (imageView.image === item.image || imageView.image === item.selectedImage) {
      imageView.layer.add(animation, forKey: "liquidGlassTabIconEffect")
    }
  }
}

private extension UIView {
  func descendants<T: UIView>(of type: T.Type) -> [T] {
    subviews.flatMap { subview -> [T] in
      let own = (subview as? T).map { [$0] } ?? []
      return own + subview.descendants(of: type)
    }
  }
}

private extension CAAnimation {
  /// Keyframe animations named after Dart's `LiquidGlassTabIconEffect`.
  static func tabIconEffect(named name: String) -> CAAnimation? {
    let animation: CAKeyframeAnimation
    switch name {
    case "bounce":
      animation = CAKeyframeAnimation(keyPath: "transform.scale")
      animation.values = [1, 0.78, 1.12, 0.96, 1]
      animation.keyTimes = [0, 0.25, 0.55, 0.8, 1]
      animation.duration = 0.5
    case "scale":
      animation = CAKeyframeAnimation(keyPath: "transform.scale")
      animation.values = [1, 1.25, 1]
      animation.duration = 0.35
    case "pulse":
      animation = CAKeyframeAnimation(keyPath: "opacity")
      animation.values = [1, 0.3, 1]
      animation.duration = 0.5
    case "wiggle":
      animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
      animation.values = [0, -0.26, 0.22, -0.14, 0.07, 0]
      animation.duration = 0.55
    case "rotate":
      animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
      // A full turn, so the icon ends where it started.
      animation.values = [0, CGFloat.pi * 2]
      animation.duration = 0.6
    case "breathe":
      animation = CAKeyframeAnimation(keyPath: "transform.scale")
      animation.values = [1, 1.15, 0.97, 1]
      animation.duration = 0.8
    default:
      return nil
    }
    animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    return animation
  }
}
