import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

/// 절취선 자리에 반원 홈이 파인 티켓 모양.
///
/// Card의 `shape`로 쓰면 그림자와 잘림(clip)이 티켓 윤곽을 그대로 따른다.
class TicketShapeBorder extends ShapeBorder {
  const TicketShapeBorder({
    required this.splitAxis,
    required this.splitOffset,
    this.fromEnd = false,
    this.radius = AppRadius.xl,
    this.notchRadius = AppSpacing.sm,
  });

  /// [Axis.vertical]이면 세로 절취선(좌우로 나뉨) → 위·아래 가장자리에 홈.
  /// [Axis.horizontal]이면 가로 절취선(위아래로 나뉨) → 좌·우 가장자리에 홈.
  final Axis splitAxis;

  /// 절취선 위치. 시작(왼쪽·위)에서의 거리, [fromEnd]면 끝(오른쪽·아래)에서의 거리.
  final double splitOffset;
  final bool fromEnd;
  final double radius;
  final double notchRadius;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final body = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

    final (Offset a, Offset b) = switch (splitAxis) {
      Axis.vertical => () {
        final x = fromEnd ? rect.right - splitOffset : rect.left + splitOffset;
        return (Offset(x, rect.top), Offset(x, rect.bottom));
      }(),
      Axis.horizontal => () {
        final y = fromEnd ? rect.bottom - splitOffset : rect.top + splitOffset;
        return (Offset(rect.left, y), Offset(rect.right, y));
      }(),
    };
    final notches = Path()
      ..addOval(Rect.fromCircle(center: a, radius: notchRadius))
      ..addOval(Rect.fromCircle(center: b, radius: notchRadius));

    return Path.combine(PathOperation.difference, body, notches);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => TicketShapeBorder(
    splitAxis: splitAxis,
    splitOffset: splitOffset * t,
    fromEnd: fromEnd,
    radius: radius * t,
    notchRadius: notchRadius * t,
  );
}

/// 티켓 절취선용 점선.
class DashedLine extends StatelessWidget {
  const DashedLine({super.key, required this.axis, required this.color});

  final Axis axis;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: axis == Axis.vertical
          ? const Size(1.5, double.infinity)
          : const Size(double.infinity, 1.5),
      painter: _DashedLinePainter(axis: axis, color: color),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.axis, required this.color});

  final Axis axis;
  final Color color;

  static const _dash = 5.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final length = axis == Axis.vertical ? size.height : size.width;
    for (var d = 0.0; d < length; d += _dash + _gap) {
      final end = (d + _dash).clamp(0, length).toDouble();
      if (axis == Axis.vertical) {
        canvas.drawLine(
          Offset(size.width / 2, d),
          Offset(size.width / 2, end),
          paint,
        );
      } else {
        canvas.drawLine(
          Offset(d, size.height / 2),
          Offset(end, size.height / 2),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) =>
      old.axis != axis || old.color != color;
}
