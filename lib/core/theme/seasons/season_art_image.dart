import 'package:flutter/material.dart';

import 'season_palette.dart';

/// Shows a bundled image, or the active season's replacement for it.
/// Pass the base (Halloween) asset path; seasons override it via
/// `SeasonDecor.art` with another asset or an emoji.
class SeasonArtImage extends StatelessWidget {
  const SeasonArtImage(
    this.baseAsset, {
    super.key,
    this.fit = BoxFit.contain,
    this.color,
    this.colorBlendMode,
  });

  final String baseAsset;
  final BoxFit fit;
  final Color? color;
  final BlendMode? colorBlendMode;

  @override
  Widget build(BuildContext context) {
    final art = SeasonPalette.current.decor.art[baseAsset];
    if (art?.emoji != null) {
      return FittedBox(
        fit: BoxFit.contain,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(art!.emoji!, style: const TextStyle(fontSize: 64)),
        ),
      );
    }
    return Image.asset(
      art?.asset ?? baseAsset,
      fit: fit,
      color: color,
      colorBlendMode: colorBlendMode,
    );
  }
}
