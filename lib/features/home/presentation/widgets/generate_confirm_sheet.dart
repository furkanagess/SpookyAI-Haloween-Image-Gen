import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/seasons/season_palette.dart';
import '../../data/models/prompt_category.dart';
import '../../domain/generation_mode.dart';
import 'prompt_preview.dart';

/// Confirmation bottom sheet: a picture and the name of what will be made,
/// a short description of the style, the cost, Generate and Cancel. Returns true on confirm.
Future<bool> showGenerateConfirmSheet(
  BuildContext context, {
  required GenerationMode mode,
  required double cost,
  required double balance,
  PromptItem? style,
  String? promptText,
  Uint8List? photo,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (_) => _GenerateConfirmSheet(
      mode: mode,
      cost: cost,
      balance: balance,
      style: style,
      promptText: promptText,
      photo: photo,
    ),
  );
  return result == true;
}

class _GenerateConfirmSheet extends StatefulWidget {
  const _GenerateConfirmSheet({
    required this.mode,
    required this.cost,
    required this.balance,
    this.style,
    this.promptText,
    this.photo,
  });

  final GenerationMode mode;
  final double cost;
  final double balance;
  final PromptItem? style;
  final String? promptText;
  final Uint8List? photo;

  @override
  State<_GenerateConfirmSheet> createState() => _GenerateConfirmSheetState();
}

class _GenerateConfirmSheetState extends State<_GenerateConfirmSheet>
    with SingleTickerProviderStateMixin {
  /// One controller drives a staggered entrance: hero, balance, button.
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    final reduce = SchedulerBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    reduce ? _in.value = 1 : _in.forward();
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  /// 0..1 progress of one step of the entrance.
  Animation<double> _step(double from, double to) => CurvedAnimation(
    parent: _in,
    curve: Interval(from, to, curve: Curves.easeOutCubic),
  );

  Widget _reveal(Animation<double> a, Widget child, {double dy = 18}) =>
      AnimatedBuilder(
        animation: a,
        builder: (context, c) => Opacity(
          opacity: a.value,
          child: Transform.translate(
            offset: Offset(0, (1 - a.value) * dy),
            child: c,
          ),
        ),
        child: child,
      );

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final accent = SeasonPalette.accent;
    final accent2 = SeasonPalette.secondaryAccent;
    final description = (widget.style?.description ?? '').trim();
    final typed = (widget.promptText ?? '').trim();
    final title = widget.style?.title ?? (typed.isEmpty ? null : typed);

    return Container(
      decoration: BoxDecoration(
        color: SeasonPalette.scaffold,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 40,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
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
              const SizedBox(height: 16),

              // Hero: the picture with the name on it and the cost on top.
              _reveal(_step(0.0, 0.6), _hero(title, accent, accent2), dy: 26),
              const SizedBox(height: 16),

              // About the style (never its prompt).
              if (description.isNotEmpty) ...[
                _reveal(
                  _step(0.2, 0.75),
                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.4,
                      color: SeasonPalette.text.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ] else
                const SizedBox(height: 4),

              // The one action.
              _reveal(_step(0.35, 1.0), _generateButton(accent, accent2)),
              const SizedBox(height: 4),
              _reveal(
                _step(0.45, 1.0),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: SeasonPalette.text.withOpacity(0.65),
                    ),
                  ),
                ),
                dy: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(String? title, Color accent, Color accent2) {
    final style = widget.style;
    final Widget picture;
    if (style != null) {
      picture = PromptPreview(
        id: style.id,
        tags: style.tags,
        isImageToImage: style.promptType == PromptType.imageToImage,
        imageUrl: style.imageUrl,
        borderRadius: 0,
      );
    } else if (widget.photo != null) {
      picture = Image.memory(widget.photo!, fit: BoxFit.cover);
    } else {
      picture = Container(
        color: accent,
        alignment: Alignment.center,
        child: Text(
          SeasonPalette.current.emoji,
          style: const TextStyle(fontSize: 64),
        ),
      );
    }

    return Container(
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          picture,
          // Cost chip.
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department, size: 18, color: accent2),
                  const SizedBox(width: 6),
                  Text(
                    _fmt(widget.cost),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (title != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withOpacity(0.6),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _generateButton(Color accent, Color accent2) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(true);
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: accent,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_pressed ? 0.2 : 0.35),
                blurRadius: _pressed ? 12 : 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 22,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Text(
                'Generate · ${_fmt(widget.cost)} token${widget.cost == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
