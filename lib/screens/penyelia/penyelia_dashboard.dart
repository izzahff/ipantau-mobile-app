import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/ip_format.dart';
import '../../widgets/v2/dash_widgets.dart';
import '../../widgets/v2/ui.dart';
import '../shared/checkin_screen.dart';
import 'pantau_pekerja_screen.dart';
import 'semak_laporan_screen.dart';

class PenyeliaDashboard extends StatefulWidget {
  const PenyeliaDashboard({super.key, this.onOpenTab});

  /// Switch bottom-nav tab (e.g. 2 = Semak).
  final ValueChanged<int>? onOpenTab;

  @override
  State<PenyeliaDashboard> createState() => _PenyeliaDashboardState();
}

class _PenyeliaDashboardState extends State<PenyeliaDashboard> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _checkinHariIni;
  int _tapakCount = 0;
  int _hadir = 0;
  List<Map<String, dynamic>> _laporanTapak = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() {
        _loading = false;
        _error = 'Sesi tamat. Sila log masuk semula.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final results = await Future.wait([
      ApiService.getTapakSaya(token),
      ApiService.getCheckinHariIni(token),
      ApiService.getLaporanTapak(token),
      ApiService.getPekerjaKehadiranHariIni(token),
    ]);
    if (!mounted) return;
    final [resTapak, resCheckin, resLaporan, resPekerja] = results;

    if (resTapak['success'] != true || resCheckin['success'] != true) {
      setState(() {
        _loading = false;
        _error = (resTapak['success'] != true ? resTapak['message'] : null) ??
            (resCheckin['success'] != true ? resCheckin['message'] : null) ??
            'Gagal muatkan dashboard.';
      });
      return;
    }

    final checkinData = resCheckin['data'];
    final pekerja = resPekerja['success'] == true && resPekerja['data'] is List ? resPekerja['data'] as List : const [];
    setState(() {
      _tapakCount = ((resTapak['data'] as List?) ?? const []).length;
      _checkinHariIni = checkinData == null ? null : Map<String, dynamic>.from(checkinData as Map);
      _laporanTapak = resLaporan['success'] == true
          ? ((resLaporan['data'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : [];
      _hadir = pekerja.where((p) => p is Map && p['hadir'] == true).length;
      _loading = false;
    });
  }

  Future<void> _push(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _load();
  }

  void _openSemak() {
    if (widget.onOpenTab != null) {
      widget.onOpenTab!(2);
    } else {
      _push(const SemakLaporanScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final user = context.watch<AuthProvider>().pengguna;
    final ci = CheckinState.from(_checkinHariIni);
    final pending = _laporanTapak.where((l) => ReportStatus.isPending(l['status']?.toString())).length;
    final terkini = _laporanTapak.take(4).toList();

    return Column(children: [
      DashHeader(
        nama: user?['nama']?.toString() ?? 'Penyelia',
        syarikat: user?['nama_syarikat']?.toString() ?? '',
        checkin: ci,
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _load,
          color: c.azure500,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_error != null) ...[IpErrorBox(_error!, onRetry: _load), const SizedBox(height: 16)],
              if (_loading) ...[
                LinearProgressIndicator(minHeight: 3, color: c.azure500, backgroundColor: c.surface3),
                const SizedBox(height: 14),
              ],
              Row(children: [
                Expanded(child: IpStatCard(value: '$_tapakCount', label: 'Tapak Dipantau', icon: 'building')),
                const SizedBox(width: 10),
                Expanded(child: IpStatCard(value: '$_hadir', label: 'Pekerja Hadir', icon: 'users')),
                const SizedBox(width: 10),
                Expanded(child: IpStatCard(value: '$pending', label: 'Laporan Pending', icon: 'clipboardCheck')),
              ]),
              const SizedBox(height: 22),
              const IpSectionLabel('Tugasan Hari Ini', icon: 'route'),
              IpCard(
                pad: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  child: Column(children: [
                    TaskRow(
                      icon: 'clipboardCheck',
                      title: 'Semak laporan',
                      count: pending,
                      urgent: pending > 0,
                      sub: pending > 0 ? '$pending laporan menunggu keputusan' : 'Semua laporan telah disemak',
                      onTap: _openSemak,
                    ),
                    TaskRow(
                      icon: 'users',
                      title: 'Pantau pekerja',
                      count: _hadir,
                      sub: '$_hadir pekerja hadir di tapak',
                      onTap: () => _push(const PantauPekerjaScreen()),
                    ),
                    TaskRow(
                      icon: 'pin',
                      title: ci.checkedIn && !ci.checkedOut ? 'Check-out' : 'Check-in kehadiran',
                      sub: ci.checkedOut
                          ? 'Sesi tamat · ${IpFormat.time(ci.keluar)}'
                          : ci.checkedIn
                              ? 'Hadir sejak ${IpFormat.time(ci.masuk)}'
                              : 'Rekod kehadiran anda',
                      last: true,
                      onTap: () => _push(const CheckinScreen()),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 24),
              IpSectionLabel('Aktiviti Terkini', icon: 'clock', action: IpLinkButton('Lihat semua', onTap: _openSemak)),
              if (terkini.isEmpty)
                const DashEmpty(title: 'Tiada aktiviti hari ini.', sub: 'Laporan baru dari pekerja akan muncul di sini.')
              else
                IpCard(
                  pad: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    child: Column(children: [
                      for (final (i, l) in terkini.indexed)
                        ActivityRow(
                          title: l['pekerja_nama']?.toString() ?? 'Pekerja',
                          sub: '${l['tapak_nama'] ?? l['nama_tapak'] ?? '-'} · ${IpFormat.dateTime(laporanTarikh(l))}',
                          status: l['status']?.toString(),
                          last: i == terkini.length - 1,
                          onTap: _openSemak,
                        ),
                    ]),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ]);
  }
}
