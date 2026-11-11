import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/ip_format.dart';
import '../../widgets/v2/dash_widgets.dart';
import '../../widgets/v2/report_widgets.dart';
import '../../widgets/v2/ui.dart';

/// Tab "Semak" for supervisors: review queue (default filter Menunggu).
class SemakLaporanScreen extends StatefulWidget {
  const SemakLaporanScreen({super.key});

  @override
  State<SemakLaporanScreen> createState() => _SemakLaporanScreenState();
}

class _SemakLaporanScreenState extends State<SemakLaporanScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _laporan = [];
  ReportFilter _filter = ReportFilter.menunggu;
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
    final res = await ApiService.getLaporanTapak(token);
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
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => SemakanScreen(laporan: l)));
    if (mounted && changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final filtered = _laporan.where((l) => matchesFilter(l, _filter) && matchesQuery(l, _search.text)).toList();
    final groups = groupReports(filtered);

    return Column(children: [
      const IpAppHeader(title: 'Semak Laporan Pekerja', right: IpHeaderBell()),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _load,
          color: c.azure500,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              IpSearchBar(controller: _search, hint: 'Cari pekerja, tapak atau ID', onChanged: (_) => setState(() {})),
              const SizedBox(height: 10),
              StatusPills(value: _filter, onChanged: (f) => setState(() => _filter = f)),
              const SizedBox(height: 16),
              if (_error != null) ...[IpErrorBox(_error!, onRetry: _load), const SizedBox(height: 12)],
              if (_loading)
                const IpLoading()
              else if (groups.isEmpty)
                DashEmpty(
                  icon: 'clipboardCheck',
                  title: _laporan.isEmpty ? 'Tiada laporan untuk disemak' : 'Tiada laporan',
                  sub: _laporan.isEmpty
                      ? 'Laporan daripada pekerja akan muncul di sini.'
                      : 'Tiada laporan yang sepadan dengan penapis.',
                )
              else
                for (final (label, items) in groups) ...[
                  GroupHeader(label: label, count: items.length),
                  for (final l in items)
                    Padding(padding: const EdgeInsets.only(bottom: 12), child: _QueueCard(laporan: l, onOpen: () => _open(l))),
                ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ]);
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.laporan, required this.onOpen});
  final Map<String, dynamic> laporan;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final l = laporan;
    final pekerja = l['pekerja_nama']?.toString() ?? '-';
    final jumlah = (l['jumlah_gambar'] as num?)?.toInt() ?? 0;
    return IpCard(
      pad: 15,
      onTap: onOpen,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l['tapak_nama']?.toString() ?? '-',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.text, letterSpacing: -.16)),
              const SizedBox(height: 2),
              Text('${laporanKod(l)} · ${IpFormat.time(l['submitted_at'])}', style: ipMono(context, size: 11.5, color: c.text3)),
            ]),
          ),
          const SizedBox(width: 10),
          IpStatusText(l['status']?.toString(), small: true),
        ]),
        const SizedBox(height: 11),
        Wrap(spacing: 14, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            IpAvatar(name: pekerja, size: 24),
            const SizedBox(width: 6),
            Text(pekerja, style: TextStyle(fontSize: 12.5, color: c.text2, fontWeight: FontWeight.w600)),
          ]),
          Row(mainAxisSize: MainAxisSize.min, children: [
            IpIcon('image', size: 15, color: c.text3),
            const SizedBox(width: 5),
            Text('$jumlah gambar', style: TextStyle(fontSize: 12.5, color: c.text3)),
          ]),
        ]),
        const SizedBox(height: 11),
        Text(l['ringkasan']?.toString() ?? '',
            maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, color: c.text2, height: 1.45)),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerRight, child: LihatButton(onTap: onOpen)),
      ]),
    );
  }
}

/// Supervisor review: photo, info, note, Tolak / Lulus. Pops `true` when decided.
class SemakanScreen extends StatefulWidget {
  const SemakanScreen({super.key, required this.laporan});
  final Map<String, dynamic> laporan;

  @override
  State<SemakanScreen> createState() => _SemakanScreenState();
}

class _SemakanScreenState extends State<SemakanScreen> {
  final _nota = TextEditingController();
  List<Map<String, dynamic>>? _gambar;
  bool _submitting = false;
  String? _error;

  Map<String, dynamic> get l => widget.laporan;

  @override
  void initState() {
    super.initState();
    _nota.text = l['nota_admin']?.toString() ?? '';
    _loadGambar();
  }

  @override
  void dispose() {
    _nota.dispose();
    super.dispose();
  }

  Future<void> _loadGambar() async {
    final token = context.read<AuthProvider>().token;
    final id = (l['id'] as num?)?.toInt();
    if (token == null || id == null) {
      setState(() => _gambar = []);
      return;
    }
    final res = await ApiService.getGambarLaporan(token: token, laporanId: id);
    if (!mounted) return;
    setState(() {
      _gambar = res['success'] == true
          ? ((res['data'] as List?) ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .where((g) => (g['url']?.toString() ?? '').isNotEmpty)
              .toList()
          : [];
    });
  }

  Future<void> _semak(String status) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final nota = _nota.text.trim().isEmpty ? (status == 'lulus' ? 'Diluluskan.' : 'Ditolak.') : _nota.text.trim();
    final res = await ApiService.semakLaporan(
      token: token,
      laporanId: (l['id'] as num).toInt(),
      status: status,
      nota: nota,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res['success'] == true) {
      showIpToast(context, status == 'lulus' ? 'Laporan diluluskan' : 'Laporan ditolak',
          tone: status == 'lulus' ? IpToastTone.success : IpToastTone.danger);
      Navigator.pop(context, true);
    } else {
      setState(() => _error = res['message']?.toString() ?? 'Gagal semak laporan.');
    }
  }

