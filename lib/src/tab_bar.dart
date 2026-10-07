import 'package:flutter/cupertino.dart';

import 'native_glass_view.dart';

/// One item of a [LiquidGlassTabBar].
class LiquidGlassTabItem {
  const LiquidGlassTabItem({
    required this.label,
    required this.systemImage,
    this.selectedSystemImage,
    this.badge,
  });

  final String label;

  /// SF Symbols name, e.g. `'house'`.
  final String systemImage;

  /// SF Symbols name used when selected, e.g. `'house.fill'`.
  final String? selectedSystemImage;

  /// Badge text; null hides the badge.
  final String? badge;

  Map<String, Object?> toMap() => {
    'label': label,
    'systemImage': systemImage,
    'selectedSystemImage': selectedSystemImage,
    'badge': badge,
  };
}

/// A native iOS tab bar (`UITabBar`), which uses Liquid Glass on iOS 26.
///
/// Typically placed at the bottom of a [Stack] over scrolling content so the
/// glass has something to refract. Controlled: rebuild with the new
/// [currentIndex] from [onTap].
class LiquidGlassTabBar extends StatefulWidget {
  const LiquidGlassTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.activeColor,
    this.inactiveColor,
    this.iconSize,
  }) : assert(items.length > 1);

  final List<LiquidGlassTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color? activeColor;
  final Color? inactiveColor;

  /// Point size of the SF Symbols; null keeps the system default.
  final double? iconSize;

  @override
  State<LiquidGlassTabBar> createState() => _LiquidGlassTabBarState();
}

class _LiquidGlassTabBarState extends State<LiquidGlassTabBar>
    with NativeGlassViewMixin {
  @override
  String get viewType => 'tab_bar';

  @override
  Map<String, Object?> get creationParams => {
    'items': [for (final item in widget.items) item.toMap()],
    'selectedIndex': widget.currentIndex,
    'tint': widget.activeColor?.toARGB32(),
    'unselectedTint': widget.inactiveColor?.toARGB32(),
    'iconSize': widget.iconSize,
  };

  @override
  void handleEvent(String method, Object? arguments) {
    if (method == 'onTap') {
      widget.onTap(arguments! as int);
      resyncAfterFrame();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isNativeGlassPlatform) {
      return CupertinoTabBar(
        currentIndex: widget.currentIndex,
        onTap: widget.onTap,
        activeColor: widget.activeColor,
        inactiveColor: widget.inactiveColor ?? CupertinoColors.inactiveGray,
        iconSize: widget.iconSize ?? 30,
        items: [
          for (final item in widget.items)
            BottomNavigationBarItem(
              icon: const Icon(CupertinoIcons.circle),
              label: item.label,
            ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      height: intrinsicSize?.height ?? 62,
      child: buildNativeView(),
    );
  }
}
