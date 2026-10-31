import 'package:flutter/material.dart';

/// キャラ取得/レベルアップ・バッジ取得など、「やった感」を盛り上げる祝賀
/// ダイアログ全般で使う共通の演出パーツ。第三者パッケージ(confetti等)は
/// 使わず、Flutter標準の`AnimationController`のみで多色の星の散らばり+
/// 広がるグローリング+中央コンテンツの弾む登場を表現する。
class CelebrationBurst extends StatelessWidget {
  const CelebrationBurst({
    super.key,
    required this.controller,
    required this.child,
    this.size = 180,
  });

  final AnimationController controller;
  final Widget child;
  final double size;

  static const _particles = [
    (-1.0, -0.6, Colors.amber, Icons.star),
    (-0.3, -1.1, Colors.deepOrange, Icons.auto_awesome),
    (0.4, -1.0, Colors.amber, Icons.star_rate_rounded),
    (1.0, -0.5, Colors.purple, Icons.auto_awesome),
    (-0.8, 0.3, Colors.teal, Icons.star),
    (0.9, 0.4, Colors.amber, Icons.auto_awesome),
    (0.0, -1.3, Colors.deepOrange, Icons.star_rate_rounded),
    (-1.1, -0.1, Colors.purple, Icons.star),
    (1.1, -0.1, Colors.teal, Icons.auto_awesome),
    (-0.5, 1.0, Colors.amber, Icons.star_rate_rounded),
    (0.5, 1.0, Colors.deepOrange, Icons.star),
    (0.0, 1.3, Colors.purple, Icons.auto_awesome),
  ];

  @override
  Widget build(BuildContext context) {
    final radius = size / 2;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 広がりながら薄くなる、2重のグローリング(放射状の輪)。
          for (final ringDelay in [0.0, 0.15])
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final t = ((controller.value - ringDelay) / (1 - ringDelay)).clamp(0.0, 1.0);
                final progress = Curves.easeOut.transform(t);
                return Opacity(
                  opacity: (1 - progress) * 0.5,
                  child: Container(
                    width: size * 0.7 + size * 0.5 * progress,
                    height: size * 0.7 + size * 0.5 * progress,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber, width: 3),
                    ),
                  ),
                );
              },
            ),
          // 多色の星が弾けて飛び散る粒子。
          for (final (dx, dy, color, icon) in _particles)
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final progress = Curves.easeOut.transform(controller.value);
                final opacity = (1 - progress).clamp(0.0, 1.0);
                // 序盤は少し拡大してから縮む、ポップするような大きさの変化。
                final pop = Curves.easeOut.transform((controller.value * 2).clamp(0.0, 1.0));
                final scale = (1.0 - progress) * (0.6 + 0.6 * pop);
                return Positioned(
                  left: radius + dx * radius * 0.9 * progress - 11,
                  top: radius + dy * radius * 0.9 * progress - 11,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: Icon(icon, size: 22, color: color),
                    ),
                  ),
                );
              },
            ),
          ScaleTransition(
            scale: CurvedAnimation(parent: controller, curve: Curves.elasticOut),
            child: child,
          ),
        ],
      ),
    );
  }
}
