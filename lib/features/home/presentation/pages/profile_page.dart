import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/token_display_widget.dart';
import '../../../../core/widgets/rewarded_ad_widget.dart';
import '../../../../core/services/profile_provider.dart';
import '../../../../core/services/version_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/platform_utils.dart';
import '../../../../core/theme/app_metrics.dart';
import 'spin_page.dart';
import 'purchase_page.dart';
import 'stats_page.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Load profile data through provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfileData();
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



  // Daily reward feature removed

  Widget _buildActionsSection(ProfileProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D162B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6A00), Color(0xFF9C27B0)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Daily reward removed
            ],
          ),
          const SizedBox(height: 20),

          // Rewarded Ad Widget
          const RewardedAdWidget(
            customMessage:
                'Watch ads to earn free tokens for image generation!',
          ),
          const SizedBox(height: 20),

          // Navigation Buttons
          Row(
            children: [
              Expanded(
                child: _buildNavigationButton(
                  imagePath: 'assets/images/spinwheel.png',
                  title: 'Spin Wheel',
                  subtitle: 'Try your luck',
                  onTap: () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(builder: (_) => const SpinPage()),
                        )
                        .then((_) {
                          provider.refreshProfileData();
                        });
                  },
                  color: const Color(0xFFFF6A00),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNavigationButton(
                  imagePath: 'assets/images/statistics.png',
                  title: 'Statistics',
                  subtitle: 'View your stats',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StatsPage()),
                    );
                  },
                  color: const Color(0xFF2196F3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // _buildDailyRewardButton removed

  Widget _buildSupportSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D162B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.support_agent,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Support',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'spookyaihelp@gmail.com',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _copyEmailToClipboard(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.copy_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildRateAppSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D162B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rate App',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enjoying SpookyAI? Rate us!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openStorePage(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      PlatformUtils.isAndroid ? 'Play' : 'App Store',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openStorePage() async {
    String storeUrl;
    
    if (PlatformUtils.isAndroid) {
      // Google Play Store
      storeUrl = 'https://play.google.com/store/apps/details?id=com.furkanages.spookyai';
    } else if (PlatformUtils.isIOS) {
      // App Store
      storeUrl = 'https://apps.apple.com/us/app/spookyai-halloween-image-gen/id6753217831';
    } else {
      if (mounted) {
        NotificationService.error(
          context,
          message: 'Store not available on this platform.',
        );
      }
      return;
    }

    try {
      final Uri uri = Uri.parse(storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          NotificationService.error(
            context,
            message: 'Could not open store page. Please try again later.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationService.error(
          context,
          message: 'Could not open store page. Please try again later.',
        );
      }
    }
  }

  Widget _buildNavigationButton({
    String? imagePath,
    IconData? icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: imagePath != null
                    ? Image.asset(
                        imagePath,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      )
                    : Icon(icon ?? Icons.info, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Icon(
                Icons.arrow_forward,
                color: color.withOpacity(0.6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }


  // _activatePremiumDemo removed (unused)

  // _deactivatePremiumDemo removed (unused)

  // _openPremiumTesterMenu removed (unused)

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F0B1A),
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6A00), Color(0xFF9C27B0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0F0B1A),
            elevation: 0,
            toolbarHeight: AppMetrics.toolbarHeight,
            actions: [
              // Premium toggle button
              // Container(
              //   margin: const EdgeInsets.only(right: 8),
              //   child: IconButton(
              //     onPressed: _openPremiumTesterMenu,
              //     icon: Icon(
              //       provider.isPremium ? Icons.star : Icons.star_border,
              //       color: provider.isPremium
              //           ? const Color(0xFFFF6A00)
              //           : Colors.white,
              //     ),
              //     tooltip: 'Premium Tester',
              //   ),
              // ),
              TokenDisplayWidget(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PurchasePage()),
                  );
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              // Background decorations
              Positioned(
                bottom: 40,
                left: 20,
                child: Opacity(
                  opacity: 0.06,
                  child: Text('🕸️', style: TextStyle(fontSize: 80)),
                ),
              ),
              Positioned(
                top: 60,
                right: 20,
                child: Opacity(
                  opacity: 0.04,
                  child: Text('🎃', style: TextStyle(fontSize: 60)),
                ),
              ),
              Positioned(
                top: 120,
                left: 40,
                child: Opacity(
                  opacity: 0.04,
                  child: Text('🕷️', style: TextStyle(fontSize: 50)),
                ),
              ),

              // Main content
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: provider.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF6A00),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildActionsSection(provider),
                              const SizedBox(height: 20),
                              _buildSupportSection(),
                              const SizedBox(height: 20),
                              _buildRateAppSection(),
                              const SizedBox(height: 20),
                              _buildVersionInfo(),
                              const SizedBox(height: 20), // Bottom padding
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVersionInfo() {
    return FutureBuilder<Map<String, String>>(
      future: VersionService.getVersionInfo(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final versionInfo = snapshot.data!;
        final version = versionInfo['version'] ?? '1.1.0';
        final buildNumber = versionInfo['buildNumber'] ?? '15';
        final isDebug = versionInfo['isDebug'] == 'true';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1D162B).withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white.withOpacity(0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Version $version ($buildNumber)',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isDebug) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'DEBUG',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'SpookyAI - AI-Powered Halloween Image Generator',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
