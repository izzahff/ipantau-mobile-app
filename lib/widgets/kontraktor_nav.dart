import 'package:flutter/material.dart';

import '../screens/kontraktor/kontraktor_dashboard.dart';
import '../screens/shared/laporan_saya_screen.dart';
import '../screens/shared/tapak_screen.dart';
import '../screens/shared/tetapan_screen.dart';
import 'v2/ui.dart';

/// Contractor shell: Utama · Tapak · Laporan · Tetapan.
class KontraktorNav extends StatefulWidget {
  final int initialIndex;
  const KontraktorNav({super.key, this.initialIndex = 0});

  @override
  State<KontraktorNav> createState() => _KontraktorNavState();
}

class _KontraktorNavState extends State<KontraktorNav> {
  late int _index;

  static const _items = [
    IpNavItem('home', 'Utama'),
    IpNavItem('building', 'Tapak'),
    IpNavItem('file', 'Laporan'),
    IpNavItem('settings', 'Tetapan'),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, _items.length - 1);
  }

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      KontraktorDashboard(key: const ValueKey('utama'), onOpenTab: _go),
      const TapakScreen(key: ValueKey('tapak')),
      const LaporanSayaScreen(key: ValueKey('laporan')),
      const TetapanScreen(key: ValueKey('tetapan')),
    ];
    return Scaffold(
      backgroundColor: context.ip.bg,
      body: pages[_index],
      bottomNavigationBar: IpBottomNav(items: _items, index: _index, onTap: _go),
    );
  }
}
