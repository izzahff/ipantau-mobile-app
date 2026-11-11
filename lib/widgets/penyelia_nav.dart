import 'package:flutter/material.dart';

import '../screens/penyelia/penyelia_dashboard.dart';
import '../screens/penyelia/semak_laporan_screen.dart';
import '../screens/shared/tapak_screen.dart';
import '../screens/shared/tetapan_screen.dart';
import 'v2/ui.dart';

/// Supervisor shell: Utama · Tapak · Semak · Tetapan.
class PenyeliaNav extends StatefulWidget {
  final int initialIndex;
  const PenyeliaNav({super.key, this.initialIndex = 0});

  @override
  State<PenyeliaNav> createState() => _PenyeliaNavState();
}

class _PenyeliaNavState extends State<PenyeliaNav> {
  late int _index;

  static const _items = [
    IpNavItem('home', 'Utama'),
    IpNavItem('building', 'Tapak'),
    IpNavItem('clipboardCheck', 'Semak'),
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
      PenyeliaDashboard(key: const ValueKey('utama'), onOpenTab: _go),
      const TapakScreen(key: ValueKey('tapak')),
      const SemakLaporanScreen(key: ValueKey('semak')),
      const TetapanScreen(key: ValueKey('tetapan')),
    ];
    return Scaffold(
      backgroundColor: context.ip.bg,
      body: pages[_index],
      bottomNavigationBar: IpBottomNav(items: _items, index: _index, onTap: _go),
    );
  }
}
