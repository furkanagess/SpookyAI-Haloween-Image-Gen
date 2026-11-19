import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/prompt_input_provider.dart';
import '../../../../core/theme/seasons/season_palette.dart';

class PromptInputWidget extends StatefulWidget {
  const PromptInputWidget({
    super.key,
    required this.onPromptChanged,
    required this.hintText,
    this.initialText,
    this.onSurprise,
    this.title = 'Describe your vision',
    this.minLines = 4,
  });

  final Function(String) onPromptChanged;
  final String hintText;
  final String? initialText;

  /// When set, a "Surprise me" action is shown in the header.
  final VoidCallback? onSurprise;
  final String title;
  final int minLines;

  @override
  State<PromptInputWidget> createState() => _PromptInputWidgetState();
}

class _PromptInputWidgetState extends State<PromptInputWidget>
    with TickerProviderStateMixin {
  final math.Random _rng = math.Random();
  int _value = 5; // the face that is showing when the dice is still

  int _nextValue() {
    var n = _value;
    while (n == _value) {
      n = _rng.nextInt(6) + 1;
    }
    return n;
  }

  /// Full roll when the dice is tapped.
  late final AnimationController _roll = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  int _lastIssueTick = 0;

  late final TextEditingController _controller;
  final FocusNode _focus = FocusNode();

  /// True while the text is set from the parent (e.g. the dice). That happens
  /// inside didUpdateWidget, i.e. during build, so listeners must not notify
  /// synchronously there.
  bool _syncingFromParent = false;

  void _notifyTextChanged() {
    if (!mounted) return;
    context.read<PromptInputProvider>().updateText(_controller.text);
    widget.onPromptChanged(_controller.text);
  }

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController();
    _focus.addListener(() => setState(() {}));
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _controller.text = widget.initialText!;
    }
    _controller.addListener(() {
      if (_syncingFromParent) return;
      _notifyTextChanged();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PromptInputProvider>().initialize(widget.initialText);
    });
  }

  @override
  void didUpdateWidget(covariant PromptInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialText != null &&
        widget.initialText != oldWidget.initialText) {
      if (_controller.text != widget.initialText) {
        _syncingFromParent = true;
        _controller.value = TextEditingValue(
          text: widget.initialText!,
          selection: TextSelection.collapsed(
            offset: widget.initialText!.length,
          ),
        );
        _syncingFromParent = false;
        // Tell the provider/parent after this frame, not during build.
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _notifyTextChanged(),
        );
      }
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    _roll.dispose();
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Icon-only "surprise me": a small die that stays still until it is
  /// tapped, then rattles, tumbles and lands on a new face.
  Widget _buildDice() {
    return Semantics(
      button: true,
      label: 'Surprise me',
      child: Tooltip(
        message: 'Surprise me',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.mediumImpact();
            setState(() => _value = _nextValue());
            _roll.forward(from: 0);
            widget.onSurprise?.call();
          },
          child: SizedBox(
            width: 44,
            height: 44,
            child: AnimatedBuilder(
              animation: _roll,
              builder: (context, _) {
                final u = _roll.value;
                final rolling = _roll.isAnimating;
                final env = rolling ? math.sin(u * math.pi) : 0.0;
                final jitter = Offset(
                  math.sin(u * 70) * 1.8 * env,
                  math.cos(u * 55) * 1.8 * env,
                );
                final angle = rolling
                    ? Curves.easeOutCubic.transform(u) * math.pi * 2 +
                          math.sin(u * 40) * 0.4 * env
                    : 0.0;
                // Faces flicker while it moves, then settle on `_value`.
                final shown = rolling && u < 0.8
                    ? ((_value + u * 30).floor() % 6) + 1
                    : _value;
                return Center(
                  child: Transform.translate(
                    offset: jitter,
                    child: Transform.rotate(
                      angle: angle,
                      child: CustomPaint(
                        size: const Size(26, 26),
                        painter: _DicePainter(
                          value: shown,
                          color: SeasonPalette.accent,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PromptInputProvider>(
      builder: (context, provider, child) {
        final issue = provider.issueMessage;
        final over = provider.isOverLimit || issue != null;
        final focused = _focus.hasFocus;
        if (provider.issueTick != _lastIssueTick) {
          _lastIssueTick = provider.issueTick;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _shake.forward(from: 0);
          });
        }
        final borderColor = over
            ? Colors.redAccent.withOpacity(0.7)
            : focused
            ? SeasonPalette.accent.withOpacity(0.8)
            : SeasonPalette.text.withOpacity(0.10);

        return AnimatedBuilder(
          animation: _shake,
          builder: (_, child) => Transform.translate(
            offset: Offset(
              math.sin(_shake.value * math.pi * 6) * 9 * (1 - _shake.value),
              0,
            ),
            child: child,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: SeasonPalette.inputFill,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor, width: focused ? 1.5 : 1),
              boxShadow: [
                BoxShadow(
                  color: (over ? Colors.redAccent : SeasonPalette.accent)
                      .withOpacity(focused ? 0.18 : 0.0),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 12, 0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 18,
                        color: SeasonPalette.accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      if (widget.onSurprise != null) _buildDice(),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: provider.characterCount > 0
                            ? IconButton(
                                key: const ValueKey('clear'),
                                tooltip: 'Clear',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _controller.clear(),
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: SeasonPalette.text.withOpacity(0.55),
                                ),
                              )
                            : const SizedBox(key: ValueKey('none'), height: 40),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    minLines: widget.minLines,
                    maxLines: 8,
                    maxLength: 500,
                    cursorColor: SeasonPalette.accent,
                    style: TextStyle(
                      color: SeasonPalette.text,
                      fontSize: 16,
                      height: 1.45,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: TextStyle(
                        color: SeasonPalette.text.withOpacity(0.35),
                        fontSize: 16,
                        height: 1.45,
                      ),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      counterText: '',
                    ),
                    keyboardAppearance: Brightness.dark,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    onEditingComplete: () => FocusScope.of(context).unfocus(),
                    scrollPadding: const EdgeInsets.only(bottom: 220),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          issue ??
                              (provider.isOverLimit
                                  ? 'Too long — shorten your prompt'
                                  : 'More detail gives better results'),
                          style: TextStyle(
                            fontSize: 12,
                            color: over
                                ? Colors.redAccent
                                : SeasonPalette.text.withOpacity(0.4),
                          ),
                        ),
                      ),
                      Text(
                        '${provider.characterCount}/500',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: over
                              ? Colors.redAccent
                              : SeasonPalette.text.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A small die: rounded square in the season color, white pips.
class _DicePainter extends CustomPainter {
  _DicePainter({required this.value, required this.color});

  final int value;
  final Color color;

  static const _pips = <int, List<Offset>>{
    1: [Offset(0.5, 0.5)],
    2: [Offset(0.27, 0.27), Offset(0.73, 0.73)],
    3: [Offset(0.27, 0.27), Offset(0.5, 0.5), Offset(0.73, 0.73)],
    4: [
      Offset(0.27, 0.27),
      Offset(0.73, 0.27),
      Offset(0.27, 0.73),
      Offset(0.73, 0.73),
    ],
    5: [
      Offset(0.27, 0.27),
      Offset(0.73, 0.27),
      Offset(0.5, 0.5),
      Offset(0.27, 0.73),
      Offset(0.73, 0.73),
    ],
    6: [
      Offset(0.27, 0.25),
      Offset(0.73, 0.25),
      Offset(0.27, 0.5),
      Offset(0.73, 0.5),
      Offset(0.27, 0.75),
      Offset(0.73, 0.75),
    ],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final body = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.width * 0.26),
    );
    canvas.drawRRect(
      body.shift(const Offset(0, 1.5)),
      Paint()..color = Colors.black.withOpacity(0.28),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, 0.28)!, color],
        ).createShader(rect),
    );
    canvas.drawRRect(
      body.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withOpacity(0.35),
    );
    final pip = Paint()..color = Colors.white;
    for (final p in _pips[value.clamp(1, 6)]!) {
      canvas.drawCircle(
        Offset(p.dx * size.width, p.dy * size.height),
        size.width * 0.085,
        pip,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DicePainter old) =>
      old.value != value || old.color != color;
}
