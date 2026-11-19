import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/prompt_preview_assets.dart';
import '../../../../core/services/main_navigation_provider.dart';
import '../../../../core/services/prompts_provider.dart';
import '../../../../core/widgets/app_bar_title.dart';
import '../../../../core/theme/app_metrics.dart';
import '../../../../core/theme/seasons/season_palette.dart';
import '../../../../core/widgets/token_display_widget.dart';
import '../../data/models/prompt_category.dart';
import '../../domain/generation_mode.dart';
import '../widgets/prompt_detail_sheet.dart';
import '../widgets/prompt_preview.dart';
import 'purchase_page.dart';
import '../widgets/masonry_grid.dart';

enum _Filter { text, realistic, fantasy, favorites }

/// Flat prompt library: every prompt is one card with a sample picture,
/// title, prompt preview and type. One mode filter, no sub-genres.
class PromptsPage extends StatefulWidget {
  const PromptsPage({super.key, this.onUseStyle, this.filterRequest});

  /// Asks the page to jump to a mode's section (set by the Generate screen).
  final ValueNotifier<GenerationMode?>? filterRequest;

  /// Called when the user picks a style. The style's prompt stays inside the
  /// app; the Generate screen only shows its title and preview.
  final void Function(PromptItem style)? onUseStyle;

  @override
  State<PromptsPage> createState() => _PromptsPageState();
}

class _PromptsPageState extends State<PromptsPage> {
  final TextEditingController _search = TextEditingController();
  _Filter _filter = _Filter.text;
  String _query = '';

  @override
  void initState() {
    super.initState();
    widget.filterRequest?.addListener(_onFilterRequest);
  }

  void _onFilterRequest() {
    final mode = widget.filterRequest?.value;
    if (mode == null) return;
    widget.filterRequest!.value = null;
    _search.clear();
    setState(() {
      _query = '';
      _filter = mode == GenerationMode.image ? _Filter.realistic : _Filter.text;
    });
  }

  @override
  void dispose() {
    widget.filterRequest?.removeListener(_onFilterRequest);
    _search.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- actions

  void _useBuiltIn(PromptItem item, PromptsProvider provider) {
    if (provider.isPromptLocked(item)) {
      _showPremiumRequiredDialog();
      return;
    }
    widget.onUseStyle?.call(item);
  }

  void _openBuiltIn(PromptItem item, PromptsProvider provider) {
    final locked = provider.isPromptLocked(item);
    showPromptDetailSheet(
      context,
      detail: PromptDetail(
        title: item.title,
        tags: item.tags,
        tagline: item.tagline,
        description: item.description,
        mode: item.promptType == PromptType.imageToImage
            ? GenerationMode.image
            : GenerationMode.text,
        preview: _previewFor(item, radius: 0),
        isPopular: item.isPopular,
        isLocked: locked,
        isFavorite: provider.isFavorite(item.id),
        onFavoriteChanged: (_) => provider.toggleFavorite(item.id),
      ),
      onUse: () => _useBuiltIn(item, provider),
    );
  }

  PromptPreview _previewFor(PromptItem item, {double radius = 16}) {
    return PromptPreview(
      id: item.id,
      tags: item.tags,
      isImageToImage: item.promptType == PromptType.imageToImage,
      imageUrl: PromptPreviewAssets.forPrompt(item.id) ?? item.imageUrl,
      borderRadius: radius,
    );
  }

  /// "witch · moon · fantasy": a hint of what a style is, never its prompt.
  String _tagLine(List<String> tags) =>
      tags.take(3).map((t) => t[0].toUpperCase() + t.substring(1)).join(' · ');

  // ------------------------------------------------------------------ data

  List<PromptItem> _builtIn(PromptsProvider provider) {
    final all = <PromptItem>[
      for (final c in provider.getAllCategories()) ...c.prompts,
    ];
    // Popular first, otherwise keep authoring order.
    final sorted = [
      ...all.where((p) => p.isPopular),
      ...all.where((p) => !p.isPopular),
    ];
    return sorted;
  }

  bool _matches(String title, List<String> tags) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return title.toLowerCase().contains(q) ||
        tags.any((t) => t.toLowerCase().contains(q));
  }

