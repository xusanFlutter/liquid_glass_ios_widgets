# liquid_glass_ios_widgets

Native iOS 26 **Liquid Glass** components as Flutter widgets.

Each widget is backed by a real SwiftUI / UIKit view through a platform view
(`UiKitView`). You get the system look and behavior: refraction, the
glass thumb on sliders and switches, the press shimmer, and the floating tab bar.

| Widget | Native component |
| --- | --- |
| `LiquidGlassButton` / `LiquidGlassButton.icon` | SwiftUI `Button` + `.buttonStyle(.glass)` / `.glassProminent` |
| `LiquidGlassSwitch` | `UISwitch` |
| `LiquidGlassSlider` | SwiftUI `Slider` |
| `LiquidGlassSegmentedControl` | SwiftUI `Picker` + `.pickerStyle(.segmented)` |
| `LiquidGlassContainer` | SwiftUI `.glassEffect(_:in:)`, with a Flutter child on top |
| `LiquidGlassTabBar` | `UITabBar` |

## Requirements

- iOS only. The plugin registers only the iOS platform.
- Building requires **Xcode 26+** (iOS 26 SDK).
- The iOS deployment target must be **15.0** or higher.
- Real Liquid Glass renders on **iOS 26+**. On iOS 15–18 the same widgets use
  native materials and `.bordered` button styles.
- On non-iOS platforms (e.g. widget tests) the widgets render Cupertino
  fallbacks.

Set the minimum iOS version in `ios/Podfile`:

```ruby
platform :ios, '15.0'
```

## Usage

```dart
import 'package:liquid_glass_ios_widgets/liquid_glass_ios_widgets.dart';

LiquidGlassButton(
  label: 'Share',
  systemImage: 'square.and.arrow.up', // SF Symbols name
  onPressed: () {},
);

LiquidGlassButton.icon(
  systemImage: 'plus',
  style: LiquidGlassButtonStyle.prominent,
  tint: Colors.orange,
  onPressed: () {},
);

LiquidGlassSwitch(
  value: enabled,
  onChanged: (value) => setState(() => enabled = value),
);

LiquidGlassSlider(
  value: volume,
  onChanged: (value) => setState(() => volume = value),
);

LiquidGlassSegmentedControl(
  selectedIndex: index,
  onChanged: (i) => setState(() => index = i),
  segments: const [
    LiquidGlassSegment(label: 'Day'),
    LiquidGlassSegment(label: 'Week'),
    LiquidGlassSegment(systemImage: 'calendar'),
  ],
);

LiquidGlassContainer(
  shape: const LiquidGlassShape.rect(cornerRadius: 24),
  padding: const EdgeInsets.all(16),
  child: const Text('Flutter content on native glass'),
);
```

The tab bar is meant to float over content, so the glass has something to
refract:

```dart
Stack(
  children: [
    content,
    Positioned(
      left: 0,
      right: 0,
      bottom: MediaQuery.paddingOf(context).bottom,
      child: LiquidGlassTabBar(
        currentIndex: tab,
        onTap: (i) => setState(() => tab = i),
        items: const [
          LiquidGlassTabItem(label: 'Home', systemImage: 'house', selectedSystemImage: 'house.fill'),
          LiquidGlassTabItem(label: 'Search', systemImage: 'magnifyingglass'),
        ],
      ),
    ),
  ],
);
```

Check at runtime whether real Liquid Glass is available:

```dart
final supported = await LiquidGlass.isSupported(); // true on iOS 26+
```

## How it works

```
Flutter widget ──creationParams──▶ UiKitView ──▶ FlutterPlatformViewFactory
      ▲                                                  │
      │   MethodChannel "liquid_glass_ios_widgets/view_<id>"
      │     Dart → iOS: update(params)                   ▼
      └──── iOS → Dart: onPressed / onChanged / …   UIHostingController(SwiftUI view)
                        intrinsicSize                 or a UIKit control
```

- Each native view gets its own method channel. When the widget rebuilds with
  new parameters, the whole parameter map is sent with `update`.
- Widgets without an explicit size, such as buttons and the segmented
  control, are sized from the size the native side measures and reports
  (`intrinsicSize`).
- Controls are **controlled**: rebuild with the new value in `onChanged`. If
  you don't, the native control snaps back to the value you passed.

## Limitations

- **Performance.** Every widget is a separate platform view. Dozens of them
  in a scrolling list cost more than plain Flutter widgets.
- **No morphing between widgets.** `GlassEffectContainer` merging and morphing
  only works inside a single SwiftUI hierarchy, so it can't happen between
  separate Flutter widgets.
- The glass refracts content Flutter draws *behind* the platform view. Content
  drawn *on top* of it (e.g. `LiquidGlassContainer.child`) is not refracted.
- Icons are SF Symbols names (`'heart.fill'`), not Flutter `IconData`.

## Example

```bash
cd example && flutter run
```
