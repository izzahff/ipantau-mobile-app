import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/v2/dash_widgets.dart';
import '../../widgets/v2/ui.dart';
import 'checkin_screen.dart';

enum _TapakFilter { semua, berjalan, selesai }

class TapakScreen extends StatefulWidget {
  const TapakScreen({super.key});

  @override
  State<TapakScreen> createState() => _TapakScreenState();
}

class _TapakScreenState extends State<TapakScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _tapak = [];
  _TapakFilter _filter = _TapakFilter.semua;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
    final res = await ApiService.getTapakSaya(token);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _tapak = ((res['data'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error = res['message']?.toString() ?? 'Gagal muatkan tapak.';
      });
    }
  }

  static bool _selesai(Map<String, dynamic> t) {
    final s = (t['status'] ?? 'aktif').toString().toLowerCase();
    return s == 'selesai' || s == 'completed' || s == 'tamat';
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.text.trim().toLowerCase();
    return _tapak.where((t) {
      final okFilter = switch (_filter) {
        _TapakFilter.semua => true,
        _TapakFilter.berjalan => !_selesai(t),
        _TapakFilter.selesai => _selesai(t),
      };
      if (!okFilter) return false;
      if (q.isEmpty) return true;
      return t.values.whereType<String>().join(' ').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final list = _filtered;
    return Column(children: [
      const IpAppHeader(title: 'Tapak', right: IpHeaderBell()),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _load,
          color: c.azure500,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              IpSearchBar(controller: _search, hint: 'Cari nama tapak atau ID', onChanged: (_) => setState(() {})),
              const SizedBox(height: 12),
              Row(children: [
                for (final (f, l) in const [
                  (_TapakFilter.semua, 'Semua'),
                  (_TapakFilter.berjalan, 'Berjalan'),
                  (_TapakFilter.selesai, 'Selesai'),
                ]) ...[
                  _pill(context, l, _filter == f, () => setState(() => _filter = f)),
                  const SizedBox(width: 8),
                ],
              ]),
              const SizedBox(height: 16),
              if (_error != null) ...[IpErrorBox(_error!, onRetry: _load), const SizedBox(height: 12)],
              if (_loading)
                const IpLoading()
              else if (list.isEmpty)
                const DashEmpty(icon: 'building', title: 'Tiada tapak', sub: 'Tiada tapak yang sepadan dengan carian.')
              else
                for (final t in list)
                  Padding(padding: const EdgeInsets.only(bottom: 12), child: _SiteCard(tapak: t, selesai: _selesai(t))),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _pill(BuildContext context, String label, bool on, VoidCallback onTap) {
    final c = context.ip;
    final active = c.isDark ? c.azure600 : c.navy800;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: on ? active : c.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: on ? active : c.line2, width: 1.5),
        ),
        child: Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: on ? Colors.white : c.text2)),
      ),
    );
  }
}

class _SiteCard extends StatelessWidget {
  const _SiteCard({required this.tapak, required this.selesai});
  final Map<String, dynamic> tapak;
  final bool selesai;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final nama = (tapak['nama_tapak'] ?? tapak['nama'])?.toString() ?? '-';
    final kod = tapak['kod_tapak']?.toString() ?? '-';
    final alamat = (tapak['alamat'] ?? tapak['projek'])?.toString();
    final radius = tapak['radius_geofence'];
    final workers = num.tryParse('${tapak['jumlah_pekerja'] ?? ''}');
    final present = num.tryParse('${tapak['pekerja_hadir'] ?? ''}');
    final id = (tapak['id'] as num?)?.toInt();

    return IpCard(
      pad: 15,
      onTap: id == null
          ? null
          : () => Navigator.push(context, MaterialPageRoute(builder: (_) => CheckinScreen(initialTapakId: id))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 44, height: 44, child: Center(child: IpIcon('pin', size: 24, color: selesai ? c.text3 : c.azure600))),
        const SizedBox(width: 13),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(nama, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.text, letterSpacing: -.16)),
              ),
              const SizedBox(width: 8),
              Text(selesai ? 'Selesai' : 'Aktif',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: selesai ? c.text3 : c.emerald600)),
            ]),
            const SizedBox(height: 3),
            Text(radius == null ? kod : '$kod · radius ${radius}m', style: ipMono(context, size: 12, color: c.text3)),
            if (alamat != null && alamat.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(children: [
                IpIcon('route', size: 13, color: c.text3),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(alamat, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: c.text2)),
                ),
              ]),
            ],
            if (workers != null && present != null && workers > 0) ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: Text('$present daripada $workers pekerja',
                      style: TextStyle(fontSize: 12, color: c.text2, fontWeight: FontWeight.w600)),
                ),
                Text('${(present / workers * 100).round()}%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: present > 0 ? c.emerald600 : c.text3)),
              ]),
              const SizedBox(height: 6),
              IpProgressBar(value: present / workers, color: c.emerald500),
            ],
          ]),
        ),
      ]),
    );
  }
}
