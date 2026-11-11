import 'package:flutter/material.dart';

import 'ui.dart';

/// Password rules (exact Malay copy from the design).
List<(String, bool)> pwCriteria(String pw) => [
      ('Mestilah sekurang-kurangnya 8 aksara', pw.length >= 8),
      ('Mesti mengandungi sekurang-kurangnya 1 huruf besar', RegExp(r'[A-Z]').hasMatch(pw)),
      ('Mesti mengandungi sekurang-kurangnya 1 huruf kecil', RegExp(r'[a-z]').hasMatch(pw)),
      ('Mesti mengandungi sekurang-kurangnya 1 nombor/digit', RegExp(r'[0-9]').hasMatch(pw)),
      ('Mesti mengandungi sekurang-kurangnya 1 simbol/aksara khas', RegExp(r'[^A-Za-z0-9]').hasMatch(pw)),
    ];

bool pwAllMet(String pw) => pwCriteria(pw).every((c) => c.$2);

class PasswordChecklist extends StatelessWidget {
  const PasswordChecklist({super.key, required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, ok) in pwCriteria(password))
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: IpIcon(ok ? 'checkCircle' : 'xCircle', size: 16, color: ok ? c.emerald600 : c.crimson600),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.35, color: ok ? c.emerald600 : c.crimson600)),
              ),
            ]),
          ),
      ],
    );
  }
}
