import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: DemoPage(),
  ));
}

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = List.generate(
      8,
          (_) => const _BeforeAfterPair(
            before: const AssetImage("assets/images/before.png"),
            after: const AssetImage("assets/images/after.png"),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFE6ECFF),
      appBar: AppBar(
        centerTitle: true,
      ),
      body: Center(
        child: BeforeAfterCarousel(
          items: items,
          cardWidth: 440,
          cardHeight: 560,
          cardPadding: const EdgeInsets.all(16),
          cardRadius: 24,
          cardElevation: 12,
          spacing: 22,
          autoScrollSpeedPxPerSec: 80,
        ),
      ),
    );
  }
}

class _BeforeAfterPair {
  const _BeforeAfterPair({required this.before, required this.after});
  final ImageProvider before;
  final ImageProvider after;
}

/// A horizontally auto-scrolling, endless carousel of before/after cards.
/// A single vertical slider spans the carousel; each card reveals based on
/// that slider’s X position.
class BeforeAfterCarousel extends StatefulWidget {
  const BeforeAfterCarousel({
    super.key,
    required this.items,
    this.cardWidth = 320,
    this.cardHeight = 440,
    this.cardPadding = const EdgeInsets.all(16),
    this.cardRadius = 20,
    this.cardElevation = 8,
    this.spacing = 16,
    this.autoScrollSpeedPxPerSec = 70,
  });

  final List<_BeforeAfterPair> items;
  final double cardWidth;
  final double cardHeight;
  final EdgeInsetsGeometry cardPadding;
  final double cardRadius;
  final double cardElevation;
  final double spacing;
  final double autoScrollSpeedPxPerSec;

  @override
  State<BeforeAfterCarousel> createState() => _BeforeAfterCarouselState();
}

class _BeforeAfterCarouselState extends State<BeforeAfterCarousel> {
  final ScrollController _sc = ScrollController();
  Timer? _autoTimer;

  // Global slider position as a fraction of the visible viewport width.
  double _globalX = 0.5;

  double _viewportW = 0;

  @override
  void initState() {
    super.initState();
    if (widget.autoScrollSpeedPxPerSec > 0) {
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _sc.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    const tick = Duration(milliseconds: 16); // ~60fps
    final double dx = widget.autoScrollSpeedPxPerSec * tick.inMilliseconds / 1000.0;

    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(tick, (_) {
      if (!_sc.hasClients) return;
      _sc.jumpTo(_sc.offset + dx); // endless leftward scroll
      if (mounted) setState(() {}); // keeps reveals in sync while moving
    });
  }

  @override
  Widget build(BuildContext context) {
    final double tileW = widget.cardWidth + widget.spacing;
    final double listHPad = widget.spacing;

    return SizedBox(
      height: widget.cardHeight,
      child: LayoutBuilder(builder: (context, box) {
        _viewportW = box.maxWidth;

        // One global vertical slider overlay.
        final overlaySlider = Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (d) =>
                setState(() => _globalX = (d.localPosition.dx / _viewportW).clamp(0, 1)),
            onHorizontalDragUpdate: (d) =>
                setState(() => _globalX = (d.localPosition.dx / _viewportW).clamp(0, 1)),
            child: Stack(
              children: [
                Positioned(
                  left: _globalX * _viewportW - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.25),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: _globalX * _viewportW - 20,
                  top: widget.cardHeight / 2 - 20,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.25),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.drag_handle_rounded, size: 22),
                  ),
                ),
              ],
            ),
          ),
        );

        return Stack(
          children: [
            ListView.builder(
              controller: _sc,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: listHPad),
              itemBuilder: (context, index) {
                final pair = widget.items[index % widget.items.length];

                // Card's left edge within viewport.
                final double leftEdge = index * tileW - _sc.offset + listHPad;

                // Global divider X in viewport px.
                final double dividerX = _globalX * _viewportW;

                // Local reveal for this card.
                double t = (dividerX - leftEdge) / widget.cardWidth;
                t = t.clamp(0.0, 1.0);

                return Padding(
                  padding: EdgeInsets.only(right: widget.spacing),
                  child: _Card(
                    width: widget.cardWidth,
                    height: widget.cardHeight,
                    padding: widget.cardPadding,
                    borderRadius: widget.cardRadius,
                    elevation: widget.cardElevation,
                    before: pair.before,
                    after: pair.after,
                    t: t,
                  ),
                );
              },
            ),

            // Only ONE switcher/divider for the whole carousel:
            overlaySlider,
          ],
        );
      }),
    );
  }
}

