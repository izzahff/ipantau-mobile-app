import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/logout_dialog.dart';
import '../../widgets/v2/ui.dart';
import 'profil_screen.dart';
import 'tukar_kata_laluan_screen.dart';

String labelPeranan(String? p) => switch (p) {
      'penyelia' => 'Penyelia',
      'kontraktor' => 'Kontraktor',
      _ => p ?? '-',
    };

/// Tab "Tetapan". The profile card is the only entry point to Profil.
class TetapanScreen extends StatelessWidget {
  const TetapanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final user = context.watch<AuthProvider>().pengguna ?? const {};
    final peranan = context.watch<AuthProvider>().peranan;
    final theme = context.watch<ThemeProvider>();
    final nama = user['nama']?.toString() ?? '-';
    final syarikat = user['nama_syarikat']?.toString() ?? '-';

    return Column(children: [
      const IpAppHeader(title: 'Tetapan', right: IpHeaderBell()),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            IpCard(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilScreen())),
              child: Row(children: [
                IpAvatar(name: nama, size: 54),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.text, letterSpacing: -.17)),
                    Text(labelPeranan(peranan), style: TextStyle(fontSize: 13, color: c.text2)),
                    const SizedBox(height: 2),
                    Text(syarikat, maxLines: 1, overflow: TextOverflow.ellipsis, style: ipMono(context, size: 12, color: c.text3)),
                  ]),
                ),
                IpIcon('chevronRight', size: 20, color: c.text3),
              ]),
            ),
            const SizedBox(height: 22),
            const IpSectionLabel('Keutamaan', icon: 'settings'),
            _group(context, [
              IpSettingRow(
                icon: theme.isDark ? 'moon' : 'sun',
                title: 'Mod gelap',
                sub: theme.isDark ? 'Dihidupkan' : 'Dimatikan',
                right: IpToggle(value: theme.isDark, onChanged: theme.setDark),
              ),
              IpSettingRow(
                icon: 'bell',
                title: 'Notifikasi',
                sub: 'Kemas kini status & laporan',
                last: true,
                right: IpToggle(value: theme.notifikasi, onChanged: theme.setNotifikasi),
              ),
            ]),
            const SizedBox(height: 18),
            const IpSectionLabel('Akaun', icon: 'user'),
            _group(context, [
              IpSettingRow(
                icon: 'lock',
                title: 'Tukar kata laluan',
                sub: 'Kemas kini keselamatan akaun',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TukarKataLaluanScreen())),
              ),
              IpSettingRow(
                icon: 'info',
                title: 'Bantuan & sokongan',
                last: true,
                onTap: () => showIpToast(context, 'Hubungi penyelia atau pentadbir sistem untuk bantuan.', tone: IpToastTone.info),
              ),
            ]),
            const SizedBox(height: 18),
            const IpSectionLabel('Mengenai', icon: 'shield'),
            _group(context, [
              IpSettingRow(
                icon: 'info',
                title: 'Versi aplikasi',
                last: true,
                right: Text('iPANTAU v2.0.0', style: ipMono(context, size: 12.5, color: c.text3)),
              ),
            ]),
            const SizedBox(height: 18),
            IpButton('Log keluar',
                full: true, variant: IpButtonVariant.danger, icon: 'logout', onPressed: () => confirmAndLogout(context)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ]);
  }

  Widget _group(BuildContext context, List<Widget> rows) => IpCard(
        pad: 0,
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2), child: Column(children: rows)),
      );
}

class IpSettingRow extends StatelessWidget {
  const IpSettingRow({
    super.key,
    required this.icon,
    required this.title,
    this.sub,
    this.right,
    this.onTap,
    this.last = false,
    this.danger = false,
  });

  final String icon;
  final String title;
  final String? sub;
  final Widget? right;
  final VoidCallback? onTap;
  final bool last;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final row = Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: c.line))),
      child: Row(children: [
        SizedBox(width: 40, height: 40, child: Center(child: IpIcon(icon, size: 20, color: danger ? c.crimson600 : c.icon))),
        const SizedBox(width: 13),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: danger ? c.crimson600 : c.text)),
            if (sub != null) ...[
              const SizedBox(height: 1),
              Text(sub!, style: TextStyle(fontSize: 12.5, color: c.text3)),
            ],
          ]),
        ),
        right ?? (onTap != null ? IpIcon('chevronRight', size: 19, color: c.text3) : const SizedBox.shrink()),
      ]),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}
