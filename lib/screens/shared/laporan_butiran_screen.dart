import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'gambar_screen.dart';

String _fmtDate(dynamic raw) {
  if (raw == null) return '';
  final dt = DateTime.tryParse(raw.toString());
  if (dt == null) return '';
  final local = dt.toLocal();
  const months = [
    'Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun',
    'Jul', 'Ogo', 'Sep', 'Okt', 'Nov', 'Dis',
  ];
  final mm = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${months[local.month - 1]}, ${local.hour}:$mm';
}

Color _stTextColor(String s) {
  switch (s) {
    case 'lulus':
      return const Color(0xFF166534);
    case 'tolak':
      return const Color(0xFF991B1B);
    case 'menunggu_admin':
      return const Color(0xFF1E40AF);
    default:
      return const Color(0xFF92400E);
  }
}

Color _stBgColor(String s) {
  switch (s) {
    case 'lulus':
      return const Color(0xFFDCFCE7);
    case 'tolak':
      return const Color(0xFFFEE2E2);
    case 'menunggu_admin':
      return const Color(0xFFDBEAFE);
    default:
      return const Color(0xFFFEF3C7);
  }
}

String _stLabel(String s) {
  switch (s) {
    case 'lulus':
      return 'Diluluskan';
    case 'tolak':
      return 'Ditolak';
    case 'menunggu_admin':
      return 'Menunggu Admin';
    default:
      return 'Menunggu';
  }
}

Widget _statusBadge(String status) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: _stBgColor(status),
      borderRadius: BorderRadius.circular(50),
    ),
    child: Text(
      _stLabel(status),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: _stTextColor(status),
      ),
    ),
  );
}

