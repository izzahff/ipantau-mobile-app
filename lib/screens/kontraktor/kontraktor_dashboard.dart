import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/ip_format.dart';
import '../../widgets/v2/dash_widgets.dart';
import '../../widgets/v2/ui.dart';
import '../shared/checkin_screen.dart';
import '../shared/gambar_screen.dart';
import '../shared/laporan_butiran_screen.dart';

class KontraktorDashboard extends StatefulWidget {
  const KontraktorDashboard({super.key, this.onOpenTab});

  /// Switch bottom-nav tab (e.g. 2 = Laporan).
  final ValueChanged<int>? onOpenTab;

  @override
  State<KontraktorDashboard> createState() => _KontraktorDashboardState();
}

class _KontraktorDashboardState extends State<KontraktorDashboard> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _checkinHariIni;
  List<Map<String, dynamic>> _tapakSaya = [];
  List<Map<String, dynamic>> _laporan = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  static String _statusKey(Map<String, dynamic> t) {
    final s = (t['status'] ?? 'aktif').toString().toLowerCase();
    if (s == 'selesai' || s == 'completed' || s == 'tamat') return 'selesai';
    if (s == 'menunggu' || s == 'pending') return 'menunggu';
    return 'aktif';
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
      ApiService.getLaporanSaya(token),
    ]);
    if (!mounted) return;
    final [resTapak, resCheckin, resLaporan] = results;

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
    setState(() {
      _tapakSaya = ((resTapak['data'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      _checkinHariIni = checkinData == null ? null : Map<String, dynamic>.from(checkinData as Map);
      _laporan = resLaporan['success'] == true
          ? ((resLaporan['data'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : [];
      _loading = false;
    });
  }

  Future<void> _push(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final user = context.watch<AuthProvider>().pengguna;
    final ci = CheckinState.from(_checkinHariIni);
    final aktif = _tapakSaya.where((t) => _statusKey(t) == 'aktif').length;
    final hariIni = _laporan.where((l) => isTodayIso(laporanTarikh(l))).length;
    final terkini = _laporan.take(4).toList();

    final cur = ci.checkedOut ? 3 : (ci.checkedIn ? 1 : 0);
    FlowState stateOf(int i) {
      if (ci.checkedOut || i < cur) return FlowState.done;
      if (i == cur) return FlowState.active;
      if (i == 2 && ci.checkedIn) return FlowState.ready;
      return FlowState.locked;
    }

    final steps = [
      FlowStep('Check-in di tapak',
          ci.checkedIn ? '${ci.tapakNama ?? 'Tapak'} · ${IpFormat.time(ci.masuk)}' : 'Lokasi GPS mesti dalam radius tapak'),
      FlowStep('Ambil gambar & hantar laporan',
          hariIni > 0 ? '$hariIni laporan dihantar hari ini' : 'Gambar bukti bertera GPS & masa'),
      FlowStep('Check-out', ci.checkedOut ? 'Selesai · ${IpFormat.time(ci.keluar)}' : 'Tamatkan sesi kerja hari ini'),
    ];

    final Widget actions = switch (cur) {
      0 => IpButton('Check-in sekarang', full: true, icon: 'pin', onPressed: () => _push(const CheckinScreen())),
      1 => Row(children: [
          Expanded(child: IpButton('Ambil gambar', full: true, icon: 'camera', onPressed: () => _push(const GambarScreen()))),
          const SizedBox(width: 10),
          IpButton('Check-out', variant: IpButtonVariant.outline, onPressed: () => _push(const CheckinScreen())),
        ]),
      _ => const SessionDoneBanner(),
    };

    return Column(children: [
      DashHeader(
        nama: user?['nama']?.toString() ?? 'Kontraktor',
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
                Expanded(child: IpStatCard(value: '$aktif', label: 'Tapak Aktif', icon: 'building', tone: IpTone.azure)),
                const SizedBox(width: 12),
                Expanded(child: IpStatCard(value: '$hariIni', label: 'Laporan Hari Ini', icon: 'file')),
              ]),
              const SizedBox(height: 22),
              const IpSectionLabel('Tugasan Hari Ini', icon: 'route'),
              TodayFlowCard(steps: steps, stateOf: stateOf, actions: actions),
              const SizedBox(height: 24),
              IpSectionLabel(
                'Aktiviti Terkini',
                icon: 'clock',
                action: widget.onOpenTab == null ? null : IpLinkButton('Lihat semua', onTap: () => widget.onOpenTab!(2)),
              ),
              if (terkini.isEmpty)
                const DashEmpty(icon: 'file', title: 'Tiada laporan lagi.', sub: 'Laporan yang anda hantar akan muncul di sini.')
              else
                IpCard(
                  pad: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    child: Column(children: [
                      for (final (i, l) in terkini.indexed)
                        ActivityRow(
                          title: 'Laporan · ${l['tapak_nama'] ?? l['nama_tapak'] ?? '-'}',
                          sub: '${laporanKod(l)} · ${IpFormat.dateTime(laporanTarikh(l))}',
                          status: l['status']?.toString(),
                          last: i == terkini.length - 1,
                          onTap: () => _push(LaporanButiranScreen(laporan: l, allLaporan: _laporan)),
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
