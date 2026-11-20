import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/seasons/season_provider.dart';
import '../../../../core/theme/seasons/season_registry.dart';
import '../../../../core/theme/seasons/season_theme.dart';
import '../../../tour/product_tour.dart';

enum _Shape {
  heart,
  discoBall,
  lantern,
  crescent,
  egg,
  sun,
  diya,
  clover,
  flower,
  leaf,
  crystal,
  cassette,
  hexagon,
  star,
}

/// A world that is on the roadmap but cannot be entered yet. It is drawn in
/// its own shape and colors, muted, with a lock.
class _Upcoming {
  const _Upcoming({
    required this.name,
    required this.emoji,
    required this.shape,
    required this.accent,
    required this.light,
    required this.scaffold,
    required this.style,
  });

  final String name;
  final String emoji;
  final _Shape shape;
  final Color accent;
  final Color light;
  final Color scaffold;
  final _WorldStyle style;
}

/// In calendar order after Christmas (see docs/SEASON_CALENDAR.md). Moving a
/// world into `SeasonRegistry` and out of this list unlocks it.
const List<_Upcoming> _upcoming = [
  _Upcoming(
    name: "New Year's Eve",
    emoji: '🎆',
    shape: _Shape.discoBall,
    accent: Color(0xFFFFD54F),
    light: Color(0xFFB0BEC5),
    scaffold: Color(0xFF070A1A),
    style: _WorldStyle.fireworks,
  ),
  _Upcoming(
    name: "Valentine's Day",
    emoji: '💝',
    shape: _Shape.heart,
    accent: Color(0xFFE8436E),
    light: Color(0xFFFFB3C1),
    scaffold: Color(0xFF1A0B14),
    style: _WorldStyle.bokeh,
  ),
  _Upcoming(
    name: 'Lunar New Year',
    emoji: '🏮',
    shape: _Shape.lantern,
    accent: Color(0xFFD32F2F),
    light: Color(0xFFFFC107),
    scaffold: Color(0xFF1A0808),
    style: _WorldStyle.lanterns,
  ),
  _Upcoming(
    name: 'Ramadan & Eid',
    emoji: '🌙',
    shape: _Shape.crescent,
    accent: Color(0xFFD4AF37),
    light: Color(0xFF26A69A),
    scaffold: Color(0xFF081A1F),
    style: _WorldStyle.crescent,
  ),
  _Upcoming(
    name: "St. Patrick's Day",
    emoji: '☘️',
    shape: _Shape.clover,
    accent: Color(0xFF2E9E5B),
    light: Color(0xFFB9F6CA),
    scaffold: Color(0xFF08160D),
    style: _WorldStyle.fields,
  ),
  _Upcoming(
    name: 'Spring',
    emoji: '🐣',
    shape: _Shape.egg,
    accent: Color(0xFFF48FB1),
    light: Color(0xFFA5D6A7),
    scaffold: Color(0xFF0E1A14),
    style: _WorldStyle.petals,
  ),
  _Upcoming(
    name: "Mother's Day",
    emoji: '💐',
    shape: _Shape.flower,
    accent: Color(0xFFEC6FA6),
    light: Color(0xFFFFD3E4),
    scaffold: Color(0xFF1A0C14),
    style: _WorldStyle.petals,
  ),
  _Upcoming(
    name: 'Summer',
    emoji: '☀️',
    shape: _Shape.sun,
    accent: Color(0xFFFF7043),
    light: Color(0xFFFFCA28),
    scaffold: Color(0xFF0A1A26),
    style: _WorldStyle.sunset,
  ),
  _Upcoming(
    name: 'Autumn',
    emoji: '🍂',
    shape: _Shape.leaf,
    accent: Color(0xFFE07B39),
    light: Color(0xFFF2C14E),
    scaffold: Color(0xFF1A100A),
    style: _WorldStyle.leaves,
  ),
  _Upcoming(
    name: 'Diwali',
    emoji: '🪔',
    shape: _Shape.diya,
    accent: Color(0xFFFF4081),
    light: Color(0xFFFFC107),
    scaffold: Color(0xFF0D1030),
    style: _WorldStyle.diyas,
  ),
  _Upcoming(
    name: 'Fantasy',
    emoji: '🔮',
    shape: _Shape.crystal,
    accent: Color(0xFF3DDC97),
    light: Color(0xFFB388FF),
    scaffold: Color(0xFF08141A),
    style: _WorldStyle.fantasy,
  ),
  _Upcoming(
    name: 'Retro 90s',
    emoji: '📼',
    shape: _Shape.cassette,
    accent: Color(0xFFFF4FA3),
    light: Color(0xFF26E0D0),
    scaffold: Color(0xFF140A1C),
    style: _WorldStyle.synthwave,
  ),
  _Upcoming(
    name: 'Cyberpunk',
    emoji: '🌃',
    shape: _Shape.hexagon,
    accent: Color(0xFF00E5FF),
    light: Color(0xFFFF2D95),
    scaffold: Color(0xFF05091A),
    style: _WorldStyle.city,
  ),
  _Upcoming(
    name: 'Fairytale',
    emoji: '🧚',
    shape: _Shape.star,
    accent: Color(0xFFE8A0BF),
    light: Color(0xFFA8C9A0),
    scaffold: Color(0xFF150E16),
    style: _WorldStyle.sparkle,
  ),
];

/// A quiet vertical map. Each season is a region of one continuous sky; a
/// dotted trail climbs from the bottom region to the top. Tapping a region's
/// medallion walks the marker there and switches the app to that season.
/// No labels: the emblem, the lit trail and the marker tell the story.
class SeasonMapPage extends StatefulWidget {
  const SeasonMapPage({super.key});

  @override
  State<SeasonMapPage> createState() => _SeasonMapPageState();
}

