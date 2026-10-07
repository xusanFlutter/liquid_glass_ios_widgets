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
    let configuration = params.double("iconSize").map { UIImage.SymbolConfiguration(pointSize: CGFloat($0)) }
    let symbol = { (name: String) in UIImage(systemName: name, withConfiguration: configuration) }
    let items = params.maps("items").enumerated().map { index, item -> UITabBarItem in
      let image = item.string("systemImage").flatMap(symbol)
      let selectedImage = item.string("selectedSystemImage").flatMap(symbol)
      let tabItem = UITabBarItem(title: item.string("label"), image: image, selectedImage: selectedImage ?? image)
      tabItem.tag = index
      tabItem.badgeValue = item.string("badge")
      return tabItem
    }

    // Replacing items resets the selection animation, so only do it on change.
    let current = tabBar.items ?? []
    let changed = current.count != items.count || zip(current, items).contains {
      $0.title != $1.title || $0.image != $1.image || $0.badgeValue != $1.badgeValue
    }
    if changed {
      tabBar.setItems(items, animated: false)
    }

    tabBar.tintColor = params.uiColor("tint")
    tabBar.unselectedItemTintColor = params.uiColor("unselectedTint")

    let index = params.int("selectedIndex") ?? 0
    if let items = tabBar.items, items.indices.contains(index), tabBar.selectedItem !== items[index] {
      tabBar.selectedItem = items[index]
    }

    DispatchQueue.main.async { [weak self] in
      self?.reportIntrinsicSize()
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
  }
}
