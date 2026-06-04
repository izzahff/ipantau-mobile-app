import 'package:flutter/material.dart';

import '../screens/kontraktor/kontraktor_dashboard.dart';
import '../screens/shared/lagi_screen.dart';
import '../screens/shared/tapak_screen.dart';
import '../theme/app_theme.dart';
import '../utils/logout_dialog.dart';

class KontraktorNav extends StatefulWidget {
  final int initialIndex;
  const KontraktorNav({super.key, this.initialIndex = 0});

  @override
  State<KontraktorNav> createState() => _KontraktorNavState();
}

class _KontraktorNavState extends State<KontraktorNav> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 2);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const KontraktorDashboard(),
      const TapakScreen(appBarColor: AppTheme.navy),
      const LagiScreen(appBarColor: AppTheme.navy),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _navItem(Icons.home_outlined, 'Utama', 0),
              _navItem(Icons.domain_outlined, 'Tapak', 1),
              _navItem(Icons.more_horiz, 'Lagi', 2),
              _navItem(Icons.logout, 'Log keluar', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isLogout = index == 3;
    final selected = !isLogout && _index == index;
    final color = selected ? AppTheme.navy : AppTheme.textMuted;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isLogout) {
            confirmAndLogout(context);
            return;
          }
          setState(() => _index = index);
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: selected ? AppTheme.navy : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
