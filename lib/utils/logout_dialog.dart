import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

Future<void> confirmAndLogout(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Log keluar'),
      content: const Text('Adakah anda pasti mahu log keluar?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
          child: const Text('Log keluar'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  await context.read<AuthProvider>().logout();
  if (context.mounted) {
    Navigator.pushReplacementNamed(context, '/login');
  }
}