/// A single card that renders the before/after reveal and a single bottom label.
/// The reveal is driven by [t] (0..1), coming from the global slider.
/// NOTE: this card **does not** draw any switcher/handle—only images + label.
class _Card extends StatelessWidget {
  const _Card({
    required this.width,
    required this.height,
    required this.padding,
    required this.borderRadius,
    required this.elevation,
    required this.before,
    required this.after,
    required this.t,
  });

  final double width;
  final double height;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double elevation;
  final ImageProvider before;
  final ImageProvider after;
  final double t;

  @override
  Widget build(BuildContext context) {
    final r = Radius.circular(borderRadius);

    // Label sizing
    const double labelHeight = 48.0;
    const double labelTopSpacing = 10.0;

    return Material(
      elevation: elevation,
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(.12),
      borderRadius: BorderRadius.circular(borderRadius + 6),
      child: Container(
        width: width,
        height: height,
        padding: padding,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Use the *inner* height (after padding) to avoid overflow.
            final double innerH = constraints.maxHeight;
            final double imageAreaHeight =
                innerH - labelHeight - labelTopSpacing;

            return Column(
              children: [
                SizedBox(
                  height: imageAreaHeight.clamp(0, double.infinity),
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(r),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image(image: after, fit: BoxFit.cover),
                        ),
                        Positioned.fill(
                          child: ClipPath(
                            clipper: _LeftClipper(t),
                            child: Image(image: before, fit: BoxFit.cover),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: labelTopSpacing),
                SizedBox(
                  height: labelHeight,
                  child: _BottomLabel(
                    t: t,
                    beforeLabel: 'Before',
                    afterLabel: 'After',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Clipper used to reveal the left portion [t] of the child.
class _LeftClipper extends CustomClipper<Path> {
  _LeftClipper(this.t);
  final double t;
  @override
  Path getClip(Size size) {
    final w = size.width * t.clamp(0.0, 1.0);
    return Path()..addRect(Rect.fromLTWH(0, 0, w, size.height));
  }

  @override
  bool shouldReclip(covariant _LeftClipper oldClipper) => oldClipper.t != t;
}

/// Bottom label with your color/gradient rules and AnimatedSwitcher.
class _BottomLabel extends StatelessWidget {
  const _BottomLabel({
    super.key,
    required this.t,
    required this.beforeLabel,
    required this.afterLabel,
  });

  final double t; // 0..1
  final String beforeLabel;
  final String afterLabel;

  @override
  Widget build(BuildContext context) {
    // 0 → "After" (solid black bg, white text)
    // 1 → "Before" (soft gradient bg, black text)
    final double f = ((t - 0.5) * 2).clamp(-1.0, 1.0) * 0.5 + 0.5;

    final Color textColor = Color.lerp(Colors.white, Colors.black, f)!;

    final Color topBefore = Colors.black.withOpacity(0.05);
    final Color botBefore = Colors.black.withOpacity(0.15);
    const Color topAfter = Colors.black;
    const Color botAfter = Colors.black;

    final Color topColor = Color.lerp(topAfter, topBefore, f)!;
    final Color botColor = Color.lerp(botAfter, botBefore, f)!;

    final String label = t < 0.5 ? afterLabel : beforeLabel;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: Container(
        key: ValueKey(label),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [topColor, botColor],
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                blurRadius: 8,
                color: Colors.black.withOpacity(.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
