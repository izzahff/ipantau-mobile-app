import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ipantau_app_bar.dart';
import 'laporan_saya_screen.dart';

class HantarLaporanScreen extends StatefulWidget {
  final int tapakId;
  final int checkinId;
  final String tapakNama;
  final List<int> gambarIds;
  final bool isEdit;
  final int? laporanId;
  final String? initialRingkasan;
  final int? initialKemajuan;

  const HantarLaporanScreen({
    super.key,
    required this.tapakId,
    required this.checkinId,
    required this.tapakNama,
    required this.gambarIds,
    this.isEdit = false,
    this.laporanId,
    this.initialRingkasan,
    this.initialKemajuan,
  });

  @override
  State<HantarLaporanScreen> createState() => _HantarLaporanScreenState();
}

class _HantarLaporanScreenState extends State<HantarLaporanScreen> {
  final TextEditingController _ringkasanController = TextEditingController();
  int _kemajuan = 0;
  bool _loading = false;
  String? _error;
  late String _role;

  List<Map<String, dynamic>> _tapakList = [];
  bool _loadingTapak = false;
  late int _selectedTapakId;
  int? _selectedCheckinId;
  late String _selectedTapakNama;
  String? _checkinWarning;

  @override
  void initState() {
    super.initState();
    _ringkasanController.text = widget.initialRingkasan ?? '';
    _kemajuan = widget.initialKemajuan ?? 0;
    _role =
        context.read<AuthProvider>().pengguna?['peranan'] as String? ??
            'kontraktor';
    _selectedTapakId = widget.tapakId;
    _selectedCheckinId = widget.checkinId;
    _selectedTapakNama = widget.tapakNama;

    if (!widget.isEdit && _role == 'kontraktor') {
      _loadTapak();
    }
  }

  @override
  void dispose() {
    _ringkasanController.dispose();
    super.dispose();
  }

  Future<void> _loadTapak() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() => _loadingTapak = true);
    final res = await ApiService.getTapakSaya(token);
    if (!mounted) return;
    if (res['success'] == true) {
      final data = (res['data'] as List?) ?? [];
      setState(() {
        _tapakList =
            data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loadingTapak = false;
      });
    } else {
      setState(() => _loadingTapak = false);
    }
  }

  Future<void> _onTapakChanged(int newTapakId) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final newTapak = _tapakList.firstWhere(
      (t) => (t['id'] as num).toInt() == newTapakId,
      orElse: () => {},
    );

    setState(() {
      _selectedTapakId = newTapakId;
      _selectedTapakNama = newTapak['nama_tapak']?.toString() ?? '-';
      _selectedCheckinId = null;
      _checkinWarning = null;
    });

    final res =
        await ApiService.getCheckinHariIni(token, tapakId: newTapakId);
    if (!mounted) return;

    final data = res['data'];
    if (data != null) {
      setState(() {
        _selectedCheckinId = (data['id'] as num).toInt();
        _checkinWarning = null;
      });
    } else {
      setState(() {
        _checkinWarning = 'Anda perlu check-in ke tapak ini dahulu.';
      });
    }
  }

  Future<void> _submit() async {
    final token = context.read<AuthProvider>().token;
    final role =
        context.read<AuthProvider>().pengguna?['peranan'] as String? ??
            'kontraktor';
    if (token == null) {
      setState(() => _error = 'Sesi tamat. Sila log masuk semula.');
      return;
    }

    if (_ringkasanController.text.trim().isEmpty) {
      setState(() => _error = 'Ringkasan kerja diperlukan.');
      return;
    }

    if (!widget.isEdit && role == 'kontraktor' && _selectedCheckinId == null) {
      setState(() => _error = 'Sila pilih tapak yang anda telah check-in.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = widget.isEdit
        ? await ApiService.updateLaporan(
            token: token,
            laporanId: widget.laporanId!,
            ringkasan: _ringkasanController.text.trim(),
            kemajuanPeratus: _kemajuan,
            gambarIds: widget.gambarIds,
          )
        : await ApiService.createLaporan(
            token: token,
            tapakId: _selectedTapakId,
            checkinId: _selectedCheckinId!,
            ringkasan: _ringkasanController.text.trim(),
            kemajuanPeratus: _kemajuan,
            jenisLaporan: role == 'penyelia' ? 'pemantauan' : 'pekerja',
            gambarIds: widget.gambarIds,
          );

    if (!mounted) return;

    setState(() => _loading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(result['message'] ?? 'Laporan berjaya dihantar.')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (_) => const LaporanSayaScreen(showBackButton: true)),
        (route) => false,
      );
      return;
    }

    setState(() => _error = result['message'] ?? 'Gagal hantar laporan.');
  }

  @override
  Widget build(BuildContext context) {
    final showDropdown =
        !widget.isEdit && _role == 'kontraktor' && _tapakList.isNotEmpty;
    final submitDisabled =
        _loading ||
        (!widget.isEdit &&
            _role == 'kontraktor' &&
            _selectedCheckinId == null);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: IpantauAppBar(
        title: widget.isEdit ? 'Edit & Hantar Semula' : 'Hantar Laporan',
        backgroundColor: AppTheme.navy,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tapak',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (_loadingTapak)
                  const LinearProgressIndicator()
                else if (showDropdown)
                  DropdownButtonFormField<int>(
                    initialValue: _selectedTapakId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    items: _tapakList
                        .map((t) => DropdownMenuItem<int>(
                              value: (t['id'] as num).toInt(),
                              child: Text(
                                t['nama_tapak']?.toString() ?? '-',
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      _onTapakChanged(val);
                    },
                  )
                else
                  Text(_selectedTapakNama),
                if (_checkinWarning != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _checkinWarning!,
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ringkasan Kerja',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _ringkasanController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        'Contoh: Kerja pembersihan dan bancuhan konkrit siap 60%',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_role != 'kontraktor') ...[
            const SizedBox(height: 12),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kemajuan Kerja',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Slider(
                    value: _kemajuan.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '$_kemajuan%',
                    onChanged: (value) =>
                        setState(() => _kemajuan = value.round()),
                  ),
                  Text(
                    '$_kemajuan%',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _card(
            child: Text(
                'Jumlah gambar dilampirkan: ${widget.gambarIds.length}'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: Color(0xFFB91C1C)),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: submitDisabled ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navy,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      widget.isEdit ? 'Hantar Semula' : 'Hantar Laporan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD0DFF0)),
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }
}
