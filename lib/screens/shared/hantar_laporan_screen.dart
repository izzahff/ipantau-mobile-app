import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/v2/ui.dart';

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
      showIpToast(context, widget.isEdit ? 'Laporan berjaya dihantar semula' : 'Laporan berjaya dihantar');
      // Back to the role shell: contractors land on the Laporan tab.
      Navigator.of(context).pushNamedAndRemoveUntil(
        role == 'penyelia' ? '/penyelia/dashboard' : '/kontraktor/dashboard',
        (route) => false,
        arguments: role == 'penyelia' ? 0 : 2,
      );
      return;
    }

    setState(() => _error = result['message'] ?? 'Gagal hantar laporan.');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final showPicker = !widget.isEdit && _role == 'kontraktor' && _tapakList.isNotEmpty;
    final submitDisabled = _loading || (!widget.isEdit && _role == 'kontraktor' && _selectedCheckinId == null);

    return IpPushedScaffold(
      title: widget.isEdit ? 'Edit & Hantar Semula' : 'Laporan Baru',
      sub: _selectedTapakNama,
      bottom: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
        decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.line))),
        child: IpButton(
          widget.isEdit ? 'Hantar Semula' : 'Hantar Laporan',
          full: true,
          size: IpButtonSize.lg,
          icon: 'send',
          loading: _loading,
          onPressed: submitDisabled ? null : _submit,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null) ...[IpErrorBox(_error!), const SizedBox(height: 14)],
          const IpFieldLabel('Tapak'),
          if (_loadingTapak)
            const IpLoading()
          else if (showPicker)
            SizedBox(
              height: 62,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _tapakList.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final t = _tapakList[i];
                  final id = (t['id'] as num).toInt();
                  final on = id == _selectedTapakId;
                  return GestureDetector(
                    onTap: on ? null : () => _onTapakChanged(id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                      decoration: BoxDecoration(
                        color: on ? c.azure50 : c.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: on ? c.azure500 : c.line2, width: 1.5),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text(t['kod_tapak']?.toString() ?? '-', style: ipMono(context, size: 11, color: on ? c.azure700 : c.text3)),
                        Text(t['nama_tapak']?.toString() ?? '-',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text)),
                      ]),
                    ),
                  );
                },
              ),
            )
          else
            IpCard(
              pad: 14,
              child: Row(children: [
                IpIcon('pin', size: 20, color: c.azure600),
                const SizedBox(width: 10),
                Expanded(child: Text(_selectedTapakNama, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text))),
              ]),
            ),
          if (_checkinWarning != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              IpIcon('alert', size: 16, color: c.amberText),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_checkinWarning!, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.amberText)),
              ),
            ]),
          ],
          const SizedBox(height: 16),
          const IpFieldLabel('Ringkasan kerja'),
          IpInput(
            controller: _ringkasanController,
            hint: 'Terangkan kerja yang telah disiapkan…',
            maxLines: 4,
            keyboardType: TextInputType.multiline,
          ),
          if (_role != 'kontraktor') ...[
            const SizedBox(height: 16),
            Row(children: [
              const Expanded(child: IpFieldLabel('Kemajuan kerja')),
              Text('$_kemajuan%', style: ipMono(context, size: 14, weight: FontWeight.w800, color: c.azure700)),
            ]),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: c.azure500,
                inactiveTrackColor: c.surface3,
                thumbColor: c.azure500,
                overlayColor: c.azure500.withValues(alpha: .12),
              ),
              child: Slider(
                value: _kemajuan.toDouble(),
                min: 0,
                max: 100,
                divisions: 100,
                label: '$_kemajuan%',
                onChanged: (v) => setState(() => _kemajuan = v.round()),
              ),
            ),
          ],
          const SizedBox(height: 16),
          IpCard(
            pad: 14,
            color: c.surface2,
            child: Row(children: [
              IpIcon('image', size: 19, color: c.icon),
              const SizedBox(width: 10),
              Expanded(
                child: Text('${widget.gambarIds.length} gambar dilampirkan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
              ),
              const IpChip('Tera GPS auto', small: true, tone: IpTone.azure),
            ]),
          ),
        ],
      ),
    );
  }
}
