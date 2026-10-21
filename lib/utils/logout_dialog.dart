import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/ip_colors.dart';

Future<void> confirmAndLogout(BuildContext context) async {
  final c = context.ip;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(IpRadius.lg)),
      title: Text('Log keluar', style: TextStyle(color: c.text, fontWeight: FontWeight.w800)),
      content: Text('Adakah anda pasti mahu log keluar?', style: TextStyle(color: c.text2)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Batal', style: TextStyle(color: c.text2, fontWeight: FontWeight.w700)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: c.crimson600,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Log keluar', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  await context.read<AuthProvider>().logout();
  if (context.mounted) {
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (_) => false);
  }
}
