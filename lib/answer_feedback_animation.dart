import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 回答直後のフィードバック演出。正解時はカードが弾むように登場して
/// 星の粒がふわっと舞い、不正解時はカードが控えめに左右へ揺れる
/// (強く不安にさせない程度の、再挑戦を促す演出)。
/// 新しい問題に進むたびに外側で`key`を変えて作り直すことで、演出が
/// 毎回リセットされるようにする想定。
class AnswerFeedbackAnimation extends StatefulWidget {
  const AnswerFeedbackAnimation({super.key, required this.correct, required this.child});

  final bool correct;
  final Widget child;

  @override
  State<AnswerFeedbackAnimation> createState() => _AnswerFeedbackAnimationState();
}

class _AnswerFeedbackAnimationState extends State<AnswerFeedbackAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.correct ? const Duration(milliseconds: 700) : const Duration(milliseconds: 400),
  )..forward();

  static const _starOffsets = [
    (-1.0, -0.6),
    (-0.4, -1.0),
    (0.2, -0.9),
    (0.8, -0.5),
    (-0.8, -0.1),
    (0.9, -1.0),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.correct) {
      // 不正解: カードを左右に軽く揺らす(シェイク)。
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          final shake = math.sin(progress * math.pi * 6) * (1 - progress) * 6;
          return Transform.translate(offset: Offset(shake, 0), child: child);
        },
        child: widget.child,
      );
    }

    // 正解: カードが弾むように拡大登場し、星の粒が周囲に舞う。
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ScaleTransition(
          scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
          child: widget.child,
        ),
        for (var i = 0; i < _starOffsets.length; i++)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final (dx, dy) = _starOffsets[i];
              final progress = Curves.easeOut.transform(_controller.value);
              final opacity = (1 - progress).clamp(0.0, 1.0);
              return Positioned(
                left: 24 + dx * 80 * progress,
                top: 24 + dy * 80 * progress,
                child: Opacity(
                  opacity: opacity,
                  child: Icon(
                    Icons.star,
                    key: i == 0 ? const Key('answerCelebrationStar') : null,
                    size: 18,
                    color: Colors.amber,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
