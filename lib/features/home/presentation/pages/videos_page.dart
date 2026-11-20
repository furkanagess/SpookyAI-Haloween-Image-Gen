import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/saved_videos_provider.dart';
import '../../../../core/theme/app_metrics.dart';
import '../../../../core/theme/seasons/season_palette.dart';
import '../../../../core/widgets/app_bar_title.dart';
import '../widgets/masonry_grid.dart';
import 'video_result_page.dart';

/// Every video made with image to video, in the same masonry grid as the
/// Photos tab. A tap opens the video detail screen.
class VideosPage extends StatelessWidget {
  const VideosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SavedVideosProvider>(
      builder: (context, store, _) {
        return Scaffold(
          backgroundColor: SeasonPalette.scaffold,
          appBar: AppBar(
            title: const AppBarTitle(
              icon: Icons.video_library_rounded,
              title: 'My Videos',
            ),
            backgroundColor: SeasonPalette.scaffold,
            elevation: 0,
            toolbarHeight: AppMetrics.toolbarHeight,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(
                AppMetrics.photosBottomHeight,
              ),
              child: Container(
                height: 44,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: SeasonPalette.accent,
                ),
                child: Center(
                  child: Text(
                    store.videos.isEmpty
                        ? 'Your videos are saved here'
                        : 'Tap a video to play, save or share',
                    style: TextStyle(
                      color: SeasonPalette.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: const VideosGrid(),
        );
      },
    );
  }
}

/// The video grid (or its empty state). Used by My Videos and by the Video
/// tab of the Photos screen.
class VideosGrid extends StatelessWidget {
  const VideosGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SavedVideosProvider>();
    if (store.isLoading && store.videos.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: SeasonPalette.accent),
      );
    }
    if (store.videos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.movie_creation_outlined,
                size: 56,
                color: SeasonPalette.accent,
              ),
              const SizedBox(height: 18),
              const Text(
                'No videos yet',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Open a picture and tap "Make it a video".',
                textAlign: TextAlign.center,
                style: TextStyle(color: SeasonPalette.text.withOpacity(0.6)),
              ),
            ],
          ),
        ),
      );
    }
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
          for (final video in store.videos)
            MasonryTile(
              key: video.id,
              child: (h) => _VideoTile(
                video: video,
                posterPath: store.posterPath(video),
                onTap: () => openVideoResultPage(context, video: video),
              ),
            ),
        ],
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({
    required this.video,
    required this.posterPath,
    required this.onTap,
  });

  final SavedVideo video;
  final String posterPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Video',
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
              Image.file(
                File(posterPath),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                cacheWidth: 600,
                errorBuilder: (_, __, ___) => ColoredBox(
                  color: SeasonPalette.card,
                  child: Icon(
                    Icons.movie_outlined,
                    color: SeasonPalette.subtleIcon,
                    size: 30,
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.black.withOpacity(0.55),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 9),
                  child: Text(
                    video.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
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
