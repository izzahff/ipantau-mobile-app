import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ipantau_app_bar.dart';
import '../shared/checkin_screen.dart';
import '../shared/profil_screen.dart';
import 'pantau_pekerja_screen.dart';
import 'semak_laporan_screen.dart';

class PenyeliaDashboard extends StatefulWidget {
  const PenyeliaDashboard({super.key});

  @override
  State<PenyeliaDashboard> createState() => _PenyeliaDashboardState();
}

class _PenyeliaDashboardState extends State<PenyeliaDashboard> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _checkinHariIni;
  List<Map<String, dynamic>> _tapakSaya = [];
  List<Map<String, dynamic>> _laporanTerkini = [];
  List<Map<String, dynamic>> _aktivitiTerkini = [];

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

    final resTapak = await ApiService.getTapakSaya(token);
    final resCheckin = await ApiService.getCheckinHariIni(token);
    final resLaporan = await ApiService.getLaporanSaya(token);

    if (!mounted) return;

    if (resTapak['success'] != true || resCheckin['success'] != true) {
      setState(() {
        _loading = false;
        _error = (resTapak['success'] != true ? resTapak['message'] : null) ??
            (resCheckin['success'] != true ? resCheckin['message'] : null) ??
            'Gagal muatkan dashboard.';
      });
      return;
    }

    final tapakList = (resTapak['data'] as List?) ?? [];
    final checkinData = resCheckin['data'];
    final tapak =
        tapakList.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    List<Map<String, dynamic>> laporan = [];
    if (resLaporan['success'] == true) {
      final list = (resLaporan['data'] as List?) ?? [];
      laporan = list
          .take(3)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    setState(() {
      _tapakSaya = tapak;
      _checkinHariIni = checkinData == null
          ? null
          : Map<String, dynamic>.from(checkinData as Map);
      _laporanTerkini = laporan;
      _loading = false;
    });

    _loadAktivitiTerkini();
  }

  Future<void> _loadAktivitiTerkini() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final res = await ApiService.getAktivitiTerkini(token);
    if (!mounted) return;
    if (res['success'] == true) {
      final data = (res['data'] as List?) ?? [];
      setState(() {
        _aktivitiTerkini =
            data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
    }
  }

  int _countLaporanPending() {
    return _laporanTerkini.where((l) {
      final s = (l['status'] ?? '').toString().toLowerCase();
      return s == 'pending' || s == 'menunggu';
    }).length;
  }

  String _todayLabel() {
    final d = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ogo', 'Sep', 'Okt', 'Nov', 'Dis'
    ];
    const days = ['Ahad', 'Isnin', 'Sel', 'Rab', 'Kha', 'Jum', 'Sab'];
    return '${days[d.weekday % 7]}, ${d.day} ${months[d.month - 1]}';
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return raw.length > 5 ? raw.substring(0, 5) : raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().pengguna;
    final hasCheckin = _checkinHariIni != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const IpantauAppBar(title: 'Utama'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppTheme.navy,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildHeader(user: user, hasCheckin: hasCheckin),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.md,
                  AppTheme.md,
                  AppTheme.md,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      _errorBanner(),
                      const SizedBox(height: AppTheme.md),
                    ],
                    if (_loading) ...[
                      const LinearProgressIndicator(
                        minHeight: 4,
                        color: AppTheme.navy,
                      ),
                      const SizedBox(height: AppTheme.md),
                    ],
                    _buildStatsRow(),
                    const SizedBox(height: AppTheme.lg),
                    _sectionTitle('Tindakan Pantas'),
                    const SizedBox(height: AppTheme.sm + 4),
                    _buildQuickActionsGrid(),
                    const SizedBox(height: AppTheme.lg),
                    _sectionTitle('Aktiviti Terkini'),
                    const SizedBox(height: AppTheme.sm + 4),
                    _buildAktivitiTerkini(),
                    const SizedBox(height: AppTheme.lg),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({
    required Map<String, dynamic>? user,
    required bool hasCheckin,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.lg,
        AppTheme.lg,
        AppTheme.lg,
        AppTheme.xl,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.navy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppTheme.radiusXl),
          bottomRight: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat datang,',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  user?['nama'] ?? 'Penyelia',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?['nama_syarikat'] ?? '',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _todayLabel(),
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: AppTheme.sm),
              _checkinChip(hasCheckin: hasCheckin),
            ],
          ),
        ],
      ),
    );
  }

  Widget _checkinChip({required bool hasCheckin}) {
    if (hasCheckin) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.gold,
          borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        ),
        child: const Text(
          'Hadir',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        border: Border.all(color: Colors.white54),
      ),
      child: const Text(
        'Belum Check-in',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard('${_tapakSaya.length}', 'Tapak Dipantau'),
        ),
        const SizedBox(width: AppTheme.sm),
        Expanded(
          child: _statCard(
            _checkinHariIni != null ? '1' : '0',
            'Pekerja Hadir',
          ),
        ),
        const SizedBox(width: AppTheme.sm),
        Expanded(
          child: _statCard('${_countLaporanPending()}', 'Laporan Pending'),
        ),
      ],
    );
  }

  Widget _statCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppTheme.sm + 4,
      mainAxisSpacing: AppTheme.sm + 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        _actionCard(
          Icons.location_on_outlined,
          'GPS Check-in',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CheckinScreen()),
          ),
        ),
        _actionCard(
          Icons.people_outline,
          'Pantau Pekerja',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PantauPekerjaScreen()),
          ),
        ),
        _actionCard(
          Icons.fact_check_outlined,
          'Semak Laporan',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SemakLaporanScreen()),
          ),
        ),
        _actionCard(
          Icons.person_outline_rounded,
          'Profil',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfilScreen()),
          ),
        ),
      ],
    );
  }

  Widget _actionCard(IconData icon, String label, VoidCallback onTap) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: const BorderSide(color: AppTheme.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.sm + 2),
                  decoration: BoxDecoration(
                    color: AppTheme.navy.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppTheme.navy, size: 20),
                ),
                const SizedBox(height: AppTheme.sm),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAktivitiTerkini() {
    if (_aktivitiTerkini.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.lg),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.cardShadow,
        ),
        child: const Center(
          child: Text(
            'Tiada aktiviti hari ini.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          for (int i = 0; i < _aktivitiTerkini.length; i++) ...[
            _aktivitiItemRow(_aktivitiTerkini[i]),
            if (i < _aktivitiTerkini.length - 1)
              Divider(height: 1, color: AppTheme.border),
          ],
        ],
      ),
    );
  }

  Widget _aktivitiItemRow(Map<String, dynamic> item) {
    final jenis = item['jenis']?.toString() ?? '';
    final tapakNama = item['tapak_nama']?.toString() ?? '-';
    final masa = _formatTime(item['masa']?.toString());

    if (jenis == 'checkin') {
      final dalamGeofence = item['dalam_geofence'] == true;
      final masaCheckout = item['masa_checkout'];
      final iconColor =
          dalamGeofence ? AppTheme.success : AppTheme.warning;
      final statusText =
          dalamGeofence ? 'Dalam kawasan geofence' : 'Di luar kawasan';

      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.md,
          vertical: AppTheme.sm + 4,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.sm),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.login_rounded, color: iconColor, size: 18),
            ),
            const SizedBox(width: AppTheme.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Check-in: $tapakNama',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '$masa · $statusText',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textMuted),
                  ),
                  if (masaCheckout != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Check-out: ${_formatTime(masaCheckout.toString())}',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (jenis == 'semakan') {
      final pekerja = item['pekerja_nama']?.toString() ?? '-';
      final status = item['status']?.toString() ?? '';
      final isLulus = status == 'lulus';
      final statusColor = isLulus ? AppTheme.success : AppTheme.error;
      final statusLabel = isLulus ? 'Lulus' : 'Ditolak';

      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.md,
          vertical: AppTheme.sm + 4,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.sm),
              decoration: BoxDecoration(
                color: AppTheme.navy.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fact_check_outlined,
                color: AppTheme.navy,
                size: 18,
              ),
            ),
            const SizedBox(width: AppTheme.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Semak laporan: $pekerja',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '$tapakNama · $statusLabel',
                    style: TextStyle(fontSize: 11, color: statusColor),
                  ),
                  Text(
                    masa,
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
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

