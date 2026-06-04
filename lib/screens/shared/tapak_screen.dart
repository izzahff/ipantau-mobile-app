import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/ipantau_app_bar.dart';
import 'checkin_screen.dart';

enum _TapakFilter { semua, berjalan, selesai }

class TapakScreen extends StatefulWidget {
  const TapakScreen({super.key, required this.appBarColor});

  final Color appBarColor;

  @override
  State<TapakScreen> createState() => _TapakScreenState();
}

class _TapakScreenState extends State<TapakScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _tapak = [];
  _TapakFilter _filter = _TapakFilter.semua;

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

    final res = await ApiService.getTapakSaya(token);
    if (!mounted) return;

    if (res['success'] == true) {
      final list = (res['data'] as List?) ?? [];
      setState(() {
        _tapak =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error = res['message']?.toString() ?? 'Gagal muatkan tapak.';
      });
    }
  }

  static String _statusKey(Map<String, dynamic> t) {
    final s = (t['status'] ?? 'aktif').toString().toLowerCase();
    if (s == 'selesai' || s == 'completed' || s == 'tamat') return 'selesai';
    if (s == 'menunggu' || s == 'pending') return 'menunggu';
    return 'aktif';
  }

  static String _statusLabel(String key) {
    switch (key) {
      case 'selesai':
        return 'Selesai';
      case 'menunggu':
        return 'Menunggu';
      default:
        return 'Aktif';
    }
  }

  static Color _statusColor(String key) {
    switch (key) {
      case 'selesai':
        return AppTheme.textSecondary;
      case 'menunggu':
        return AppTheme.gold;
      default:
        return AppTheme.navyLight;
    }
  }

  static Color _statusBg(String key) {
    switch (key) {
      case 'selesai':
        return AppTheme.border;
      case 'menunggu':
        return AppTheme.goldLight;
      default:
        return AppTheme.navyLight;
    }
  }

  List<Map<String, dynamic>> get _filtered {
    switch (_filter) {
      case _TapakFilter.semua:
        return _tapak;
      case _TapakFilter.berjalan:
        return _tapak.where((t) => _statusKey(t) != 'selesai').toList();
      case _TapakFilter.selesai:
        return _tapak.where((t) => _statusKey(t) == 'selesai').toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: IpantauAppBar(
        title: 'Tapak',
        backgroundColor: widget.appBarColor,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppTheme.navy,
          child: _loading
              ? const ShimmerList()
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.md,
                      ),
                      child: _filterChipsRow(),
                    ),
                    const SizedBox(height: AppTheme.sm + 4),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.md,
                          vertical: AppTheme.sm,
                        ),
                        child: _errorBanner(),
                      ),
                    if (_filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 64),
                        child: Center(
                          child: Text(
                            'Tiada tapak untuk tapisan ini.',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._filtered.map(_tapakCard),
                    const SizedBox(height: AppTheme.lg),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _filterChipsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(_TapakFilter.semua, 'Semua'),
          const SizedBox(width: AppTheme.sm),
          _filterChip(_TapakFilter.berjalan, 'Berjalan'),
          const SizedBox(width: AppTheme.sm),
          _filterChip(_TapakFilter.selesai, 'Selesai'),
        ],
      ),
    );
  }

  Widget _filterChip(_TapakFilter f, String label) {
    final sel = _filter == f;
    return GestureDetector(
      onTap: () => setState(() => _filter = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppTheme.navy : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.navy,
            width: sel ? 0 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: sel ? Colors.white : AppTheme.navy,
          ),
        ),
      ),
    );
  }

  Widget _tapakCard(Map<String, dynamic> t) {
    final key = _statusKey(t);
    final color = _statusColor(key);
    final bg = _statusBg(key);
    final nama = t['nama_tapak']?.toString() ?? '-';
    final kod = t['kod_tapak']?.toString() ?? '-';
    final id = (t['id'] as num).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Material(
          color: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppTheme.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CheckinScreen(
                    initialTapakId: id,
                    appBarColor: widget.appBarColor,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.md,
                vertical: AppTheme.sm + 6,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.sm + 2),
                    decoration: BoxDecoration(
                      color: AppTheme.navy.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      color: AppTheme.navy,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.sm + 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nama,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          kod,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: bg.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                      border: Border.all(color: color.withValues(alpha: 0.30)),
                    ),
                    child: Text(
                      _statusLabel(key),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.xs),
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
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
