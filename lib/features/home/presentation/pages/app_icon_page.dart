import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/app_icon_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/seasons/season_palette.dart';
import '../../../../core/theme/seasons/season_registry.dart';
import '../../../../core/theme/seasons/season_theme.dart';
import '../../../../core/utils/platform_utils.dart';

/// Lets the user pick the home-screen icon, one per season.
class AppIconPage extends StatefulWidget {
  const AppIconPage({super.key});

  @override
  State<AppIconPage> createState() => _AppIconPageState();
}

class _AppIconPageState extends State<AppIconPage> {
  SeasonId? _current;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    AppIconService.current().then((id) {
      if (mounted) setState(() => _current = id);
    });
  }

  Future<void> _select(SeasonId season) async {
    if (_busy || season == _current) return;
    HapticFeedback.selectionClick();
    final previous = _current;
    setState(() {
      _current = season;
      _busy = true;
    });
    final ok = await AppIconService.setIcon(season);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!ok) _current = previous;
    });
    if (!ok) {
      NotificationService.error(
        context,
        message: 'Could not change the app icon.',
      );
    } else {
      NotificationService.success(
        context,
        message: PlatformUtils.isAndroid
            ? '${SeasonRegistry.byId(season).displayName} icon selected. '
                  'It appears on your home screen after you leave the app.'
            : '${SeasonRegistry.byId(season).displayName} icon is now on '
                  'your home screen.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final seasons = SeasonRegistry.all
        .where((s) => AppIconService.previewAssets.containsKey(s.id))
        .toList();
    return Scaffold(
      backgroundColor: SeasonPalette.scaffold,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: SeasonPalette.text,
        title: const Text(
          'App icon',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              'Choose the icon that appears on your home screen.',
              style: TextStyle(
                fontSize: 14,
                color: SeasonPalette.text.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.82,
              children: [for (final s in seasons) _tile(s)],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(SeasonTheme season) {
    final selected = season.id == _current;
    return Semantics(
      button: true,
      selected: selected,
      label: '${season.displayName} app icon',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _select(season.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: SeasonPalette.inputFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? season.accent : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        AppIconService.previewAssets[season.id]!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${season.emoji} ${season.displayName}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: SeasonPalette.text,
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: season.accent,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
