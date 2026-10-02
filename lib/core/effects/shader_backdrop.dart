import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../design/design.dart';

typedef ShaderUniforms = void Function(
  ui.FragmentShader shader,
  Size size,
  double seconds,
);

/// Paints a GLSL fragment shader as an animated backdrop.
///
/// Programs are compiled once and cached. The ticker only runs while the
/// widget is visible (it respects [TickerMode]) and stops entirely when the
/// platform asks for reduced motion. If the shader cannot be loaded, for
/// example on a renderer without runtime effects, [fallback] is shown.
class ShaderBackdrop extends StatefulWidget {
  const ShaderBackdrop({
    super.key,
    required this.asset,
    required this.uniforms,
    required this.fallback,
    this.speed = 1.0,
    this.initialTime = 8.0,
  });

  final String asset;
  final ShaderUniforms uniforms;
  final Widget fallback;

  /// Multiplier applied to elapsed time.
  final double speed;

  /// Start time in seconds, so the first frame already looks settled.
  final double initialTime;

  static final Map<String, Future<ui.FragmentProgram>> _programs = {};

  static Future<ui.FragmentProgram> _load(String asset) {
    return _programs.putIfAbsent(
      asset,
      () => ui.FragmentProgram.fromAsset(asset),
    );
  }

  /// Warms the program cache so the first screen that needs it paints
  /// immediately.
  static Future<void> precache(List<String> assets) async {
    for (final asset in assets) {
      try {
        await _load(asset);
      } catch (error) {
        debugPrint('Shader $asset unavailable: $error');
      }
    }
  }

  @override
  State<ShaderBackdrop> createState() => _ShaderBackdropState();
}

class _ShaderBackdropState extends State<ShaderBackdrop>
    with SingleTickerProviderStateMixin {
  ui.FragmentShader? _shader;
  late final Ticker _ticker;
  late final ValueNotifier<double> _time;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _time = ValueNotifier(widget.initialTime);
    _ticker = createTicker((elapsed) {
      _time.value =
          widget.initialTime + elapsed.inMicroseconds / 1e6 * widget.speed;
    });
    _init();
  }

  Future<void> _init() async {
    try {
      final program = await ShaderBackdrop._load(widget.asset);
      if (!mounted) return;
      setState(() => _shader = program.fragmentShader());
      _syncTicker();
    } catch (error) {
      if (kDebugMode) debugPrint('Shader ${widget.asset} failed: $error');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  void _syncTicker() {
    if (_shader == null) return;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce && _ticker.isActive) _ticker.stop();
    if (!reduce && !_ticker.isActive) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shader = _shader;
    if (_failed || shader == null) return widget.fallback;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _ShaderPainter(shader, widget.uniforms, _time),
        size: Size.infinite,
      ),
    );
  }
}

class _ShaderPainter extends CustomPainter {
  _ShaderPainter(this.shader, this.uniforms, this.time) : super(repaint: time);

  final ui.FragmentShader shader;
  final ShaderUniforms uniforms;
  final ValueListenable<double> time;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    uniforms(shader, size, time.value);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_ShaderPainter old) =>
      old.shader != shader || old.uniforms != uniforms;
}

/// Writes uniforms sequentially, matching declaration order in the shader.
class UniformWriter {
  UniformWriter(this.shader);

  final ui.FragmentShader shader;
  int _index = 0;

  void float(double value) => shader.setFloat(_index++, value);

  void vec2(double x, double y) {
    float(x);
    float(y);
  }

  void color(Color c) {
    float(c.r);
    float(c.g);
    float(c.b);
  }
}

/// Animated rolling-field landscape used behind the splash and sign-in.
class FieldBackdrop extends StatelessWidget {
  const FieldBackdrop({super.key, this.horizon = 0.42});

  /// Horizon position as a fraction of the height.
  final double horizon;

  static const asset = 'shaders/field.frag';

  @override
  Widget build(BuildContext context) {
    final colors = FieldColors.of(context);
    return ShaderBackdrop(
      asset: asset,
      speed: 0.9,
      uniforms: (shader, size, t) {
        UniformWriter(shader)
          ..vec2(size.width, size.height)
          ..float(t)
          ..color(colors.skyTop)
          ..color(colors.skyBottom)
          ..color(colors.far)
          ..color(colors.near)
          ..color(colors.sun)
          ..float(horizon);
      },
      fallback: CustomPaint(
        painter: _FieldFallbackPainter(colors, horizon),
        size: Size.infinite,
      ),
    );
  }
}

class FieldColors {
  const FieldColors({
    required this.skyTop,
    required this.skyBottom,
    required this.far,
    required this.near,
    required this.sun,
  });

  final Color skyTop;
  final Color skyBottom;
  final Color far;
  final Color near;
  final Color sun;

  static FieldColors of(BuildContext context) {
    if (context.isDark) {
      return const FieldColors(
        skyTop: Color(0xFF0F1A13),
        skyBottom: Color(0xFF223628),
        far: Color(0xFF3A5A40),
        near: Color(0xFF0B160F),
        sun: Color(0xFFE2BE6A),
      );
    }
    return const FieldColors(
      skyTop: Color(0xFFF4EFE0),
      skyBottom: Color(0xFFE6EBD6),
      far: Color(0xFFA7C29B),
      near: Swatch.green800,
      sun: Color(0xFFF5DE9E),
    );
  }
}

class _FieldFallbackPainter extends CustomPainter {
  _FieldFallbackPainter(this.colors, this.horizon);

  final FieldColors colors;
  final double horizon;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.skyTop, colors.skyBottom],
        ).createShader(rect),
    );
    for (var i = 0; i < 4; i++) {
      final k = i / 3;
      final base = size.height * (horizon + 0.02 + k * k * (1 - horizon) * 0.6);
      final path = Path()..moveTo(0, base);
      for (var x = 0.0; x <= size.width; x += size.width / 6) {
        path.quadraticBezierTo(
          x + size.width / 12,
          base - 14 - 10 * ((i + x ~/ 40) % 3),
          x + size.width / 6,
          base,
        );
      }
      path
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      final color = Color.lerp(colors.far, colors.near, k)!;
      canvas.drawPath(
        path,
        Paint()..color = Color.lerp(color, colors.skyBottom, (1 - k) * 0.5)!,
      );
    }
  }

  @override
  bool shouldRepaint(_FieldFallbackPainter old) =>
      old.colors != colors || old.horizon != horizon;
}

/// Slowly drifting topographic lines on the hero colour. Used behind
/// dashboard headers.
class ContourBackdrop extends StatelessWidget {
  const ContourBackdrop({
    super.key,
    this.base,
    this.line,
    this.intensity = 0.28,
    this.bands = 9,
  });

  final Color? base;
  final Color? line;
  final double intensity;
  final double bands;

  static const asset = 'shaders/contour.frag';

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final baseColor = base ?? p.hero;
    final lineColor = line ?? p.heroLine;
    return ShaderBackdrop(
      asset: asset,
      speed: 0.6,
      initialTime: 3,
      uniforms: (shader, size, t) {
        UniformWriter(shader)
          ..vec2(size.width, size.height)
          ..float(t)
          ..color(baseColor)
          ..color(lineColor)
          ..float(intensity)
          ..float(bands);
      },
      fallback: ColoredBox(color: baseColor),
    );
  }
}
