import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/v2/ui.dart';
import 'lupa_kata_laluan_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'kontraktor';
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_refresh);
    _passwordController.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _valid => _emailController.text.contains('@') && _passwordController.text.isNotEmpty;

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final success = await auth.login(_emailController.text, _passwordController.text);
    if (!mounted || !success) return;

    final peranan = auth.peranan;
    if (peranan == 'kontraktor') {
      Navigator.pushReplacementNamed(context, '/kontraktor/dashboard');
    } else if (peranan == 'penyelia') {
      Navigator.pushReplacementNamed(context, '/penyelia/dashboard');
    }
  }

  Future<void> _lupaKataLaluan() async {
    final email = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => LupaKataLaluanScreen(initialEmail: _emailController.text.trim())),
    );
    if (!mounted || email == null) return;
    _emailController.text = email;
    _passwordController.clear();
    context.read<AuthProvider>().clearError();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final welcome = _role == 'kontraktor'
        ? 'Kontraktor: log masuk untuk check-in lokasi GPS.'
        : 'Penyelia: log masuk untuk pantau pekerja.';

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          _hero(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Selamat datang',
                      style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: c.text, letterSpacing: -.68)),
                  const SizedBox(height: 7),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 42),
                    child: Text(welcome, style: TextStyle(fontSize: 14.5, color: c.text2, height: 1.5)),
                  ),
                  const SizedBox(height: 20),
                  const IpFieldLabel('Peranan'),
                  IpSegmented<String>(
                    value: _role,
                    options: const [('kontraktor', 'Kontraktor'), ('penyelia', 'Penyelia')],
                    onChanged: (v) {
                      setState(() => _role = v);
                      context.read<AuthProvider>().clearError();
                    },
                  ),
                  const SizedBox(height: 18),
                  const IpFieldLabel('Emel'),
                  IpInput(
                    controller: _emailController,
                    icon: 'mail',
                    hint: 'emel@domain.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  const IpFieldLabel('Kata laluan'),
                  IpInput(
                    controller: _passwordController,
                    icon: 'lock',
                    hint: 'Masukkan kata laluan',
                    obscure: !_showPassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _valid ? _handleLogin() : null,
                    trailing: IpIconButton(
                      icon: _showPassword ? 'eyeOff' : 'eye',
                      size: 20,
                      color: c.text3,
                      label: 'Tunjuk kata laluan',
                      onTap: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 10, 2, 0),
                    child: Text(
                      'Mestilah 8 aksara atau lebih, dengan sekurang-kurangnya 1 nombor dan 1 simbol.',
                      style: TextStyle(fontSize: 12.5, color: c.text3, height: 1.45),
                    ),
                  ),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) => auth.error == null
                        ? const SizedBox.shrink()
                        : Padding(padding: const EdgeInsets.only(top: 14), child: IpErrorBox(auth.error!)),
                  ),
                  const SizedBox(height: 26),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) => IpButton(
                      'Log masuk',
                      full: true,
                      size: IpButtonSize.lg,
                      variant: IpButtonVariant.navy,
                      loading: auth.isLoading,
                      onPressed: _valid ? _handleLogin : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: IpLinkButton('Lupa kata laluan?', onTap: _lupaKataLaluan),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context) {
    final c = context.ip;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: c.headerGradient),
        child: Stack(
          children: [
            Positioned(top: -60, right: -50, child: _ring(200, .06)),
            Positioned(top: -28, right: -14, child: _ring(120, .07)),
            Padding(
              padding: EdgeInsets.fromLTRB(24, MediaQuery.paddingOf(context).top + 34, 24, 30),
              child: Center(
                child: Column(
                  children: [
                    const IpLogoMark(size: 66),
                    const SizedBox(height: 14),
                    const IpWordmark(size: 30),
                    const SizedBox(height: 14),
                    Text('Sistem Pemantauan Tapak GPS',
                        style: ipMono(context, size: 13, color: c.onNavy2).copyWith(letterSpacing: .52)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ring(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: alpha), width: 1.5),
        ),
      );
}