class _SeasonMapPageState extends State<SeasonMapPage>
    with TickerProviderStateMixin {
  static const double _regionH = 360;
  static const double _dotGap = 26;

  /// The world keeps going below the first region, under the pill.
  static const double _bottomExtra = 130;

  // The map only scrolls (no zooming), a little wider than the screen so
  // there is scenery to explore to the left and right of the trail.
  static const double _wide = 1.4;
  static const Offset _markerOffset = Offset(0, -96);
  double _worldW(double w) => w * _wide;
  double _offsetX(double w) => (_worldW(w) - w) / 2;
  double get _totalH => _nodeCount * _regionH + _bottomExtra;

  final TransformationController _tc = TransformationController();
  late final AnimationController _moveAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  Size _viewport = Size.zero;
  late final AnimationController _travel = AnimationController(vsync: this);
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  List<SeasonTheme> get _seasons => SeasonRegistry.all;
  int get _nodeCount => _seasons.length + _upcoming.length;

  _Trail? _trail;
  double _width = 0;
  int _at = 0;
  bool _busy = false;
  double _fromDist = 0;
  double _toDist = 0;
  int? _burstNode;
  bool _placed = false;

  bool get _reduceMotion => SchedulerBinding
      .instance
      .platformDispatcher
      .accessibilityFeatures
      .disableAnimations;

  @override
  void initState() {
    super.initState();
    final provider = context.read<SeasonProvider>();
    _at = math.max(0, _seasons.indexWhere((s) => s.id == provider.current.id));
    _travel.addListener(_followMarker);
    if (!_reduceMotion) _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _tc.dispose();
    _moveAnim.dispose();
    _travel.dispose();
    _burst.dispose();
    _pulse.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ geometry

  /// Region 0 is at the bottom; the journey climbs.
  Offset _nodeCenter(int i, double w) => Offset(
    _offsetX(w) + w * (i.isEven ? 0.32 : 0.68),
    (_nodeCount - 1 - i) * _regionH + _regionH * 0.5,
  );

  static const Color _lockedTint = Color(0xFF181B30);

  /// Sky colors from the top of the map down (locked worlds are muted).
  List<Color> get _skyTopDown => [
    for (final u in _upcoming.reversed)
      Color.lerp(Color.lerp(u.scaffold, u.accent, 0.12)!, _lockedTint, 0.3)!,
    for (final s in _seasons.reversed)
      Color.lerp(s.scaffoldBackground, s.cardGradientStart, 0.75)!,
  ];

  /// Each region's halo uses its own accent (muted when locked).
  List<Color> get _glowsTopDown => [
    for (final u in _upcoming.reversed)
      Color.lerp(u.accent, const Color(0xFF8A90B0), 0.55)!,
    for (final s in _seasons.reversed) s.accent,
  ];

  /// Two scenery colors per region, top-down (muted when locked).
  List<Color> get _tintsA => [
    for (final u in _upcoming.reversed)
      Color.lerp(u.accent, const Color(0xFF8A90B0), 0.2)!,
    for (final s in _seasons.reversed) s.accent,
  ];
  List<Color> get _tintsB => [
    for (final u in _upcoming.reversed)
      Color.lerp(u.light, const Color(0xFF8A90B0), 0.2)!,
    for (final s in _seasons.reversed) s.secondaryAccent,
  ];

  /// Scenery per region, top-down.
  List<_WorldStyle> get _stylesTopDown => [
    for (final u in _upcoming.reversed) u.style,
    for (final s in _seasons.reversed) _styleOf(s.id),
  ];

  /// Exhaustive on purpose: a new season must choose its scenery here.
  static _WorldStyle _styleOf(SeasonId id) => switch (id) {
    SeasonId.halloween => _WorldStyle.night,
    SeasonId.christmas => _WorldStyle.snow,
  };

  double get _dist {
    final t = Curves.easeInOutCubic.transform(_travel.value);
    return _busy ? _fromDist + (_toDist - _fromDist) * t : _fromDist;
  }

  /// Keeps the view inside the world, centering when the world is smaller
  /// than the screen on an axis.
  Matrix4 _matrix(double scale, double tx, double ty) {
    final minTx = _viewport.width - _worldW(_viewport.width) * scale;
    final minTy = _viewport.height - _totalH * scale;
    final x = minTx >= 0 ? minTx / 2 : tx.clamp(minTx, 0.0);
    final y = minTy >= 0 ? minTy / 2 : ty.clamp(minTy, 0.0);
    return Matrix4.diagonal3Values(scale, scale, 1)..setTranslationRaw(x, y, 0);
  }

  /// Keeps the marker vertically centered. Horizontally the view stays
  /// where the user left it, unless [centerX] asks for the middle.
  void _followMarker({bool centerX = false}) {
    final trail = _trail;
    if (trail == null || _viewport.isEmpty) return;
    final p = trail.pointAt(_dist) + _markerOffset;
    final tx = centerX
        ? (_viewport.width - _worldW(_viewport.width)) / 2
        : _tc.value.getTranslation().x;
    _tc.value = _matrix(1, tx, _viewport.height / 2 - p.dy);
  }

  void _animateTo(Matrix4 end) {
    final tween = Matrix4Tween(begin: _tc.value, end: end);
    void tick() => _tc.value = tween.transform(
      Curves.easeOutCubic.transform(_moveAnim.value),
    );
    _moveAnim
      ..removeListener(_moveTick ?? () {})
      ..reset();
    _moveTick = tick;
    _moveAnim
      ..addListener(tick)
      ..forward();
  }

  VoidCallback? _moveTick;

  /// Back to the player.
  void _recenter() {
    final trail = _trail;
    if (trail == null || _viewport.isEmpty) return;
    HapticFeedback.selectionClick();
    final p = trail.pointAt(_dist) + _markerOffset;
    _animateTo(
      _matrix(
        1,
        (_viewport.width - _worldW(_viewport.width)) / 2,
        _viewport.height / 2 - p.dy,
      ),
    );
  }

  // ------------------------------------------------------------- actions

  Future<void> _hopTo(int node, Future<void> Function() onArrive) async {
    final trail = _trail;
    if (trail == null || _busy) return;
    final to = trail.nodeDist[node];
    if (_reduceMotion) {
      setState(() {
        _at = node;
        _fromDist = to;
      });
      await onArrive();
      return;
    }
    final from = trail.nodeDist[_at];
    setState(() {
      _busy = true;
      _fromDist = from;
      _toDist = to;
    });
    _travel.duration = Duration(
      milliseconds: ((to - from).abs() * 2.4).clamp(700, 2200).toInt(),
    );
    await _travel.forward(from: 0);
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _at = node;
      _fromDist = to;
      _busy = false;
      _burstNode = node;
    });
    _burst.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    await onArrive();
  }

  Future<void> _onNodeTap(int i, SeasonProvider provider) async {
    if (_busy) return;
    if (i >= _seasons.length) {
      // Locked world: a soft tap on the lock, nothing else happens.
      HapticFeedback.lightImpact();
      return;
    }
    HapticFeedback.selectionClick();
    final target = _seasons[i];
    if (provider.current.id == target.id && !provider.isAuto) {
      _burstNode = i;
      _burst.forward(from: 0);
      return;
    }
    await _hopTo(i, () => provider.setOverride(target.id));
  }

  Future<void> _setAuto(bool auto, SeasonProvider provider) async {
    if (_busy) return;
    HapticFeedback.selectionClick();
    if (!auto) {
      await provider.setOverride(provider.current.id);
      return;
    }
    final calendarId = SeasonRegistry.forDate(DateTime.now());
    final idx = _seasons.indexWhere((s) => s.id == calendarId);
    if (idx >= 0 && idx != _at) {
      await _hopTo(idx, () => provider.setOverride(null));
    } else {
      await provider.setOverride(null);
    }
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SeasonProvider>();
    final current = provider.current;

    return Scaffold(
      backgroundColor: _skyTopDown.last,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final resized = _viewport != Size(box.maxWidth, box.maxHeight);
          _viewport = Size(box.maxWidth, box.maxHeight);
          if (resized && _placed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _tc.value = _matrix(
                1,
                _tc.value.getTranslation().x,
                _tc.value.getTranslation().y,
              );
            });
          }
          if (_trail == null || w != _width) {
            _width = w;
            _trail = _Trail.build([
              for (var i = 0; i < _nodeCount; i++) _nodeCenter(i, w),
            ], _dotGap);
            if (!_busy) _fromDist = _trail!.nodeDist[_at];
          }
          final trail = _trail!;
          if (!_placed) {
            _placed = true;
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _followMarker(centerX: true),
            );
          }

          return Stack(
            children: [
              InteractiveViewer(
                transformationController: _tc,
                constrained: false,
                scaleEnabled: false, // pan only
                boundaryMargin: EdgeInsets.zero,
                child: SizedBox(
                  height: _totalH,
                  width: _worldW(w),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_travel, _burst, _pulse, _tc]),
                    builder: (context, _) {
                      final dist = _dist;
                      final zoom = _tc.value.getMaxScaleOnAxis();
                      final top = -_tc.value.getTranslation().y / zoom;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _WorldPainter(
                                colors: _skyTopDown,
                                glows: _glowsTopDown,
                                styles: _stylesTopDown,
                                tintsA: _tintsA,
                                tintsB: _tintsB,
                                bandLeft: _offsetX(w),
                                bandW: w,
                                viewport: box.maxHeight / zoom,
                                regionH: _regionH,
                                scroll: top,
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _TrailPainter(
                                trail: trail,
                                progress: dist,
                                lit: current.accent,
                              ),
                            ),
                          ),
                          for (var i = 0; i < _nodeCount; i++)
                            _node(i, w, provider),
                          if (_burstNode != null && _burst.isAnimating)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _BurstPainter(
                                    center: _nodeCenter(_burstNode!, w),
                                    t: _burst.value,
                                    color: _burstNode! < _seasons.length
                                        ? _seasons[_burstNode!].accent
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          _marker(trail.pointAt(dist), dist, current),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                left: 16,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _LocateButton(
                      surface: current.surface,
                      onTap: _recenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _AutoPill(
                      key: ProductTourKeys.mapAuto,
                      isAuto: provider.isAuto,
                      accent: current.accent,
                      surface: current.surface,
                      onChanged: (v) => _setAuto(v, provider),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _node(int i, double w, SeasonProvider provider) {
    final c = _nodeCenter(i, w);
    final locked = i >= _seasons.length;
    final season = locked ? null : _seasons[i];
    final up = locked ? _upcoming[i - _seasons.length] : null;
    final isHere = !locked && _at == i && !_busy;
    final pulse = isHere ? _pulse.value : 0.0;
    final accent = season != null
        ? season.accent
        : Color.lerp(up!.accent, const Color(0xFF5A6080), 0.5)!;
    const w0 = 116.0; // medallion canvas
    const h0 = 124.0; // body (108) + stem/cap above it

    return Positioned(
      left: c.dx - w0 / 2 - 24,
      top: c.dy - 70 - 8,
      child: Semantics(
        button: true,
        selected: isHere,
        label: locked ? '${up!.name}, coming soon' : season!.displayName,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onNodeTap(i, provider),
          child: Padding(
            key: !locked && season == provider.current
                ? ProductTourKeys.mapHere
                : null,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: w0,
                  height: h0 + 14,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none, // let the glow fade out freely
                    children: [
                      // Ground shadow.
                      Positioned(
                        bottom: 0,
                        child: Container(
                          width: w0 * 0.62,
                          height: 14,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Themed body. Locked worlds keep their own shape but
                      // are muted and dimmed.
                      Positioned(
                        top: -5 * pulse,
                        child: Opacity(
                          opacity: locked ? 0.7 : 1,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withOpacity(
                                    (locked ? 0.18 : 0.3) + 0.4 * pulse,
                                  ),
                                  blurRadius: 24 + 16 * pulse,
                                  spreadRadius: 0 + 4 * pulse,
                                ),
                              ],
                            ),
                            child: CustomPaint(
                              size: const Size(w0, h0),
                              painter: _MedallionPainter(
                                season: season,
                                upcoming: up,
                                active: isHere,
                              ),
                              child: SizedBox(
                                width: w0,
                                height: h0,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Center(
                                    child: Opacity(
                                      opacity: locked ? 0.5 : 1,
                                      child: Text(
                                        season?.emoji ?? up!.emoji,
                                        style: TextStyle(
                                          fontSize: locked ? 46 : 54,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (locked)
                        Positioned(
                          right: 2,
                          bottom: 18,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22263A),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.8),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  season?.displayName ?? up!.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: locked ? 16 : 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: Colors.white.withOpacity(locked ? 0.62 : 1),
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _marker(Offset p, double dist, SeasonTheme current) {
    final hop = _busy ? -(math.sin(dist / _dotGap * math.pi).abs()) * 12 : 0.0;
    final bob = _busy ? 0.0 : -3 * _pulse.value;
    return Positioned(
      left: p.dx + _markerOffset.dx - 20,
      top: p.dy + _markerOffset.dy - 20 + hop + bob,
      child: IgnorePointer(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: current.accent.withOpacity(0.55),
                blurRadius: 14,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            Icons.person_pin_circle_rounded,
            color: current.accent,
            size: 26,
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- medallion

/// The medallion body. Shape and colors follow the season:
///  * Halloween: a ribbed pumpkin with a stem,
///  * Christmas: a glossy bauble with a ribbon band and a gold cap,
///  * locked: a plain dark stone.
class _MedallionPainter extends CustomPainter {
  _MedallionPainter({
    required this.season,
    this.upcoming,
    required this.active,
  });

  final SeasonTheme? season;
  final _Upcoming? upcoming;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, 70);
    const r = 52.0;
    final s = season;

    final up = upcoming;
    if (up != null) {
      _paintUpcoming(canvas, center, r, up);
      return;
    }

    if (s == null) {
      _body(
        canvas,
        Path()..addOval(Rect.fromCircle(center: center, radius: r)),
        center,
        r,
        const Color(0xFF7A8099),
        const Color(0xFF3A3F55),
      );
      return;
    }

    switch (s.id) {
      case SeasonId.halloween:
        // Ribbed pumpkin: a circle whose radius breathes 8 times.
        final path = Path();
        for (var i = 0; i <= 160; i++) {
          final a = i / 160 * math.pi * 2;
          final rr =
              r * (1 + 0.055 * math.cos(a * 8)) * (a > math.pi ? 0.98 : 1);
          final p = center + Offset(math.cos(a), math.sin(a) * 0.94) * rr;
          if (i == 0) {
            path.moveTo(p.dx, p.dy);
          } else {
            path.lineTo(p.dx, p.dy);
          }
        }
        path.close();
        _body(
          canvas,
          path,
          center,
          r,
          s.secondaryAccent,
          Color.lerp(s.accent, Colors.black, 0.45)!,
          mid: s.accent,
        );
        // Rib lines.
        final rib = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.black.withOpacity(0.16);
        for (var k = -2; k <= 2; k++) {
          canvas.drawPath(
            Path()
              ..moveTo(center.dx + k * 17, center.dy - r * 0.88)
              ..quadraticBezierTo(
                center.dx + k * 27,
                center.dy,
                center.dx + k * 17,
                center.dy + r * 0.88,
              ),
            rib,
          );
        }
        // Stem.
        final stem = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx + 3, center.dy - r - 2),
            width: 15,
            height: 20,
          ),
          const Radius.circular(6),
        );
        canvas.drawRRect(stem, Paint()..color = s.highlightDeep);
        canvas.drawRRect(
          stem.deflate(2.5),
          Paint()..color = Color.lerp(s.highlight, Colors.white, 0.2)!,
        );
        break;

      case SeasonId.christmas:
        final disc = Path()
          ..addOval(Rect.fromCircle(center: center, radius: r));
        _body(
          canvas,
          disc,
          center,
          r,
          Color.lerp(s.accent, Colors.white, 0.45)!,
          Color.lerp(s.accent, Colors.black, 0.5)!,
          mid: s.accent,
        );
        // Ribbon band across the bauble, clipped to its shape.
        canvas.save();
        canvas.clipPath(disc);
        canvas.translate(center.dx, center.dy);
        canvas.rotate(-0.5);
        canvas.drawRect(
          const Rect.fromLTRB(-90, -11, 90, 11),
          Paint()..color = s.highlight.withOpacity(0.92),
        );
        canvas.drawRect(
          const Rect.fromLTRB(-90, -11, 90, -8),
          Paint()..color = Colors.white.withOpacity(0.35),
        );
        canvas.restore();
        // Gold cap and loop.
        final cap = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy - r - 3),
            width: 26,
            height: 14,
          ),
          const Radius.circular(4),
        );
        canvas.drawRRect(cap, Paint()..color = s.secondaryAccent);
        canvas.drawRRect(
          cap.deflate(2),
          Paint()..color = Color.lerp(s.secondaryAccent, Colors.white, 0.35)!,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy - r - 14),
            width: 16,
            height: 16,
          ),
          math.pi,
          math.pi,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = s.secondaryAccent,
        );
        break;
    }
  }

  /// Locked worlds: their own shape, in muted colors.
  void _paintUpcoming(Canvas canvas, Offset c, double r, _Upcoming up) {
    const mute = Color(0xFF5A6080);
    Color m(Color x, [double t = 0.45]) => Color.lerp(x, mute, t)!;
    final light = m(up.light);
    final mid = m(up.accent);
    final dark = m(Color.lerp(up.accent, Colors.black, 0.55)!);

    Path polar(double Function(double a) radius, {double sy = 1}) {
      final p = Path();
      for (var i = 0; i <= 120; i++) {
        final a = i / 120 * math.pi * 2;
        final rr = radius(a);
        final pt = c + Offset(math.cos(a) * rr, math.sin(a) * rr * sy);
        if (i == 0) {
          p.moveTo(pt.dx, pt.dy);
        } else {
          p.lineTo(pt.dx, pt.dy);
        }
      }
      return p..close();
    }

    switch (up.shape) {
      case _Shape.heart:
        final p = Path();
        for (var i = 0; i <= 140; i++) {
          final t = i / 140 * math.pi * 2;
          final x = 16 * math.pow(math.sin(t), 3);
          final y =
              -(13 * math.cos(t) -
                  5 * math.cos(2 * t) -
                  2 * math.cos(3 * t) -
                  math.cos(4 * t));
          final pt = Offset(c.dx + x * r / 16.5, c.dy + y * r / 16.5 + 4);
          if (i == 0) {
            p.moveTo(pt.dx, pt.dy);
          } else {
            p.lineTo(pt.dx, pt.dy);
          }
        }
        p.close();
        _body(canvas, p, c, r, light, dark, mid: mid);
      case _Shape.egg:
        final p = Path();
        for (var i = 0; i <= 120; i++) {
          final t = i / 120 * math.pi * 2;
          final x = r * 0.84 * math.cos(t) * (1 + 0.16 * math.sin(t));
          final y = r * math.sin(t);
          final pt = c + Offset(x, y);
          if (i == 0) {
            p.moveTo(pt.dx, pt.dy);
          } else {
            p.lineTo(pt.dx, pt.dy);
          }
        }
        p.close();
        _body(canvas, p, c, r, light, dark, mid: mid);
        canvas.save();
        canvas.clipPath(p);
        final band = Paint()..color = m(up.light, 0.2).withOpacity(0.55);
        canvas.drawRect(Rect.fromLTWH(c.dx - r, c.dy - 4, r * 2, 12), band);
        canvas.drawRect(Rect.fromLTWH(c.dx - r, c.dy + 22, r * 2, 7), band);
        canvas.restore();
      case _Shape.sun:
        final p = polar((a) {
          final k = ((a / (math.pi * 2)) * 48).floor();
          return k.isEven ? r : r * 0.8;
        });
        _body(canvas, p, c, r, light, dark, mid: mid);
      case _Shape.discoBall:
        final p = Path()..addOval(Rect.fromCircle(center: c, radius: r));
        _body(canvas, p, c, r, light, dark, mid: mid);
        canvas.save();
        canvas.clipPath(p);
        final grid = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = Colors.white.withOpacity(0.28);
        for (var k = -3; k <= 3; k++) {
          canvas.drawLine(
            Offset(c.dx - r, c.dy + k * 15),
            Offset(c.dx + r, c.dy + k * 15),
            grid,
          );
          canvas.drawOval(
            Rect.fromCenter(
              center: c,
              width: r * 2 * (k.abs() / 3 + 0.12),
              height: r * 2,
            ),
            grid,
          );
        }
        canvas.restore();
      case _Shape.lantern:
        final rect = Rect.fromCenter(
          center: c + const Offset(0, 2),
          width: r * 1.6,
          height: r * 1.7,
        );
        final p = Path()
          ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(30)));
        _body(canvas, p, c, r, light, dark, mid: mid);
        final cap = m(up.light, 0.15);
        for (final y in [rect.top - 3, rect.bottom - 6]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(c.dx - 16, y, 32, 9),
              const Radius.circular(3),
            ),
            Paint()..color = cap,
          );
        }
        canvas.drawLine(
          Offset(c.dx, rect.bottom + 4),
          Offset(c.dx, rect.bottom + 16),
          Paint()
            ..color = cap
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
      case _Shape.crescent:
        final p = Path.combine(
          PathOperation.difference,
          Path()..addOval(Rect.fromCircle(center: c, radius: r)),
          Path()..addOval(
            Rect.fromCircle(
              center: c + Offset(r * 0.5, -r * 0.12),
              radius: r * 0.86,
            ),
          ),
        );
        _body(canvas, p, c, r, light, dark, mid: mid);
      case _Shape.clover:
        final p = Path();
        for (final o in const [
          Offset(-0.4, -0.4),
          Offset(0.4, -0.4),
          Offset(-0.4, 0.4),
          Offset(0.4, 0.4),
        ]) {
          p.addOval(Rect.fromCircle(center: c + o * r, radius: r * 0.56));
        }
        _body(canvas, p, c, r, light, dark, mid: mid);
        canvas.drawLine(
          c + Offset(0, r * 0.25),
          c + Offset(r * 0.18, r * 1.0),
          Paint()
            ..color = dark
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round,
        );
      case _Shape.flower:
        final p = Path();
        for (var k = 0; k < 6; k++) {
          final a = k / 6 * math.pi * 2;
          p.addOval(
            Rect.fromCircle(
              center: c + Offset(math.cos(a), math.sin(a)) * r * 0.55,
              radius: r * 0.46,
            ),
          );
        }
        _body(canvas, p, c, r, light, dark, mid: mid);
        canvas.drawCircle(c, r * 0.3, Paint()..color = m(up.light, 0.1));
      case _Shape.leaf:
        final p = Path()
          ..moveTo(c.dx, c.dy - r)
          ..cubicTo(
            c.dx + r * 1.15,
            c.dy - r * 0.4,
            c.dx + r * 0.85,
            c.dy + r * 0.75,
            c.dx,
            c.dy + r,
          )
          ..cubicTo(
            c.dx - r * 0.85,
            c.dy + r * 0.75,
            c.dx - r * 1.15,
            c.dy - r * 0.4,
            c.dx,
            c.dy - r,
          )
          ..close();
        _body(canvas, p, c, r, light, dark, mid: mid);
        canvas.drawLine(
          c + Offset(0, -r * 0.85),
          c + Offset(0, r * 1.05),
          Paint()
            ..color = dark.withOpacity(0.6)
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
      case _Shape.crystal:
        final pts = [
          c + Offset(-r * 0.62, -r * 0.28),
          c + Offset(-r * 0.34, -r * 0.82),
          c + Offset(r * 0.34, -r * 0.82),
          c + Offset(r * 0.62, -r * 0.28),
          c + Offset(0, r),
        ];
        final p = Path()..addPolygon(pts, true);
        _body(canvas, p, c, r, light, dark, mid: mid);
        final facet = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = Colors.white.withOpacity(0.3);
        canvas.drawLine(pts[0], pts[3], facet);
        canvas.drawLine(pts[1], c + Offset(0, r), facet);
        canvas.drawLine(pts[2], c + Offset(0, r), facet);
      case _Shape.cassette:
        final rect = Rect.fromCenter(
          center: c,
          width: r * 1.95,
          height: r * 1.4,
        );
        final p = Path()
          ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(14)));
        _body(canvas, p, c, r, light, dark, mid: mid);
        final win = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: c + Offset(0, -r * 0.1),
            width: r * 1.35,
            height: r * 0.5,
          ),
          const Radius.circular(10),
        );
        canvas.drawRRect(win, Paint()..color = Colors.black.withOpacity(0.35));
        for (final dx in [-r * 0.38, r * 0.38]) {
          canvas.drawCircle(
            c + Offset(dx, -r * 0.1),
            r * 0.15,
            Paint()..color = m(up.light, 0.1),
          );
        }
      case _Shape.hexagon:
        final hex = Path();
        for (var k = 0; k < 6; k++) {
          final a = k / 6 * math.pi * 2 - math.pi / 2;
          final pt = c + Offset(math.cos(a), math.sin(a)) * r;
          if (k == 0) {
            hex.moveTo(pt.dx, pt.dy);
          } else {
            hex.lineTo(pt.dx, pt.dy);
          }
        }
        hex.close();
        _body(canvas, hex, c, r, light, dark, mid: mid);
        canvas.drawCircle(
          c,
          r * 0.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = m(up.light, 0.1).withOpacity(0.8),
        );
      case _Shape.star:
        final p = Path();
        for (var k = 0; k < 10; k++) {
          final a = k / 10 * math.pi * 2 - math.pi / 2;
          final rr = k.isEven ? r : r * 0.5;
          final pt = c + Offset(math.cos(a), math.sin(a)) * rr;
          if (k == 0) {
            p.moveTo(pt.dx, pt.dy);
          } else {
            p.lineTo(pt.dx, pt.dy);
          }
        }
        p.close();
        _body(canvas, p, c, r, light, dark, mid: mid);
      case _Shape.diya:
        final bowl = Path()
          ..moveTo(c.dx - r, c.dy - 2)
          ..quadraticBezierTo(
            c.dx - r * 0.85,
            c.dy + r * 0.85,
            c.dx,
            c.dy + r * 0.85,
          )
          ..quadraticBezierTo(
            c.dx + r * 0.85,
            c.dy + r * 0.85,
            c.dx + r,
            c.dy - 2,
          )
          ..close();
        _body(canvas, bowl, c, r, light, dark, mid: mid);
        final flame = Path()
          ..moveTo(c.dx, c.dy - r * 0.95)
          ..cubicTo(
            c.dx + 18,
            c.dy - r * 0.45,
            c.dx + 12,
            c.dy - 6,
            c.dx,
            c.dy - 6,
          )
          ..cubicTo(
            c.dx - 12,
            c.dy - 6,
            c.dx - 18,
            c.dy - r * 0.45,
            c.dx,
            c.dy - r * 0.95,
          )
          ..close();
        canvas.drawPath(flame, Paint()..color = m(up.light, 0.15));
    }
  }

  void _body(
    Canvas canvas,
    Path path,
    Offset center,
    double r,
    Color light,
    Color dark, {
    Color? mid,
  }) {
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.45, -0.55),
          radius: 1.05,
          colors: [
            Color.lerp(light, Colors.white, 0.3)!,
            light,
            mid ?? Color.lerp(light, dark, 0.5)!,
            dark,
          ],
          stops: const [0.0, 0.28, 0.68, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = active ? 4 : 3
        ..color = Colors.white.withOpacity(active ? 1 : 0.85),
    );
    // Gloss.
    canvas.drawOval(
      Rect.fromCenter(
        center: center + const Offset(-20, -30),
        width: 34,
        height: 16,
      ),
      Paint()..color = Colors.white.withOpacity(0.3),
    );
  }

  @override
  bool shouldRepaint(covariant _MedallionPainter old) =>
      old.season != season || old.upcoming != upcoming || old.active != active;
}

// ------------------------------------------------------------------ world

Color _colorAtY(List<Color> colors, double regionH, double y) {
  final f = (y / regionH - 0.5).clamp(0.0, colors.length - 1.0);
  final lo = f.floor();
  final hi = math.min(lo + 1, colors.length - 1);
  return Color.lerp(
    colors[lo],
    colors[hi],
    Curves.easeInOut.transform(f - lo),
  )!;
}

enum _WorldStyle {
  night,
  snow,
  mist,
  bokeh,
  fireworks,
  lanterns,
  crescent,
  fields,
  petals,
  sunset,
  leaves,
  diyas,
  fantasy,
  synthwave,
  city,
  sparkle,
}

/// One continuous sky, then scenery that belongs to each region: a moonlit
/// night with stars for Halloween, an aurora and falling snow for Christmas,
/// drifting haze for the unexplored. Every piece fades toward the region's
/// borders, so one world melts into the next.
class _WorldPainter extends CustomPainter {
  _WorldPainter({
    required this.colors,
    required this.glows,
    required this.styles,
    required this.tintsA,
    required this.tintsB,
    required this.bandLeft,
    required this.bandW,
    required this.viewport,
    required this.regionH,
    required this.scroll,
  });

  final List<Color> colors;
  final List<Color> glows;
  final List<_WorldStyle> styles;
  final List<Color> tintsA;
  final List<Color> tintsB;

  /// The part of the (wider) canvas where medallions live.
  final double bandLeft;
  final double bandW;
  final double viewport;
  final double regionH;
  final double scroll;

  /// 0 at a region's border, 1 at its middle (smooth).
  double _window(double y, int v) {
    final u = ((y - v * regionH) / regionH).clamp(0.0, 1.0);
    final d = 1 - (2 * u - 1).abs();
    return d * d * (3 - 2 * d);
  }

  bool _visible(int v) {
    final top = v * regionH;
    return top + regionH > scroll - 160 && top < scroll + viewport + 160;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = colors.length;
    // Sky: a color stop at every region's middle, clamped past both ends so
    // it always reaches the screen edges.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: [
            for (var i = 0; i < n; i++) (i + 0.5) * regionH / size.height,
          ],
        ).createShader(Offset.zero & size),
    );

    // Soft halo behind each medallion.
    for (var v = 0; v < n; v++) {
      if (!_visible(v)) continue;
      final cy = v * regionH + regionH * 0.5;
      final cx = bandLeft + bandW * ((n - 1 - v).isEven ? 0.32 : 0.68);
      final rect = Rect.fromCircle(
        center: Offset(cx, cy),
        radius: regionH * 0.85,
      );
      final g = glows[v];
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              g.withOpacity(0.34),
              g.withOpacity(0.22),
              g.withOpacity(0.11),
              g.withOpacity(0.04),
              g.withOpacity(0),
            ],
            stops: const [0.0, 0.25, 0.5, 0.78, 1.0],
          ).createShader(rect),
      );
    }

    // Sky scenery (behind the hills).
    for (var v = 0; v < n; v++) {
      if (!_visible(v)) continue;
      final a = tintsA[v];
      final b = tintsB[v];
      switch (styles[v]) {
        case _WorldStyle.night:
          _stars(canvas, size, v, 26, const Color(0xFFFFF1D6));
          _moon(canvas, size, v);
          _bats(canvas, size, v);
        case _WorldStyle.snow:
          _aurora(canvas, size, v);
          _stars(canvas, size, v, 12, const Color(0xFFE3F3FF));
        case _WorldStyle.mist:
          _stars(canvas, size, v, 10, const Color(0xFFB9C0E0));
        case _WorldStyle.bokeh:
          _bokeh(canvas, size, v, a, b);
        case _WorldStyle.fireworks:
          _fireworks(canvas, size, v, a, b);
          _stars(canvas, size, v, 14, const Color(0xFFE8ECFF));
        case _WorldStyle.lanterns:
          _lanterns(canvas, size, v, a, b, 8);
        case _WorldStyle.crescent:
          _stars(canvas, size, v, 20, const Color(0xFFFFE9B0));
          _crescent(canvas, size, v, b);
          _lanterns(canvas, size, v, a, b, 3);
        case _WorldStyle.fields:
          _fireflies(canvas, size, v, b, 18);
        case _WorldStyle.petals:
          _petals(canvas, size, v, a, b);
        case _WorldStyle.sunset:
          _sunset(canvas, size, v, a, b);
        case _WorldStyle.leaves:
          _leaves(canvas, size, v, a, b);
        case _WorldStyle.diyas:
          _diyas(canvas, size, v, a, b);
          _stars(canvas, size, v, 10, const Color(0xFFFFE9B0));
        case _WorldStyle.fantasy:
          _aurora(canvas, size, v, const [
            Color(0xFFB388FF),
            Color(0xFF3DDC97),
            Color(0xFF7C4DFF),
          ]);
          _fireflies(canvas, size, v, b, 14);
          _crystals(canvas, size, v, a);
        case _WorldStyle.synthwave:
          _synthwave(canvas, size, v, a, b);
        case _WorldStyle.city:
          _skyline(canvas, size, v, a, b);
        case _WorldStyle.sparkle:
          _stars(canvas, size, v, 14, const Color(0xFFFFE6F2));
          _sparkles(canvas, size, v, a, b);
      }
    }

    // Hills, tinted by the world they sit in (snowy ones are paler).
    for (var v = 0; v < n; v++) {
      if (!_visible(v)) continue;
      for (var k = 0; k < 3; k++) {
        final y = v * regionH + regionH * (0.46 + k * 0.19);
        final base = _colorAtY(colors, regionH, y + 60);
        final snowy = styles[v] == _WorldStyle.snow;
        final ridge = snowy
            ? Color.lerp(base, Colors.white, 0.28 - k * 0.07)!
            : Color.lerp(base, Colors.black, 0.14 + k * 0.1)!;
        final amp = (snowy ? 20.0 : 15.0) + k * 6;
        final len = bandW * (1.3 + 0.3 * k);
        final phase = v * 1.9 + k * 2.1 + scroll * 0.0009 * (k + 1);
        final path = Path()..moveTo(0, y);
        for (var x = 0.0; x <= size.width + 8; x += 8) {
          path.lineTo(x, y + math.sin(x / len * math.pi * 2 + phase) * amp);
        }
        path
          ..lineTo(size.width, y + regionH)
          ..lineTo(0, y + regionH)
          ..close();
        final fill = Rect.fromLTWH(0, y - amp, size.width, regionH * 0.7);
        canvas.drawPath(
          path,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ridge.withOpacity(0.6),
                ridge.withOpacity(0.26),
                ridge.withOpacity(0),
              ],
              stops: const [0.0, 0.45, 1.0],
            ).createShader(fill),
        );
      }
    }

    // Foreground: falling snow.
    for (var v = 0; v < n; v++) {
      if (styles[v] == _WorldStyle.snow && _visible(v)) _snow(canvas, size, v);
    }

    // Mist at every border.
    for (var v = 1; v < n; v++) {
      final rect = Rect.fromLTWH(0, v * regionH - 140, size.width, 280);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0),
              Colors.white.withOpacity(0.03),
              Colors.white.withOpacity(0.07),
              Colors.white.withOpacity(0.03),
              Colors.white.withOpacity(0),
            ],
            stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
          ).createShader(rect),
      );
    }
  }

  void _stars(Canvas canvas, Size size, int v, int count, Color color) {
    final r = math.Random(v * 53 + 11);
    final total = (count * size.width / bandW).round();
    for (var i = 0; i < total; i++) {
      final y = v * regionH + r.nextDouble() * regionH * 0.75;
      final a = (0.25 + r.nextDouble() * 0.55) * _window(y, v);
      final x = r.nextDouble() * size.width;
      final rad = 0.7 + r.nextDouble() * 1.3;
      canvas.drawCircle(
        Offset(x, y),
        rad,
        Paint()..color = color.withOpacity(a),
      );
      if (rad > 1.5) {
        canvas.drawCircle(
          Offset(x, y),
          rad * 3,
          Paint()..color = color.withOpacity(a * 0.15),
        );
      }
    }
  }

  void _moon(Canvas canvas, Size size, int v) {
    // On the side opposite the medallion.
    final onRight = (n(v)).isEven;
    final c = Offset(
      bandLeft + bandW * (onRight ? 0.78 : 0.22),
      v * regionH + regionH * 0.2,
    );
    final halo = Rect.fromCircle(center: c, radius: 120);
    canvas.drawRect(
      halo,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE9B0).withOpacity(0.22),
            const Color(0xFFFFE9B0).withOpacity(0.08),
            const Color(0xFFFFE9B0).withOpacity(0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(halo),
    );
    final disc = Rect.fromCircle(center: c, radius: 30);
    canvas.drawCircle(
      c,
      30,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.4),
          colors: [Color(0xFFFFFBEA), Color(0xFFF6DFA2), Color(0xFFD9B976)],
          stops: [0.0, 0.6, 1.0],
        ).createShader(disc),
    );
    // A few craters.
    final crater = Paint()..color = const Color(0xFFB99A5A).withOpacity(0.25);
    canvas.drawCircle(c + const Offset(-9, 6), 6, crater);
    canvas.drawCircle(c + const Offset(10, -8), 4, crater);
    canvas.drawCircle(c + const Offset(6, 12), 3, crater);
  }

  int n(int v) => colors.length - 1 - v; // world index from visual index

  void _aurora(
    Canvas canvas,
    Size size,
    int v, [
    List<Color> palette = const [
      Color(0xFF3DDC97),
      Color(0xFF4FC3F7),
      Color(0xFFB388FF),
    ],
  ]) {
    for (var i = 0; i < 3; i++) {
      final y0 = v * regionH + regionH * (0.16 + i * 0.09);
      final path = Path();
      for (var x = -20.0; x <= size.width + 20; x += 10) {
        final y =
            y0 +
            math.sin(x / bandW * math.pi * 1.6 + i * 1.3 + scroll * 0.0008) *
                26;
        if (x == -20.0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 46 - i * 8
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26)
          ..color = palette[i].withOpacity(0.2 * _window(y0, v)),
      );
    }
  }

  // ---- scenery pieces: few elements, low opacity, faded at region borders

  /// Element counts follow the painted width, so density is the same at any
  /// zoom or screen size.
  int _count(int base, Size size) =>
      math.max(1, (base * size.width / bandW).round());

  double _y(math.Random r, int v, double from, double to) =>
      v * regionH + regionH * (from + r.nextDouble() * (to - from));

  Color _c(Color base, double a) => base.withOpacity(a.clamp(0.0, 1.0));

  Path _heartPath(Offset c, double s) {
    final p = Path();
    for (var i = 0; i <= 60; i++) {
      final t = i / 60 * math.pi * 2;
      final x = 16 * math.pow(math.sin(t), 3);
      final y =
          -(13 * math.cos(t) -
              5 * math.cos(2 * t) -
              2 * math.cos(3 * t) -
              math.cos(4 * t));
      final pt = c + Offset(x * s / 16, y * s / 16);
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }

  Path _sparklePath(double s) => Path()
    ..addPolygon([
      Offset(0, -s),
      Offset(s * 0.22, -s * 0.22),
      Offset(s, 0),
      Offset(s * 0.22, s * 0.22),
      Offset(0, s),
      Offset(-s * 0.22, s * 0.22),
      Offset(-s, 0),
      Offset(-s * 0.22, -s * 0.22),
    ], true);

  void _bokeh(Canvas canvas, Size size, int v, Color a, Color b) {
    final r = math.Random(v * 41 + 5);
    for (var i = 0; i < _count(18, size); i++) {
      final y = _y(r, v, 0.05, 0.85);
      final al = (0.05 + r.nextDouble() * 0.08) * _window(y, v);
      canvas.drawCircle(
        Offset(r.nextDouble() * size.width, y),
        14 + r.nextDouble() * 34,
        Paint()..color = _c(i.isEven ? a : b, al),
      );
    }
    for (var i = 0; i < _count(8, size); i++) {
      final y = _y(r, v, 0.1, 0.8);
      canvas.drawPath(
        _heartPath(
          Offset(r.nextDouble() * size.width, y),
          6 + r.nextDouble() * 7,
        ),
        Paint()..color = _c(a, 0.22 * _window(y, v)),
      );
    }
  }

  void _fireworks(Canvas canvas, Size size, int v, Color a, Color b) {
    final r = math.Random(v * 29 + 9);
    for (var k = 0; k < _count(4, size); k++) {
      final c = Offset(r.nextDouble() * size.width, _y(r, v, 0.1, 0.5));
      final al = 0.4 * _window(c.dy, v);
      final col = k.isEven ? a : b;
      for (var i = 0; i < 14; i++) {
        final ang = i / 14 * math.pi * 2;
        final d = Offset(math.cos(ang), math.sin(ang));
        final len = 22 + r.nextDouble() * 10;
        canvas.drawLine(
          c + d * 9,
          c + d * len,
          Paint()
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round
            ..color = _c(col, al),
        );
        canvas.drawCircle(c + d * (len + 4), 1.6, Paint()..color = _c(col, al));
      }
    }
    for (var i = 0; i < _count(26, size); i++) {
      final y = _y(r, v, 0.05, 0.85);
      canvas.save();
      canvas.translate(r.nextDouble() * size.width, y);
      canvas.rotate(r.nextDouble() * 3);
      canvas.drawRect(
        const Rect.fromLTWH(-2, -1, 5, 2.4),
        Paint()..color = _c(i.isEven ? a : b, 0.35 * _window(y, v)),
      );
      canvas.restore();
    }
  }

  void _lanterns(Canvas canvas, Size size, int v, Color a, Color b, int count) {
    final r = math.Random(v * 17 + 3);
    for (var i = 0; i < _count(count, size); i++) {
      final c = Offset(r.nextDouble() * size.width, _y(r, v, 0.08, 0.6));
      final al = _window(c.dy, v);
      final glow = Rect.fromCircle(center: c, radius: 44);
      canvas.drawRect(
        glow,
        Paint()
          ..shader = RadialGradient(
            colors: [_c(a, 0.26 * al), _c(a, 0)],
          ).createShader(glow),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: 13, height: 18),
          const Radius.circular(5),
        ),
        Paint()..color = _c(a, 0.55 * al),
      );
      canvas.drawLine(
        c + const Offset(0, -9),
        c + const Offset(0, -15),
        Paint()
          ..strokeWidth = 1.4
          ..color = _c(b, 0.5 * al),
      );
    }
  }

  void _crescent(Canvas canvas, Size size, int v, Color tint) {
    final onRight = n(v).isEven;
    final c = Offset(
      bandLeft + bandW * (onRight ? 0.78 : 0.22),
      v * regionH + regionH * 0.2,
    );
    final path = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: c, radius: 30)),
      Path()..addOval(
        Rect.fromCircle(center: c + const Offset(13, -4), radius: 26),
      ),
    );
    final halo = Rect.fromCircle(center: c, radius: 110);
    canvas.drawRect(
      halo,
      Paint()
        ..shader = RadialGradient(
          colors: [_c(tint, 0.2), _c(tint, 0)],
        ).createShader(halo),
    );
    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFFFFE9B0).withOpacity(0.9),
    );
  }

  void _fireflies(Canvas canvas, Size size, int v, Color col, int count) {
    final r = math.Random(v * 23 + 7);
    for (var i = 0; i < _count(count, size); i++) {
      final y = _y(r, v, 0.1, 0.85);
      final al = (0.35 + r.nextDouble() * 0.45) * _window(y, v);
      final c = Offset(r.nextDouble() * size.width, y);
      canvas.drawCircle(c, 7, Paint()..color = _c(col, al * 0.18));
      canvas.drawCircle(c, 1.7, Paint()..color = _c(col, al));
    }
  }

  void _petals(Canvas canvas, Size size, int v, Color a, Color b) {
    final r = math.Random(v * 13 + 1);
    for (var i = 0; i < _count(24, size); i++) {
      final y = _y(r, v, 0.05, 0.9);
      canvas.save();
      canvas.translate(r.nextDouble() * size.width, y);
      canvas.rotate(r.nextDouble() * math.pi);
      final s = 6 + r.nextDouble() * 6;
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: s * 1.6, height: s),
        Paint()..color = _c(i.isEven ? a : b, 0.34 * _window(y, v)),
      );
      canvas.restore();
    }
  }

  void _sunset(Canvas canvas, Size size, int v, Color a, Color b) {
    final onRight = n(v).isEven;
    final c = Offset(
      bandLeft + bandW * (onRight ? 0.75 : 0.25),
      v * regionH + regionH * 0.56,
    );
    final al = _window(c.dy, v);
    final glow = Rect.fromCircle(center: c, radius: 170);
    canvas.drawRect(
      glow,
      Paint()
        ..shader = RadialGradient(
          colors: [_c(b, 0.34 * al), _c(a, 0.12 * al), _c(a, 0)],
          stops: const [0, 0.45, 1],
        ).createShader(glow),
    );
    final disc = Rect.fromCircle(center: c, radius: 34);
    canvas.drawCircle(
      c,
      34,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_c(b, 0.9 * al), _c(a, 0.9 * al)],
        ).createShader(disc),
    );
    final r = math.Random(v * 5);
    for (var i = 0; i < 4; i++) {
      final p = Offset(r.nextDouble() * size.width, _y(r, v, 0.12, 0.4));
      final s = 6 + r.nextDouble() * 4;
      canvas.drawPath(
        Path()
          ..moveTo(p.dx - s, p.dy)
          ..quadraticBezierTo(p.dx - s / 2, p.dy - s / 2, p.dx, p.dy)
          ..quadraticBezierTo(p.dx + s / 2, p.dy - s / 2, p.dx + s, p.dy),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withOpacity(0.35 * _window(p.dy, v)),
      );
    }
  }

  void _leaves(Canvas canvas, Size size, int v, Color a, Color b) {
    final r = math.Random(v * 19 + 2);
    for (var i = 0; i < _count(18, size); i++) {
      final y = _y(r, v, 0.05, 0.9);
      final s = 8 + r.nextDouble() * 9;
      canvas.save();
      canvas.translate(r.nextDouble() * size.width, y);
      canvas.rotate(r.nextDouble() * math.pi * 2);
      canvas.drawPath(
        Path()
          ..moveTo(0, -s)
          ..quadraticBezierTo(s * 0.8, 0, 0, s)
          ..quadraticBezierTo(-s * 0.8, 0, 0, -s),
        Paint()..color = _c(i % 3 == 0 ? b : a, 0.34 * _window(y, v)),
      );
      canvas.restore();
    }
  }

  void _diyas(Canvas canvas, Size size, int v, Color a, Color b) {
    final cnt = _count(12, size);
    for (var i = 0; i < cnt; i++) {
      final x = size.width * (i + 0.5) / cnt;
      final y = v * regionH + regionH * 0.7 + math.sin(i * 0.7) * 10;
      final al = _window(y, v);
      final glow = Rect.fromCircle(center: Offset(x, y), radius: 26);
      canvas.drawRect(
        glow,
        Paint()
          ..shader = RadialGradient(
            colors: [_c(b, 0.3 * al), _c(b, 0)],
          ).createShader(glow),
      );
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = _c(b, 0.9 * al));
    }
  }

  void _crystals(Canvas canvas, Size size, int v, Color col) {
    final r = math.Random(v * 31 + 4);
    for (var i = 0; i < _count(8, size); i++) {
      final y = _y(r, v, 0.1, 0.8);
      canvas.save();
      canvas.translate(r.nextDouble() * size.width, y);
      canvas.rotate(r.nextDouble() * 0.6 - 0.3);
      final s = 6 + r.nextDouble() * 8;
      canvas.drawPath(
        Path()..addPolygon([
          Offset(0, -s * 1.3),
          Offset(s * 0.8, 0),
          Offset(0, s * 1.3),
          Offset(-s * 0.8, 0),
        ], true),
        Paint()..color = _c(col, 0.38 * _window(y, v)),
      );
      canvas.restore();
    }
  }

  void _synthwave(Canvas canvas, Size size, int v, Color a, Color b) {
    final onRight = n(v).isEven;
    final cx = bandLeft + bandW * (onRight ? 0.74 : 0.26);
    final horizon = v * regionH + regionH * 0.7;
    final al = _window(horizon - regionH * 0.2, v);
    final disc = Rect.fromCircle(center: Offset(cx, horizon - 20), radius: 46);
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(cx - 60, horizon - 80, cx + 60, horizon));
    canvas.drawCircle(
      Offset(cx, horizon - 20),
      46,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_c(b, 0.85 * al), _c(a, 0.85 * al)],
        ).createShader(disc),
    );
    // Stripes cut out of the sun.
    for (var k = 0; k < 5; k++) {
      canvas.drawRect(
        Rect.fromLTWH(cx - 60, horizon - 6 - k * 9, 120, 1.5 + k * 0.7),
        Paint()..color = colors[v],
      );
    }
    canvas.restore();
    final grid = Paint()
      ..strokeWidth = 1
      ..color = _c(a, 0.16 * al);
    for (var i = -6; i <= 6; i++) {
      canvas.drawLine(
        Offset(cx + i * 7, horizon),
        Offset(cx + i * 70, horizon + regionH * 0.26),
        grid,
      );
    }
    var d = 6.0;
    for (var k = 0; k < 6; k++) {
      canvas.drawLine(
        Offset(cx - 420, horizon + d),
        Offset(cx + 420, horizon + d),
        grid,
      );
      d *= 1.55;
    }
  }

  void _skyline(Canvas canvas, Size size, int v, Color a, Color b) {
    final r = math.Random(v * 7 + 13);
    final base = v * regionH + regionH * 0.8;
    final al = _window(base - regionH * 0.2, v);
    var x = 0.0;
    while (x < size.width) {
      final w = 14 + r.nextDouble() * 22;
      final h = 28 + r.nextDouble() * 70;
      canvas.drawRect(
        Rect.fromLTWH(x, base - h, w, h + regionH),
        Paint()..color = const Color(0xFF04060F).withOpacity(0.5 * al),
      );
      for (var k = 0; k < 4; k++) {
        if (r.nextDouble() < 0.55) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            x + 3 + r.nextDouble() * (w - 7),
            base - h + 5 + r.nextDouble() * (h - 10),
            2.2,
            3,
          ),
          Paint()..color = _c(r.nextBool() ? a : b, 0.7 * al),
        );
      }
      x += w + 2 + r.nextDouble() * 4;
    }
    final line = Rect.fromLTWH(0, base - 4, size.width, 8);
    canvas.drawRect(
      line,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_c(b, 0), _c(b, 0.25 * al), _c(b, 0)],
        ).createShader(line),
    );
  }

  void _sparkles(Canvas canvas, Size size, int v, Color a, Color b) {
    final r = math.Random(v * 43 + 6);
    for (var i = 0; i < _count(20, size); i++) {
      final y = _y(r, v, 0.05, 0.85);
      canvas.save();
      canvas.translate(r.nextDouble() * size.width, y);
      canvas.drawPath(
        _sparklePath(4 + r.nextDouble() * 7),
        Paint()..color = _c(i.isEven ? a : b, 0.45 * _window(y, v)),
      );
      canvas.restore();
    }
  }

  void _bats(Canvas canvas, Size size, int v) {
    final r = math.Random(v * 11 + 8);
    for (var i = 0; i < _count(4, size); i++) {
      final p = Offset(r.nextDouble() * size.width, _y(r, v, 0.1, 0.45));
      final s = 7 + r.nextDouble() * 6;
      canvas.drawPath(
        Path()
          ..moveTo(p.dx - s, p.dy)
          ..quadraticBezierTo(
            p.dx - s * 0.5,
            p.dy - s * 0.8,
            p.dx,
            p.dy - s * 0.2,
          )
          ..quadraticBezierTo(p.dx + s * 0.5, p.dy - s * 0.8, p.dx + s, p.dy)
          ..quadraticBezierTo(
            p.dx + s * 0.5,
            p.dy - s * 0.1,
            p.dx,
            p.dy + s * 0.35,
          )
          ..quadraticBezierTo(p.dx - s * 0.5, p.dy - s * 0.1, p.dx - s, p.dy),
        Paint()
          ..color = const Color(
            0xFF0B0714,
          ).withOpacity(0.55 * _window(p.dy, v)),
      );
    }
  }

  void _snow(Canvas canvas, Size size, int v) {
    final r = math.Random(v * 71 + 3);
    for (var i = 0; i < _count(70, size); i++) {
      final y = v * regionH + r.nextDouble() * regionH;
      final a = (0.25 + r.nextDouble() * 0.5) * _window(y, v);
      canvas.drawCircle(
        Offset(r.nextDouble() * size.width, y),
        0.9 + r.nextDouble() * 2.2,
        Paint()..color = Colors.white.withOpacity(a),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WorldPainter old) =>
      old.scroll != scroll ||
      old.colors != colors ||
      old.glows != glows ||
      old.viewport != viewport ||
      old.bandLeft != bandLeft;
}

// ------------------------------------------------------------------ trail

class _Trail {
  _Trail(this.points, this.cumulative, this.nodeDist, this.dotGap);

  final List<Offset> points;
  final List<double> cumulative;
  final List<double> nodeDist;
  final double dotGap;

  double get total => cumulative.last;

  static _Trail build(List<Offset> nodes, double dotGap) {
    final pts = <Offset>[nodes.first];
    final cum = <double>[0];
    final nodeDist = <double>[0];
    for (var i = 0; i < nodes.length - 1; i++) {
      final a = nodes[i]; // below
      final b = nodes[i + 1]; // above
      final c1 = Offset(a.dx, a.dy - 140);
      final c2 = Offset(b.dx, b.dy + 140);
      const steps = 80;
      for (var s = 1; s <= steps; s++) {
        final t = s / steps;
        final u = 1 - t;
        final p =
            a * (u * u * u) +
            c1 * (3 * u * u * t) +
            c2 * (3 * u * t * t) +
            b * (t * t * t);
        cum.add(cum.last + (p - pts.last).distance);
        pts.add(p);
      }
      nodeDist.add(cum.last);
    }
    return _Trail(pts, cum, nodeDist, dotGap);
  }

  Offset pointAt(double d) {
    if (d <= 0) return points.first;
    if (d >= total) return points.last;
    var lo = 0;
    var hi = cumulative.length - 1;
    while (hi - lo > 1) {
      final mid = (lo + hi) >> 1;
      if (cumulative[mid] <= d) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final span = cumulative[hi] - cumulative[lo];
    final f = span == 0 ? 0.0 : (d - cumulative[lo]) / span;
    return Offset.lerp(points[lo], points[hi], f)!;
  }
}

class _TrailPainter extends CustomPainter {
  _TrailPainter({
    required this.trail,
    required this.progress,
    required this.lit,
  });

  final _Trail trail;
  final double progress;
  final Color lit;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = Colors.white.withOpacity(0.22);
    final on = Paint()..color = Colors.white;
    final glow = Paint()
      ..color = lit.withOpacity(0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    for (var d = trail.dotGap; d < trail.total; d += trail.dotGap) {
      final p = trail.pointAt(d);
      if (d <= progress) {
        canvas.drawCircle(p, 9, glow);
        canvas.drawCircle(p, 5.5, on);
      } else {
        canvas.drawCircle(p, 4, dim);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrailPainter old) =>
      old.progress != progress || old.lit != lit || old.trail != trail;
}

/// A ring and a few sparks in the region's color, no glyphs.
class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.center, required this.t, required this.color});

  final Offset center;
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final e = Curves.easeOutCubic.transform(t);
    final fade = (1 - t).clamp(0.0, 1.0);
    canvas.drawCircle(
      center,
      70 + 90 * e,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * fade
        ..color = Colors.white.withOpacity(0.7 * fade),
    );
    for (var i = 0; i < 12; i++) {
      final a = (i / 12) * math.pi * 2;
      final r = 80 + (i % 3) * 30;
      final p = center + Offset(math.cos(a), math.sin(a)) * (r * e);
      canvas.drawCircle(
        p,
        (4 - (i % 3)) * fade,
        Paint()
          ..color = Color.lerp(color, Colors.white, 0.4)!.withOpacity(fade),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) =>
      old.t != t || old.center != center;
}

// ------------------------------------------------------------------- pill

/// Calendar icon + switch: follow the season automatically or stay put.
class _AutoPill extends StatelessWidget {
  const _AutoPill({
    super.key,
    required this.isAuto,
    required this.accent,
    required this.surface,
    required this.onChanged,
  });

  final bool isAuto;
  final Color accent;
  final Color surface;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isAuto ? 'Following the calendar' : 'Pinned to the chosen world',
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
        decoration: BoxDecoration(
          color: surface.withOpacity(0.92),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 20,
              color: isAuto ? accent : Colors.white.withOpacity(0.5),
            ),
            Switch(
              value: isAuto,
              activeThumbColor: accent,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ locate

/// "Back to me": scrolls the map to the player.
class _LocateButton extends StatelessWidget {
  const _LocateButton({required this.surface, required this.onTap});

  final Color surface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Back to me',
      child: Material(
        color: surface.withOpacity(0.92),
        shape: const CircleBorder(),
        elevation: 6,
        shadowColor: Colors.black54,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              Icons.my_location_rounded,
              size: 22,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
