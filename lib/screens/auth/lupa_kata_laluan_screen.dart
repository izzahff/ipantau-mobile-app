import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../widgets/v2/password_rules.dart';
import '../../widgets/v2/ui.dart';

/// Forgot password: 1) request a 6-digit code by email, 2) enter code + new password.
/// Pops with the email on success so the login screen can prefill it.
class LupaKataLaluanScreen extends StatefulWidget {
  const LupaKataLaluanScreen({super.key, this.initialEmail});
  final String? initialEmail;

  @override
  State<LupaKataLaluanScreen> createState() => _LupaKataLaluanScreenState();
}

class _LupaKataLaluanScreenState extends State<LupaKataLaluanScreen> {
  static const _cooldownSeconds = 60;

  late final _email = TextEditingController(text: widget.initialEmail ?? '');
  final _kod = TextEditingController();
  final _pw = TextEditingController();
  final _confirm = TextEditingController();

  int _step = 1;
  bool _loading = false;
  bool _show = false;
  String? _error;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    for (final c in [_email, _kod, _pw, _confirm]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in [_email, _kod, _pw, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _emailValid => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_email.text.trim());
  bool get _kodValid => RegExp(r'^\d{6}$').hasMatch(_kod.text.trim());
  bool get _match => _confirm.text.isNotEmpty && _confirm.text == _pw.text;
  bool get _step2Valid => _kodValid && pwAllMet(_pw.text) && _match;

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = _cooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _hantarKod() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await ApiService.lupaKataLaluan(email: _email.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['success'] == true) {
      setState(() => _step = 2);
      _startCooldown();
      showIpToast(context, 'Kod dihantar. Sila semak emel anda.');
    } else {
      setState(() => _error = res['message']?.toString() ?? 'Gagal menghantar kod. Cuba lagi.');
    }
  }

  Future<void> _reset() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await ApiService.resetKataLaluan(email: _email.text, kod: _kod.text, kataLaluanBaru: _pw.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['success'] == true) {
      showIpToast(context, 'Kata laluan berjaya ditetapkan semula. Sila log masuk.');
      Navigator.pop(context, _email.text.trim());
    } else {
      setState(() => _error = res['message']?.toString() ?? 'Kod tidak sah atau telah tamat tempoh.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    return IpPushedScaffold(
      title: 'Lupa Kata Laluan',
      sub: _step == 1 ? 'Langkah 1 / 2 · emel' : 'Langkah 2 / 2 · kod & kata laluan',
      right: const SizedBox.shrink(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
        children: [
          _StepDots(step: _step),
          const SizedBox(height: 20),
          if (_step == 1) ..._step1(c) else ..._step2(c),
        ],
      ),
    );
  }

  List<Widget> _step1(IpColors c) => [
        Text('Tetapkan semula kata laluan',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.text, letterSpacing: -.44)),
        const SizedBox(height: 7),
        Text('Masukkan emel akaun anda. Kami akan hantar kod 6 digit untuk menetapkan kata laluan baharu.',
            style: TextStyle(fontSize: 14.5, color: c.text2, height: 1.5)),
        const SizedBox(height: 22),
        const IpFieldLabel('Emel'),
        IpInput(
          controller: _email,
          icon: 'mail',
          hint: 'emel@domain.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _emailValid && !_loading ? _hantarKod() : null,
        ),
        if (_error != null) ...[const SizedBox(height: 14), IpErrorBox(_error!)],
        const SizedBox(height: 24),
        IpButton('Hantar kod',
            full: true,
            size: IpButtonSize.lg,
            variant: IpButtonVariant.navy,
            icon: 'send',
            loading: _loading,
            onPressed: _emailValid ? _hantarKod : null),
      ];

  List<Widget> _step2(IpColors c) {
    final eye = IpIconButton(
      icon: _show ? 'eyeOff' : 'eye',
      size: 20,
      color: c.text3,
      label: 'Tunjuk kata laluan',
      onTap: () => setState(() => _show = !_show),
    );
    return [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: c.azure50, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.azure100)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 1), child: IpIcon('mail', size: 18, color: c.azure700)),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'Jika emel '),
                TextSpan(text: _email.text.trim(), style: const TextStyle(fontWeight: FontWeight.w800)),
                const TextSpan(text: ' berdaftar, kod 6 digit telah dihantar. Kod sah selama 15 minit.'),
              ]),
              style: TextStyle(fontSize: 13, color: c.text2, height: 1.45),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 18),
      const IpFieldLabel('Kod pengesahan'),
      Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.line, width: 1.5),
          borderRadius: BorderRadius.circular(14),
          boxShadow: c.shadowSm,
        ),
        child: TextField(
          controller: _kod,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: ipMono(context, size: 26, weight: FontWeight.w700, color: c.text).copyWith(letterSpacing: 12),
          decoration: InputDecoration(
            counterText: '',
            border: InputBorder.none,
            hintText: '••••••',
            hintStyle: ipMono(context, size: 26, color: c.text3).copyWith(letterSpacing: 12),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Row(children: [
        Text('Tiada kod?', style: TextStyle(fontSize: 13, color: c.text3)),
        const SizedBox(width: 4),
        if (_cooldown > 0)
          Text('Hantar semula dalam ${_cooldown}s', style: ipMono(context, size: 12.5, color: c.text3))
        else
          IpLinkButton('Hantar semula', onTap: _loading ? () {} : _hantarKod),
        const Spacer(),
        IpLinkButton('Tukar emel', onTap: () => setState(() {
              _step = 1;
              _error = null;
            })),
      ]),
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
      if (_error != null) ...[const SizedBox(height: 14), IpErrorBox(_error!)],
      const SizedBox(height: 24),
      IpButton('Tetapkan Kata Laluan',
          full: true,
          size: IpButtonSize.lg,
          variant: IpButtonVariant.navy,
          icon: 'check',
          loading: _loading,
          onPressed: _step2Valid ? _reset : null),
    ];
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    Widget bar(bool on) => Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 4,
            decoration: BoxDecoration(color: on ? c.azure500 : c.surface3, borderRadius: BorderRadius.circular(99)),
          ),
        );
    return Row(children: [bar(true), const SizedBox(width: 6), bar(step >= 2)]);
  }
}
