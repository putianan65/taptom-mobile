import 'package:flutter/material.dart';

import '../design/design.dart';

/// GISTNU, the Naresuan University centre that commissioned and developed
/// TAPTOM, credited wherever the app introduces itself.
abstract final class Gistnu {
  static const asset = 'assets/images/partners/gistnu.webp';
  static const nameTh = 'ศูนย์ภูมิสารสนเทศเพื่อการพัฒนาภาคเหนือตอนล่าง';
  static const university = 'มหาวิทยาลัยนเรศวร';
}

/// A partner logo on a white plate. Logos keep their own colours, so on the
/// dark theme or a green header they sit on white instead of being recoloured.
class LogoPlate extends StatelessWidget {
  const LogoPlate({
    super.key,
    required this.asset,
    required this.label,
    this.height = 28,
    this.plate,
  });

  final String asset;
  final String label;
  final double height;

  /// Force the plate on or off. By default it is drawn on the dark theme only.
  final bool? plate;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      asset,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: label,
      errorBuilder: (_, __, ___) => SizedBox(height: height),
    );
    if (!(plate ?? context.isDark)) return image;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: height * 0.4, vertical: height * 0.22),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: Radii.control),
      child: image,
    );
  }
}

/// "Developed by GISTNU" with the logo, for footers and about sections.
class DevelopedBy extends StatelessWidget {
  const DevelopedBy({super.key, this.logoHeight = 30, this.showName = true, this.plate});

  final double logoHeight;

  /// Show the centre's full Thai name under the logo.
  final bool showName;

  /// See [LogoPlate.plate].
  final bool? plate;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      container: true,
      label: 'พัฒนาโดย GISTNU ${Gistnu.nameTh} ${Gistnu.university}',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('พัฒนาโดย', style: context.text.labelMedium?.copyWith(color: p.inkSubtle)),
            const SizedBox(height: Space.sm),
            LogoPlate(asset: Gistnu.asset, label: 'GISTNU', height: logoHeight, plate: plate),
            if (showName) ...[
              const SizedBox(height: Space.sm),
              Text(
                '${Gistnu.nameTh}\n${Gistnu.university}',
                textAlign: TextAlign.center,
                style: context.text.bodySmall?.copyWith(color: p.inkSubtle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