  // ------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return Consumer<PromptsProvider>(
      builder: (context, provider, _) {
        final built = _builtIn(provider);
        final text = built
            .where((p) => p.promptType == PromptType.textToImage)
            .toList();
        final image = built
            .where((p) => p.promptType == PromptType.imageToImage)
            .toList();
        final realistic = image
            .where((p) => p.kind == StyleKind.realistic)
            .toList();
        final fantasy = image
            .where((p) => p.kind == StyleKind.fantasy)
            .toList();
        final byId = {for (final p in built) p.id: p};
        // Most recently favorited first.
        final favs = [
          for (final id in provider.favoriteIds.reversed)
            if (byId[id] != null) byId[id]!,
        ];

        List<PromptItem> shown = switch (_filter) {
          _Filter.text => text,
          _Filter.realistic => realistic,
          _Filter.fantasy => fantasy,
          _Filter.favorites => favs,
        };
        shown = shown.where((p) => _matches(p.title, p.tags)).toList();
        final bottom = MediaQuery.of(context).padding.bottom;

        return Scaffold(
          backgroundColor: SeasonPalette.scaffold,
          body: NotificationListener<UserScrollNotification>(
            onNotification: _onUserScroll,
            child: NestedScrollView(
              // Header slides away on scroll down and returns on any
              // scroll up (floating + snap), like a social feed.
              floatHeaderSlivers: true,
              headerSliverBuilder: (context, _) => [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  pinned: false,
                  backgroundColor: SeasonPalette.scaffold,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  toolbarHeight: AppMetrics.toolbarHeight,
                  title: const AppBarTitle(
                    icon: Icons.lightbulb_rounded,
                    title: 'Prompts',
                  ),
                  actions: [
                    TokenDisplayWidget(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PurchasePage()),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: _SearchAndFilters(
                      controller: _search,
                      selected: _filter,
                      counts: {
                        _Filter.text: text.length,
                        _Filter.realistic: realistic.length,
                        _Filter.fantasy: fantasy.length,
                        _Filter.favorites: favs.length,
                      },
                      onFilterChanged: (f) {
                        setState(() => _filter = f);
                        _setNavHidden(false);
                      },
                      onQueryChanged: (v) => setState(() => _query = v.trim()),
                    ),
                  ),
                ),
              ],
              body: KeyedSubtree(
                key: ValueKey(_filter),
                child: _buildBuiltIn(shown, provider, bottom),
              ),
            ),
          ),
        );
      },
    );
  }

  // Hide the bottom bar while scrolling down, show it when scrolling up or
  // when back at the top.
  bool _onUserScroll(UserScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (n.metrics.pixels <= n.metrics.minScrollExtent + 1) {
      _setNavHidden(false);
    } else if (n.direction == ScrollDirection.reverse) {
      _setNavHidden(true);
    } else if (n.direction == ScrollDirection.forward) {
      _setNavHidden(false);
    }
    return false;
  }

  void _setNavHidden(bool hidden) {
    if (!mounted) return;
    context.read<MainNavigationProvider>().setNavHidden(hidden);
  }

  Widget _buildBuiltIn(
    List<PromptItem> items,
    PromptsProvider provider,
    double bottom,
  ) {
    if (items.isEmpty) {
      return _filter == _Filter.favorites && _query.isEmpty
          ? const _EmptyState(
              emoji: '💜',
              title: 'No favorites yet',
              body: 'Tap the heart on any prompt to save it here.',
            )
          : const _EmptyState(
              emoji: '🔍',
              title: 'No prompts found',
              body: 'Try a different word or switch the filter.',
            );
    }
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!provider.isPremium)
            _UnlockBanner(
              lockedCount: PromptsProvider.lockedCountAllSeasons,
              freePerMode: PromptsProvider.freePromptsPerMode,
              onTap: _showPremiumRequiredDialog,
            ),
          MasonryGrid(
            tiles: [
              for (final item in items)
                MasonryTile(
                  key: item.id,
                  child: (h) => _PromptTile(
                    height: h,
                    title: item.title,
                    subtitle: item.tagline.isNotEmpty
                        ? item.tagline
                        : _tagLine(item.tags),
                    isLocked: provider.isPromptLocked(item),
                    isFavorite: provider.isFavorite(item.id),
                    onFavorite: () => provider.toggleFavorite(item.id),
                    preview: _previewFor(item, radius: 0),
                    onTap: () => _openBuiltIn(item, provider),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- dialogs

  /// Locked styles go straight to the plans: one tap, no extra dialog.
  void _showPremiumRequiredDialog() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PurchasePage()));
  }
}

// =============================================================== widgets

/// One compact row: a circular search button on the far left, followed by the
/// filter tags. Tapping the circle expands it horizontally into a search field
/// (tags fade/slide away); the close button collapses it again.
///
/// Performance: the layout is computed once. The expansion is purely a
/// paint/transform animation (animated pill painter, fade and slide
/// transitions), so no widget is re-laid-out or rebuilt per frame.
class _SearchAndFilters extends StatefulWidget {
  const _SearchAndFilters({
    required this.controller,
    required this.selected,
    required this.counts,
    required this.onFilterChanged,
    required this.onQueryChanged,
  });

