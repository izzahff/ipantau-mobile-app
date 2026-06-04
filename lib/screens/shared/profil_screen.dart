import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/logout_dialog.dart';
import '../../widgets/ipantau_app_bar.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key, this.appBarColor});

  final Color? appBarColor;

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _namaController = TextEditingController();
  final _telefonController = TextEditingController();
  final _lamaController = TextEditingController();
  final _baruController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _saving = false;
  bool _showPassword = false;
  bool _obscureLama = true;
  bool _obscureBaru = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final u = context.read<AuthProvider>().pengguna;
      if (!mounted || u == null) return;
      _namaController.text = u['nama']?.toString() ?? '';
      _telefonController.text = u['no_telefon']?.toString() ?? '';
    });
  }

  @override
  void dispose() {
    _namaController.dispose();
    _telefonController.dispose();
    _lamaController.dispose();
    _baruController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String _initials(String? nama) {
    if (nama == null || nama.trim().isEmpty) return '?';
    final parts = nama.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final a = parts[0].isNotEmpty ? parts[0][0] : '';
      final b = parts[1].isNotEmpty ? parts[1][0] : '';
      return ('$a$b').toUpperCase();
    }
    final s = parts[0];
    if (s.length >= 2) return s.substring(0, 2).toUpperCase();
    return s.toUpperCase();
  }

  String _labelPeranan(String? p) {
    switch (p) {
      case 'penyelia':
        return 'Penyelia';
      case 'kontraktor':
        return 'Kontraktor';
      default:
        return p ?? '-';
    }
  }

  Future<void> _simpan() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    final nama = _namaController.text.trim();
    if (nama.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama diperlukan.')),
      );
      return;
    }

    final l = _lamaController.text;
    final b = _baruController.text;
    final c = _confirmController.text;
    final anyPwd = l.isNotEmpty || b.isNotEmpty || c.isNotEmpty;

    if (anyPwd) {
      if (l.isEmpty || b.isEmpty || c.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Lengkapkan semua medan kata laluan.')),
        );
        return;
      }
      if (b.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Kata laluan baru sekurang-kurangnya 6 aksara.')),
        );
        return;
      }
      if (b != c) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Kata laluan baru dan pengesahan tidak sepadan.')),
        );
        return;
      }
    }

    setState(() => _saving = true);

    final profilRes = await ApiService.updateProfil(
      token: token,
      nama: nama,
      noTelefon: _telefonController.text.trim(),
    );

    if (!mounted) return;

    if (profilRes['success'] != true) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(profilRes['message']?.toString() ??
                'Gagal menyimpan profil.')),
      );
      return;
    }

    if (profilRes['pengguna'] != null) {
      await auth.applyPengguna(
        Map<String, dynamic>.from(profilRes['pengguna'] as Map),
      );
    }

    if (anyPwd) {
      final pwdRes = await ApiService.tukarKataLaluan(
        token: token,
        kataLaluanLama: l,
        kataLaluanBaru: b,
      );
      if (!mounted) return;
      if (pwdRes['success'] != true) {
        setState(() => _saving = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(pwdRes['message']?.toString() ??
                  'Gagal menukar kata laluan.')),
        );
        return;
      }
      _lamaController.clear();
      _baruController.clear();
      _confirmController.clear();
    }

    setState(() => _saving = false);
    if (!mounted) return;
    final msg = anyPwd
        ? '${profilRes['message']?.toString() ?? 'Profil dikemas kini.'} Kata laluan ditukar.'
        : (profilRes['message']?.toString() ?? 'Profil dikemas kini.');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.pengguna;
    final peranan = auth.peranan;
    final email = user?['email']?.toString() ?? '-';
    final syarikat = user?['nama_syarikat']?.toString() ?? '-';
    final nama = user?['nama']?.toString() ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: IpantauAppBar(
        title: 'Profil',
        backgroundColor: widget.appBarColor ?? AppTheme.navy,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildNavyHeader(nama: nama, peranan: peranan),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.md,
                AppTheme.lg,
                AppTheme.md,
                AppTheme.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfoCard(
                    email: email,
                    syarikat: syarikat,
                  ),
                  const SizedBox(height: AppTheme.sm + 4),
                  _buildKeselamatanCard(),
                  const SizedBox(height: AppTheme.lg),
                  _buildSimpanButton(),
                  const SizedBox(height: AppTheme.sm + 4),
                  _buildLogoutButton(),
                  const SizedBox(height: AppTheme.md),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavyHeader({required String nama, required String? peranan}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.lg,
        AppTheme.md,
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
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials(nama),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.sm + 2),
          Text(
            nama.isEmpty ? '-' : nama,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppTheme.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(AppTheme.radiusRound),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.60)),
            ),
            child: Text(
              _labelPeranan(peranan),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String email, required String syarikat}) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Maklumat Peribadi', Icons.person_outline_rounded),
          const SizedBox(height: AppTheme.md),
          _fieldRow(
            'Nama',
            TextField(
              controller: _namaController,
              decoration: _fieldDecoration('Nama penuh'),
            ),
          ),
          const SizedBox(height: AppTheme.sm + 4),
          _fieldRow(
            'Emel',
            InputDecorator(
              decoration: _fieldDecoration('Emel', readOnly: true),
              child: Text(
                email,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.sm + 4),
          _fieldRow(
            'No. Telefon',
            TextField(
              controller: _telefonController,
              keyboardType: TextInputType.phone,
              decoration: _fieldDecoration('+60…'),
            ),
          ),
          const SizedBox(height: AppTheme.sm + 4),
          _fieldRow(
            'Syarikat',
            InputDecorator(
              decoration: _fieldDecoration('Syarikat', readOnly: true),
              child: Text(
                syarikat,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeselamatanCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Keselamatan', Icons.lock_outline_rounded),
          const SizedBox(height: AppTheme.sm + 4),
          InkWell(
            onTap: () => setState(() => _showPassword = !_showPassword),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.sm),
              child: Row(
                children: [
                  const Icon(
                    Icons.vpn_key_outlined,
                    size: 18,
                    color: AppTheme.navy,
                  ),
                  const SizedBox(width: AppTheme.sm + 4),
                  const Expanded(
                    child: Text(
                      'Tukar kata laluan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    _showPassword
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppTheme.textMuted,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _passwordFields(),
            crossFadeState: _showPassword
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }

  Widget _passwordFields() {
    return Column(
      children: [
        const SizedBox(height: AppTheme.sm + 4),
        Divider(height: 1, color: AppTheme.border),
        const SizedBox(height: AppTheme.md),
        _fieldRow(
          'Kata laluan lama',
          TextField(
            controller: _lamaController,
            obscureText: _obscureLama,
            decoration: _fieldDecoration(
              '••••••••',
              suffix: _eyeButton(
                visible: _obscureLama,
                onTap: () => setState(() => _obscureLama = !_obscureLama),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.sm + 4),
        _fieldRow(
          'Kata laluan baru',
          TextField(
            controller: _baruController,
            obscureText: _obscureBaru,
            decoration: _fieldDecoration(
              '••••••••',
              suffix: _eyeButton(
                visible: _obscureBaru,
                onTap: () => setState(() => _obscureBaru = !_obscureBaru),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.sm + 4),
        _fieldRow(
          'Sahkan kata laluan baru',
          TextField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            decoration: _fieldDecoration(
              '••••••••',
              suffix: _eyeButton(
                visible: _obscureConfirm,
                onTap: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.sm),
      ],
    );
  }

  Widget _buildSimpanButton() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: _saving ? [] : AppTheme.buttonShadow,
      ),
      child: SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: _saving ? null : _simpan,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.navy,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppTheme.border,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Simpan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _saving ? null : () => confirmAndLogout(context),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text(
          'Log keluar',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.error,
          backgroundColor: Colors.transparent,
          side: const BorderSide(color: AppTheme.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(AppTheme.md),
      child: child,
    );
  }

  Widget _cardHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.sm),
          decoration: BoxDecoration(
            color: AppTheme.navy.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.navy, size: 16),
        ),
        const SizedBox(width: AppTheme.sm + 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _fieldRow(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }

  Widget _eyeButton({required bool visible, required VoidCallback onTap}) {
    return IconButton(
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: AppTheme.textMuted,
        size: 18,
      ),
      onPressed: onTap,
    );
  }

  InputDecoration _fieldDecoration(
    String hint, {
    Widget? suffix,
    bool readOnly = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
      filled: true,
      fillColor: readOnly ? AppTheme.background : AppTheme.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd - 2),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd - 2),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd - 2),
        borderSide: const BorderSide(color: AppTheme.navyLight, width: 1.5),
      ),
    );
  }
}