Widget _buildThumbnailRow({
  required List<String> urls,
  required double size,
  required double radius,
  required int maxCount,
  required void Function(List<String> urls, int index) onTap,
}) {
  final showExtra = urls.length > maxCount;
  final visibleCount = showExtra ? maxCount - 1 : urls.length;
  final extra = urls.length - visibleCount;

  return Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (int i = 0; i < visibleCount; i++)
        GestureDetector(
          onTap: () => onTap(urls, i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: SizedBox(
              width: size,
              height: size,
              child: Image.network(
                urls[i],
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Container(
                        color: AppTheme.border,
                        child: const Center(
                          child: Icon(Icons.image_outlined,
                              color: AppTheme.textMuted, size: 18),
                        ),
                      ),
                errorBuilder: (_, _, _) => Container(
                  color: AppTheme.border,
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: AppTheme.textMuted, size: 18),
                  ),
                ),
              ),
            ),
          ),
        ),
      if (showExtra)
        GestureDetector(
          onTap: () => onTap(urls, visibleCount),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Container(
              width: size,
              height: size,
              color: AppTheme.border,
              child: Center(
                child: Text(
                  '+$extra',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class LaporanButiranScreen extends StatefulWidget {
  const LaporanButiranScreen({
    super.key,
    required this.laporan,
    required this.allLaporan,
  });

  final Map<String, dynamic> laporan;
  final List<Map<String, dynamic>> allLaporan;

  @override
  State<LaporanButiranScreen> createState() => _LaporanButiranScreenState();
}

class _LaporanButiranScreenState extends State<LaporanButiranScreen> {
  List<String>? _photoUrls;
  bool _photosLoading = true;

  late List<Map<String, dynamic>> _chain;
  late Map<String, dynamic> _latest;
  late List<Map<String, dynamic>> _susulan;

  @override
  void initState() {
    super.initState();
    _computeChain();
    _fetchPhotos();
  }

  void _computeChain() {
    final current = widget.laporan;
    final tapakId = (current['tapak_id'] as num).toInt();
    final checkinId = (current['checkin_id'] as num).toInt();
    final currentCount = (current['resubmit_count'] as num?)?.toInt() ?? 0;

    _chain = widget.allLaporan.where((l) {
      final lt = (l['tapak_id'] as num?)?.toInt();
      final lc = (l['checkin_id'] as num?)?.toInt();
      return lt == tapakId && lc == checkinId;
    }).toList();

    _latest = _chain.isEmpty
        ? widget.laporan
        : _chain.reduce((a, b) {
            final aCount = (a['resubmit_count'] as num?)?.toInt() ?? 0;
            final bCount = (b['resubmit_count'] as num?)?.toInt() ?? 0;
            return aCount >= bCount ? a : b;
          });

    _susulan = _chain
        .where((l) =>
            ((l['resubmit_count'] as num?)?.toInt() ?? 0) > currentCount)
        .toList()
      ..sort((a, b) {
        final aCount = (a['resubmit_count'] as num?)?.toInt() ?? 0;
        final bCount = (b['resubmit_count'] as num?)?.toInt() ?? 0;
        return aCount.compareTo(bCount);
      });
  }

  Future<void> _fetchPhotos() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() => _photosLoading = false);
      return;
    }
    final laporanId = (widget.laporan['id'] as num).toInt();
    final res =
        await ApiService.getGambarLaporan(token: token, laporanId: laporanId);
    if (!mounted) return;
    final data = (res['data'] as List?) ?? [];
    setState(() {
      _photoUrls = data
          .map((e) => (e as Map)['url']?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList();
      _photosLoading = false;
    });
  }

  void _openImageViewer(List<String> urls, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullImageViewer(urls: urls, initialIndex: index),
      ),
    );
  }

  void _showPetaDialog() {
    final lat =
        (widget.laporan['tapak_latitud'] as num?)?.toDouble();
    final lon =
        (widget.laporan['tapak_longitud'] as num?)?.toDouble();
    if (lat == null || lon == null) return;

    final tapakNama = widget.laporan['tapak_nama']?.toString() ?? 'Tapak';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          tapakNama,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(lat, lon),
                initialZoom: 16,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'ipantau',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(lat, lon),
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: AppTheme.navy,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _section(String label, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          content,
        ],
      ),
    );
  }

  Widget _sectionBox({required Widget child, Color? bg}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg ?? AppTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }

  Widget _sectionMaklumatTapak() {
    final l = widget.laporan;
    final tapakNama = l['tapak_nama']?.toString() ?? '-';
    final alamat = l['alamat']?.toString() ?? '';
    final lat = (l['tapak_latitud'] as num?)?.toDouble();
    final lon = (l['tapak_longitud'] as num?)?.toDouble();

    return _section(
      'MAKLUMAT TAPAK',
      _sectionBox(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tapakNama,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (alamat.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      alamat,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            if (lat != null && lon != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _showPetaDialog,
                child: const Text(
                  '📍 Lihat peta',
                  style: TextStyle(fontSize: 11, color: Color(0xFF3B82F6)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTarikh() {
    final l = widget.laporan;
    final submitted = _fmtDate(l['submitted_at']);
    final reviewed = _fmtDate(l['reviewed_at']);

    return _section(
      'TARIKH',
      _sectionBox(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dihantar',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    submitted.isNotEmpty ? submitted : '—',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status dikemas kini',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    reviewed.isNotEmpty ? reviewed : '—',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionRingkasan() {
    final ringkasan = widget.laporan['ringkasan']?.toString() ?? '';
    return _section(
      'RINGKASAN KERJA',
      _sectionBox(
        child: ringkasan.isNotEmpty
            ? Text(
                ringkasan,
                style: const TextStyle(fontSize: 13, height: 1.5),
              )
            : const Text(
                'Tiada ringkasan',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
      ),
    );
  }

  Widget _sectionGambar() {
    final jumlahFromData =
        (widget.laporan['jumlah_gambar'] as num?)?.toInt() ?? 0;
    final count = _photoUrls?.length ?? jumlahFromData;

    Widget content;
    if (_photosLoading) {
      content = _sectionBox(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else if (_photoUrls == null || _photoUrls!.isEmpty) {
      content = _sectionBox(
        child: const Text(
          'Tiada gambar',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    } else {
      content = _buildThumbnailRow(
        urls: _photoUrls!,
        size: 68,
        radius: 8,
        maxCount: 4,
        onTap: _openImageViewer,
      );
    }

    return _section('GAMBAR ($count)', content);
  }

  Widget _sectionTindakan() {
    final status = widget.laporan['status']?.toString() ?? 'pending';
    final notaAdmin = widget.laporan['nota_admin']?.toString() ?? '';

    Widget content;
    if (status == 'lulus') {
      content = _sectionBox(
        bg: const Color(0xFFECFDF5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Diluluskan oleh penyelia',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF065F46),
              ),
            ),
            if (notaAdmin.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Nota: $notaAdmin',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ],
        ),
      );
    } else if (status == 'tolak') {
      content = _sectionBox(
        bg: const Color(0xFFFEF2F2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ditolak oleh penyelia',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF991B1B),
              ),
            ),
            if (notaAdmin.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(notaAdmin, style: const TextStyle(fontSize: 13)),
            ],
          ],
        ),
      );
    } else {
      content = _sectionBox(
        child: const Text(
          'Belum disemak',
          style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
        ),
      );
    }

    return _section('TINDAKAN PENYELIA', content);
  }

  Widget _sectionSusulan() {
    final status = widget.laporan['status']?.toString() ?? 'pending';
    if (status != 'tolak' || _susulan.isEmpty) return const SizedBox.shrink();

    return _section(
      'SUSULAN (${_susulan.length})',
      Column(
        children: _susulan
            .map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SusulanCard(
                    key: ValueKey((l['id'] as num).toInt()),
                    laporan: l,
                  ),
                ))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.laporan;
    final resubmitCount = (l['resubmit_count'] as num?)?.toInt() ?? 0;
    final kodTapak = l['kod_tapak']?.toString() ?? '';
    final headerStatus = _latest['status']?.toString() ?? 'pending';
    final showEditButton = headerStatus == 'tolak';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Butiran Laporan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              '$kodTapak · Hantaran #${resubmitCount + 1}',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: _statusBadge(headerStatus),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                    16, 20, 16, showEditButton ? 8 : 20),
                children: [
                  _sectionMaklumatTapak(),
                  _sectionTarikh(),
                  _sectionRingkasan(),
                  _sectionGambar(),
                  _sectionTindakan(),
                  _sectionSusulan(),
                ],
              ),
            ),
            if (showEditButton)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      await navigator.push(
                        MaterialPageRoute(
                          builder: (_) => GambarScreen(
                            isEdit: true,
                            laporanId: (_latest['id'] as num).toInt(),
                            tapakId: (_latest['tapak_id'] as num).toInt(),
                            checkinId: (_latest['checkin_id'] as num).toInt(),
                            tapakNama:
                                _latest['tapak_nama']?.toString() ?? '-',
                            initialRingkasan:
                                _latest['ringkasan']?.toString(),
                            initialKemajuan:
                                (_latest['kemajuan_peratus'] as num?)
                                        ?.toInt() ??
                                    0,
                          ),
                        ),
                      );
                      // canPop() guards against the submit-success path where
                      // HantarLaporanScreen already cleared the stack via
                      // pushAndRemoveUntil — popping the sole remaining route
                      // would crash with '_history.isNotEmpty' assertion.
                      if (mounted && navigator.canPop()) navigator.pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Edit & Hantar Semula',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SusulanCard extends StatefulWidget {
  const _SusulanCard({super.key, required this.laporan});

  final Map<String, dynamic> laporan;

  @override
  State<_SusulanCard> createState() => _SusulanCardState();
}

class _SusulanCardState extends State<_SusulanCard> {
  List<String>? _photoUrls;

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
  }

  Future<void> _fetchPhotos() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() => _photoUrls = []);
      return;
    }
    final laporanId = (widget.laporan['id'] as num).toInt();
    final res =
        await ApiService.getGambarLaporan(token: token, laporanId: laporanId);
    if (!mounted) return;
    final data = (res['data'] as List?) ?? [];
    setState(() {
      _photoUrls = data
          .map((e) => (e as Map)['url']?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.laporan;
    final status = l['status']?.toString() ?? 'pending';
    final resubmitCount = (l['resubmit_count'] as num?)?.toInt() ?? 0;
    final ringkasan = l['ringkasan']?.toString() ?? '';
    final notaAdmin = l['nota_admin']?.toString() ?? '';
    final date = _fmtDate(l['submitted_at']);
    final isTolak = status == 'tolak';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge + Hantaran #N
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statusBadge(status),
              Text(
                'Hantaran #${resubmitCount + 1}',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
          // Ringkasan
          if (ringkasan.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(ringkasan, style: const TextStyle(fontSize: 13)),
          ],
          // Rejection reason
          if (isTolak && notaAdmin.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sebab ditolak:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(notaAdmin, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
          // Date
          const SizedBox(height: 6),
          Text(date,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textMuted)),
          // Photos
          if (_photoUrls != null && _photoUrls!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildThumbnailRow(
              urls: _photoUrls!,
              size: 44,
              radius: 6,
              maxCount: 4,
              onTap: (urls, i) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      _FullImageViewer(urls: urls, initialIndex: i),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FullImageViewer extends StatefulWidget {
  const _FullImageViewer({required this.urls, required this.initialIndex});

  final List<String> urls;
  final int initialIndex;

  @override
  State<_FullImageViewer> createState() => _FullImageViewerState();
}

class _FullImageViewerState extends State<_FullImageViewer> {
  late final PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: widget.urls.length > 1
            ? Text(
                '${_current + 1} / ${widget.urls.length}',
                style: const TextStyle(fontSize: 14),
              )
            : null,
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => InteractiveViewer(
          child: Center(
            child: Image.network(
              widget.urls[i],
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 80,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
