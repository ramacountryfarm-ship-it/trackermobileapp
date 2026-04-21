import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'batches/batch_list_screen.dart';
import 'daily_log/daily_log_list_screen.dart';
import 'eggs/egg_management_screen.dart';
import 'more_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _idx = 0;

  final _screens = const [
    DashboardScreen(),
    BatchListScreen(),
    DailyLogListScreen(),
    EggManagementScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceBg,
      body: Stack(
        children: [
          // Screens
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _screens[_idx],
          ),
          // Glass bottom nav
          Positioned(
            left: 16, right: 16, bottom: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.white.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 0.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 30, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _tab(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                      _tab(1, Icons.groups_outlined, Icons.groups_rounded, 'Batches'),
                      _tab(2, Icons.edit_calendar_outlined, Icons.edit_calendar_rounded, 'Log'),
                      _tab(3, Icons.egg_outlined, Icons.egg_rounded, 'Eggs'),
                      _tab(4, Icons.grid_view_outlined, Icons.grid_view_rounded, 'More'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(int i, IconData icon, IconData activeIcon, String label) {
    final sel = _idx == i;
    return GestureDetector(
      onTap: () => setState(() => _idx = i),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: sel ? 14 : 10, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? AppTheme.black : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(sel ? activeIcon : icon, size: 20,
                color: sel ? AppTheme.white : AppTheme.gray),
            if (sel) ...[
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.white)),
            ],
          ],
        ),
      ),
    );
  }
}
