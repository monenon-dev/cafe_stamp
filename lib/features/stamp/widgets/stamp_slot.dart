import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// 스탬프 카드의 원형 슬롯 1칸.
///
/// 채워진 칸은 칸마다 기울기가 조금씩 다른 도장 모양으로 그리고,
/// 빈 칸에서 채워진 칸으로 바뀌는 순간에만 "쿵" 찍히는 애니메이션을 재생한다.
class StampSlot extends StatefulWidget {
  const StampSlot({
    super.key,
    required this.index,
    required this.filled,
    this.isReward = false,
  });

  /// 1부터 시작하는 칸 번호
  final int index;
  final bool filled;

  /// 마지막(보상) 칸 여부. 보조색으로 강조한다.
  final bool isReward;

  @override
  State<StampSlot> createState() => _StampSlotState();
}

class _StampSlotState extends State<StampSlot>
    with SingleTickerProviderStateMixin {
  /// 손으로 찍은 듯한 칸별 기울기(도). 칸 번호로 정해져 매번 같다.
  static const _tiltDegrees = [-8, 5, -3, 9, -6, 4, -9, 7, -4, 6];

  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    // 처음 그려질 때는 애니메이션 없이 완료 상태로 시작한다.
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.stampPop,
      value: 1,
    );
    // 위에서 크게 내려와 살짝 눌렸다가 제자리로.
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.8,
          end: 0.9,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.9,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
    ]).animate(_controller);
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.4, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(StampSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.filled && widget.filled) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _tilt =>
      _tiltDegrees[(widget.index - 1) % _tiltDegrees.length] * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ink = widget.isReward ? colors.tertiary : colors.primary;

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;
          if (widget.filled) {
            return FadeTransition(
              opacity: _opacity,
              child: ScaleTransition(
                scale: _scale,
                child: Transform.rotate(
                  angle: _tilt,
                  child: _InkStamp(
                    ink: ink,
                    onInk: widget.isReward
                        ? colors.onTertiary
                        : colors.onPrimary,
                    icon: widget.isReward
                        ? Icons.redeem_rounded
                        : Icons.local_cafe_rounded,
                    size: size,
                  ),
                ),
              ),
            );
          }
          return _EmptySlot(
            index: widget.index,
            isReward: widget.isReward,
            size: size,
          );
        },
      ),
    );
  }
}

/// 찍힌 도장: 바깥 테두리 + 안쪽 잉크 원 + 아이콘.
class _InkStamp extends StatelessWidget {
  const _InkStamp({
    required this.ink,
    required this.onInk,
    required this.icon,
    required this.size,
  });

  final Color ink;
  final Color onInk;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ring = size * 0.04;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ink.withValues(alpha: 0.85), width: ring),
      ),
      child: Padding(
        padding: EdgeInsets.all(ring * 1.5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // 잉크가 살짝 번진 느낌으로 가운데가 조금 더 진하다.
            gradient: RadialGradient(
              colors: [ink, ink.withValues(alpha: 0.82)],
            ),
          ),
          child: Center(
            child: Icon(icon, size: size * 0.42, color: onInk),
          ),
        ),
      ),
    );
  }
}

/// 빈 칸: 점선 원 + 칸 번호. 보상 칸은 선물 아이콘.
class _EmptySlot extends StatelessWidget {
  const _EmptySlot({
    required this.index,
    required this.isReward,
    required this.size,
  });

  final int index;
  final bool isReward;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final lineColor = isReward
        ? colors.tertiary.withValues(alpha: 0.7)
        : colors.onSurfaceVariant.withValues(alpha: 0.3);

    return CustomPaint(
      painter: _DashedCirclePainter(color: lineColor, strokeWidth: 1.5),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isReward
              ? colors.tertiaryContainer.withValues(alpha: 0.6)
              : null,
        ),
        child: Center(
          child: isReward
              ? Icon(
                  Icons.card_giftcard_rounded,
                  size: size * 0.4,
                  color: colors.tertiary,
                )
              : Text(
                  '$index',
                  style: textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.55),
                  ),
                ),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  static const _dashCount = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    ).deflate(strokeWidth / 2);
    const sweep = 2 * math.pi / _dashCount;
    for (var i = 0; i < _dashCount; i++) {
      canvas.drawArc(rect, i * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}
