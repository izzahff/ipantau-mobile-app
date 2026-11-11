import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/ip_format.dart';
import '../../widgets/v2/report_widgets.dart';
import '../../widgets/v2/ui.dart';
import 'gambar_screen.dart';

int _resubmit(Map<String, dynamic> l) => (l['resubmit_count'] as num?)?.toInt() ?? 0;

/// Report detail for the submitter (contractor), incl. resubmission chain.
class LaporanButiranScreen extends StatefulWidget {
  const LaporanButiranScreen({super.key, required this.laporan, required this.allLaporan});

  final Map<String, dynamic> laporan;
  final List<Map<String, dynamic>> allLaporan;

  @override
  State<LaporanButiranScreen> createState() => _LaporanButiranScreenState();
}

class _LaporanButiranScreenState extends State<LaporanButiranScreen> {
  List<Map<String, dynamic>>? _photos;
  late Map<String, dynamic> _latest;
  late List<Map<String, dynamic>> _susulan;

  Map<String, dynamic> get l => widget.laporan;

  @override
  void initState() {
    super.initState();
    _computeChain();
    _fetchPhotos();
  }

  void _computeChain() {
    final tapakId = (l['tapak_id'] as num?)?.toInt();
    final checkinId = (l['checkin_id'] as num?)?.toInt();
    final current = _resubmit(l);
    final chain = widget.allLaporan
        .where((x) => (x['tapak_id'] as num?)?.toInt() == tapakId && (x['checkin_id'] as num?)?.toInt() == checkinId)
        .toList();
    _latest = chain.isEmpty ? l : chain.reduce((a, b) => _resubmit(a) >= _resubmit(b) ? a : b);
    _susulan = chain.where((x) => _resubmit(x) > current).toList()..sort((a, b) => _resubmit(a).compareTo(_resubmit(b)));
  }

  Future<void> _fetchPhotos() async {
    final token = context.read<AuthProvider>().token;
    final id = (l['id'] as num?)?.toInt();
    if (token == null || id == null) {
      setState(() => _photos = []);
      return;
    }
    final res = await ApiService.getGambarLaporan(token: token, laporanId: id);
    if (!mounted) return;
    setState(() {
      _photos = ((res['data'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((g) => (g['url']?.toString() ?? '').isNotEmpty)
          .toList();
    });
  }

  WatermarkStamp _stamp(int i) {
    final g = (_photos != null && i < _photos!.length) ? _photos![i] : const <String, dynamic>{};
    final lat = g['latitud'] ?? l['latitud'];
    final lng = g['longitud'] ?? l['longitud'];
    return WatermarkStamp(
      kodTapak: l['kod_tapak']?.toString() ?? '-',
      pekerja: (l['pekerja_nama'] ?? context.read<AuthProvider>().pengguna?['nama'] ?? '-').toString(),
      masa: IpFormat.dateTime(g['captured_at'] ?? l['submitted_at']),
      coord: lat == null || lng == null ? null : IpFormat.coord(lat, lng),
    );
  }

  void _openViewer(int i) {
    final urls = _photos!.map((g) => g['url'].toString()).toList();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PhotoViewerScreen(urls: urls, initialIndex: i, stampBuilder: _stamp)),
    );
  }

  void _showPeta() {
    final lat = (l['tapak_latitud'] as num?)?.toDouble();
    final lon = (l['tapak_longitud'] as num?)?.toDouble();
    if (lat == null || lon == null) return;
    showSiteMapSheet(context, title: l['tapak_nama']?.toString() ?? 'Tapak', point: LatLng(lat, lon));
  }

  Future<void> _editResubmit() async {
    final navigator = Navigator.of(context);
    await navigator.push(MaterialPageRoute(
      builder: (_) => GambarScreen(
        isEdit: true,
        laporanId: (_latest['id'] as num).toInt(),
        tapakId: (_latest['tapak_id'] as num).toInt(),
        checkinId: (_latest['checkin_id'] as num).toInt(),
        tapakNama: _latest['tapak_nama']?.toString() ?? '-',
        initialRingkasan: _latest['ringkasan']?.toString(),
        initialKemajuan: (_latest['kemajuan_peratus'] as num?)?.toInt() ?? 0,
      ),
    ));
    // The submit path clears the stack itself; only pop if still possible.
    if (mounted && navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final status = l['status']?.toString();
    final headerStatus = _latest['status']?.toString();
    final hasPeta = l['tapak_latitud'] != null && l['tapak_longitud'] != null;
    final jumlah = _photos?.length ?? (l['jumlah_gambar'] as num?)?.toInt() ?? 0;
    final alamat = l['alamat']?.toString() ?? '';
    final kemajuan = (l['kemajuan_peratus'] as num?)?.toInt();

    return IpPushedScaffold(
      title: 'Butiran Laporan',
      sub: '${l['kod_tapak'] ?? '-'} · Hantaran #${_resubmit(l) + 1}',
      right: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IpChip(ReportStatus.label(headerStatus), small: true, tone: ReportStatus.tone(headerStatus)),
      ),
      bottom: headerStatus == 'tolak'
          ? Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
              decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.line))),
              child: IpButton('Edit & Hantar Semula',
                  full: true, size: IpButtonSize.lg, variant: IpButtonVariant.danger, icon: 'edit', onPressed: _editResubmit),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          IpSectionLabel(
            'Maklumat Tapak',
            icon: 'building',
            action: hasPeta ? _peta(context) : null,
          ),
          IpCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l['tapak_nama']?.toString() ?? '-', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.text)),
              if (alamat.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(alamat, style: TextStyle(fontSize: 13, color: c.text2)),
              ],
            ]),
          ),
          const SizedBox(height: 18),
          const IpSectionLabel('Tarikh', icon: 'calendar'),
          IpCard(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _DetailCol(label: 'Dihantar', value: IpFormat.dateTime(l['submitted_at']))),
              const SizedBox(width: 16),
              Expanded(
                child: _DetailCol(
                  label: 'Status dikemas kini',
                  value: l['reviewed_at'] == null ? '—' : IpFormat.dateTime(l['reviewed_at']),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          const IpSectionLabel('Ringkasan Kerja', icon: 'edit'),
          IpCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                (l['ringkasan']?.toString() ?? '').isEmpty ? 'Tiada ringkasan.' : l['ringkasan'].toString(),
                style: TextStyle(fontSize: 14.5, color: c.text, height: 1.55),
              ),
              if (kemajuan != null && kemajuan > 0) ...[
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: IpProgressBar(value: kemajuan / 100)),
                  const SizedBox(width: 10),
                  Text('$kemajuan%', style: ipMono(context, size: 12.5, weight: FontWeight.w700, color: c.text2)),
                ]),
              ],
            ]),
          ),
          const SizedBox(height: 18),
          IpSectionLabel('Gambar ($jumlah)', icon: 'image'),
          if (_photos == null)
            const IpPhotoPlaceholder(label: 'memuatkan gambar…', height: 210)
          else if (_photos!.isEmpty)
            const IpPhotoPlaceholder(label: 'tiada gambar', height: 120)
          else ...[
            WatermarkedPhoto(url: _photos!.first['url'].toString(), stamp: _stamp(0), onTap: () => _openViewer(0)),
            if (_photos!.length > 1) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos!.length - 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => _openViewer(i + 1),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(_photos![i + 1]['url'].toString(),
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
          const SizedBox(height: 18),
          const IpSectionLabel('Tindakan Penyelia', icon: 'shield'),
          ReviewOutcomeCard(status: status, nota: l['nota_admin']?.toString()),
          if (status == 'tolak' && _susulan.isNotEmpty) ...[
            const SizedBox(height: 18),
            IpSectionLabel('Susulan (${_susulan.length})', icon: 'refresh'),
            for (final s in _susulan)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SusulanCard(
                  laporan: s,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LaporanButiranScreen(laporan: s, allLaporan: widget.allLaporan)),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _peta(BuildContext context) {
    final c = context.ip;
    return InkWell(
      onTap: _showPeta,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          IpIcon('map', size: 15, color: c.azure600),
          const SizedBox(width: 4),
          Text('Lihat peta', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.azure600)),
        ]),
      ),
    );
  }
}

