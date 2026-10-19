import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format/app_date_format.dart';
import '../../core/format/keep_all.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/coupon.dart';
import '../../data/repositories/repository_providers.dart';
import '../../data/state/coupon_notifier.dart';
import '../../widgets/ticket.dart';
import '../../widgets/titled_page.dart';
import 'widgets/coupon_tile.dart';

/// 쿠폰 상세: 쿠폰 번호, 유효기간, 이용 안내, 사용하기.
class CouponDetailScreen extends ConsumerStatefulWidget {
  const CouponDetailScreen({super.key, required this.couponId});

  final String couponId;

  @override
  ConsumerState<CouponDetailScreen> createState() => _CouponDetailScreenState();
}

class _CouponDetailScreenState extends ConsumerState<CouponDetailScreen> {
  bool _using = false;

  static const _notes = [
    '매장 직원에게 이 화면을 보여 준 뒤 사용하기를 눌러 주세요.',
    '다른 쿠폰과 함께 사용할 수 없어요.',
    '사용한 쿠폰은 되돌릴 수 없어요.',
    '유효기간이 지나면 만료 탭으로 옮겨져요.',
  ];

  Future<void> _onUsePressed(Coupon coupon) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('쿠폰을 사용할까요?'),
        content: Text(
          '${coupon.title}\n\n'
          '직원에게 화면을 보여 주셨다면 사용하기를 눌러 주세요. '
          '사용한 쿠폰은 되돌릴 수 없어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('사용하기'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _using = true);
    final used = await ref.read(couponsProvider.notifier).use(coupon.id);
    if (!mounted) return;
    setState(() => _using = false);
    if (!used) return;

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('쿠폰을 사용했어요. 맛있게 드세요!')));
  }

  @override
  Widget build(BuildContext context) {
    final coupon = ref.watch(couponByIdProvider(widget.couponId));
    final now = ref.watch(clockProvider)();

    if (coupon == null) {
      return const TitledPage(title: '쿠폰 상세', body: _CouponNotFound());
    }

    final status = coupon.statusAt(now);
    final available = status == CouponStatus.available;

    return TitledPage(
      title: '쿠폰 상세',
      body: ListView(
        padding: AppSpacing.page,
        children: [
          _CouponHeader(coupon: coupon, now: now),
          const SizedBox(height: AppSpacing.md),
          _InfoCard(coupon: coupon, now: now),
          const SizedBox(height: AppSpacing.md),
          _NotesCard(notes: _notes),
        ],
      ),
      // 스크롤과 관계없이 항상 보이도록 하단에 고정한다.
      bottomBar: FilledButton(
        onPressed: available && !_using ? () => _onUsePressed(coupon) : null,
        child: Text(switch (status) {
          _ when _using => '사용 처리 중이에요',
          CouponStatus.available => '쿠폰 사용하기',
          CouponStatus.used => '이미 사용한 쿠폰이에요',
          CouponStatus.expired => '유효기간이 지난 쿠폰이에요',
        }),
      ),
    );
  }
}

/// 쿠폰 상세 상단 티켓: 위쪽은 혜택, 절취선 아래는 쿠폰 번호.
class _CouponHeader extends StatelessWidget {
  const _CouponHeader({required this.coupon, required this.now});

  final Coupon coupon;
  final DateTime now;

  /// 절취선 아래 영역 높이. 사용 가능한 쿠폰은 바코드까지 들어간다.
  static const _codeHeight = 112.0;
  static const _barcodeAreaHeight = 196.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final status = coupon.statusAt(now);
    final active = status == CouponStatus.available;
    final tone = couponColors(colors, coupon, active: active);
    final (value, caption) = couponBadge(coupon);
    final bottomHeight = active ? _barcodeAreaHeight : _codeHeight;

    return Card(
      color: tone.background,
      clipBehavior: Clip.antiAlias,
      shape: TicketShapeBorder(
        splitAxis: Axis.horizontal,
        splitOffset: bottomHeight,
        fromEnd: true,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            child: Column(
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: textTheme.displaySmall?.copyWith(
                          color: tone.foreground,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: ' $caption',
                        style: textTheme.titleMedium?.copyWith(
                          color: tone.foreground.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  coupon.title,
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(color: tone.foreground),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  coupon.description.keepAll,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: tone.foreground.withValues(alpha: 0.85),
                  ),
                ),
                if (!active) ...[
                  const SizedBox(height: AppSpacing.md),
                  Chip(
                    label: Text(
                      status == CouponStatus.used ? '사용 완료' : '기간 만료',
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: DashedLine(
              axis: Axis.horizontal,
              color: tone.foreground.withValues(alpha: 0.35),
            ),
          ),
          SizedBox(
            height: bottomHeight,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (active) ...[
                      // 매장 스캐너가 읽을 수 있도록 흰 바탕에 진한 색으로 그린다.
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: BarcodeWidget(
                          barcode: Barcode.code128(),
                          data: coupon.displayCode.replaceAll(' ', ''),
                          drawText: false,
                          color: colors.onSurface,
                          width: 240,
                          height: 64,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Text(
                      '쿠폰 번호',
                      style: textTheme.labelMedium?.copyWith(
                        color: tone.foreground.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      coupon.displayCode,
                      style: textTheme.headlineSmall?.copyWith(
                        color: tone.foreground,
                        letterSpacing: 2,
                        decoration: active ? null : TextDecoration.lineThrough,
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
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.coupon, required this.now});

  final Coupon coupon;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final status = coupon.statusAt(now);
    final rows = [
      (
        '유효기간',
        status == CouponStatus.available
            ? '${AppDateFormat.date(coupon.expiresAt)}까지 '
                  '(${AppDateFormat.dDay(coupon.expiresAt, now: now)})'
            : '${AppDateFormat.date(coupon.expiresAt)}까지',
      ),
      ('발급일', AppDateFormat.date(coupon.issuedAt)),
      if (coupon.usedAt != null)
        ('사용일', AppDateFormat.dateTime(coupon.usedAt!, now: now)),
    ];

    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(
                    rows[i].$1,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.end,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});

  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final noteStyle = textTheme.bodyMedium?.copyWith(
      color: colors.onSurfaceVariant,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('이용 안내', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            for (final note in notes)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('·  ', style: noteStyle),
                    Expanded(child: Text(note.keepAll, style: noteStyle)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CouponNotFound extends StatelessWidget {
  const _CouponNotFound();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: colors.outline),
            const SizedBox(height: AppSpacing.md),
            Text('쿠폰을 찾을 수 없어요', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '삭제되었거나 잘못된 주소예요. 쿠폰함에서 다시 확인해 주세요.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
