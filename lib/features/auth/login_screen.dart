import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/validation/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/state/auth_notifier.dart';
import 'widgets/password_field.dart';

/// 로그인. 로그인하면 라우터가 홈으로 보낸다.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function(AuthNotifier auth) action) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(ref.read(authProvider.notifier));
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _signIn() {
    if (!_formKey.currentState!.validate()) return;
    _run((auth) => auth.signIn(email: _email.text, password: _password.text));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 앱 바가 없는 밝은 화면이라 상태 표시줄 아이콘을 어둡게 지정한다.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xxl,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Image.asset(
                    'assets/branding/icon.png',
                    width: 64,
                    height: 64,
                    semanticLabel: '모아 스탬프 로고',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('모아 스탬프와 함께해요', style: textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '로그인하고 모아 둔 스탬프와 쿠폰을 확인해 보세요.',
                style: textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        validator: Validators.email,
                        decoration: const InputDecoration(labelText: '이메일'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      PasswordField(
                        controller: _password,
                        label: '비밀번호',
                        validator: Validators.requiredPassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _signIn(),
                      ),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: colors.error),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _error!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _busy ? null : _signIn,
                child: _busy
                    ? SizedBox.square(
                        dimension: AppSpacing.lg,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.onSurfaceVariant,
                        ),
                      )
                    : const Text('로그인'),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '아직 회원이 아니신가요?',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => context.push(AppRoutes.signup),
                    child: const Text('회원가입'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Text(
                      '또는',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _run((auth) => auth.signInDemo()),
                child: const Text('데모 계정으로 둘러보기'),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '샘플 앱이라 계정 정보는 서버로 보내지 않고 이 기기에만 저장해요.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: colors.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