  final TextEditingController controller;
  final _Filter selected;
  final Map<_Filter, int> counts;
  final ValueChanged<_Filter> onFilterChanged;
  final ValueChanged<String> onQueryChanged;

  @override
  State<_SearchAndFilters> createState() => _SearchAndFiltersState();
}

class _SearchAndFiltersState extends State<_SearchAndFilters>
    with SingleTickerProviderStateMixin {
  static const double _h = 44;
  static const _labels = {
    _Filter.text: 'Text to Image',
    _Filter.realistic: 'Realistic Photo',
    _Filter.fantasy: 'Fantasy Photo',
    _Filter.favorites: 'Favorites',
  };

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  late final Animation<double> _chipsOpacity = Tween<double>(
    begin: 1,
    end: 0,
  ).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5)));
  late final Animation<Offset> _chipsSlide = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(0.08, 0),
  ).animate(_t);
  late final Animation<double> _fieldOpacity = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.45, 1, curve: Curves.easeOut),
  );

  final FocusNode _focus = FocusNode();
  final ScrollController _scroll = ScrollController();

  bool get _open =>
      _ctrl.status == AnimationStatus.forward ||
      _ctrl.status == AnimationStatus.completed;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _openSearch() async {
    if (_open) return;
    HapticFeedback.selectionClick();
    // The circle scrolls with the tags; bring it home before expanding.
    if (_scroll.hasClients && _scroll.offset > 1) {
      await _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
      );
    }
    if (!mounted) return;
    _ctrl.forward();
    _focus.requestFocus();
    setState(() {}); // refresh hit-testing flags only
  }

  void _closeSearch() {
    _focus.unfocus();
    widget.controller.clear();
    widget.onQueryChanged('');
    _ctrl.reverse();
    setState(() {});
  }

  /// The collapsed search button: first item of the horizontal list, so it
  /// scrolls away together with the filter tags.
  Widget _searchCircle() {
    return Semantics(
      button: true,
      label: 'Search prompts',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openSearch,
        child: Container(
          width: _h,
          height: _h,
          decoration: BoxDecoration(
            color: SeasonPalette.text.withOpacity(0.06),
            shape: BoxShape.circle,
            border: Border.all(color: SeasonPalette.text.withOpacity(0.12)),
          ),
          child: Icon(
            Icons.search_rounded,
            size: 22,
            color: SeasonPalette.text.withOpacity(0.85),
          ),
        ),
      ),
    );
  }

  Widget _chips() {
    return ListView.separated(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _Filter.values.length + 1,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, index) {
        if (index == 0) return _searchCircle();
        final i = index - 1;
        final f = _Filter.values[i];
        final on = f == widget.selected;
        return Semantics(
          button: true,
          selected: on,
          child: GestureDetector(
            onTap: () {
              if (!on) HapticFeedback.selectionClick();
              widget.onFilterChanged(f);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on
                    ? SeasonPalette.accent
                    : SeasonPalette.text.withOpacity(0.06),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: on
                      ? SeasonPalette.accent
                      : SeasonPalette.text.withOpacity(0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _labels[f]!,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: on ? SeasonPalette.onAccent : SeasonPalette.text,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.counts[f] ?? 0}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: on
                          ? SeasonPalette.onAccent
                          : SeasonPalette.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final open = _open;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
      child: SizedBox(
        height: _h,
        child: LayoutBuilder(
          builder: (context, box) {
            final maxW = box.maxWidth - 32;
            return RepaintBoundary(
              child: Stack(
                children: [
                  // Filter tags (laid out once, faded/slid by transforms).
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: open,
                      child: FadeTransition(
                        opacity: _chipsOpacity,
                        child: SlideTransition(
                          position: _chipsSlide,
                          child: _chips(),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    left: 16,
                    right: 16,
                    child: Stack(
                      children: [
                        // Animated pill background (paint only).
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _PillPainter(
                                t: _t,
                                maxWidth: maxW,
                                height: _h,
                                accent: SeasonPalette.accent,
                                base: SeasonPalette.scaffold,
                              ),
                            ),
                          ),
                        ),
                        // Search field: laid out at full width once, revealed by fade.
                        Positioned(
                          left: _h,
                          right: _h,
                          top: 0,
                          bottom: 0,
                          child: IgnorePointer(
                            ignoring: !open,
                            child: FadeTransition(
                              opacity: _fieldOpacity,
                              child: Center(
                                child: TextField(
                                  controller: widget.controller,
                                  focusNode: _focus,
                                  onChanged: widget.onQueryChanged,
                                  textInputAction: TextInputAction.search,
                                  cursorColor: SeasonPalette.accent,
                                  textAlignVertical: TextAlignVertical.center,
                                  style: const TextStyle(fontSize: 15),
                                  decoration: const InputDecoration(
                                    hintText: 'Search prompts',
                                    filled: false,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Close button, pinned to the right edge of the open pill.
                        Positioned(
                          right: 0,
                          top: 0,
                          width: _h,
                          height: _h,
                          child: IgnorePointer(
                            ignoring: !open,
                            child: FadeTransition(
                              opacity: _fieldOpacity,
                              child: Semantics(
                                button: true,
                                label: 'Close search',
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: _closeSearch,
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 20,
                                    color: SeasonPalette.text.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Search icon of the expanded pill (the collapsed one is part
                        // of the scrolling list).
                        Positioned(
                          left: 0,
                          top: 0,
                          width: _h,
                          height: _h,
                          child: IgnorePointer(
                            child: FadeTransition(
                              opacity: _t,
                              child: Icon(
                                Icons.search_rounded,
                                size: 22,
                                color: SeasonPalette.accent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Draws the circle→pill background. Repaints from the animation only.
class _PillPainter extends CustomPainter {
  _PillPainter({
    required this.t,
    required this.maxWidth,
    required this.height,
    required this.accent,
    required this.base,
  }) : super(repaint: t);

  final Animation<double> t;
  final double maxWidth;
  final double height;
  final Color accent;
  final Color base;

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    if (v <= 0.001) return; // collapsed: the list's own circle is shown

    // Opaque colors so the list item underneath is fully covered.
    final fillClosed = Color.alphaBlend(
      SeasonPalette.text.withOpacity(0.06),
      base,
    );
    final fillOpen = Color.alphaBlend(
      SeasonPalette.text.withOpacity(0.08),
      base,
    );
    final w = height + (maxWidth - height) * v;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, height),
      Radius.circular(height / 2),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = Color.lerp(fillClosed, fillOpen, v)!,
    );
    canvas.drawRRect(
      rect.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Color.lerp(
          Color.alphaBlend(SeasonPalette.text.withOpacity(0.12), base),
          accent.withOpacity(0.7),
          v,
        )!,
    );
  }

  @override
  bool shouldRepaint(covariant _PillPainter old) =>
      old.maxWidth != maxWidth ||
      old.height != height ||
      old.accent != accent ||
      old.base != base ||
      old.t != t;
}

/// Image-first tile: full-bleed sample, title and one-line prompt on a solid
/// dark footer. No borders, no buttons; the whole tile is the tap target.
class _PromptTile extends StatelessWidget {
  const _PromptTile({
    required this.height,
    required this.title,
    required this.subtitle,
    required this.isLocked,
    required this.preview,
    required this.onTap,
    required this.isFavorite,
    required this.onFavorite,
  });

  final double height;
  final String title;
  final String subtitle;
  final bool isLocked;
  final Widget preview;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              preview,
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.black.withOpacity(0.62),
                  padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withOpacity(0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isLocked)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD54F), Color(0xFFFF9800)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.workspace_premium_rounded,
                          size: 13,
                          color: Color(0xFF3B2300),
                        ),
                        SizedBox(width: 3),
                        Text(
                          'PRO',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: Color(0xFF3B2300),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                top: 2,
                right: 2,
                child: Semantics(
                  button: true,
                  label: isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onFavorite();
                    },
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            transitionBuilder: (c, a) =>
                                ScaleTransition(scale: a, child: c),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              key: ValueKey(isFavorite),
                              size: 18,
                              color: isFavorite
                                  ? SeasonPalette.accent
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slim, quiet upsell above the list for free users: one line of value, one
/// tap to the plans. No animation, scrolls away with the list.
class _UnlockBanner extends StatelessWidget {
  const _UnlockBanner({
    required this.lockedCount,
    required this.freePerMode,
    required this.onTap,
  });

  final int lockedCount;
  final int freePerMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = SeasonPalette.accent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        label:
            'Go Pro: unlock $lockedCount more styles and get 50 tokens every month',
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 56,
            padding: const EdgeInsets.fromLTRB(14, 0, 8, 0),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.workspace_premium_rounded, color: accent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unlock $lockedCount more styles',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        '+50 tokens every month with Premium',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: SeasonPalette.text.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Go Pro',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.emoji,
    required this.title,
    required this.body,
  });
  final String emoji;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: SeasonPalette.text.withOpacity(0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
