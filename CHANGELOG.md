## 0.3.1

- Native views now follow the Flutter theme's brightness instead of the iOS
  system appearance, so an in-app dark mode no longer leaves the tab bar and
  other components light.

## 0.3.0

- Add `LiquidGlassTabBar.iconSize` to set the point size of the tab SF Symbols.

## 0.2.0

- Add `LiquidGlass.isSupportLiquidGlass`, a synchronous check for Liquid Glass support.
- Add `LiquidGlassAdaptive`, which shows one widget when Liquid Glass is supported and another otherwise.

## 0.1.0

- Initial release: `LiquidGlassButton`, `LiquidGlassSwitch`, `LiquidGlassSlider`,
  `LiquidGlassSegmentedControl`, `LiquidGlassContainer`, `LiquidGlassTabBar`.
- Material / bordered fallbacks on iOS < 26, Cupertino fallbacks on other platforms.
- CocoaPods and Swift Package Manager support.
