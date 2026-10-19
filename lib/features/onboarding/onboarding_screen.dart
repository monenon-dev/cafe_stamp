import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/repositories/repository_providers.dart';
import '../../widgets/ticket.dart';
import '../stamp/widgets/stamp_slot.dart';

/// 첫 실행 때 한 번만 보여 주는 소개 화면 3장.
///
/// 스플래시와 같은 에스프레소 바탕이라 앱이 열리는 흐름이 끊기지 않는다.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    (
      title: '한 잔마다 도장 하나',
      body: '음료를 주문할 때마다\n스탬프가 하나씩 쌓여요.',
      art: _StampArt(),
    ),
    (
      title: '10개 모으면 한 잔 무료',
      body: '스탬프 10개를 채우면\n무료 음료 쿠폰을 바로 드려요.',
      art: _CouponArt(),
    ),
    (
      title: 'QR 하나로 적립 끝',
      body: '매장에서 멤버십 QR만 보여 주면\n적립도 쿠폰 사용도 간편해요.',
      art: _QrArt(),
    ),
  ];

  bool get _isLast => _page == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(sharedPreferencesProvider).setBool(onboardingDoneKey, true);
    if (mounted) context.go(AppRoutes.home);
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: colors.tertiary,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: AnimatedOpacity(
                    opacity: _isLast ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: TextButton(
                      onPressed: _isLast ? null : _finish,
                      style: TextButton.styleFrom(
                        foregroundColor: colors.secondary,
                      ),
                      child: const Text('건너뛰기'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    final page = _pages[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(child: Center(child: page.art)),
                          Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium?.copyWith(
                              color: colors.onTertiary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            page.body,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge?.copyWith(
                              color: colors.onTertiary.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                        ],
                      ),
                    );
                  },
                ),
              ),
              _PageDots(count: _pages.length, current: _page),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.md,
                ),
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.tertiaryContainer,
                    foregroundColor: colors.onTertiaryContainer,
                  ),
                  child: Text(_isLast ? '시작하기' : '다음'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            width: i == current ? AppSpacing.xl : AppSpacing.xs,
            height: AppSpacing.xs,
            decoration: BoxDecoration(
              color: i == current
                  ? colors.secondary
                  : colors.onTertiary.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
      ],
    );
  }
}

/// 1장: 작은 스탬프 카드
class _StampArt extends StatelessWidget {
  const _StampArt();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SizedBox(
          width: 260,
          child: Row(
            children: [
              for (var i = 1; i <= 4; i++) ...[
                if (i > 1) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: StampSlot(index: i, filled: i <= 3),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 2장: 무료 음료 티켓 쿠폰
class _CouponArt extends StatelessWidget {
  const _CouponArt();

  static const _stubWidth = 96.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: 280,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: const TicketShapeBorder(
          splitAxis: Axis.vertical,
          splitOffset: _stubWidth,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: colors.primary,
                child: SizedBox(
                  width: _stubWidth,
                  child: Center(
                    child: Text(
                      'FREE',
                      style: textTheme.titleLarge?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              DashedLine(axis: Axis.vertical, color: colors.outlineVariant),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('무료 음료 쿠폰', style: textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '원하는 음료 1잔',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 3장: 멤버십 QR
class _QrArt extends StatelessWidget {
  const _QrArt();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: QrImageView(
          data: 'moastamp://member/preview',
          size: 168,
          padding: EdgeInsets.zero,
          eyeStyle: QrEyeStyle(
            eyeShape: QrEyeShape.circle,
            color: colors.tertiary,
          ),
          dataModuleStyle: QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.circle,
            color: colors.tertiary,
          ),
        ),
      ),
    );
  }
}
