import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../features/home/data/models/prompt_category.dart';

/// One trend section (e.g. "GTA 6", "Thanksgiving") with its styles.
///
/// Sections live in Firestore (`trend_sections/{id}`) and are edited in the
/// Firebase console, so new trends ship without an app update. Document
/// shape:
///
/// ```
/// title:     "GTA 6"            (required)
/// subtitle:  "Vice City vibes"  (optional)
/// emoji:     "🌴"               (optional)
/// accent:    "#FF2D95"          (optional, glow color)
/// order:     1                  (optional, lower first)
/// active:    true               (optional, false hides it)
/// startsAt / endsAt: Timestamp  (optional, shown only in this window)
/// items: [ {                    (array of maps)
///   id, title, prompt,          (required; prompt is never shown to users)
///   tagline, description,
///   imageUrl (https URL, gs:// URL or Storage path like trends/gta6/a.jpg),
///   type: "text" | "image",     (image = uses the user's photo)
///   isPremium, isHot, ownsScene, kind: "realistic" | "fantasy",
///   tags: [..], active
/// } ]
/// ```
class TrendSection {
  const TrendSection({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.emoji = '',
    this.accent,
    this.order = 0,
    this.items = const [],
    this.badges = const {},
    this.showCount = true,
  });

  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final Color? accent;
  final int order;
  final List<PromptItem> items;

  /// Optional custom badge per item id (`badge` / `badgeColor` fields),
  /// e.g. "NEW" or "LIMITED".
  final Map<String, ({String text, Color? color})> badges;

  /// Shows the "N styles" chip next to the section title.
  final bool showCount;

  /// Builds a section from a Firestore map; returns null when the section is
  /// inactive, outside its time window, malformed or has no usable items.
  static TrendSection? fromMap(
    String id,
    Map<String, dynamic> d,
    DateTime now,
  ) {
    if (d['active'] == false) return null;
    final starts = _date(d['startsAt']);
    final ends = _date(d['endsAt']);
    if (starts != null && now.isBefore(starts)) return null;
    if (ends != null && !now.isBefore(ends)) return null;
    final title = _str(d['title']);
    if (title.isEmpty) return null;

    final items = <PromptItem>[];
    final badges = <String, ({String text, Color? color})>{};
    final raw = d['items'];
    if (raw is List) {
      for (var i = 0; i < raw.length; i++) {
        final m = raw[i];
        if (m is! Map) continue;
        final map = Map<String, dynamic>.from(m);
        final item = _item(id, i, map);
        if (item == null) continue;
        items.add(item);
        final badge = _str(map['badge']);
        if (badge.isNotEmpty) {
          badges[item.id] = (
            text: badge,
            color: parseHexColor(_str(map['badgeColor'])),
          );
        }
      }
    }
    if (items.isEmpty) return null;

    return TrendSection(
      id: id,
      title: title,
      subtitle: _str(d['subtitle']),
      emoji: _str(d['emoji']),
      accent: parseHexColor(_str(d['accent'])),
      order: (d['order'] is num) ? (d['order'] as num).toInt() : 0,
      items: items,
      badges: badges,
      showCount: d['showCount'] != false,
    );
  }

  static PromptItem? _item(
    String sectionId,
    int index,
    Map<String, dynamic> m,
  ) {
    if (m['active'] == false) return null;
    final title = _str(m['title']);
    final prompt = _str(m['prompt']);
    if (title.isEmpty || prompt.isEmpty) return null;
    final rawId = _str(m['id']);
    final tags = m['tags'] is List
        ? (m['tags'] as List).map((e) => e.toString()).toList()
        : <String>[];
    return PromptItem(
      // Prefixed so a trend can never collide with a library style id.
      id: 'trend_${sectionId}_${rawId.isEmpty ? index : rawId}',
      title: title,
      prompt: prompt,
      imageUrl: resolveTrendImage(
        _str(m['imageUrl']).isNotEmpty ? _str(m['imageUrl']) : _str(m['image']),
      ),
      tagline: _str(m['tagline']),
      description: _str(m['description']),
      tags: tags,
      isPopular: m['isHot'] == true,
      isPremium: m['isPremium'] == true,
      ownsScene: m['ownsScene'] == true,
      kind: _str(m['kind']) == 'fantasy'
          ? StyleKind.fantasy
          : StyleKind.realistic,
      promptType: _str(m['type']) == 'image'
          ? PromptType.imageToImage
          : PromptType.textToImage,
    );
  }

  static String _str(Object? v) => v is String ? v.trim() : '';

