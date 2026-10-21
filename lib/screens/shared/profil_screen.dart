import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/logout_dialog.dart';
import '../../widgets/v2/ui.dart';
import 'tetapan_screen.dart' show labelPeranan;

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  Future<String?> _save(BuildContext context, {String? nama, String? telefon}) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    final u = auth.pengguna ?? const {};
    if (token == null) return 'Sesi tamat. Sila log masuk semula.';
    final res = await ApiService.updateProfil(
      token: token,
      nama: nama ?? u['nama']?.toString() ?? '',
      noTelefon: telefon ?? u['no_telefon']?.toString() ?? '',
    );
    if (res['success'] != true) return res['message']?.toString() ?? 'Gagal menyimpan profil.';
    if (res['pengguna'] != null) {
      await auth.applyPengguna(Map<String, dynamic>.from(res['pengguna'] as Map));
    } else {
      await auth.refreshPenggunaFromServer();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final auth = context.watch<AuthProvider>();
    final u = auth.pengguna ?? const {};
    final nama = u['nama']?.toString() ?? '-';
    final peranan = labelPeranan(auth.peranan);
    final syarikat = u['nama_syarikat']?.toString() ?? '-';
    final isPenyelia = auth.peranan == 'penyelia';

    return IpPushedScaffold(
      title: 'Profil',
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: BoxDecoration(gradient: c.headerGradient),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
            child: Column(children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: Colors.white.withValues(alpha: .2), width: 2),
                ),
                alignment: Alignment.center,
                child: Text(IpAvatar.initialsOf(nama),
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              const SizedBox(height: 11),
              Text(nama,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -.2)),
              const SizedBox(height: 2),
              Text(syarikat, textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, color: c.onNavy2)),
              const SizedBox(height: 11),
              IpChip(peranan, tone: IpTone.azure, small: true),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              IpCard(
                pad: 15,
                color: c.azure50,
                borderColor: c.azure100,
                child: Row(children: [
                  SizedBox(width: 44, height: 44, child: Center(child: IpIcon('building', size: 22, color: c.azure700))),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('SYARIKAT',
                          style: TextStyle(fontSize: 11.5, color: c.azure700, fontWeight: FontWeight.w700, letterSpacing: .46)),
                      Text(syarikat, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: c.text)),
                      const SizedBox(height: 2),
                      Row(children: [
                        IpIcon('shield', size: 12, color: c.emerald600),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            isPenyelia ? 'Hanya urus kontraktor syarikat sama' : 'Diurus oleh penyelia syarikat sama',
                            style: TextStyle(fontSize: 11.5, color: c.text2),
                          ),
                        ),
                      ]),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 18),
              const IpSectionLabel('Maklumat', icon: 'user'),
              IpCard(
                pad: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  child: Column(children: [
                    _ProfileLine(icon: 'shield', label: 'ID Pengguna', value: '${u['id'] ?? '-'}', mono: true),
                    _EditableLine(
                      icon: 'user',
                      label: 'Nama',
                      value: u['nama']?.toString() ?? '',
                      mono: false,
                      validate: (v) => v.isEmpty ? 'Nama diperlukan' : '',
                      onSave: (v) => _save(context, nama: v),
                    ),
                    _ProfileLine(icon: 'mail', label: 'Emel', value: u['email']?.toString() ?? '-', mono: true),
                    _EditableLine(
                      icon: 'route',
                      label: 'Telefon',
                      value: u['no_telefon']?.toString() ?? '',
                      keyboardType: TextInputType.phone,
                      validate: (v) => RegExp(r'^\+?[0-9\s-]{9,15}$').hasMatch(v) ? '' : 'Nombor telefon tidak sah',
                      onSave: (v) => _save(context, telefon: v),
                    ),
                    _ProfileLine(icon: 'building', label: 'Peranan', value: peranan, last: true),
                  ]),
                ),
              ),
              const SizedBox(height: 18),
              IpButton('Log keluar',
                  full: true, variant: IpButtonVariant.danger, icon: 'logout', onPressed: () => confirmAndLogout(context)),
              const SizedBox(height: 8),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({required this.icon, required this.label, required this.value, this.mono = false, this.last = false});
  final String icon, label, value;
  final bool mono, last;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final valueStyle = mono
        ? ipMono(context, size: 13.5, weight: FontWeight.w700, color: c.text)
        : TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.text);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
      decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: c.line))),
      child: Row(children: [
        IpIcon(icon, size: 18, color: c.text3),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 13.5, color: c.text3)),
        const SizedBox(width: 12),
        Expanded(child: Text(value, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: valueStyle)),
      ]),
    );
  }
}