  WatermarkStamp _stamp(int i) {
    final g = (_gambar != null && i < _gambar!.length) ? _gambar![i] : const <String, dynamic>{};
    final lat = g['latitud'];
    final lng = g['longitud'];
    return WatermarkStamp(
      kodTapak: l['kod_tapak']?.toString() ?? '-',
      pekerja: l['pekerja_nama']?.toString() ?? '-',
      masa: IpFormat.dateTime(g['captured_at'] ?? l['submitted_at']),
      coord: lat == null || lng == null ? null : IpFormat.coord(lat, lng),
    );
  }

  void _openViewer(int i) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoViewerScreen(
          urls: _gambar!.map((g) => g['url'].toString()).toList(),
          initialIndex: i,
          stampBuilder: _stamp,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final status = l['status']?.toString();
    final decided = !ReportStatus.isPending(status);
    final jumlah = _gambar?.length ?? (l['jumlah_gambar'] as num?)?.toInt() ?? 0;

    final Widget footer = decided
        ? Row(children: [
            IpIcon(status == 'lulus' ? 'checkCircle' : (status == 'tolak' ? 'xCircle' : 'clock'),
                size: 20, color: toneColors(context, ReportStatus.tone(status)).$2),
            const SizedBox(width: 10),
            Text(
              status == 'lulus'
                  ? 'Laporan diluluskan.'
                  : status == 'tolak'
                      ? 'Laporan ditolak.'
                      : 'Menunggu semakan admin.',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: toneColors(context, ReportStatus.tone(status)).$2),
            ),
          ])
        : Row(children: [
            Expanded(
              child: IpButton('Tolak',
                  full: true,
                  size: IpButtonSize.lg,
                  variant: IpButtonVariant.danger,
                  icon: 'x',
                  onPressed: _submitting ? null : () => _semak('tolak')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: IpButton('Lulus',
                  full: true,
                  size: IpButtonSize.lg,
                  variant: IpButtonVariant.emerald,
                  icon: 'check',
                  loading: _submitting,
                  onPressed: _submitting ? null : () => _semak('lulus')),
            ),
          ]);

    return IpPushedScaffold(
      title: 'Semak Laporan',
      sub: '${l['kod_tapak'] ?? '-'} · ${laporanKod(l)}',
      right: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IpChip(ReportStatus.label(status), small: true, tone: ReportStatus.tone(status)),
      ),
      bottom: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
        decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.line))),
        child: footer,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        children: [
          if (_error != null) ...[IpErrorBox(_error!), const SizedBox(height: 14)],
          IpCard(
            child: Column(children: [
              InfoLine(icon: 'building', label: 'Tapak', value: l['tapak_nama']?.toString() ?? '-'),
              InfoLine(icon: 'user', label: 'Pekerja', value: l['pekerja_nama']?.toString() ?? '-'),
              InfoLine(icon: 'clock', label: 'Dihantar', value: IpFormat.dateTime(l['submitted_at']), last: true),
            ]),
          ),
          const SizedBox(height: 16),
          const IpSectionLabel('Ringkasan Kerja', icon: 'edit'),
          IpCard(
            child: Text(
              (l['ringkasan']?.toString() ?? '').isEmpty ? 'Tiada ringkasan.' : l['ringkasan'].toString(),
              style: TextStyle(fontSize: 14.5, color: c.text, height: 1.55),
            ),
          ),
          const SizedBox(height: 16),
          IpSectionLabel('Gambar Kerja ($jumlah)', icon: 'image'),
          if (_gambar == null)
            const IpPhotoPlaceholder(label: 'memuatkan gambar…', height: 210)
          else if (_gambar!.isEmpty)
            const IpPhotoPlaceholder(label: 'tiada gambar', height: 120)
          else ...[
            WatermarkedPhoto(url: _gambar!.first['url'].toString(), stamp: _stamp(0), onTap: () => _openViewer(0)),
            if (_gambar!.length > 1) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _gambar!.length - 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => _openViewer(i + 1),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(_gambar![i + 1]['url'].toString(),
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(width: 72, height: 72, color: c.surface3)),
                    ),
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          const IpSectionLabel('Nota Penyelia', icon: 'edit'),
          if (decided)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.line, width: 1.5),
              ),
              child: Text(_nota.text.isEmpty ? '—' : _nota.text, style: TextStyle(fontSize: 14.5, color: c.text2, height: 1.5)),
            )
          else
            IpInput(
              controller: _nota,
              hint: 'cth: tak okay, redo / kerja kemas, lulus',
              maxLines: 4,
              keyboardType: TextInputType.multiline,
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