  static DateTime? _date(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}

/// Default Firebase Storage bucket of the app (used for plain paths).
const trendStorageBucket = 'spookyai-app-ratings.firebasestorage.app';

/// Turns a preview image value from Firestore into a loadable URL:
/// - `https://…`            -> as is
/// - `gs://bucket/path.jpg` -> public download URL of that object
/// - `trends/gta6/a.jpg`    -> object in the app's default Storage bucket
/// - `assets/…`             -> bundled asset, as is
/// Returns null for empty input.
String? resolveTrendImage(String value, {String bucket = trendStorageBucket}) {
  final v = value.trim();
  if (v.isEmpty) return null;
  if (v.startsWith('http://') ||
      v.startsWith('https://') ||
      v.startsWith('assets/')) {
    return v;
  }
  var b = bucket;
  var path = v;
  if (v.startsWith('gs://')) {
    final rest = v.substring(5);
    final slash = rest.indexOf('/');
    if (slash <= 0) return null;
    b = rest.substring(0, slash);
    path = rest.substring(slash + 1);
  }
  path = path.replaceFirst(RegExp(r'^/+'), '');
  if (path.isEmpty) return null;
  return 'https://firebasestorage.googleapis.com/v0/b/$b/o/'
      '${Uri.encodeComponent(path)}?alt=media';
}

/// "#RRGGBB" or "#AARRGGBB" -> Color; null when malformed.
Color? parseHexColor(String hex) {
  var h = hex.replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return null;
  final v = int.tryParse(h, radix: 16);
  return v == null ? null : Color(v);
}

/// Loads trend sections from Firestore. Firestore's offline cache keeps the
/// last result available without network.
class TrendService {
  static const collection = 'trend_sections';

  @visibleForTesting
  static FirebaseFirestore Function()? firestoreOverride;

  /// Last loaded sections, so a style picked from Trends can be found again
  /// (e.g. to restore it after a restart once the trends have loaded).
  static List<TrendSection> cached = const [];

  static PromptItem? findItem(String id) {
    for (final s in cached) {
      for (final p in s.items) {
        if (p.id == id) return p;
      }
    }
    return null;
  }

  /// Screen texts, colors and switches from `trend_config/screen`.
  /// Listened to by the bottom nav (tab label) and the Trends page.
  static final ValueNotifier<TrendScreenConfig> config = ValueNotifier(
    const TrendScreenConfig(),
  );

  static Future<List<TrendSection>> load() async {
    if (firestoreOverride == null && Firebase.apps.isEmpty) return const [];
    final db = firestoreOverride?.call() ?? FirebaseFirestore.instance;
    final results = await Future.wait([
      db.collection(collection).get(),
      db
          .collection(configCollection)
          .doc(configDoc)
          .get()
          .then<Map<String, dynamic>?>((d) => d.data())
          .catchError((_) => null),
    ]);
    final snap = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final cfg = results[1] as Map<String, dynamic>?;
    if (cfg != null) config.value = TrendScreenConfig.fromMap(cfg);
    final now = DateTime.now();
    final sections = <TrendSection>[
      for (final doc in snap.docs)
        if (TrendSection.fromMap(doc.id, doc.data(), now) case final s?) s,
    ]..sort((a, b) => a.order.compareTo(b.order));
    cached = sections;
    return sections;
  }

  static const configCollection = 'trend_config';
  static const configDoc = 'screen';
}

/// Everything on the Trends screen that is not a section: texts, colors and
/// switches. Every field is optional in Firestore; missing ones keep the
/// built-in default below. Texts may contain `\n` for a line break.
/// Items for the top carousel. [refs] ("sectionId/itemId") pick them in
/// order; unknown or hidden ones are skipped. With no refs (or none found),
/// HOT items are used, then each section's first item.
List<(PromptItem, TrendSection)> pickHeroItems(
  List<TrendSection> sections,
  List<String> refs,
) {
  final picked = <(PromptItem, TrendSection)>[];
  for (final ref in refs) {
    final slash = ref.indexOf('/');
    if (slash <= 0) continue;
    final sid = ref.substring(0, slash);
    final id = 'trend_${sid}_${ref.substring(slash + 1)}';
    for (final s in sections) {
      if (s.id != sid) continue;
      for (final p in s.items) {
        if (p.id == id) picked.add((p, s));
      }
    }
  }
  if (picked.isNotEmpty) return picked;
  for (final s in sections) {
    for (final p in s.items) {
      if (p.isPopular) picked.add((p, s));
    }
  }
  if (picked.isNotEmpty) return picked;
  return [for (final s in sections) (s.items.first, s)];
}

class TrendScreenConfig {
  const TrendScreenConfig({
    this.tabLabel = 'Trends',
    this.tabColors = const [],
    this.appBarTitle = 'Trends',
    this.headline = 'What everyone is\ncreating right now',
    this.subheadline =
        'Fresh styles drop here first. Tap one and make it yours.',
    this.headlineColors = const [],
    this.showHeader = true,
    this.showLive = true,
    this.liveText = 'LIVE',
    this.liveColor = const Color(0xFFFF2D55),
    this.showHero = true,
    this.heroTitle = '',
    this.showBadges = false,
    this.showTagline = false,
    this.showSectionLabel = false,
    this.heroItems = const [],
    this.tryText = 'Try it now',
    this.unlockText = 'Unlock',
    this.hotText = '',
    this.hotColor = const Color(0xFFFF2D55),
    this.photoText = '📸 Your photo',
    this.photoColor = const Color(0xFF3D7BFF),
    this.showPhotoBadge = false,
    this.proText = '👑 PRO',
    this.proColor = const Color(0xFFFFB300),
    this.countText = '{n} styles',
    this.emptyTitle = 'New trends are on the way',
    this.emptyBody = 'Check back soon for the hottest styles.',
    this.errorTitle = 'Trends could not load',
    this.errorBody = 'Check your connection and try again.',
    this.refreshText = 'Refresh',
    this.glow = true,
    this.glowSeconds = 4,
    this.accent,
    this.secondaryAccent,
  });

