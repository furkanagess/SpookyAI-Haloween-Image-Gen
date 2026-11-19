import 'package:in_app_review/in_app_review.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/token_display_widget.dart';
import '../../../../core/services/profile_provider.dart';
import '../../../../core/services/app_icon_service.dart';
import '../../../../core/services/ambient_sound_service.dart';
import '../../../../core/theme/seasons/season_registry.dart';
import '../../../../core/theme/seasons/season_theme.dart';
import '../../../../core/services/version_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/platform_utils.dart';
import '../../../../core/widgets/app_bar_title.dart';
import '../../../../core/theme/app_metrics.dart';
import 'purchase_page.dart';
import 'app_icon_page.dart';
import '../../../../core/theme/seasons/season_provider.dart';
import '../../../../core/theme/seasons/season_palette.dart';
import '../../../tour/product_tour.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _appIconSupported = false;
  SeasonId _appIcon = SeasonId.halloween;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Load profile data through provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfileData();
    });
    _loadAppIcon();
  }

  Future<void> _loadAppIcon() async {
    final supported = await AppIconService.isSupported();
    final current = supported
        ? await AppIconService.current()
        : SeasonId.halloween;
    if (!mounted) return;
    setState(() {
      _appIconSupported = supported;
      _appIcon = current;
    });
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

  // ------------------------------------------------------------- sections

  void _openPurchase() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const PurchasePage()));

  /// A titled group of rows on one soft surface; rows are divided by an
  /// inset hairline instead of being cards of their own.
  Widget _group(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: SeasonPalette.text.withOpacity(0.45),
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            color: SeasonPalette.inputFill,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 62,
                      color: SeasonPalette.text.withOpacity(0.07),
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _row({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap();
            },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: SeasonPalette.text.withOpacity(0.55),
                        ),
                      ),
                  ],
                ),
              ),
              trailing ??
                  (onTap != null
                      ? Icon(
                          Icons.chevron_right_rounded,
                          color: SeasonPalette.text.withOpacity(0.3),
                        )
                      : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorldGroup() {
    final season = context.watch<SeasonProvider>();

    Widget segment(ThemeMode mode, IconData icon, String label) {
      final selected = season.themeMode == mode;
      return Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (selected) return;
            HapticFeedback.selectionClick();
            season.setThemeMode(mode);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: selected ? SeasonPalette.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 17,
              color: selected
                  ? Colors.white
                  : SeasonPalette.text.withOpacity(0.55),
            ),
          ),
        ),
      );
    }

    return _group('Appearance', [
      KeyedSubtree(
        key: ProductTourKeys.themeMode,
        child: _row(
          icon: switch (season.themeMode) {
            ThemeMode.light => Icons.light_mode_rounded,
            ThemeMode.dark => Icons.dark_mode_rounded,
            ThemeMode.system => Icons.brightness_auto_rounded,
          },
          color: const Color(0xFFFFC107),
          title: 'Theme',
          subtitle: switch (season.themeMode) {
            ThemeMode.light => 'Light',
            ThemeMode.dark => 'Dark',
            ThemeMode.system => 'Follows your device',
          },
          trailing: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: SeasonPalette.text.withOpacity(0.06),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                segment(
                  ThemeMode.system,
                  Icons.brightness_auto_rounded,
                  'System',
                ),
                segment(ThemeMode.light, Icons.light_mode_rounded, 'Light'),
                segment(ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
              ],
            ),
          ),
        ),
      ),
      KeyedSubtree(
        key: ProductTourKeys.effects,
        child: _row(
          icon: Icons.auto_awesome_rounded,
          color: const Color(0xFF4FC3F7),
          title: 'Theme effects',
          subtitle: 'Falling snow, embers and more on every screen',
          trailing: Switch(
            value: season.effectsEnabled,
            activeThumbColor: SeasonPalette.accent,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              season.setEffectsEnabled(v);
            },
          ),
        ),
      ),
      KeyedSubtree(key: ProductTourKeys.sound, child: _buildSoundRow()),
      if (_appIconSupported)
        KeyedSubtree(
          key: ProductTourKeys.appIcon,
          child: _row(
            icon: Icons.apps_rounded,
            color: const Color(0xFFAB47BC),
            title: 'App icon',
            subtitle: SeasonRegistry.byId(_appIcon).displayName,
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: SeasonPalette.text.withOpacity(0.4),
            ),
            onTap: () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AppIconPage()));
              _loadAppIcon();
            },
          ),
        ),
    ]);
  }

  Widget _buildSoundRow() {
    final sound = context.watch<AmbientSoundController>();
    final on = sound.enabled;
    return Column(
      children: [
        _row(
          icon: on && sound.volume > 0
              ? Icons.music_note_rounded
              : Icons.music_off_rounded,
          color: const Color(0xFFEC407A),
          title: 'Theme sound',
          subtitle: sound.hasSoundForSeason
              ? 'Ambient music for the current season'
              : 'No sound for this season yet',
          trailing: Switch(
            value: on,
            activeThumbColor: SeasonPalette.accent,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              sound.setEnabled(v);
            },
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: on
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(52, 0, 12, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.volume_down_rounded,
                        size: 20,
                        color: SeasonPalette.text.withOpacity(0.45),
                      ),
                      Expanded(
                        child: Slider(
                          value: sound.volume,
                          activeColor: SeasonPalette.accent,
                          inactiveColor: SeasonPalette.text.withOpacity(0.12),
                          label: '${(sound.volume * 100).round()}%',
                          divisions: 20,
                          semanticFormatterCallback: (v) =>
                              'Volume ${(v * 100).round()} percent',
                          onChanged: sound.setVolume,
                          onChangeEnd: (_) => sound.saveVolume(),
                        ),
                      ),
                      Icon(
                        Icons.volume_up_rounded,
                        size: 20,
                        color: SeasonPalette.text.withOpacity(0.45),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _buildHelpGroup() {
    return _group('Help', [
      _row(
        icon: Icons.support_agent_rounded,
        color: const Color(0xFF26A69A),
        title: 'Contact support',
        subtitle: 'spookyaihelp@gmail.com',
        trailing: Icon(
          Icons.copy_rounded,
          size: 20,
          color: SeasonPalette.text.withOpacity(0.4),
        ),
        onTap: _copyEmailToClipboard,
      ),
      _row(
        icon: Icons.star_rounded,
        color: const Color(0xFFFFC107),
        title: 'Rate SpookyAI',
        subtitle: PlatformUtils.isAndroid
            ? 'Enjoying it? Rate us on Google Play'
            : 'Enjoying it? Rate us on the App Store',
        onTap: _requestInAppReview,
      ),
    ]);
  }

  Future<void> _copyEmailToClipboard() async {
    const email = 'spookyaihelp@gmail.com';
    await Clipboard.setData(const ClipboardData(text: email));
    if (mounted) {
      NotificationService.success(
        context,
        message: 'Email copied to clipboard!',
      );
    }
  }

  static const String _androidPackageId = 'com.furkanages.spookyai';

  /// Tries each URL in turn and stops at the first one that actually opens.
  /// `canLaunchUrl` alone is not trusted here: on Android 11+ it can
  /// wrongly report false for a scheme that `launchUrl` would still open,
  /// unless the manifest declares that scheme under `<queries>` (see
  /// AndroidManifest.xml) — so every candidate is attempted directly.
  Future<bool> _tryLaunch(List<String> urls) async {
    for (final url in urls) {
      try {
        final uri = Uri.parse(url);
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          return true;
        }
      } catch (_) {
        // Try the next candidate.
      }
    }
    return false;
  }

  /// Shows the system rating sheet inside the app (StoreKit on iOS, Play
  /// In-App Review on Android). The OS may skip it (quota, no Play
  /// services), so fall back to the store listing then.
  Future<void> _requestInAppReview() async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
        return;
      }
    } catch (_) {}
    await _openStorePage();
  }

  Future<void> _openStorePage() async {
    List<String> urls;

    if (PlatformUtils.isAndroid) {
      urls = [
        // The Play Store app itself, if installed: no browser hop, and the
        // most reliable path on Android.
        'market://details?id=$_androidPackageId',
        // Falls back to the web listing (also opens the Play Store app on
        // most devices via an app link, or a browser otherwise).
        'https://play.google.com/store/apps/details?id=$_androidPackageId',
      ];
    } else if (PlatformUtils.isIOS) {
      urls = [
        'https://apps.apple.com/us/app/spookyai-halloween-image-gen/id6753217831',
      ];
    } else {
      if (mounted) {
        NotificationService.error(
          context,
          message: 'Store not available on this platform.',
        );
      }
      return;
    }

    final opened = await _tryLaunch(urls);
    if (!opened && mounted) {
      NotificationService.error(
        context,
        message: 'Could not open store page. Please try again later.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: SeasonPalette.scaffold,
          appBar: AppBar(
            title: const AppBarTitle(
              icon: Icons.person_rounded,
              title: 'Profile',
            ),
            backgroundColor: SeasonPalette.scaffold,
            elevation: 0,
            toolbarHeight: AppMetrics.toolbarHeight,
            actions: [TokenDisplayWidget(onTap: _openPurchase)],
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: provider.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: SeasonPalette.accent,
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        24 + MediaQuery.of(context).padding.bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildWorldGroup(),
                          const SizedBox(height: 24),
                          _buildHelpGroup(),
                          const SizedBox(height: 20),
                          _buildVersionInfo(),
                        ],
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVersionInfo() {
    return FutureBuilder<Map<String, String>>(
      future: VersionService.getVersionInfo(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 8);
        final info = snapshot.data!;
        final version = info['version'] ?? '1.1.0';
        final build = info['buildNumber'] ?? '15';
        return Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Text(
            'SpookyAI $version ($build)',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SeasonPalette.text.withOpacity(0.35),
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }
}
