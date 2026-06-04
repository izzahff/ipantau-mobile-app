import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/ipantau_app_bar.dart';
import 'laporan_saya_screen.dart';
import 'profil_screen.dart';
import 'tetapan_screen.dart';

class LagiScreen extends StatelessWidget {
  const LagiScreen({super.key, required this.appBarColor});

  final Color appBarColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: IpantauAppBar(title: 'Lagi', backgroundColor: appBarColor),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(
            context,
            icon: Icons.description_outlined,
            label: 'Laporan',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LaporanSayaScreen(appBarColor: appBarColor)),
              );
            },
          ),
          _tile(
            context,
            icon: Icons.person_outline,
            label: 'Profil',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfilScreen(appBarColor: appBarColor)),
              );
            },
          ),
          _tile(
            context,
            icon: Icons.settings_outlined,
            label: 'Tetapan',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TetapanScreen(appBarColor: appBarColor)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFD0DFF0)),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.navy),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
