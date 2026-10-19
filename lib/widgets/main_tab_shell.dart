import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 하단 탭 바를 포함한 메인 화면 틀.
class MainTabShell extends StatelessWidget {
  const MainTabShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: '홈',
    ),
    NavigationDestination(
      icon: Icon(Icons.approval_outlined),
      selectedIcon: Icon(Icons.approval_rounded),
      label: '적립',
    ),
    NavigationDestination(
      icon: Icon(Icons.confirmation_number_outlined),
      selectedIcon: Icon(Icons.confirmation_number_rounded),
      label: '쿠폰함',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: '내 정보',
    ),
  ];

  void _onTap(int index) {
    // 이미 선택된 탭을 다시 누르면 해당 탭의 첫 화면으로 돌아간다.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: _destinations,
      ),
    );
  }
}
