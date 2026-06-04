import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/ipantau_app_bar.dart';

class SemakLaporanScreen extends StatefulWidget {
  const SemakLaporanScreen({super.key});

  @override
  State<SemakLaporanScreen> createState() => _SemakLaporanScreenState();
}

class _SemakLaporanScreenState extends State<SemakLaporanScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _laporan = [];

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

    final res = await ApiService.getLaporanTapak(token);
    if (!mounted) return;

    if (res['success'] == true) {
      final data = (res['data'] as List?) ?? [];
      setState(() {
        _laporan = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error = res['message'] ?? 'Gagal memuatkan laporan.';
      });
    }
  }

  Color _statusColor(String status) {
    if (status == 'lulus') return AppTheme.success;
    if (status == 'tolak') return AppTheme.error;
    return AppTheme.gold;
  }

  Color _statusBg(String status) {
    if (status == 'lulus') return AppTheme.successLight;
    if (status == 'tolak') return AppTheme.errorLight;
    return AppTheme.goldLight;
  }

  String _statusLabel(String status) {
    if (status == 'lulus') return 'Lulus';
    if (status == 'tolak') return 'Tolak';
    return 'Pending';
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return '';
    final local = dt.toLocal();
    const months = ['Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun', 'Jul', 'Ogo', 'Sep', 'Okt', 'Nov', 'Dis'];
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${months[local.month - 1]}, $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const IpantauAppBar(title: 'Semak Laporan Pekerja'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppTheme.navy,
          child: _loading
              ? const ShimmerList()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(AppTheme.md, AppTheme.md, AppTheme.md, 100),
                  children: [
                    if (_error != null) ...[
                      _errorBanner(),
                      const SizedBox(height: AppTheme.md),
                    ],
                    if (_laporan.isEmpty)
                      _emptyState()
                    else
                      ..._laporan.map(_laporanCard),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.lg),
            decoration: BoxDecoration(
              color: AppTheme.navy.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fact_check_outlined, size: 40, color: AppTheme.navy),
          ),
          const SizedBox(height: AppTheme.md),
          const Text(
            'Tiada laporan untuk disemak',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: AppTheme.xs),
          const Text(
            'Laporan daripada pekerja akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _laporanCard(Map<String, dynamic> item) {
    final status = item['status']?.toString() ?? 'pending';
    final statusColor = _statusColor(status);
    final statusBg = _statusBg(status);
    final tapakNama = item['tapak_nama']?.toString() ?? '-';
    final pekerja = item['pekerja_nama']?.toString() ?? '-';
    final date = _formatDate(item['submitted_at']);
    final ringkasan = item['ringkasan']?.toString() ?? '';
    final jumlahGambar = (item['jumlah_gambar'] as num?)?.toInt() ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.sm + 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Material(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              final refreshed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => _SemakLaporanDetailScreen(laporan: item)),
              );
              if (refreshed == true && mounted) _load();
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(AppTheme.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          tapakNama,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (date.isNotEmpty) ...[
                        const SizedBox(width: AppTheme.sm),
                        Text(date, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                      ],
                      const SizedBox(width: AppTheme.sm),
                      _statusBadge(label: _statusLabel(status), color: statusColor, bg: statusBg),
                    ],
                  ),
                  const SizedBox(height: AppTheme.xs),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 13, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        pekerja,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                      if (jumlahGambar > 0) ...[
                        const SizedBox(width: AppTheme.sm),
                        const Icon(Icons.photo_library_outlined, size: 13, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '$jumlahGambar gambar',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ],
                  ),
                  if (ringkasan.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.sm - 2),
                    Text(
                      ringkasan,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.4),
                    ),
                  ],
                  const SizedBox(height: AppTheme.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Ketuk untuk semak →',
                        style: TextStyle(fontSize: 10, color: AppTheme.navy.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge({required String label, required Color color, required Color bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _errorBanner() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.sm + 4),
      decoration: BoxDecoration(
        color: AppTheme.errorLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 16),
          const SizedBox(width: AppTheme.sm),
          Expanded(
            child: Text(_error!, style: const TextStyle(fontSize: 12, color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _SemakLaporanDetailScreen extends StatefulWidget {
  const _SemakLaporanDetailScreen({required this.laporan});

  final Map<String, dynamic> laporan;

  @override
  State<_SemakLaporanDetailScreen> createState() => _SemakLaporanDetailScreenState();
}

class _SemakLaporanDetailScreenState extends State<_SemakLaporanDetailScreen> {
  final TextEditingController _notaController = TextEditingController();
  bool _submitting = false;
  String? _error;

  bool _loadingGambar = true;
  List<Map<String, dynamic>> _gambar = [];

  @override
  void initState() {
    super.initState();
    _notaController.text = widget.laporan['nota_admin']?.toString() ?? '';
    _loadGambar();
  }

  @override
  void dispose() {
    _notaController.dispose();
    super.dispose();
  }

  Future<void> _loadGambar() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() => _loadingGambar = false);
      return;
    }

    final laporanId = (widget.laporan['id'] as num).toInt();
    final res = await ApiService.getGambarLaporan(token: token, laporanId: laporanId);
    if (!mounted) return;

    setState(() {
      _loadingGambar = false;
      if (res['success'] == true) {
        final data = (res['data'] as List?) ?? [];
        _gambar = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    });
  }

  Future<void> _semak(String status) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final laporanId = (widget.laporan['id'] as num).toInt();
    final res = await ApiService.semakLaporan(
      token: token,
      laporanId: laporanId,
      status: status,
      nota: _notaController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Berjaya.')),
      );
      Navigator.pop(context, true);
    } else {
      setState(() => _error = res['message'] ?? 'Gagal semak laporan.');
    }
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '-';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return '-';
    final local = dt.toLocal();
    const months = ['Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun', 'Jul', 'Ogo', 'Sep', 'Okt', 'Nov', 'Dis'];
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${months[local.month - 1]}, $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final laporan = widget.laporan;
    final status = laporan['status']?.toString() ?? 'pending';
    final isReviewed = status == 'lulus' || status == 'tolak';
    final tapakNama = laporan['tapak_nama']?.toString() ?? '-';
    final pekerja = laporan['pekerja_nama']?.toString() ?? '-';
    final ringkasan = laporan['ringkasan']?.toString() ?? '';
    final submittedAt = _formatDate(laporan['submitted_at']);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const IpantauAppBar(title: 'Semak Laporan'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.md),
          children: [
            // Info card
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(Icons.domain_outlined, 'Tapak', tapakNama),
                  const SizedBox(height: AppTheme.sm),
                  _infoRow(Icons.person_outline, 'Pekerja', pekerja),
                  const SizedBox(height: AppTheme.sm),
                  _infoRow(Icons.schedule_outlined, 'Dihantar', submittedAt),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.md),

            // Ringkasan kerja
            if (ringkasan.isNotEmpty) ...[
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ringkasan Kerja', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: AppTheme.sm),
                    Text(
                      ringkasan,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.md),
            ],

            // Gambar section
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gambar Kerja', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: AppTheme.sm),
                  if (_loadingGambar)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppTheme.lg),
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.navy),
                      ),
                    )
                  else if (_gambar.isEmpty)
                    const Text(
                      'Tiada gambar dilampirkan.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    )
                  else
                    SizedBox(
                      height: 130,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _gambar.length,
                        separatorBuilder: (_, _) => const SizedBox(width: AppTheme.sm),
                        itemBuilder: (_, i) {
                          final url = _gambar[i]['url']?.toString() ?? '';
                          return GestureDetector(
                            onTap: () => _showImageDialog(url),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              child: Image.network(
                                url,
                                width: 130,
                                height: 130,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 130,
                                  height: 130,
                                  color: AppTheme.border,
                                  child: const Icon(Icons.broken_image_outlined, color: AppTheme.textMuted),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.md),

            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nota Penyelia', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: AppTheme.sm),
                  TextField(
                    controller: _notaController,
                    maxLines: 4,
                    enabled: !isReviewed,
                    decoration: InputDecoration(
                      hintText: isReviewed ? '' : 'Contoh: Kerja perlu diulang di bahagian barat...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: AppTheme.sm),
              _errorBanner(),
            ],

            const SizedBox(height: AppTheme.lg),

            if (isReviewed) ...[
              _reviewedBanner(status),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _submitting ? null : () => _semak('tolak'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: const BorderSide(color: AppTheme.error),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                        ),
                        child: _submitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.error))
                            : const Text('Tolak', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.md),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : () => _semak('lulus'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                        ),
                        child: _submitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Lulus', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppTheme.lg),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 60),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reviewedBanner(String status) {
    final isLulus = status == 'lulus';
    final color = isLulus ? AppTheme.success : AppTheme.error;
    final bg = isLulus ? AppTheme.successLight : AppTheme.errorLight;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(isLulus ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color, size: 20),
          const SizedBox(width: AppTheme.sm),
          Text(
            isLulus ? 'Laporan ini telah diluluskan.' : 'Laporan ini telah ditolak.',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppTheme.textMuted),
        const SizedBox(width: AppTheme.sm - 2),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _errorBanner() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.sm + 4),
      decoration: BoxDecoration(
        color: AppTheme.errorLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 16),
          const SizedBox(width: AppTheme.sm),
          Expanded(child: Text(_error!, style: const TextStyle(fontSize: 12, color: AppTheme.error))),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(AppTheme.md),
      child: child,
    );
  }
}
