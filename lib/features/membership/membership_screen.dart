import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/repositories/repository_providers.dart';
import '../../data/state/auth_notifier.dart';
import '../../data/state/stamp_notifier.dart';

/// 매장에서 보여 주는 멤버십 QR.
///
/// [allowDemoScan]이면 "직원 스캔 체험하기" 버튼을 보여 주고, 누르면 true를 돌려주며 닫힌다.
/// 실제 서비스에서는 매장 쪽 기기가 QR을 스캔해 서버에 적립을 요청하는 자리다.
class MembershipScreen extends ConsumerWidget {
  const MembershipScreen({super.key, this.allowDemoScan = false});

  final bool allowDemoScan;

  /// "1234 5678"
  static String formatMemberId(String id) =>
      id.length == 8 ? '${id.substring(0, 4)} ${id.substring(4)}' : id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberId = ref.watch(memberIdProvider);
    final card = ref.watch(stampProvider).card;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: colors.tertiary,
        appBar: AppBar(
          backgroundColor: colors.tertiary,
          foregroundColor: colors.onTertiary,
          titleTextStyle: textTheme.titleLarge?.copyWith(
            color: colors.onTertiary,
          ),
          title: const Text('멤버십'),
          titleSpacing: 0,
          leading: IconButton(
            tooltip: '닫기',
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: AppSpacing.page.copyWith(top: AppSpacing.md),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      Text(
                        'MOA MEMBERSHIP',
                        style: textTheme.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '${ref.watch(displayNameProvider)}님',
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Semantics(
                        label: '멤버십 QR 코드',
                        child: QrImageView(
                          data: 'moastamp://member/$memberId',
                          size: 220,
                          padding: EdgeInsets.zero,
                          eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: colors.tertiary,
                          ),
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: colors.tertiary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        '회원 번호 ${formatMemberId(memberId)}',
                        style: textTheme.titleMedium?.copyWith(
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '매장 직원에게 이 화면을 보여 주세요.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: colors.onTertiary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_cafe_rounded, color: colors.secondary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '지금 스탬프',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colors.onTertiary,
                        ),
                      ),
                    ),
                    Text(
                      '${card.count} / ${card.goal}',
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (allowDemoScan) ...[
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.tertiaryContainer,
                    foregroundColor: colors.onTertiaryContainer,
                  ),
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('직원 스캔 체험하기'),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '샘플 앱이라 매장 스캔 대신 이 버튼으로 적립을 체험할 수 있어요.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onTertiary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
