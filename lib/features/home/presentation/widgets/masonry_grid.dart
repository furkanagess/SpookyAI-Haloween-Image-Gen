import 'package:flutter/material.dart';

/// One tile of a [MasonryGrid]: a stable key (for its height) and a builder
/// that is told the height it was given.
class MasonryTile {
  const MasonryTile({required this.key, required this.child});
  final String key;
  final Widget Function(double height) child;
}

/// Two-column masonry (Pinterest style). Tile heights vary deterministically
/// per item and each tile goes into the currently shorter column, so the
/// columns stay balanced. Used by the Prompts and Photos screens.
class MasonryGrid extends StatelessWidget {
  const MasonryGrid({super.key, required this.tiles});

  final List<MasonryTile> tiles;

  static const double _gap = 10;
  static const _ratios = [1.28, 1.0, 1.48, 1.14];

  /// Stable across launches (String.hashCode is not guaranteed to be).
  static int _stableHash(String s) =>
      s.codeUnits.fold(7, (a, b) => (a * 31 + b) & 0x7fffffff);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final colW = (box.maxWidth - _gap) / 2;
        final cols = <List<Widget>>[[], []];
        final heights = [0.0, 0.0];

        for (final t in tiles) {
          final h = colW * _ratios[_stableHash(t.key) % _ratios.length];
          final c = heights[0] <= heights[1] ? 0 : 1;
          cols[c].add(
            Padding(
              padding: const EdgeInsets.only(bottom: _gap),
              child: SizedBox(width: colW, height: h, child: t.child(h)),
            ),
          );
          heights[c] += h + _gap;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(children: cols[0]),
            const SizedBox(width: _gap),
            Column(children: cols[1]),
          ],
        );
      },
    );
  }
}
