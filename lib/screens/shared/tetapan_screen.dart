import 'package:flutter/material.dart';

import '../../widgets/ipantau_app_bar.dart';

/// Placeholder tetapan (mockup: settings menu).
class TetapanScreen extends StatelessWidget {
  const TetapanScreen({super.key, required this.appBarColor});

  final Color appBarColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: IpantauAppBar(title: 'Tetapan', backgroundColor: appBarColor),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: const Text('Notifikasi tolak'),
            subtitle: const Text('Demo — akan disambungkan ke pelayan.'),
          ),
          SwitchListTile(
            value: false,
            onChanged: (_) {},
            title: const Text('Mod gelap'),
            subtitle: const Text('Demo — akan datang.'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Versi aplikasi'),
            subtitle: Text('iPANTAU (demo)'),
          ),
        ],
      ),
    );
  }
}
