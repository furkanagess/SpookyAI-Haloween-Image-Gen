import 'dart:async';
import '../../../../core/services/analytics_service.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/widgets/app_bar_title.dart';
import '../../../../core/theme/app_metrics.dart';
import '../../../../core/services/image_storage_service.dart';
import '../../../../core/services/saved_images_provider.dart';
import '../../../../core/services/saved_videos_provider.dart';
import 'package:flutter/rendering.dart';
import '../../../../core/services/main_navigation_provider.dart';
import '../widgets/masonry_grid.dart';
import 'content_report_detail_page.dart';
import 'generated_result_page.dart';
import 'videos_page.dart';
import '../../data/services/prompt_service.dart';
import '../../domain/generation_mode.dart';
import '../../domain/generated_image_result.dart';
import '../../../../core/theme/seasons/season_palette.dart';

class PhotosPage extends StatefulWidget {
  final VoidCallback? onNavigateToGenerate;

  const PhotosPage({super.key, this.onNavigateToGenerate});

  @override
  State<PhotosPage> createState() => _PhotosPageState();
}

class _PhotosPageState extends State<PhotosPage> with TickerProviderStateMixin {
  /// Which half of the gallery is shown: pictures or videos.
  bool _showVideos = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<Uint8List?> _getImageBytes(String imageId, String filePath) async {
    final provider = context.read<SavedImagesProvider>();
    return await provider.getImageBytes(imageId, filePath);
  }

