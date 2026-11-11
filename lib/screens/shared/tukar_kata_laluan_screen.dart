import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/v2/password_rules.dart';
import '../../widgets/v2/ui.dart';

class TukarKataLaluanScreen extends StatefulWidget {
  const TukarKataLaluanScreen({super.key});

  @override
  State<TukarKataLaluanScreen> createState() => _TukarKataLaluanScreenState();
}

class _TukarKataLaluanScreenState extends State<TukarKataLaluanScreen> {
  final _cur = TextEditingController();
  final _pw = TextEditingController();
  final _confirm = TextEditingController();
  bool _show = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_cur, _pw, _confirm]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _cur.dispose();
    _pw.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _match => _confirm.text.isNotEmpty && _confirm.text == _pw.text;
  bool get _valid => _cur.text.isNotEmpty && pwAllMet(_pw.text) && _match;

  Future<void> _save() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() => _saving = true);
    final res = await ApiService.tukarKataLaluan(token: token, kataLaluanLama: _cur.text, kataLaluanBaru: _pw.text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (res['success'] == true) {
      showIpToast(context, 'Kata laluan berjaya dikemas kini');
      Navigator.pop(context);
    } else {
      showIpToast(context, res['message']?.toString() ?? 'Gagal menukar kata laluan.', tone: IpToastTone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final eye = IpIconButton(
      icon: _show ? 'eyeOff' : 'eye',
      size: 20,
      color: c.text3,
      label: 'Tunjuk kata laluan',
      onTap: () => setState(() => _show = !_show),
    );
    return IpPushedScaffold(
      title: 'Tukar Kata Laluan',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const IpFieldLabel('Kata laluan semasa'),
          IpInput(controller: _cur, icon: 'lock', hint: 'Masukkan kata laluan semasa', obscure: !_show),
          const SizedBox(height: 16),
          const IpFieldLabel('Kata laluan baharu'),
          IpInput(controller: _pw, icon: 'lock', hint: 'Masukkan kata laluan baharu', obscure: !_show, trailing: eye),
          const SizedBox(height: 12),
          PasswordChecklist(password: _pw.text),
          const SizedBox(height: 9),
          const IpFieldLabel('Sahkan kata laluan baharu'),
          IpInput(controller: _confirm, icon: 'lock', hint: 'Taip semula kata laluan baharu', obscure: !_show),
          if (_confirm.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: [
              IpIcon(_match ? 'checkCircle' : 'xCircle', size: 16, color: _match ? c.emerald600 : c.crimson600),
              const SizedBox(width: 8),
              Text(_match ? 'Kata laluan sepadan' : 'Kata laluan tidak sepadan',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _match ? c.emerald600 : c.crimson600)),
            ]),
          ],
          const SizedBox(height: 24),
          IpButton(
            'Simpan Kata Laluan',
            full: true,
            size: IpButtonSize.lg,
            variant: IpButtonVariant.navy,
            loading: _saving,
            onPressed: _valid ? _save : null,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
