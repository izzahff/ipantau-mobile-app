import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ipantau_app_bar.dart';
import '../shared/checkin_screen.dart';
import '../shared/gambar_screen.dart';
import '../shared/laporan_saya_screen.dart';
import '../shared/profil_screen.dart';

class KontraktorDashboard extends StatefulWidget {
  const KontraktorDashboard({super.key});

  @override
  State<KontraktorDashboard> createState() => _KontraktorDashboardState();
}

class _KontraktorDashboardState extends State<KontraktorDashboard> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _checkinHariIni;
  List<Map<String, dynamic>> _tapakSaya = [];
  List<Map<String, dynamic>> _laporanTerkini = [];

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

  int _countStatus(String key) =>
      _tapakSaya.where((t) => _statusKey(t) == key).length;

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
                    _buildRecentActivity(hasCheckin: hasCheckin),
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
                  user?['nama'] ?? 'Kontraktor',
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
          child: _statCard('${_countStatus('aktif')}', 'Tapak Aktif'),
        ),
        const SizedBox(width: AppTheme.sm),
        Expanded(
          child: _statCard('${_laporanTerkini.length}', 'Laporan Hantar'),
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
          Icons.camera_alt_outlined,
          'Ambil Gambar',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GambarScreen()),
          ),
        ),
        _actionCard(
          Icons.description_outlined,
          'Laporan Saya',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LaporanSayaScreen()),
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

  Widget _buildRecentActivity({required bool hasCheckin}) {
    final items = <_ActivityItem>[];

    if (hasCheckin) {
      final ci = _checkinHariIni!;
      final within = ci['dalam_geofence'] == true;
      items.add(_ActivityItem(
        icon: Icons.location_on_outlined,
        iconColor: within ? AppTheme.success : AppTheme.warning,
        title: 'Check-in hari ini',
        subtitle: within ? 'Dalam kawasan geofence' : 'Di luar kawasan geofence',
        timestamp: _formatTime(ci['waktu_masuk']?.toString()),
        statusLabel: within ? 'Sah' : 'Luar',
        statusColor: within ? AppTheme.success : AppTheme.warning,
        statusBg: within ? AppTheme.successLight : AppTheme.warningLight,
      ));
    }

    for (final l in _laporanTerkini.take(2)) {
      final status = (l['status'] ?? 'hantar').toString();
      final tapakLabel =
          l['nama_tapak']?.toString() ?? l['tapak_id']?.toString() ?? '-';
      items.add(_ActivityItem(
        icon: Icons.description_outlined,
        iconColor: AppTheme.navy,
        title: 'Laporan tapak',
        subtitle: tapakLabel,
        timestamp: _formatTime(
            l['created_at']?.toString() ?? l['tarikh']?.toString()),
        statusLabel: status,
        statusColor: AppTheme.navy,
        statusBg: AppTheme.border,
      ));
    }

    if (items.isEmpty) {
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
            'Tiada aktiviti terkini.',
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
          for (int i = 0; i < items.length; i++) ...[
            _activityRow(items[i]),
            if (i < items.length - 1)
              Divider(height: 1, color: AppTheme.border),
          ],
        ],
      ),
    );
  }

  Widget _activityRow(_ActivityItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.md,
        vertical: AppTheme.sm + 4,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.sm),
            decoration: BoxDecoration(
              color: item.iconColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.iconColor, size: 18),
          ),
          const SizedBox(width: AppTheme.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.timestamp,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.statusBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                ),
                child: Text(
                  item.statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: item.statusColor,
                  ),
                ),
              ),
            ],
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

class _ActivityItem {
  const _ActivityItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBg,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String timestamp;
  final String statusLabel;
  final Color statusColor;
  final Color statusBg;
}
