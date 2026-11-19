import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/config/prompt_preview_assets.dart';
import '../../../../core/theme/seasons/season_palette.dart';

/// Sample picture of a prompt.
///
/// Resolution order: bundled asset `imageUrl` → network `imageUrl` → bundled
/// `assets/prompt_previews/<id>.(jpg|jpeg|png|webp)` → themed placeholder.
/// Drop an image named after the prompt id into `assets/prompt_previews/`
/// and it is picked up automatically.
class PromptPreview extends StatelessWidget {
  const PromptPreview({
    super.key,
    required this.id,
    required this.tags,
    required this.isImageToImage,
    this.imageUrl,
    this.borderRadius = 16,
  });

  final String id;
  final List<String> tags;
  final bool isImageToImage;
  final String? imageUrl;
  final double borderRadius;

  static Set<String>? _assets;
  static Future<Set<String>>? _loading;

  static Future<Set<String>> _loadAssets() {
    return _loading ??= AssetManifest.loadFromAssetBundle(rootBundle)
        .then((m) => m.listAssets().toSet())
        .then((s) => _assets = s)
        .catchError((_) => _assets = <String>{});
  }

  static String? _assetFor(String id) {
    final set = _assets;
    if (set == null) return null;
    for (final ext in const ['jpg', 'jpeg', 'png', 'webp']) {
      final path = 'assets/prompt_previews/$id.$ext';
      if (set.contains(path)) return path;
    }
    return null;
  }

  static const _emojiByTag = <String, String>{
    'forest': '🌲',
    'house': '🏚️',
    'gothic': '🏰',
    'graveyard': '⚰️',
    'ghosts': '👻',
    'skeletons': '💀',
    'pumpkin': '🎃',
    'moon': '🌕',
    'street': '🏘️',
    'party': '🎉',
    'kids': '🧒',
    'vampire': '🧛',
    'witch': '🧙',
    'zombie': '🧟',
    'liminal': '🌀',
    'vaporwave': '🌅',
    'retro': '📼',
    'vintage': '📷',
    'scifi': '🚀',
    'western': '🤠',
    'nobility': '👑',
    'action': '💥',
    'fantasy': '🧚',
    'horror': '🩸',
    'supernatural': '🔮',
    'professional': '💼',
    'snow': '❄️',
    'tree': '🎄',
    'santa': '🎅',
    'elf': '🧝',
    'cozy': '🔥',
    'market': '🛍️',
    'family': '🎁',
  };

  String get _emoji {
    for (final t in tags) {
      final e = _emojiByTag[t.toLowerCase()];
      if (e != null) return e;
    }
    return isImageToImage ? '📸' : '🖼️';
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    Widget placeholder() {
      // Deterministic per-prompt tint so tiles don't look identical.
      final mix =
          0.06 +
          (id.codeUnits.fold<int>(7, (a, b) => (a * 31 + b) & 0x7fffffff) % 7) *
              0.02;
      final bg = Color.lerp(SeasonPalette.card, SeasonPalette.accent, mix)!;
      return Container(
        color: bg,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              SeasonPalette.t(_emoji),
              style: const TextStyle(fontSize: 56),
            ),
          ),
        ),
      );
    }

    Widget content;
    final bundledPath = PromptPreviewAssets.forPrompt(id);
    if (bundledPath != null) {
      content = Image.asset(
        bundledPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder(),
      );
    } else if (imageUrl != null && imageUrl!.startsWith('assets/')) {
      content = Image.asset(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder(),
      );
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      content = Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder(),
        loadingBuilder: (_, child, p) => p == null ? child : placeholder(),
      );
    } else if (_assets != null) {
      final path = _assetFor(id);
      content = path == null
          ? placeholder()
          : Image.asset(path, fit: BoxFit.cover);
    } else {
      content = FutureBuilder<Set<String>>(
        future: _loadAssets(),
        builder: (_, __) {
          final path = _assetFor(id);
          return path == null
              ? placeholder()
              : Image.asset(path, fit: BoxFit.cover);
        },
      );
    }

    return ClipRRect(borderRadius: radius, child: content);
  }
}