  Future<void> _showReportDialog(SavedImage image) async {
    final imageBytes = await _getImageBytes(image.id, image.filePath);

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContentReportDetailPage(
          prompt: image.prompt,
          imageBytes: imageBytes,
          imageId: image.id,
          imagePath: image.filePath,
        ),
      ),
    );

    // Optionally handle the result if needed
    if (result == true) {
      // Report was submitted successfully
    }
  }

  Future<void> _deleteImage(String imageId) async {
    try {
      final provider = context.read<SavedImagesProvider>();
      await provider.deleteById(imageId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image deleted successfully'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareImage(String filePath) async {
    try {
      // Anchors the share sheet on iPad; without it the sheet can fail to
      // appear there.
      final box = context.findRenderObject() as RenderBox?;
      final origin = box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size;
      unawaited(AnalyticsService.imageShared('gallery'));
      await Share.shareXFiles([XFile(filePath)], sharePositionOrigin: origin);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(String imageId, String prompt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SeasonPalette.inputFill,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.delete_rounded, color: Colors.red, size: 24),
            SizedBox(width: 12),
            Text(
              'Delete Creation',
              style: TextStyle(
                color: SeasonPalette.text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$prompt"? This action cannot be undone.',
          style: TextStyle(
            color: SeasonPalette.text.withOpacity(0.70),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: SeasonPalette.text.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteImage(imageId);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A gallery picture opens on the same detail screen as a fresh result:
  /// the picture, its style and description, and Share / Make video, plus
  /// Delete and Report in the menu.
  Future<void> _showImagePreview(SavedImage image) async {
    final bytes = await _getImageBytes(image.id, image.filePath);
    if (!mounted) return;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This image could not be opened.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    await openGeneratedResultPage(
      context,
      result: GeneratedImageResult(
        imageBytes: bytes,
        prompt: image.prompt,
        source: GeneratedImageSource.fal,
        generatedAt: image.createdAt,
        isPersisted: true, // it is already in the gallery
      ),
      style: PromptService.findForSaved(image.prompt),
      mode: image.isImageToImage ? GenerationMode.image : GenerationMode.text,
      onShare: (_) => _shareImage(image.filePath),
      onDelete: () => _showDeleteConfirmation(image.id, image.prompt),
      onReport: () => _showReportDialog(image),
    );
  }

  Widget build(BuildContext context) {
    return Consumer<SavedImagesProvider>(
      builder: (context, provider, child) {
        final videoCount = context.watch<SavedVideosProvider>().videos.length;
        return Scaffold(
          backgroundColor: SeasonPalette.scaffold,
          // Same as Prompts: the header slides away on scroll down and comes
          // back on any scroll up (floating + snap); the bottom bar follows.
          body: NotificationListener<UserScrollNotification>(
            onNotification: _onUserScroll,
            child: NestedScrollView(
              floatHeaderSlivers: true,
              headerSliverBuilder: (context, _) => [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  pinned: false,
                  surfaceTintColor: Colors.transparent,
                  scrolledUnderElevation: 0,
                  title: const AppBarTitle(
                    icon: Icons.photo_library_rounded,
                    title: 'My Photos',
                  ),
                  backgroundColor: SeasonPalette.scaffold,
                  elevation: 0,
                  toolbarHeight: AppMetrics.toolbarHeight,
                  actions: [
                    if (!_showVideos && provider.images.isNotEmpty)
                      IconButton(
                        tooltip: 'Storage info',
                        onPressed: _showStorageInfo,
                        icon: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: SeasonPalette.inputFill,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: SeasonPalette.text.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: SeasonPalette.accent,
                            size: 20,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(
                      AppMetrics.photosBottomHeight,
                    ),
                    child: _GalleryTabs(
                      showVideos: _showVideos,
                      imageCount: provider.images.length,
                      videoCount: videoCount,
                      onChanged: (v) {
                        if (v == _showVideos) return;
                        HapticFeedback.selectionClick();
                        context.read<MainNavigationProvider>().setNavHidden(
                          false,
                        );
                        setState(() => _showVideos = v);
                      },
                    ),
                  ),
                ),
              ],
              body: Stack(
                children: [
                  // Background decorations
                  Positioned(
                    bottom: 40,
                    left: 20,
                    child: Opacity(
                      opacity: 0.06,
                      child: Text(
                        SeasonPalette.t('🕸️'),
                        style: TextStyle(fontSize: 80),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 60,
                    right: 20,
                    child: Opacity(
                      opacity: 0.04,
                      child: Text(
                        SeasonPalette.t('🎃'),
                        style: TextStyle(fontSize: 60),
                      ),
                    ),
                  ),

                  // Main content
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      // Cross-fade between the two grids instead of a hard cut.
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        layoutBuilder: (current, previous) => Stack(
                          fit: StackFit.expand,
                          children: [...previous, ?current],
                        ),
                        child: _showVideos
                            ? const KeyedSubtree(
                                key: ValueKey('videos'),
                                child: VideosGrid(),
                              )
                            : KeyedSubtree(
                                key: const ValueKey('images'),
                                child: _buildBody(provider),
                              ),
                      ),
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

  Widget _buildBody(SavedImagesProvider provider) {
    if (provider.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: SeasonPalette.accent),
      );
    }

    if (provider.images.isEmpty) {
      return _buildEmptyState();
    }

    // Pictures slide under the translucent bottom bar, which tucks away
    // while scrolling down and returns on any scroll up (as on Prompts).
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        16,
        4,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      child: MasonryGrid(
        tiles: [
          for (final image in provider.images)
            MasonryTile(
              key: image.id,
              child: (h) => _GalleryTile(
                image: image,
                loadBytes: () => _getImageBytes(image.id, image.filePath),
                onTap: () => _showImagePreview(image),
              ),
            ),
        ],
      ),
    );
  }

  bool _onUserScroll(UserScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    final nav = context.read<MainNavigationProvider>();
    if (n.metrics.pixels <= n.metrics.minScrollExtent + 1) {
      nav.setNavHidden(false);
    } else if (n.direction == ScrollDirection.reverse) {
      nav.setNavHidden(true);
    } else if (n.direction == ScrollDirection.forward) {
      nav.setNavHidden(false);
    }
    return false;
  }

  Widget _buildEmptyState() {
    return Stack(
      children: [
        // Background decorations
        Positioned(
          top: 40,
          right: 20,
          child: Opacity(
            opacity: 0.06,
            child: Text(SeasonPalette.t('🕷️'), style: TextStyle(fontSize: 80)),
          ),
        ),
        Positioned(
          bottom: 100,
          left: 20,
          child: Opacity(
            opacity: 0.06,
            child: Text(SeasonPalette.t('🎃'), style: TextStyle(fontSize: 80)),
          ),
        ),
        Positioned(
          top: 120,
          left: 40,
          child: Opacity(
            opacity: 0.04,
            child: Text(SeasonPalette.t('🕸️'), style: TextStyle(fontSize: 60)),
          ),
        ),

        // Main content
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modern icon container
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: SeasonPalette.inputFill,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: SeasonPalette.accent.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: SeasonPalette.accent.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_fix_high_rounded,
                    color: SeasonPalette.accent,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Start Creating Magic',
                  style: TextStyle(
                    color: SeasonPalette.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  'Generate your first spooky creation and it will appear here',
                  style: TextStyle(
                    color: SeasonPalette.text.withOpacity(0.70),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Call to action button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: SeasonPalette.accent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: SeasonPalette.accent.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // Navigate to generation tab
                        widget.onNavigateToGenerate?.call();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Create Your First Image',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Removed date formatter since creation info overlay is removed

  /// What is stored, in plain numbers, and the one destructive action
  /// ("Delete all") kept here instead of in the app bar.
  Future<void> _showStorageInfo() async {
    final info = await ImageStorageService.getStorageInfo();
    if (!mounted) return;
    final count = info['count'] as int? ?? 0;
    final mb = info['totalSizeMB']?.toString() ?? '0.00';
    final accent = SeasonPalette.accent;

    Widget stat(IconData icon, String value, String label) => Expanded(
      child: Column(
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: SeasonPalette.text.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );

    final deleteAll = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: SeasonPalette.scaffold,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: SeasonPalette.text.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Your storage',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.7,
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Cancel',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(ctx).pop(false),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: SeasonPalette.text.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: SeasonPalette.text.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // The two numbers that matter.
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: SeasonPalette.inputFill,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    stat(Icons.photo_library_rounded, '$count', 'Creations'),
                    Container(
                      width: 1,
                      height: 64,
                      color: SeasonPalette.text.withOpacity(0.08),
                    ),
                    stat(Icons.sd_storage_rounded, mb, 'MB used'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Icon(Icons.verified_user_rounded, size: 20, color: accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Saved on this device and in your photo gallery.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: SeasonPalette.text.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: count == 0
                      ? null
                      : () => Navigator.of(ctx).pop(true),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text(
                    'Delete all creations',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF6B6B),
                    side: BorderSide(
                      color: const Color(0xFFFF6B6B).withOpacity(0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // The confirmation is the existing dialog; it opens after the sheet.
    if (deleteAll == true && mounted) _showClearAllDialog();
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SeasonPalette.inputFill,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red, size: 24),
            SizedBox(width: 12),
            Text(
              'Clear All Images',
              style: TextStyle(
                color: SeasonPalette.text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete all your creations? This action cannot be undone.',
          style: TextStyle(
            color: SeasonPalette.text.withOpacity(0.70),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: SeasonPalette.text.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<SavedImagesProvider>();
              await ImageStorageService.clearAllImages();
              await provider.refresh();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All images cleared'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Clear All',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One picture of the gallery: full-bleed, rounded, with its name on a solid
/// footer. The bytes are loaded once, not on every rebuild.
class _GalleryTile extends StatefulWidget {
  const _GalleryTile({
    required this.image,
    required this.loadBytes,
    required this.onTap,
  });

  final SavedImage image;
  final Future<Uint8List?> Function() loadBytes;
  final VoidCallback onTap;

  @override
  State<_GalleryTile> createState() => _GalleryTileState();
}

class _GalleryTileState extends State<_GalleryTile> {
  late final Future<Uint8List?> _bytes = widget.loadBytes();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Generated image',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FutureBuilder<Uint8List?>(
                future: _bytes,
                builder: (context, snap) {
                  if (snap.hasData && snap.data != null) {
                    return Image.memory(
                      snap.data!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    );
                  }
                  final waiting =
                      snap.connectionState == ConnectionState.waiting;
                  return ColoredBox(
                    color: SeasonPalette.card,
                    child: Center(
                      child: waiting
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: SeasonPalette.accent,
                              ),
                            )
                          : Icon(
                              Icons.broken_image_outlined,
                              color: SeasonPalette.subtleIcon,
                              size: 30,
                            ),
                    ),
                  );
                },
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.black.withOpacity(0.55),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 9),
                  child: Text(
                    // Same name as the detail screen's title.
                    PromptService.savedTitle(widget.image.prompt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: Colors.white,
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

/// Image / Video switch at the top of the Photos screen, always shown.
/// One accent pill slides between the tabs (no colour cross-fade through
/// transparent, which looked muddy); the labels change colour with it.
class _GalleryTabs extends StatelessWidget {
  const _GalleryTabs({
    required this.showVideos,
    required this.imageCount,
    required this.videoCount,
    required this.onChanged,
  });

  final bool showVideos;
  final int imageCount;
  final int videoCount;
  final ValueChanged<bool> onChanged;

  static const _duration = Duration(milliseconds: 260);
  static const _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final accent = SeasonPalette.accent;
    return Container(
      height: 44,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: SeasonPalette.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SeasonPalette.text.withOpacity(0.08)),
      ),
      child: Stack(
        children: [
          // The sliding selection pill.
          AnimatedAlign(
            duration: _duration,
            curve: _curve,
            alignment: showVideos
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _tab(
                selected: !showVideos,
                icon: Icons.photo_library_rounded,
                label: 'Image',
                count: imageCount,
                onTap: () => onChanged(false),
              ),
              _tab(
                selected: showVideos,
                icon: Icons.video_library_rounded,
                label: 'Video',
                count: videoCount,
                onTap: () => onChanged(true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tab({
    required bool selected,
    required IconData icon,
    required String label,
    required int count,
    required VoidCallback onTap,
  }) {
    final idle = SeasonPalette.text.withOpacity(0.7);
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '$label, $count',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: TweenAnimationBuilder<Color?>(
            duration: _duration,
            curve: _curve,
            tween: ColorTween(end: selected ? Colors.white : idle),
            builder: (context, fg, _) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 6),
                Text(
                  count > 0 ? '$label · $count' : label,
                  maxLines: 1,
                  style: TextStyle(
                    color: fg,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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
