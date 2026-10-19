import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

/// 상단 제목과 본문 영역으로 이루어진 기본 페이지.
///
/// [body]를 넘기지 않으면 빈 화면으로 표시된다.
class TitledPage extends StatelessWidget {
  const TitledPage({
    super.key,
    required this.title,
    this.body,
    this.bottom,
    this.bottomBar,
    this.actions,
  });

  final String title;
  final Widget? body;

  /// 앱 바 아래 영역 (예: TabBar)
  final PreferredSizeWidget? bottom;

  /// 화면 하단에 고정되는 영역 (예: 주요 동작 버튼)
  final Widget? bottomBar;

  /// 앱 바 오른쪽 버튼
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: bottom,
        actions: actions,
        // 뒤로 가기 버튼이 있으면 제목을 버튼 옆에 붙인다.
        titleSpacing: Navigator.of(context).canPop() ? 0 : null,
      ),
      body: body ?? const SizedBox.expand(),
      bottomNavigationBar: bottomBar == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: bottomBar,
              ),
            ),
    );
  }
}
