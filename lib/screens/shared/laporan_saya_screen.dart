import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/ip_format.dart';
import '../../widgets/v2/dash_widgets.dart';
import '../../widgets/v2/report_widgets.dart';
import '../../widgets/v2/ui.dart';
import 'gambar_screen.dart';
import 'laporan_butiran_screen.dart';

/// Tab "Laporan" for contractors: search, status filter, grouped by day.
class LaporanSayaScreen extends StatefulWidget {
  const LaporanSayaScreen({super.key});

  @override
  State<LaporanSayaScreen> createState() => _LaporanSayaScreenState();
}

class _LaporanSayaScreenState extends State<LaporanSayaScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _laporan = [];
  ReportFilter _filter = ReportFilter.semua;
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
    final res = await ApiService.getLaporanSaya(token);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _laporan = ((res['data'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error = res['message']?.toString() ?? 'Gagal memuatkan laporan.';
      });
    }
  }

  Future<void> _open(Map<String, dynamic> l) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => LaporanButiranScreen(laporan: l, allLaporan: _laporan)));
    if (mounted) _load();
  }

  Future<void> _newReport() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const GambarScreen()));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final filtered = _laporan.where((l) => matchesFilter(l, _filter) && matchesQuery(l, _search.text)).toList();
    final groups = groupReports(filtered);

    return Column(children: [
      const IpAppHeader(title: 'Laporan', right: IpHeaderBell()),
      Expanded(
        child: Stack(children: [
          RefreshIndicator(
            onRefresh: _load,
            color: c.azure500,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                if (_error != null) ...[IpErrorBox(_error!, onRetry: _load), const SizedBox(height: 12)],
                if (_loading)
                  const IpLoading()
                else if (_laporan.isEmpty)
                  const DashEmpty(icon: 'file', title: 'Belum ada laporan', sub: 'Hantar laporan pertama anda.')
                else ...[
                  IpSearchBar(controller: _search, hint: 'Cari tapak atau ID laporan', onChanged: (_) => setState(() {})),
                  const SizedBox(height: 10),
                  StatusPills(value: _filter, onChanged: (f) => setState(() => _filter = f)),
                  const SizedBox(height: 16),
                  if (groups.isEmpty)
                    const DashEmpty(icon: 'file', title: 'Tiada laporan', sub: 'Tiada laporan yang sepadan dengan penapis.')
                  else
                    for (final (label, items) in groups) ...[
                      GroupHeader(label: label, count: items.length),
                      for (final l in items)
                        Padding(padding: const EdgeInsets.only(bottom: 12), child: _MyReportCard(laporan: l, onOpen: () => _open(l))),
                    ],
                ],
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 18,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: const Color(0xFF14223C).withValues(alpha: .22), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Material(
                color: c.azure500,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _newReport,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      IpIcon('plus', size: 20, strokeWidth: 2.6, color: Colors.white),
                      SizedBox(width: 9),
                      Text('Laporan Baru', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }
}

class _MyReportCard extends StatelessWidget {
  const _MyReportCard({required this.laporan, required this.onOpen});
  final Map<String, dynamic> laporan;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final l = laporan;
    final status = l['status']?.toString();
    final nota = l['nota_admin']?.toString();
    final resubmit = num.tryParse('${l['resubmit_count'] ?? 0}') ?? 0;
    return IpCard(
      pad: 15,
      onTap: onOpen,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IpStatusText(status, small: true),
          if (resubmit > 0) ...[
            const SizedBox(width: 8),
            IpChip('Hantar semula ×$resubmit', small: true, tone: IpTone.azure),
          ],
          const Spacer(),
          Text(laporanKod(l), style: ipMono(context, size: 11.5, color: c.text3)),
        ]),
        const SizedBox(height: 9),
        Text((l['tapak_nama'] ?? l['nama_tapak'] ?? '-').toString(),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.text, letterSpacing: -.16)),
        const SizedBox(height: 4),
        Text(l['ringkasan']?.toString() ?? '',
            maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, color: c.text2, height: 1.45)),
        if (status == 'tolak' && nota != null && nota.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(color: c.crimson50, borderRadius: BorderRadius.circular(10)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(top: 1), child: IpIcon('xCircle', size: 15, color: c.crimson600)),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'Perlu tindakan: ', style: TextStyle(fontWeight: FontWeight.w800)),
                    TextSpan(text: nota),
                  ]),
                  style: TextStyle(fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w600, color: c.crimson600),
                ),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 12),
        Row(children: [
          IpIcon('clock', size: 13, color: c.text3),
          const SizedBox(width: 6),
          Text(IpFormat.dateTime(laporanTarikh(l)), style: ipMono(context, size: 12, color: c.text3)),
          const Spacer(),
          LihatButton(onTap: onOpen),
        ]),
      ]),
    );
  }
}
