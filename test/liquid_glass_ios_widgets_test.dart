import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_ios_widgets/liquid_glass_ios_widgets.dart';

final _iOS = TargetPlatformVariant.only(TargetPlatform.iOS);
final _android = TargetPlatformVariant.only(TargetPlatform.android);

Widget _wrap(Widget child) => CupertinoApp(home: Center(child: child));

Map<String, Object?> _nativeParams(WidgetTester tester) =>
    tester.widget<UiKitView>(find.byType(UiKitView)).creationParams!
        as Map<String, Object?>;

void main() {
  group('on iOS', () {
    testWidgets('button creates a native view with its parameters', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          LiquidGlassButton(
            label: 'Go',
            systemImage: 'star',
            style: LiquidGlassButtonStyle.prominent,
            tint: const Color(0xFF112233),
            onPressed: () {},
          ),
        ),
      );

      final view = tester.widget<UiKitView>(find.byType(UiKitView));
      expect(view.viewType, 'liquid_glass_ios_widgets/button');
      final params = _nativeParams(tester);
      expect(params['label'], 'Go');
      expect(params['systemImage'], 'star');
      expect(params['style'], 'prominent');
      expect(params['tint'], 0xFF112233);
      expect(params['enabled'], isTrue);
      expect(params['expandWidth'], isFalse);
    }, variant: _iOS);

    testWidgets('icon button is a fixed-size circle', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const LiquidGlassButton.icon(
            systemImage: 'plus',
            dimension: 56,
            onPressed: null,
          ),
        ),
      );

      expect(tester.getSize(find.byType(UiKitView)), const Size(56, 56));
      final params = _nativeParams(tester);
      expect(params['shape'], 'circle');
      expect(params['enabled'], isFalse);
    }, variant: _iOS);

    testWidgets('slider converts divisions to a step', (tester) async {
      await tester.pumpWidget(
        _wrap(
          LiquidGlassSlider(
            value: 5,
            min: 0,
            max: 10,
            divisions: 4,
            onChanged: (_) {},
          ),
        ),
      );

      expect(_nativeParams(tester)['step'], 2.5);
    }, variant: _iOS);
  });

  group('on other platforms', () {
    testWidgets('widgets fall back to Cupertino', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LiquidGlassSwitch(value: true, onChanged: (_) {}),
              LiquidGlassButton(label: 'Go', onPressed: () {}),
            ],
          ),
        ),
      );

      expect(find.byType(UiKitView), findsNothing);
      expect(find.byType(CupertinoSwitch), findsOneWidget);
      expect(find.byType(CupertinoButton), findsOneWidget);
    }, variant: _android);

    testWidgets('isSupported is false', (tester) async {
      expect(LiquidGlass.isSupportLiquidGlass, isFalse);
      expect(await LiquidGlass.isSupported(), isFalse);
    }, variant: _android);
  });

  group('LiquidGlassAdaptive', () {
    tearDown(() => LiquidGlass.debugIsSupportLiquidGlassOverride = null);

    const adaptive = LiquidGlassAdaptive(
      glass: Text('glass'),
      fallback: Text('fallback'),
    );

    testWidgets('shows glass when supported', (tester) async {
      LiquidGlass.debugIsSupportLiquidGlassOverride = true;
      await tester.pumpWidget(_wrap(adaptive));

      expect(find.text('glass'), findsOneWidget);
      expect(find.text('fallback'), findsNothing);
    });

    testWidgets('shows fallback when not supported', (tester) async {
      LiquidGlass.debugIsSupportLiquidGlassOverride = false;
      await tester.pumpWidget(_wrap(adaptive));

      expect(find.text('fallback'), findsOneWidget);
      expect(find.text('glass'), findsNothing);
    });
  });

  test('parses the iOS major version', () {
    expect(LiquidGlass.iosMajorVersion('Version 26.0 (Build 23A341)'), 26);
    expect(LiquidGlass.iosMajorVersion('Version 18.6.2 (Build 22G100)'), 18);
    expect(LiquidGlass.iosMajorVersion('26.1'), 26);
    expect(LiquidGlass.iosMajorVersion('unknown'), isNull);
  });
}
