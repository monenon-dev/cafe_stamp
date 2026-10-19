import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format/keep_all.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/validation/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/state/auth_notifier.dart';
import '../../widgets/titled_page.dart';
import 'terms.dart';
import 'widgets/password_field.dart';

/// 회원가입. 가입하면 바로 로그인되고 라우터가 홈으로 보낸다.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  final _agreed = <Terms>{};
  bool _submitted = false;
  bool _busy = false;
  String? _error;

  bool get _allAgreed => _agreed.length == Terms.values.length;
  bool get _requiredAgreed =>
      Terms.values.where((t) => t.required).every(_agreed.contains);

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _toggleAll(bool? value) => setState(() {
    value == true ? _agreed.addAll(Terms.values) : _agreed.clear();
  });

  void _toggle(Terms terms, bool? value) => setState(() {
    value == true ? _agreed.add(terms) : _agreed.remove(terms);
  });

  Future<void> _showTerms(Terms terms) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(terms.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Text(
              terms.body.keepAll,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _error = null;
    });
    final formOk = _formKey.currentState!.validate();
    if (!formOk || !_requiredAgreed) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(authProvider.notifier)
          .signUp(
            name: _name.text,
            email: _email.text,
            password: _password.text,
            marketingAgreed: _agreed.contains(Terms.marketing),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('가입을 환영해요! 쿠폰함에 가입 축하 쿠폰을 넣어 드렸어요.')),
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TitledPage(
      title: '회원가입',
      body: Form(
        key: _formKey,
        autovalidateMode: _submitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: AutofillGroup(
          child: ListView(
            padding: AppSpacing.page,
            children: [
              Text(
                '가입하면 바로 스탬프를 모을 수 있어요.',
                style: textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: Validators.name,
                decoration: const InputDecoration(
                  labelText: '이름',
                  helperText: '2~10자, 매장과 멤버십 화면에 보여요.',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                validator: Validators.email,
                // "이미 가입된 이메일" 안내는 이메일을 고치면 지운다.
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: InputDecoration(
                  labelText: '이메일',
                  errorText: _error,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PasswordField(
                controller: _password,
                label: '비밀번호',
                helperText: '영문과 숫자를 넣어 8자 이상',
                autofillHints: const [AutofillHints.newPassword],
                validator: Validators.newPassword,
              ),
              const SizedBox(height: AppSpacing.md),
              PasswordField(
                controller: _confirm,
                label: '비밀번호 확인',
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                validator: (v) => Validators.confirmPassword(v, _password.text),
              ),
              const SizedBox(height: AppSpacing.xl),
              _TermsCard(
                agreed: _agreed,
                allAgreed: _allAgreed,
                onToggleAll: _toggleAll,
                onToggle: _toggle,
                onView: _showTerms,
              ),
              if (_submitted && !_requiredAgreed) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '필수 약관에 동의해 주세요.',
                  style: textTheme.bodySmall?.copyWith(color: colors.error),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomBar: FilledButton(
        onPressed: _busy ? null : _submit,
        child: Text(_busy ? '가입하는 중이에요' : '가입하기'),
      ),
    );
  }
}

class _TermsCard extends StatelessWidget {
  const _TermsCard({
    required this.agreed,
    required this.allAgreed,
    required this.onToggleAll,
    required this.onToggle,
    required this.onView,
  });

  final Set<Terms> agreed;
  final bool allAgreed;
  final ValueChanged<bool?> onToggleAll;
  final void Function(Terms, bool?) onToggle;
  final void Function(Terms) onView;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          children: [
            CheckboxListTile(
              value: allAgreed,
              onChanged: onToggleAll,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text('약관에 모두 동의해요', style: textTheme.titleMedium),
            ),
            const Divider(
              height: 1,
              indent: AppSpacing.md,
              endIndent: AppSpacing.md,
            ),
            for (final terms in Terms.values)
              CheckboxListTile(
                value: agreed.contains(terms),
                onChanged: (v) => onToggle(terms, v),
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(terms.label, style: textTheme.bodyMedium),
                secondary: TextButton(
                  onPressed: () => onView(terms),
                  child: const Text('보기'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
