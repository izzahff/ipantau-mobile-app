import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'ipantau_branding.dart';

class IpantauAppBar extends StatelessWidget implements PreferredSizeWidget {
  const IpantauAppBar({
    super.key,
    required this.title,
    this.backgroundColor = AppTheme.navy,
    this.onNotificationTap,
    this.leading,
  });

  final String title;
  final Color backgroundColor;
  final VoidCallback? onNotificationTap;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return AppBar(
      toolbarHeight: 60,
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: leading ??
          (canPop
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              : null),
      title: Row(
        children: [
          const IpantauMapPin(size: 22),
          const SizedBox(width: 10),
          Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifikasi',
          onPressed: onNotificationTap ??
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tiada notifikasi baharu.')),
                );
              },
        ),
      ],
    );
  }
}
