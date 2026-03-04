import 'dart:ui';
import 'package:flame/components.dart';
import '../entities/vessel.dart';
import '../systems/fleet.dart';
import '../systems/device.dart';
import '../systems/dev_type.dart';

/// Ported from Module.bas DrawBeam — renders laser beam weapons.
/// Original uses GDI BeginPath/LineTo with gradient pens.
/// Here we use Canvas drawLine with gradient colors.
class BeamRenderer extends Component {
  Vessel? vessel;
  List<Fleet>? activeFleets;

  // Gradient colors for beam (blue to yellow, ported from GenerateBeamGrad)
  static final List<Color> _gradColors = _generateGradient();

  static List<Color> _generateGradient() {
    const steps = 12;
    final colors = <Color>[];
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final r = (t * 255).round().clamp(0, 255);
      final g = (t * 200).round().clamp(0, 255);
      final b = ((1 - t) * 255).round().clamp(0, 255);
      colors.add(Color.fromARGB(255, r, g, b));
    }
    return colors;
  }

  @override
  void render(Canvas canvas) {
    if (vessel == null) return;

    for (final device in vessel!.devices) {
      if (device.beamActive > 0 && device.beam > 0) {
        _drawBeam(canvas, device,
            fat: device.slot == WeaponSlot.frontGun);
      }
    }
  }

  void _drawBeam(Canvas canvas, Device d, {bool fat = false}) {
    // Get color from beam animation progress
    final colorIndex =
        d.beamActive.clamp(0, _gradColors.length - 1);
    final color = _gradColors[colorIndex];

    final paint = Paint()
      ..color = color
      ..strokeWidth = fat ? 3.0 : 1.5
      ..strokeCap = StrokeCap.round;

    // Main beam line
    canvas.drawLine(
      Offset(d.sx, d.sy),
      Offset(d.dx, d.dy),
      paint,
    );

    // Fat beam: draw parallel lines for glow (FrontGun only)
    if (fat) {
      final glowIndex = (colorIndex - 1).clamp(0, _gradColors.length - 1);
      final glowPaint = Paint()
        ..color = _gradColors[glowIndex].withAlpha(180)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(d.sx - 1, d.sy),
        Offset(d.dx - 1, d.dy),
        glowPaint,
      );
      canvas.drawLine(
        Offset(d.sx + 1, d.sy),
        Offset(d.dx + 1, d.dy),
        glowPaint,
      );
    }

    // Glow effect at impact point
    final impactPaint = Paint()
      ..color = color.withAlpha(100)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(d.dx, d.dy), 6, impactPaint);
  }
}
