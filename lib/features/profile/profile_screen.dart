import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_info.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/repositories/repository_providers.dart';
import '../../data/state/auth_notifier.dart';
import '../../data/state/profile_stats.dart';
import '../../widgets/titled_page.dart';
import '../membership/membership_screen.dart';
import 'widgets/profile_header.dart';
import 'widgets/stats_row.dart';

/// 내 정보 탭: 회원 등급, 이용 통계, 데이터 관리, 앱 정보.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _busy = false;

  /// 확인 다이얼로그를 띄우고, 확인하면 [action]을 실행한 뒤 [doneMessage]를 알린다.
  Future<void> _confirmAndRun({
    required String title,
    required String message,
    required String confirmLabel,
    required bool destructive,
    required Future<void> Function() action,
    required String doneMessage,
  }) async {
    final colors = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: destructive
                ? TextButton.styleFrom(foregroundColor: colors.error)
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // 로그아웃·탈퇴하면 이 화면이 사라지므로 알림 창구를 미리 잡아 둔다.
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(doneMessage)));
  }

  void _restoreSample() => _confirmAndRun(
    title: '샘플 데이터로 되돌릴까요?',
    message: '지금까지의 스탬프와 쿠폰 기록이 처음 설치했을 때의 예시 기록으로 바뀌어요.',
    confirmLabel: '되돌리기',
    destructive: false,
    action: () => ref.read(appDataControllerProvider).restoreSample(),
    doneMessage: '샘플 데이터로 되돌렸어요.',
  );

  void _clearAll() => _confirmAndRun(
    title: '모든 기록을 지울까요?',
    message: '스탬프와 쿠폰이 모두 사라지고 빈 상태로 시작해요. 지운 기록은 되돌릴 수 없어요.',
    confirmLabel: '모두 지우기',
    destructive: true,
    action: () => ref.read(appDataControllerProvider).clearAll(),
    doneMessage: '모든 기록을 지웠어요.',
  );

  void _signOut() => _confirmAndRun(
    title: '로그아웃할까요?',
    message: '모은 스탬프와 쿠폰은 그대로 남아 있어요. 다시 로그인하면 이어서 쓸 수 있어요.',
    confirmLabel: '로그아웃',
    destructive: false,
    action: () => ref.read(authProvider.notifier).signOut(),
    doneMessage: '로그아웃했어요.',
  );

  void _deleteAccount() => _confirmAndRun(
    title: '정말 탈퇴할까요?',
    message: '계정과 함께 모은 스탬프, 받은 쿠폰이 모두 지워지고 되돌릴 수 없어요.',
    confirmLabel: '탈퇴하기',
    destructive: true,
    action: () => ref.read(authProvider.notifier).deleteAccount(),
    doneMessage: '탈퇴가 끝났어요. 그동안 이용해 주셔서 고마워요.',
  );

  Future<void> _replayOnboarding() async {
    await ref.read(sharedPreferencesProvider).remove(onboardingDoneKey);
    if (mounted) context.go(AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(profileStatsProvider);
    final now = ref.watch(clockProvider)();
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TitledPage(
      title: '내 정보',
      body: ListView(
        padding: AppSpacing.page,
        children: [
          ProfileHeader(
            name: ref.watch(displayNameProvider),
            stats: stats,
            now: now,
          ),
          const SizedBox(height: AppSpacing.md),
          StatsRow(stats: stats),
          const SizedBox(height: AppSpacing.xxl),
          _MenuCard(
            children: [
              ListTile(
                leading: const Icon(Icons.qr_code_2_rounded),
                title: const Text('멤버십 QR 보기'),
                subtitle: Text(
                  '회원 번호 ${MembershipScreen.formatMemberId(ref.watch(memberIdProvider))}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.membership),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const _SectionTitle('앱 정보'),
          _MenuCard(
            children: [
              const ListTile(
                leading: Icon(Icons.info_outline_rounded),
                title: Text('버전'),
                trailing: Text(AppInfo.version),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('오픈소스 라이선스'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: AppInfo.name,
                  applicationVersion: AppInfo.version,
                  applicationLegalese: AppInfo.legalese,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const _SectionTitle('데이터 관리'),
          _MenuCard(
            children: [
              ListTile(
                enabled: !_busy,
                leading: const Icon(Icons.restore_rounded),
                title: const Text('샘플 데이터로 되돌리기'),
                subtitle: const Text('처음 설치했을 때의 예시 기록으로 바꿔요'),
                onTap: _restoreSample,
              ),
              ListTile(
                enabled: !_busy,
                iconColor: colors.error,
                textColor: colors.error,
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('모든 기록 지우기'),
                subtitle: Text(
                  '스탬프와 쿠폰을 지우고 빈 상태로 시작해요',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                onTap: _clearAll,
              ),
              ListTile(
                enabled: !_busy,
                leading: const Icon(Icons.slideshow_rounded),
                title: const Text('소개 화면 다시 보기'),
                subtitle: const Text('처음 실행할 때 나오는 안내를 다시 열어요'),
                onTap: _replayOnboarding,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const _SectionTitle('계정'),
          _MenuCard(
            children: [
              ListTile(
                leading: const Icon(Icons.mail_outline_rounded),
                title: const Text('로그인 계정'),
                subtitle: Text(ref.watch(authProvider)?.email ?? ''),
              ),
              ListTile(
                enabled: !_busy,
                leading: const Icon(Icons.logout_rounded),
                title: const Text('로그아웃'),
                onTap: _signOut,
              ),
              ListTile(
                enabled: !_busy,
                iconColor: colors.error,
                textColor: colors.error,
                leading: const Icon(Icons.person_remove_outlined),
                title: const Text('회원 탈퇴'),
                onTap: _deleteAccount,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            '모아 스탬프는 포트폴리오용으로 만든 샘플 앱이에요.\n'
            '실제 매장이나 결제와는 연결되어 있지 않아요.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: colors.outline),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xxs,
        bottom: AppSpacing.xs,
      ),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}
