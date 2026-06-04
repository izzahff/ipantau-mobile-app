import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/ipantau_app_bar.dart';
import 'gambar_screen.dart';
import 'laporan_butiran_screen.dart';

class LaporanSayaScreen extends StatefulWidget {
  const LaporanSayaScreen(
      {super.key, this.appBarColor, this.showBackButton = false});

  final Color? appBarColor;
  final bool showBackButton;

  @override
  State<LaporanSayaScreen> createState() => _LaporanSayaScreenState();
}

class _LaporanSayaScreenState extends State<LaporanSayaScreen> {
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

    final res = await ApiService.getLaporanSaya(token);
    if (!mounted) return;

    if (res['success'] == true) {
      final data = (res['data'] as List?) ?? [];
      setState(() {
        _laporan =
            data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = false;
      _error = res['message'] ?? 'Gagal memuatkan laporan.';
    });
  }

  static String _fmtDate(dynamic raw) {
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

  static Color _stTextColor(String s) {
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

  static Color _stBgColor(String s) {
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

  static String _stLabel(String s) {
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

  Widget _badge(String status) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: IpantauAppBar(
        title: 'Laporan Saya',
        backgroundColor: widget.appBarColor ?? AppTheme.navy,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  final role =
                      context.read<AuthProvider>().pengguna?['peranan']
                              as String? ??
                          'kontraktor';
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    role == 'penyelia'
                        ? '/penyelia/dashboard'
                        : '/kontraktor/dashboard',
                    (route) => false,
                  );
                },
              )
            : null,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppTheme.navy,
          child: _loading
              ? const ShimmerList()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    if (_error != null) ...[
                      _errorBanner(),
                      const SizedBox(height: 12),
                    ],
                    if (_laporan.isEmpty)
                      _emptyState()
                    else
                      ..._laporan.map(_laporanCard),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GambarScreen()),
          );
          if (mounted) _load();
        },
        backgroundColor: AppTheme.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.camera_alt_outlined),
        label: const Text(
          'Laporan Baru',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _laporanCard(Map<String, dynamic> l) {
    final status = l['status']?.toString() ?? 'pending';
    final kodTapak = l['kod_tapak']?.toString() ?? '';
    final tapakNama = l['tapak_nama']?.toString() ?? '-';
    final ringkasan = l['ringkasan']?.toString() ?? '';
    final date = _fmtDate(l['submitted_at']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LaporanButiranScreen(
                laporan: l,
                allLaporan: _laporan,
              ),
            ),
          );
          if (mounted) _load();
        },
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: const Color(0xFFE8EFF8), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: badge + kod tapak + date
              Row(
                children: [
                  _badge(status),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      kodTapak,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  Text(
                    date,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Row 2: tapak name
              Text(
                tapakNama,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F1B35),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              // Row 3: ringkasan preview
              Text(
                ringkasan.isNotEmpty ? ringkasan : 'Tiada ringkasan',
                style: TextStyle(
                  fontSize: 13,
                  color: ringkasan.isNotEmpty
                      ? const Color(0xFF4A5568)
                      : const Color(0xFFCBD5E1),
                  fontStyle: ringkasan.isEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Row 4: "Lihat ›" link
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Lihat ›',
                  style: TextStyle(
                      fontSize: 11, color: Color(0xFF3B82F6)),
                ),
              ),
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
            child: const Icon(
              Icons.description_outlined,
              size: 40,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: AppTheme.md),
          const Text(
            'Tiada laporan lagi',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.xs),
          const Text(
            'Hantar laporan tapak pertama anda\nmenggunakan butang di bawah.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
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
            child: Text(
              _error!,
              style: const TextStyle(fontSize: 12, color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
