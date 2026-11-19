import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/token_provider.dart';
import '../../../../core/theme/seasons/season_palette.dart';

/// Celebration bottom sheet shown after a successful purchase or promo code.
Future<void> showPurchaseSuccessDialog(
  BuildContext context, {
  required int tokensAdded,
  bool isPremiumSubscription = false,
}) {
  HapticFeedback.heavyImpact();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: SeasonPalette.surface,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _PurchaseSuccessSheet(
      tokensAdded: tokensAdded,
      isPremium: isPremiumSubscription,
    ),
  );
}

class _PurchaseSuccessSheet extends StatelessWidget {
  const _PurchaseSuccessSheet({
    required this.tokensAdded,
    required this.isPremium,
  });

  final int tokensAdded;
  final bool isPremium;

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final accent = SeasonPalette.accent;
    final text = SeasonPalette.text;
    final muted = SeasonPalette.mutedText;
    final animate = !MediaQuery.of(context).disableAnimations;
    final balance = context.watch<TokenProvider>().balance;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CelebrationHeader(animate: animate, isPremium: isPremium),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  isPremium ? 'Welcome to Premium' : 'Purchase complete',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: text,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isPremium
                    ? 'Your subscription is active. Thanks for supporting SpookyAI!'
                    : 'Your tokens are ready. Time to create something amazing.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 20),
              _TokensAddedCard(
                tokensAdded: tokensAdded,
                balance: _fmt(balance),
                animate: animate,
              ),
              if (isPremium) ...[
                const SizedBox(height: 16),
                const _Section(
                  title: 'Included with Premium',
                  children: [
                    _Line(
                      icon: Icons.autorenew_rounded,
                      label: '50 tokens every month',
                    ),
                    _Line(
                      icon: Icons.lock_open_rounded,
                      label: 'Access to all prompts',
                    ),
                    _Line(
                      icon: Icons.bolt_rounded,
                      label: 'Priority AI processing',
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                label: const Text('Start creating'),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header: gallery marquee + confetti + token badge
// ---------------------------------------------------------------------------

class _CelebrationHeader extends StatefulWidget {
  const _CelebrationHeader({required this.animate, required this.isPremium});

  final bool animate;
  final bool isPremium;

  @override
  State<_CelebrationHeader> createState() => _CelebrationHeaderState();
}

class _CelebrationHeaderState extends State<_CelebrationHeader>
    with TickerProviderStateMixin {
  static const double _height = 230;

  /// One-shot celebration (badge pop, rings, confetti).
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  /// Endless slow drift of the artwork rows.
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 30),
  );

  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(7);
    _particles = List.generate(40, (i) {
      return _Particle(
        angle: (i / 40) * 2 * math.pi + rnd.nextDouble() * 0.3,
        distance: 70 + rnd.nextDouble() * 80,
        size: 4 + rnd.nextDouble() * 5,
        colorIndex: i % 4,
        spin: rnd.nextDouble() * math.pi,
        isCircle: i.isEven,
      );
    });
    if (widget.animate) {
      _burst.forward();
      _drift.repeat();
    } else {
      _burst.value = 1;
    }
  }

  @override
  void dispose() {
    _burst.dispose();
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = SeasonPalette.accent;
    final surface = SeasonPalette.surface;
    final colors = [
      accent,
      SeasonPalette.secondaryAccent,
      SeasonPalette.highlight,
      const Color(0xFFFFC107),
    ];

    return ExcludeSemantics(
      child: SizedBox(
        height: _height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Two rows of artwork made with the app, drifting opposite ways.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _drift,
                builder: (_, _) => Column(
                  children: [
                    const SizedBox(height: 14),
                    _ArtRow(art: _art.sublist(0, 6), t: _drift.value),
                    const SizedBox(height: 10),
                    _ArtRow(
                      art: _art.sublist(6),
                      t: _drift.value,
                      reverse: true,
                    ),
                  ],
                ),
              ),
            ),
            // Fade the artwork into the sheet so the badge reads clearly.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0, 0.45, 1],
                    colors: [
                      surface.withOpacity(0.35),
                      surface.withOpacity(0.6),
                      surface,
                    ],
                  ),
                ),
              ),
            ),
            // Drag handle over the artwork.
            Positioned(
              top: 10,
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: SeasonPalette.text.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            // Confetti, rings and badge.
            AnimatedBuilder(
              animation: _burst,
              builder: (_, _) {
                final v = _burst.value;
                final badge = Curves.elasticOut.transform(
                  (v / 0.45).clamp(0.0, 1.0),
                );
                final check = Curves.easeOutBack.transform(
                  ((v - 0.3) / 0.3).clamp(0.0, 1.0),
                );
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(double.infinity, _height),
                      painter: _ConfettiPainter(_particles, v, colors),
                    ),
                    for (final delay in const [0.0, 0.15])
                      Builder(
                        builder: (_) {
                          final t = ((v - delay) / 0.6).clamp(0.0, 1.0);
                          return Opacity(
                            opacity: widget.animate ? (1 - t) * 0.6 : 0,
                            child: Container(
                              width: 96 + 80 * t,
                              height: 96 + 80 * t,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: accent, width: 2),
                              ),
                            ),
                          );
                        },
                      ),
                    Transform.scale(
                      scale: badge,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent,
                          border: Border.all(color: surface, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(0.45),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.isPremium
                              ? Icons.workspace_premium_rounded
                              : Icons.local_fire_department_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(34, 34),
                      child: Transform.scale(
                        scale: check,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF2E7D32),
                            border: Border.all(color: surface, width: 3),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

const _h = 'assets/images/haloween';
const _x = 'assets/images/christmas/text-to-image';
const _art = [
  '$_h/image-to-image/vampire_noble.png',
  '$_h/text-to-image/raven_queen.jpg',
  '$_x/frost_queen.jpg',
  '$_h/image-to-image/fortune_teller.png',
  '$_h/text-to-image/pumpkin_king.png',
  '$_x/santa_workshop.jpg',
  '$_h/image-to-image/enchantedd_witch.png',
  '$_h/text-to-image/blackcat.jpg',
  '$_h/image-to-image/werewolf.png',
  '$_x/frost_dragon.jpg',
  '$_h/text-to-image/moonlit_witch.png',
  '$_x/lantern_snowman.jpg',
];

/// A horizontal strip of artwork that loops seamlessly.
class _ArtRow extends StatelessWidget {
  const _ArtRow({required this.art, required this.t, this.reverse = false});

  final List<String> art;
  final double t;
  final bool reverse;

  static const double _tile = 92;
  static const double _gap = 10;

  @override
  Widget build(BuildContext context) {
    final setW = art.length * (_tile + _gap);
    final dx = reverse ? -setW + t * setW : -t * setW;
    return SizedBox(
      height: _tile,
      child: ClipRect(
        child: OverflowBox(
          maxWidth: double.infinity,
          alignment: Alignment.centerLeft,
          child: Transform.translate(
            offset: Offset(dx, 0),
            child: Row(
              children: [
                for (final a in [...art, ...art, ...art])
                  Padding(
                    padding: const EdgeInsets.only(right: _gap),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        a,
                        width: _tile,
                        height: _tile,
                        fit: BoxFit.cover,
                        cacheWidth: 240,
                        gaplessPlayback: true,
                        excludeFromSemantics: true,
                        errorBuilder: (_, _, _) =>
                            const SizedBox(width: _tile, height: _tile),
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

// ---------------------------------------------------------------------------
// Tokens added card
// ---------------------------------------------------------------------------

class _TokensAddedCard extends StatefulWidget {
  const _TokensAddedCard({
    required this.tokensAdded,
    required this.balance,
    required this.animate,
  });

  final int tokensAdded;
  final String balance;
  final bool animate;

  @override
  State<_TokensAddedCard> createState() => _TokensAddedCardState();
}

class _TokensAddedCardState extends State<_TokensAddedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _c.forward();
    } else {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = SeasonPalette.accent;
    final text = SeasonPalette.text;
    final muted = SeasonPalette.mutedText;

    return Semantics(
      label:
          '${widget.tokensAdded} tokens added. New balance ${widget.balance}.',
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final count = Curves.easeOutCubic.transform(
            (_c.value / 0.6).clamp(0.0, 1.0),
          );
          // Token chip pops slightly as the count lands.
          final pop =
              1 +
              0.12 *
                  math.sin(math.pi * ((_c.value - 0.5) / 0.25).clamp(0.0, 1.0));
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SeasonPalette.inputFill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: text.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Stacked "coins"
                    Transform.scale(
                      scale: pop,
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: Stack(
                          children: [
                            for (var i = 2; i >= 0; i--)
                              Positioned(
                                left: i * 6.0,
                                top: i * 3.0,
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: i == 0
                                        ? SeasonPalette.surface
                                        : accent.withOpacity(0.12 + i * 0.05),
                                    border: Border.all(
                                      color: accent.withOpacity(
                                        i == 0 ? 1 : 0.35,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                  child: i == 0
                                      ? Icon(
                                          Icons.local_fire_department_rounded,
                                          color: accent,
                                          size: 28,
                                        )
                                      : null,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tokens added',
                            style: TextStyle(
                              color: muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '+${(widget.tokensAdded * count).round()}',
                                style: TextStyle(
                                  color: text,
                                  fontSize: 40,
                                  height: 1.1,
                                  fontWeight: FontWeight.w900,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'tokens',
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Progress-style fill showing the top-up landing.
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: count,
                    minHeight: 6,
                    color: accent,
                    backgroundColor: text.withOpacity(0.08),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 18,
                      color: muted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'New balance',
                      style: TextStyle(color: muted, fontSize: 14),
                    ),
                    const Spacer(),
                    Text(
                      '${widget.balance} tokens',
                      style: TextStyle(
                        color: text,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Premium benefits
// ---------------------------------------------------------------------------

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: SeasonPalette.inputFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: SeasonPalette.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 20, color: SeasonPalette.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: SeasonPalette.text, fontSize: 15),
            ),
          ),
          Icon(Icons.check_rounded, size: 20, color: SeasonPalette.accent),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Confetti
// ---------------------------------------------------------------------------

class _Particle {
  const _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.colorIndex,
    required this.spin,
    required this.isCircle,
  });

  final double angle;
  final double distance;
  final double size;
  final int colorIndex;
  final double spin;
  final bool isCircle;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.t, this.colors);

  final List<_Particle> particles;
  final double t;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final burst = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
    final fade = t < 0.7 ? 1.0 : 1 - (t - 0.7) / 0.3 * 0.65;
    final paint = Paint();
    for (final p in particles) {
      final d = p.distance * burst;
      final pos =
          center +
          Offset(math.cos(p.angle) * d * 1.5, math.sin(p.angle) * d * 0.75) +
          Offset(0, 18 * t * t);
      paint.color = colors[p.colorIndex].withOpacity(fade.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin + t * 4);
      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.5,
            ),
            const Radius.circular(1),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