class _DetailCol extends StatelessWidget {
  const _DetailCol({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: TextStyle(fontSize: 11.5, color: c.text3, fontWeight: FontWeight.w700, letterSpacing: .46)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 14.5, color: c.text, fontWeight: FontWeight.w600)),
    ]);
  }
}

/// "Tindakan Penyelia" outcome: pending / approved / rejected + note.
class ReviewOutcomeCard extends StatelessWidget {
  const ReviewOutcomeCard({super.key, required this.status, this.nota});
  final String? status;
  final String? nota;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    if (status == 'lulus' || status == 'tolak') {
      final ok = status == 'lulus';
      final fg = ok ? c.emerald600 : c.crimson600;
      return IpCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            IpIcon(ok ? 'checkCircle' : 'xCircle', size: 19, color: fg),
            const SizedBox(width: 10),
            Text(ok ? 'Diluluskan oleh penyelia' : 'Ditolak oleh penyelia',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: fg)),
          ]),
          if (nota != null && nota!.isNotEmpty) ...[
            const SizedBox(height: 11),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(12)),
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: 'Nota: ', style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
                  TextSpan(text: nota),
                ]),
                style: TextStyle(fontSize: 13.5, color: c.text2, height: 1.5),
              ),
            ),
          ],
        ]),
      );
    }
    final admin = status == 'menunggu_admin';
    return IpCard(
      child: Row(children: [
        IpIcon('clock', size: 19, color: admin ? c.azure700 : c.amberText),
        const SizedBox(width: 10),
        Text(admin ? 'Menunggu semakan admin' : 'Belum disemak',
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: admin ? c.azure700 : c.amberText)),
      ]),
    );
  }
}

class _SusulanCard extends StatelessWidget {
  const _SusulanCard({required this.laporan, required this.onTap});
  final Map<String, dynamic> laporan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final s = laporan['status']?.toString();
    return IpCard(
      pad: 14,
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Hantaran #${_resubmit(laporan) + 1}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
          const Spacer(),
          IpStatusText(s, small: true),
        ]),
        const SizedBox(height: 4),
        Text(laporan['ringkasan']?.toString() ?? '',
            maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: c.text2, height: 1.4)),
        const SizedBox(height: 6),
        Text(IpFormat.dateTime(laporan['submitted_at']), style: ipMono(context, size: 11.5, color: c.text3)),
      ]),
    );
  }
}

/// Bottom sheet with a map centred on a site.
Future<void> showSiteMapSheet(BuildContext context, {required String title, required LatLng point}) {
  return showIpSheet<void>(
    context,
    title: title,
    builder: (ctx) => ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 320,
        child: FlutterMap(
          options: MapOptions(initialCenter: point, initialZoom: 16),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'ipantau'),
            MarkerLayer(markers: [
              Marker(point: point, width: 40, height: 40, child: IpIcon('pin', size: 36, color: ctx.ip.crimson600)),
            ]),
          ],
        ),
      ),
    ),
  );
}
