import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shimmer_loading.dart';

class PantauPekerjaScreen extends StatefulWidget {
  const PantauPekerjaScreen({super.key});

  @override
  State<PantauPekerjaScreen> createState() => _PantauPekerjaScreenState();
}

class _PantauPekerjaScreenState extends State<PantauPekerjaScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() {
        _loading = false;
        _error = 'Tiada sesi log masuk.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await ApiService.getPekerjaKehadiranHariIni(token);
    if (!mounted) return;
    if (res['success'] == true && res['data'] is List) {
      final list = (res['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      setState(() {
        _rows = list;
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error = res['message']?.toString() ?? 'Gagal memuatkan data.';
      });
    }
  }

  String _formatMasa(dynamic iso) {
    if (iso == null) return '';
    final dt = iso is String ? DateTime.tryParse(iso) : (iso is DateTime ? iso : null);
    if (dt == null) return '';
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _initials(String nama) {
    final parts = nama.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  List<Map<String, dynamic>> get _filteredRows {
    final q = _searchCtrl.text.toLowerCase().trim();
    final all = q.isEmpty
        ? List<Map<String, dynamic>>.from(_rows)
        : _rows
            .where((r) =>
                (r['nama']?.toString() ?? '').toLowerCase().contains(q))
            .toList();

    final hadir = all.where((r) => r['hadir'] == true).toList()
      ..sort((a, b) {
        final at = DateTime.tryParse(a['masa_checkin']?.toString() ?? '');
        final bt = DateTime.tryParse(b['masa_checkin']?.toString() ?? '');
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return at.compareTo(bt);
      });

    final belum = all.where((r) => r['hadir'] != true).toList()
      ..sort((a, b) =>
          (a['nama']?.toString() ?? '').compareTo(b['nama']?.toString() ?? ''));

    return [...hadir, ...belum];
  }

  void _showExportSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(ctx).padding.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Eksport Kehadiran',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Muat turun rekod kehadiran hari ini',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            _exportOption(
              iconBg: const Color(0xFFFEE2E2),
              iconText: 'PDF',
              iconTextColor: const Color(0xFFDC2626),
              title: 'Laporan PDF',
              subtitle: 'Untuk cetakan dan rekod rasmi',
              onTap: () {
                Navigator.pop(ctx);
                _exportPdf();
              },
            ),
            const SizedBox(height: 8),
            _exportOption(
              iconBg: const Color(0xFFDCFCE7),
              iconText: 'CSV',
              iconTextColor: const Color(0xFF166534),
              title: 'Fail CSV',
              subtitle: 'Untuk buka di Excel / Sheets',
              onTap: () {
                Navigator.pop(ctx);
                _exportCsv();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _exportOption({
    required Color iconBg,
    required String iconText,
    required Color iconTextColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE8EFF8)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  iconText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: iconTextColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _sortedForExport() {
    final hadir = _rows.where((r) => r['hadir'] == true).toList()
      ..sort((a, b) {
        final at = DateTime.tryParse(a['masa_checkin']?.toString() ?? '');
        final bt = DateTime.tryParse(b['masa_checkin']?.toString() ?? '');
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return at.compareTo(bt);
      });
    final belum = _rows.where((r) => r['hadir'] != true).toList()
      ..sort((a, b) =>
          (a['nama']?.toString() ?? '').compareTo(b['nama']?.toString() ?? ''));
    return [...hadir, ...belum];
  }

  static const _monthsBM = [
    'Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun',
    'Jul', 'Ogo', 'Sep', 'Okt', 'Nov', 'Dis',
  ];

  Future<void> _exportPdf() async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Menghasilkan laporan PDF...'),
        duration: Duration(seconds: 3),
      ),
    );

    try {
      final sorted = _sortedForExport();
      final hadirCount = sorted.where((r) => r['hadir'] == true).length;
      final totalCount = sorted.length;
      final pct = totalCount > 0 ? (hadirCount * 100 ~/ totalCount) : 0;
      final syarikat = context.read<AuthProvider>().pengguna?['nama_syarikat']?.toString() ?? '-';

      final now = DateTime.now();
      final dateStr = '${now.day} ${_monthsBM[now.month - 1]} ${now.year}';
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final tableData = sorted.asMap().entries.map((e) {
        final i = e.key;
        final r = e.value;
        final isHadir = r['hadir'] == true;
        final masuk = _formatMasa(r['masa_checkin']);
        final keluar = _formatMasa(r['masa_checkout']);
        return [
          '${i + 1}',
          r['nama']?.toString() ?? '-',
          r['tapak_nama']?.toString() ?? '—',
          masuk.isNotEmpty ? masuk : '—',
          keluar.isNotEmpty ? keluar : '—',
          isHadir ? 'Hadir' : 'Belum Hadir',
        ];
      }).toList();

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (ctx) => [
            pw.Text(
              'LAPORAN KEHADIRAN HARIAN — iPANTAU',
              style: pw.TextStyle(
                  fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text('Tarikh: $dateStr'),
            pw.Text('Syarikat: $syarikat'),
            pw.SizedBox(height: 10),
            pw.Text(
              'Ringkasan: $hadirCount daripada $totalCount pekerja hadir ($pct%)',
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: [
                'No.',
                'Nama Pekerja',
                'Tapak',
                'Masa Masuk',
                'Masa Keluar',
                'Status',
              ],
              data: tableData,
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey100),
              cellStyle: const pw.TextStyle(fontSize: 9),
              oddRowDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey100),
              columnWidths: {
                0: const pw.FixedColumnWidth(28),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FixedColumnWidth(52),
                4: const pw.FixedColumnWidth(52),
                5: const pw.FixedColumnWidth(60),
              },
            ),
            pw.SizedBox(height: 24),
            pw.Text(
              'Dijana oleh iPANTAU pada $dateStr, $timeStr',
              style: const pw.TextStyle(
                  fontSize: 8, color: PdfColors.grey),
            ),
          ],
        ),
      );

      final bytes = await doc.save();
      final dir = await getTemporaryDirectory();
      final slug = '${now.day}_${_monthsBM[now.month - 1]}_${now.year}';
      final file = File('${dir.path}/laporan_kehadiran_$slug.pdf');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Laporan Kehadiran - $dateStr',
      );
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
              content: Text('Gagal hasilkan PDF. Cuba lagi.')),
        );
      }
    }
  }

  Future<void> _exportCsv() async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Menghasilkan fail CSV...'),
        duration: Duration(seconds: 3),
      ),
    );

    try {
      final sorted = _sortedForExport();
      final csv = StringBuffer();
      csv.write('﻿'); // UTF-8 BOM for Excel compatibility
      csv.writeln('Nama,Status,Tapak,Masa Masuk,Masa Keluar');

      for (final r in sorted) {
        final isHadir = r['hadir'] == true;
        final nama = (r['nama']?.toString() ?? '-').replaceAll('"', '""');
        final tapak =
            (r['tapak_nama']?.toString() ?? '-').replaceAll('"', '""');
        final masuk = _formatMasa(r['masa_checkin']);
        final keluar = _formatMasa(r['masa_checkout']);
        csv.writeln([
          '"$nama"',
          isHadir ? 'Hadir' : 'Belum Hadir',
          '"$tapak"',
          masuk.isNotEmpty ? masuk : '-',
          keluar.isNotEmpty ? keluar : '-',
        ].join(','));
      }

      final now = DateTime.now();
      final slug = '${now.day}_${_monthsBM[now.month - 1]}_${now.year}';
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/kehadiran_$slug.csv');
      await file.writeAsString(csv.toString(), encoding: utf8);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: 'Kehadiran Pekerja',
      );
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
              content: Text('Gagal hasilkan CSV. Cuba lagi.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: AppTheme.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Pantau Pekerja',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: 'Eksport',
            onPressed: _rows.isEmpty ? null : _showExportSheet,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifikasi',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tiada notifikasi baharu.')),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppTheme.navy,
          onRefresh: _load,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _rows.isEmpty) return const ShimmerList();

    if (_error != null && _rows.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [const SizedBox(height: 48), _errorBanner()],
      );
    }

    if (_rows.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [const SizedBox(height: 80), _emptyState()],
      );
    }

    final filtered = _filteredRows;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 12),
        _buildSearchBar(),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 32),
            child: Center(
              child: Text(
                'Tiada pekerja dijumpai.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
            ),
          )
        else
          ...filtered.map(_workerCard),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final total = _rows.length;
    final hadir = _rows.where((r) => r['hadir'] == true).length;
    final pct = total > 0 ? (hadir * 100 ~/ total) : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8EFF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kehadiran Hari Ini',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$hadir daripada $total pekerja',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.navy,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$pct%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchCtrl,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Cari nama pekerja...',
        hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
        prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textMuted),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE8EFF8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE8EFF8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.navy),
        ),
      ),
    );
  }

  Widget _workerCard(Map<String, dynamic> r) {
    final hadir = r['hadir'] == true;
    final nama = r['nama']?.toString() ?? '-';
    final tapakNama = r['tapak_nama']?.toString() ?? '';
    final masuk = _formatMasa(r['masa_checkin']);
    final keluar = _formatMasa(r['masa_checkout']);

    return Opacity(
      opacity: hadir ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE8EFF8), width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Square avatar with rounded corners
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _initials(nama),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Info column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + status row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          nama,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (hadir) ...[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Hadir',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ] else
                        const Text(
                          'Belum hadir',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Tapak or placeholder
                  Text(
                    hadir
                        ? (tapakNama.isNotEmpty ? tapakNama : '—')
                        : 'Belum check-in hari ini',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Time row — hadir only
                  if (hadir) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Text(
                          'Masuk: ',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textMuted),
                        ),
                        Text(
                          masuk.isNotEmpty ? masuk : '—',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Keluar: ',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textMuted),
                        ),
                        Text(
                          keluar.isNotEmpty ? keluar : '—',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.navy.withValues(alpha: 0.06),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.people_outline,
            size: 40,
            color: AppTheme.navy,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tiada pekerja',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tiada pekerja (kontraktor) dalam\nsyarikat anda buat masa ini.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textMuted,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _errorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 16),
          const SizedBox(width: 8),
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