class _EditableLine extends StatefulWidget {
  const _EditableLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.validate,
    required this.onSave,
    this.keyboardType,
    this.mono = true,
  });

  final String icon, label, value;
  final String Function(String) validate;
  final Future<String?> Function(String) onSave;
  final TextInputType? keyboardType;
  final bool mono;

  @override
  State<_EditableLine> createState() => _EditableLineState();
}

class _EditableLineState extends State<_EditableLine> {
  bool _editing = false;
  bool _saving = false;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _commit() async {
    final v = _ctrl.text.trim();
    if (widget.validate(v).isNotEmpty || _saving) return;
    if (v == widget.value) {
      setState(() => _editing = false);
      return;
    }
    setState(() => _saving = true);
    final err = await widget.onSave(v);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (err == null) _editing = false;
    });
    showIpToast(context, err ?? '${widget.label} dikemas kini', tone: err == null ? IpToastTone.success : IpToastTone.danger);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final border = BoxDecoration(border: Border(bottom: BorderSide(color: c.line)));
    final valueStyle = widget.mono
        ? ipMono(context, size: 13.5, weight: FontWeight.w700, color: c.text)
        : TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.text);

    if (!_editing) {
      return Container(
        padding: const EdgeInsets.fromLTRB(4, 8, 0, 8),
        decoration: border,
        child: Row(children: [
          IpIcon(widget.icon, size: 18, color: c.text3),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.label, style: TextStyle(fontSize: 12, color: c.text3)),
              const SizedBox(height: 2),
              Text(widget.value.isEmpty ? '-' : widget.value, style: valueStyle),
            ]),
          ),
          _square(
            color: c.azure50,
            child: IpIcon('edit', size: 16, color: c.azure700),
            onTap: () => setState(() {
              _ctrl.text = widget.value;
              _editing = true;
            }),
            label: 'Edit ${widget.label}',
          ),
        ]),
      );
    }

    final err = widget.validate(_ctrl.text.trim());
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: border,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IpIcon(widget.icon, size: 18, color: c.azure700),
          const SizedBox(width: 8),
          Text(widget.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.azure700)),
        ]),
        const SizedBox(height: 7),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              keyboardType: widget.keyboardType,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _commit(),
              style: widget.mono ? ipMono(context, size: 14, color: c.text) : TextStyle(fontSize: 14, color: c.text),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: c.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: err.isNotEmpty ? c.crimson600 : c.azure500, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: err.isNotEmpty ? c.crimson600 : c.azure500, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _square(
            color: c.surface2,
            child: IpIcon('x', size: 18, color: c.text2),
            onTap: () => setState(() => _editing = false),
            label: 'Batal',
          ),
          const SizedBox(width: 8),
          _square(
            color: err.isNotEmpty ? c.line : c.azure600,
            child: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const IpIcon('check', size: 18, color: Colors.white),
            onTap: err.isNotEmpty ? null : _commit,
            label: 'Simpan',
          ),
        ]),
        if (err.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(err, style: TextStyle(fontSize: 12, color: c.crimson600)),
        ],
      ]),
    );
  }

  Widget _square({required Color color, required Widget child, required VoidCallback? onTap, required String label}) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(width: 44, height: 44, child: Center(child: child)),
        ),
      ),
    );
  }
}
