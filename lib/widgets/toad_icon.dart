import 'package:flutter/widgets.dart';

import 'package:flutter_svg/flutter_svg.dart';

/// A Lucide-style stroke icon from the toadmark family set. The SVGs are
/// drawn against `currentColor`, so [color] tints them exactly like an
/// IconData glyph and they drop into any Material slot.
class ToadIcon extends StatelessWidget {
  const ToadIcon(this.asset, {super.key, this.size = 20, this.color});

  /// Asset name inside assets/icons/, e.g. `'zap.svg'`.
  final String asset;

  final double size;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/$asset',
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}
