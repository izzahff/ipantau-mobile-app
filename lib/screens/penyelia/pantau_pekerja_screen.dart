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
import '../../widgets/v2/dash_widgets.dart';
import '../../widgets/v2/ui.dart';

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
  String? _tapak; // null = semua tapak

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


  List<Map<String, dynamic>> get _filteredRows {
    final q = _searchCtrl.text.toLowerCase().trim();
    final all = _siteRows
        .where((r) => q.isEmpty || (r['nama']?.toString() ?? '').toLowerCase().contains(q))
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


  List<String> get _tapakNames =>
      _rows.map((r) => r['tapak_nama']?.toString()).whereType<String>().where((s) => s.isNotEmpty).toSet().toList()..sort();

  List<Map<String, dynamic>> get _siteRows =>
      _tapak == null ? _rows : _rows.where((r) => r['tapak_nama']?.toString() == _tapak).toList();

  void _showExportSheet() {
    showIpSheet<void>(
      context,
      title: 'Eksport Kehadiran',
      builder: (ctx) {
        final c = ctx.ip;
        Widget opt(String badge, IpTone tone, String title, String sub, VoidCallback onTap) {
          final (bg, fg) = toneColors(ctx, tone);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: IpCard(
              pad: 14,
              onTap: () {
                Navigator.pop(ctx);
                onTap();
              },
              child: Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Text(badge, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: fg)),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text)),
                    Text(sub, style: TextStyle(fontSize: 12.5, color: c.text3)),
                  ]),
                ),
                IpIcon('chevronRight', size: 18, color: c.text3),
              ]),
            ),
          );
        }

        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text('Muat turun rekod kehadiran hari ini', style: TextStyle(fontSize: 13, color: c.text2)),
          ),
          opt('PDF', IpTone.crimson, 'Laporan PDF', 'Untuk cetakan dan rekod rasmi', _exportPdf),
          opt('CSV', IpTone.emerald, 'Fail CSV', 'Untuk buka di Excel / Sheets', _exportCsv),
        ]);
      },
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
    showIpToast(context, 'Menghasilkan laporan PDF…', tone: IpToastTone.info);

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
        showIpToast(context, 'Gagal hasilkan PDF. Cuba lagi.', tone: IpToastTone.danger);
      }
    }
  }

  Future<void> _exportCsv() async {
    showIpToast(context, 'Menghasilkan fail CSV…', tone: IpToastTone.info);

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
        showIpToast(context, 'Gagal hasilkan CSV. Cuba lagi.', tone: IpToastTone.danger);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final sites = _tapakNames;
    final filtered = _filteredRows;
    final all = _siteRows;
    final present = all.where((r) => r['hadir'] == true).length;
    final pct = all.isEmpty ? 0 : (present * 100 ~/ all.length);

    return IpPushedScaffold(
      title: 'Pantau Pekerja',
      right: Row(mainAxisSize: MainAxisSize.min, children: [
        IpIconButton(icon: 'file', label: 'Eksport', onTap: _rows.isEmpty ? () {} : _showExportSheet),
        const IpHeaderBell(),
      ]),
      body: RefreshIndicator(
        color: c.azure500,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) ...[IpErrorBox(_error!, onRetry: _load), const SizedBox(height: 14)],
            if (_loading && _rows.isEmpty)
              const IpLoading()
            else if (_rows.isEmpty)
              const DashEmpty(icon: 'users', title: 'Tiada pekerja', sub: 'Tiada pekerja berdaftar di bawah syarikat anda.')
            else ...[
              if (sites.length > 1) ...[
                SizedBox(
                  height: 38,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    _sitePill(context, 'Semua tapak', _tapak == null, () => setState(() => _tapak = null)),
                    for (final s in sites) _sitePill(context, s, _tapak == s, () => setState(() => _tapak = s)),
                  ]),
                ),
                const SizedBox(height: 14),
              ],
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(gradient: c.headerGradient, borderRadius: BorderRadius.circular(IpRadius.lg)),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Kehadiran Hari Ini', style: TextStyle(fontSize: 12.5, color: c.onNavy2, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text.rich(TextSpan(children: [
                        TextSpan(
                          text: '$present ',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -.48),
                        ),
                        TextSpan(
                          text: 'daripada ${all.length} pekerja',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.onNavy2),
                        ),
                      ])),
                    ]),
                  ),
                  SizedBox(
                    width: 58,
                    height: 58,
                    child: Stack(alignment: Alignment.center, children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: pct / 100,
                          strokeWidth: 7,
                          color: c.azure400,
                          backgroundColor: Colors.white.withValues(alpha: .14),
                        ),
                      ),
                      Text('$pct%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              IpSearchBar(controller: _searchCtrl, hint: 'Cari nama pekerja…', onChanged: (_) => setState(() {})),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                DashEmpty(icon: 'search', title: 'Tiada pekerja dijumpai', sub: 'Tiada padanan untuk "${_searchCtrl.text}".')
              else
                for (final r in filtered) Padding(padding: const EdgeInsets.only(bottom: 10), child: _workerRow(context, r)),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sitePill(BuildContext context, String label, bool on, VoidCallback onTap) {
    final c = context.ip;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: on ? c.azure50 : c.surface,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: on ? c.azure500 : c.line2, width: 1.5),
          ),
          child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: on ? c.azure700 : c.text2)),
        ),
      ),
    );
  }

  Widget _workerRow(BuildContext context, Map<String, dynamic> r) {
    final c = context.ip;
    final hadir = r['hadir'] == true;
    final nama = r['nama']?.toString() ?? '-';
    final masuk = _formatMasa(r['masa_checkin']);
    final keluar = _formatMasa(r['masa_checkout']);
    final tapak = r['tapak_nama']?.toString() ?? '';
    final sub = hadir
        ? 'Check-in pada $masuk${keluar.isNotEmpty ? ' · keluar $keluar' : ''}${tapak.isNotEmpty && _tapak == null ? ' · $tapak' : ''}'
        : 'Belum check-in hari ini';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(16),
        boxShadow: c.shadowSm,
      ),
      child: Row(children: [
        IpAvatar(name: nama, size: 46, active: hadir),
        const SizedBox(width: 13),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nama,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: c.text)),
            const SizedBox(height: 2),
            Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: c.text3)),
          ]),
        ),
        const SizedBox(width: 8),
        Text(hadir ? 'Hadir' : 'Belum hadir',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: hadir ? c.emerald600 : c.text3)),
      ]),
    );
  }
}
