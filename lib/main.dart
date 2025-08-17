import 'dart:math' as math;
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
    return Scaffold(
      backgroundColor: const Color(0xFFE6ECFF),
      appBar: AppBar(
        centerTitle: true,
      ),
      body: Center(
        child: BeforeAfterSlider(
          width: 340,
          height: 460,
          padding: const EdgeInsets.all(16),
          borderRadius: 24,
          elevation: 12,
          before: const AssetImage("assets/images/before.png"),
          after: const AssetImage("assets/images/after.png"),
          beforeLabel: 'Before',
          afterLabel: 'After',
          initialPosition: 0.48,
          snapOnRelease: false,
        ),
      ),
    );
  }
}

/// A polished, animated before/after slider with a draggable handle
/// and an auto-switching label below the image area.
class BeforeAfterSlider extends StatefulWidget {
  const BeforeAfterSlider({
    super.key,
    required this.before,
    required this.after,
    this.beforeLabel = 'Before',
    this.afterLabel = 'After',
    this.initialPosition = .5,
    this.width,
    this.height,
    this.padding,
    this.borderRadius = 20,
    this.elevation = 8,
    this.snapOnRelease = false,
  });

  final ImageProvider before;
  final ImageProvider after;
  final String beforeLabel;
  final String afterLabel;

  /// 0 → show only AFTER, 1 → show only BEFORE
  final double initialPosition;

  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double elevation;

  /// If true, on release it gently snaps to 0.0 or 1.0 if close to edges.
  final bool snapOnRelease;

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider>
    with SingleTickerProviderStateMixin {
  late double _t; // 0..1 (portion of BEFORE visible from the left)
  late AnimationController _ctrl;
  Animation<double>? _anim;

  @override
  void initState() {
    super.initState();
    _t = widget.initialPosition.clamp(0.0, 1.0);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
      setState(() => _t = _anim?.value ?? _t);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _anim = Tween<double>(begin: _t, end: target.clamp(0.0, 1.0))
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_ctrl);
    _ctrl
      ..stop()
      ..reset()
      ..forward();
  }

  void _onDragUpdate(DragUpdateDetails d, BoxConstraints c) {
    final w = c.maxWidth;
    final localX = (d.localPosition.dx).clamp(0.0, w);
    setState(() => _t = (localX / w).clamp(0.0, 1.0));
  }

  void _onTapDown(TapDownDetails d, BoxConstraints c) {
    final w = c.maxWidth;
    final localX = d.localPosition.dx.clamp(0.0, w);
    _animateTo(localX / w);
  }

  void _onEnd() {
    if (!widget.snapOnRelease) return;
    // Snap to the nearest edge if within 10% range
    const edge = 0.10;
    if (_t < edge) _animateTo(0);
    if (_t > 1 - edge) _animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    final r = Radius.circular(widget.borderRadius);

    // Space reserved for the bottom label so the images stay fully above it.
    const double labelHeight = 48.0;
    const double labelTopSpacing = 10.0;

    return Material(
      elevation: widget.elevation,
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(.12),
      borderRadius: BorderRadius.circular(widget.borderRadius + 6),
      child: Container(
        width: widget.width,
        height: widget.height,
        padding: widget.padding ?? const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, c) {
            final double w = c.maxWidth;
            // Height we give to the image area so the label fits below it.
            final double imageAreaHeight =
                c.maxHeight - labelHeight - labelTopSpacing;

            final double handleX = _t * w;

            return Column(
              children: [
                // IMAGE AREA (full height, above label)
                SizedBox(
                  height: imageAreaHeight,
                  width: double.infinity,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (d) => _onDragUpdate(d, c),
                    onHorizontalDragEnd: (_) => _onEnd(),
                    onTapDown: (d) => _onTapDown(d, c),
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(r),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // AFTER (fills entire stack)
                          Positioned.fill(
                            child: Image(
                              image: widget.after,
                              fit: BoxFit.cover,
                            ),
                          ),

                          // BEFORE (fills entire stack but clipped to the left portion)
                          Positioned.fill(
                            child: ClipPath(
                              clipper: _LeftClipper(_t),
                              child: Image(
                                image: widget.before,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          // Center divider + handle
                          Positioned(
                            left: handleX - 1,
                            top: 0,
                            bottom: 0,
                            child: _DividerLine(),
                          ),
                          Positioned(
                            left: handleX - 20,
                            top: (imageAreaHeight / 2) - 20,
                            child: _Handle(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: labelTopSpacing),

                // BOTTOM LABEL (outside the image area)
                SizedBox(
                  height: labelHeight,
                  child: _BottomLabel(
                    t: _t,
                    beforeLabel: widget.beforeLabel,
                    afterLabel: widget.afterLabel,
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

/// Clips the child to a rectangle from the left, with width factor [t] of the
/// full width. Ensures full height coverage.
class _LeftClipper extends CustomClipper<Path> {
  _LeftClipper(this.t);
  final double t;

  @override
  Path getClip(Size size) {
    final double clipW = size.width * t.clamp(0.0, 1.0);
    return Path()..addRect(Rect.fromLTWH(0, 0, clipW, size.height));
  }

  @override
  bool shouldReclip(covariant _LeftClipper oldClipper) =>
      oldClipper.t != t;
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 1),
      duration: const Duration(milliseconds: 160),
      builder: (_, __, ___) {
        return Container(
          width: 2,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.25),
                blurRadius: 8,
              )
            ],
          ),
        );
      },
    );
  }
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 1),
      duration: const Duration(milliseconds: 160),
      builder: (_, __, ___) {
        return Container(
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
        );
      },
    );
  }
}

/// Bottom label that:
/// - Shows "After" when t < 0.5, "Before" otherwise
/// - Interpolates background/text colors with slider progress
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
    // Map t ∈ [0,1] to f ∈ [0,1] where:
    // f = 0 → "After" style (solid black bg, white text)
    // f = 1 → "Before" style (soft gradient bg, black text)
    final double f = ((t - 0.5) * 2).clamp(-1.0, 1.0) * 0.5 + 0.5;

    final Color textColor =
    Color.lerp(Colors.white, Colors.black, f)!; // smooth text blend

    // Interpolate gradient colors between "after" (solid black) and "before" (soft).
    final Color topBefore = Colors.black.withOpacity(0.05);
    final Color botBefore = Colors.black.withOpacity(0.15);
    final Color topAfter = Colors.black;
    final Color botAfter = Colors.black;

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