  final String tabLabel;

  /// Gradient of the highlighted Trends tab (2+ colors; empty = default).
  final List<Color> tabColors;
  final String appBarTitle;
  final String headline;
  final String subheadline;

  /// Colors of the animated headline gradient (empty = season colors).
  final List<Color> headlineColors;
  final bool showHeader;
  final bool showLive;
  final String liveText;
  final Color liveColor;
  final bool showHero;

  /// Optional title above the top carousel.
  final String heroTitle;

  /// Card extras; off = cards show only image, title and button.
  final bool showBadges;
  final bool showTagline;
  final bool showSectionLabel;

  /// Top carousel, in order, as "sectionId/itemId". Empty = all HOT items.
  final List<String> heroItems;
  final String tryText;
  final String unlockText;
  final String hotText;
  final Color hotColor;
  final String photoText;
  final Color photoColor;
  final bool showPhotoBadge;
  final String proText;
  final Color proColor;

  /// "{n}" is replaced with the number of styles.
  final String countText;
  final String emptyTitle;
  final String emptyBody;
  final String errorTitle;
  final String errorBody;
  final String refreshText;

  /// Running light around the cards, and seconds per full lap.
  final bool glow;
  final double glowSeconds;

  /// Default glow colors (null = season colors). Sections can override.
  final Color? accent;
  final Color? secondaryAccent;

  factory TrendScreenConfig.fromMap(Map<String, dynamic> d) {
    const def = TrendScreenConfig();
    String str(String k, String fallback) {
      final v = d[k];
      return v is String ? v.replaceAll(r'\n', '\n') : fallback;
    }

    bool flag(String k, bool fallback) =>
        d[k] is bool ? d[k] as bool : fallback;
    Color color(String k, Color fallback) =>
        parseHexColor(d[k] is String ? d[k] as String : '') ?? fallback;
    Color? optColor(String k) =>
        parseHexColor(d[k] is String ? d[k] as String : '');
    List<Color> colorList(String k) => d[k] is List
        ? [
            for (final c in d[k] as List)
              if (parseHexColor(c.toString()) case final col?) col,
          ]
        : const [];
    final colors = d['headlineColors'] is List
        ? [
            for (final c in d['headlineColors'] as List)
              if (parseHexColor(c.toString()) case final col?) col,
          ]
        : def.headlineColors;
    final secs = d['glowSeconds'];

    return TrendScreenConfig(
      tabLabel: str('tabLabel', def.tabLabel),
      tabColors: colorList('tabColors'),
      appBarTitle: str('appBarTitle', def.appBarTitle),
      headline: str('headline', def.headline),
      subheadline: str('subheadline', def.subheadline),
      headlineColors: colors,
      showHeader: flag('showHeader', def.showHeader),
      showLive: flag('showLive', def.showLive),
      liveText: str('liveText', def.liveText),
      liveColor: color('liveColor', def.liveColor),
      showHero: flag('showHero', def.showHero),
      heroTitle: str('heroTitle', def.heroTitle),
      showBadges: flag('showBadges', def.showBadges),
      showTagline: flag('showTagline', def.showTagline),
      showSectionLabel: flag('showSectionLabel', def.showSectionLabel),
      heroItems: d['heroItems'] is List
          ? [
              for (final r in d['heroItems'] as List)
                if (r is String && r.trim().isNotEmpty) r.trim(),
            ]
          : def.heroItems,
      tryText: str('tryText', def.tryText),
      unlockText: str('unlockText', def.unlockText),
      hotText: str('hotText', def.hotText),
      hotColor: color('hotColor', def.hotColor),
      photoText: str('photoText', def.photoText),
      photoColor: color('photoColor', def.photoColor),
      showPhotoBadge: flag('showPhotoBadge', def.showPhotoBadge),
      proText: str('proText', def.proText),
      proColor: color('proColor', def.proColor),
      countText: str('countText', def.countText),
      emptyTitle: str('emptyTitle', def.emptyTitle),
      emptyBody: str('emptyBody', def.emptyBody),
      errorTitle: str('errorTitle', def.errorTitle),
      errorBody: str('errorBody', def.errorBody),
      refreshText: str('refreshText', def.refreshText),
      glow: flag('glow', def.glow),
      glowSeconds: secs is num && secs >= 0.5 && secs <= 60
          ? secs.toDouble()
          : def.glowSeconds,
      accent: optColor('accent'),
      secondaryAccent: optColor('secondaryAccent'),
    );
  }
}
