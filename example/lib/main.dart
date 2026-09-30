import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_ios_widgets/liquid_glass_ios_widgets.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GalleryPage(),
    );
  }
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  int _tab = 0;
  bool? _supported;

  @override
  void initState() {
    super.initState();
    LiquidGlass.isSupported().then((value) {
      if (mounted) setState(() => _supported = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _ColorfulBackground()),
          Positioned.fill(
            child: IndexedStack(
              index: _tab,
              children: [
                _ControlsTab(supported: _supported),
                const _GlassTab(),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset,
            child: LiquidGlassTabBar(
              currentIndex: _tab,
              onTap: (index) => setState(() => _tab = index),
              items: const [
                LiquidGlassTabItem(
                  label: 'Controls',
                  systemImage: 'slider.horizontal.3',
                ),
                LiquidGlassTabItem(
                  label: 'Glass',
                  systemImage: 'drop',
                  selectedSystemImage: 'drop.fill',
                  badge: 'new',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlsTab extends StatefulWidget {
  const _ControlsTab({required this.supported});

  final bool? supported;

  @override
  State<_ControlsTab> createState() => _ControlsTabState();
}

class _ControlsTabState extends State<_ControlsTab> {
  bool _switch = true;
  double _slider = 0.4;
  int _segment = 0;
  int _taps = 0;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 16,
        20,
        140,
      ),
      children: [
        const Text(
          'Liquid Glass',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(switch (widget.supported) {
          null => 'Checking…',
          true => 'iOS 26 — real Liquid Glass',
          false => 'Liquid Glass unavailable, using fallbacks',
        }, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 24),
        _Section(
          title: 'Buttons — tapped $_taps times',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              LiquidGlassButton(
                label: 'Glass',
                onPressed: () => setState(() => _taps++),
              ),
              LiquidGlassButton(
                label: 'Prominent',
                style: LiquidGlassButtonStyle.prominent,
                onPressed: () => setState(() => _taps++),
              ),
              LiquidGlassButton(
                label: 'Share',
                systemImage: 'square.and.arrow.up',
                size: LiquidGlassControlSize.large,
                onPressed: () => setState(() => _taps++),
              ),
              LiquidGlassButton.icon(
                systemImage: 'heart.fill',
                foregroundColor: Colors.pink,
                onPressed: () => setState(() => _taps++),
              ),
              LiquidGlassButton.icon(
                systemImage: 'plus',
                style: LiquidGlassButtonStyle.prominent,
                tint: Colors.orange,
                onPressed: () => setState(() => _taps++),
              ),
              const LiquidGlassButton(label: 'Disabled', onPressed: null),
            ],
          ),
        ),
        _Section(
          title: 'Full width',
          child: LiquidGlassButton(
            label: 'Continue',
            style: LiquidGlassButtonStyle.prominent,
            tint: Colors.indigo,
            size: LiquidGlassControlSize.large,
            width: double.infinity,
            height: 52,
            onPressed: () => setState(() => _taps++),
          ),
        ),
        _Section(
          title: 'Switch — ${_switch ? 'on' : 'off'}',
          child: Row(
            children: [
              LiquidGlassSwitch(
                value: _switch,
                onChanged: (value) => setState(() => _switch = value),
              ),
              const SizedBox(width: 16),
              LiquidGlassSwitch(
                value: !_switch,
                activeColor: Colors.orange,
                onChanged: (value) => setState(() => _switch = !value),
              ),
            ],
          ),
        ),
        _Section(
          title: 'Slider — ${(_slider * 100).round()}%',
          child: LiquidGlassSlider(
            value: _slider,
            onChanged: (value) => setState(() => _slider = value),
          ),
        ),
        _Section(
          title: 'Segmented control — #$_segment',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LiquidGlassSegmentedControl(
                selectedIndex: _segment,
                onChanged: (index) => setState(() => _segment = index),
                segments: const [
                  LiquidGlassSegment(label: 'Day'),
                  LiquidGlassSegment(label: 'Week'),
                  LiquidGlassSegment(label: 'Month'),
                ],
              ),
              const SizedBox(height: 12),
              LiquidGlassSegmentedControl(
                expand: true,
                selectedIndex: _segment,
                onChanged: (index) => setState(() => _segment = index),
                segments: const [
                  LiquidGlassSegment(systemImage: 'list.bullet'),
                  LiquidGlassSegment(systemImage: 'square.grid.2x2'),
                  LiquidGlassSegment(systemImage: 'map'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlassTab extends StatelessWidget {
  const _GlassTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 16,
        20,
        140,
      ),
      children: [
        LiquidGlassContainer(
          padding: const EdgeInsets.all(20),
          shape: const LiquidGlassShape.rect(cornerRadius: 28),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Glass card',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'A native .glassEffect() surface with Flutter content on top. '
                'Scroll to see the background refract through it.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: LiquidGlassContainer(
                height: 120,
                tint: Colors.blue.withValues(alpha: 0.4),
                shape: const LiquidGlassShape.rect(cornerRadius: 24),
                onTap: () {},
                child: const Center(child: Text('Tinted + interactive')),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: LiquidGlassContainer(
                height: 120,
                variant: LiquidGlassVariant.clear,
                shape: const LiquidGlassShape.rect(cornerRadius: 24),
                child: const Center(
                  child: Text(
                    'Clear variant',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: LiquidGlassContainer(
            shape: const LiquidGlassShape.capsule(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.music_note_2),
                SizedBox(width: 8),
                Text('Now playing — capsule'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        for (final color in Colors.primaries)
          Container(
            height: 72,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ColorfulBackground extends StatelessWidget {
  const _ColorfulBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3C72), Color(0xFF8E2DE2), Color(0xFFFF6A00)],
        ),
      ),
    );
  }
}
