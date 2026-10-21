import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/ip_colors.dart';
import 'ip_icon.dart';

export 'ip_icon.dart';
export '../../theme/ip_colors.dart';

/* ===================================================================
   iPANTAU v2 shared UI primitives (ported from ui.jsx)
   =================================================================== */

TextStyle ipMono(BuildContext context, {double size = 12, FontWeight weight = FontWeight.w500, Color? color}) =>
    GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: weight, color: color ?? context.ip.text2);

/* ---------- Brand ---------- */

class IpLogoMark extends StatelessWidget {
  const IpLogoMark({super.key, this.size = 56, this.disc = true});
  final double size;
  final bool disc;

  @override
  Widget build(BuildContext context) {
    final inner = CustomPaint(size: Size.square(size * .62), painter: _PinPainter());
    if (!disc) return inner;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: const Color(0xFF0A1428).withValues(alpha: .22), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      alignment: Alignment.center,
      child: inner,
    );
  }
}

class _PinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final k = s.width / 24;
    final pin = Path()
      ..moveTo(12 * k, 22 * k)
      ..cubicTo(12 * k, 22 * k, 19 * k, 16 * k, 19 * k, 10 * k)
      ..arcToPoint(Offset(5 * k, 10 * k), radius: Radius.circular(7 * k), largeArc: true, clockwise: false)
      ..cubicTo(5 * k, 16 * k, 12 * k, 22 * k, 12 * k, 22 * k)
      ..close();
    canvas.drawPath(pin, Paint()..color = const Color(0xFF16263F));
    canvas.drawCircle(Offset(12 * k, 9.6 * k), 3.1 * k, Paint()..color = const Color(0xFF2F7BEF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class IpWordmark extends StatelessWidget {
  const IpWordmark({super.key, this.size = 30, this.light = true});
  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.hankenGrotesk(
      fontSize: size,
      fontWeight: FontWeight.w800,
      letterSpacing: -.02 * size,
      height: 1,
      color: light ? Colors.white : context.ip.text,
    );
    return Text.rich(TextSpan(style: style, children: const [
      TextSpan(text: 'i', style: TextStyle(color: Color(0xFF2F7BEF))),
      TextSpan(text: 'PANTAU'),
    ]));
  }
}

/* ---------- Header (navy gradient) ---------- */

class IpAppHeader extends StatelessWidget {
  const IpAppHeader({
    super.key,
    required this.title,
    this.sub,
    this.onBack,
    this.right,
    this.child,
  });

  final String title;
  final String? sub;
  final VoidCallback? onBack;
  final Widget? right;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      decoration: BoxDecoration(
        gradient: c.headerGradient,
        boxShadow: [BoxShadow(color: const Color(0xFF0C1628).withValues(alpha: .18), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      padding: EdgeInsets.fromLTRB(14, top + 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Row(
              children: [
                if (onBack != null)
                  Transform.translate(
                    offset: const Offset(-6, 0),
                    child: IpIconButton(icon: 'back', size: 23, onTap: onBack!, label: 'Kembali'),
                  ),
                if (onBack != null) const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -.18, color: c.onNavy)),
                      if (sub != null) ...[
                        const SizedBox(height: 1),
                        Text(sub!, maxLines: 1, overflow: TextOverflow.ellipsis, style: ipMono(context, size: 12, color: c.onNavy2)),
                      ],
                    ],
                  ),
                ),
                ?right,
              ],
            ),
          ),
          ?child,
        ],
      ),
    );
  }
}

class IpIconButton extends StatelessWidget {
  const IpIconButton({super.key, required this.icon, required this.onTap, this.size = 21, this.color, this.label});
  final String icon;
  final VoidCallback onTap;
  final double size;
  final Color? color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(child: IpIcon(icon, size: size, color: color ?? Colors.white)),
        ),
      ),
    );
  }
}

class IpHeaderBell extends StatelessWidget {
  const IpHeaderBell({super.key});
  @override
  Widget build(BuildContext context) => IpIconButton(
        icon: 'bell',
        label: 'Notifikasi',
        onTap: () => showIpToast(context, 'Tiada notifikasi baharu.', tone: IpToastTone.info),
      );
}

/// Scaffold for pushed (full-screen) views: navy header with back arrow.
class IpPushedScaffold extends StatelessWidget {
  const IpPushedScaffold({
    super.key,
    required this.title,
    this.sub,
    required this.body,
    this.bottom,
    this.headerChild,
    this.right,
  });
  final String title;
  final String? sub;
  final Widget body;
  final Widget? bottom;
  final Widget? headerChild;
  final Widget? right;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.ip.bg,
      body: Column(children: [
        IpAppHeader(
          title: title,
          sub: sub,
          onBack: () => Navigator.maybePop(context),
          right: right ?? const IpHeaderBell(),
          child: headerChild,
        ),
        Expanded(child: body),
        ?bottom,
      ]),
    );
  }
}

/* ---------- Button ---------- */

enum IpButtonVariant { primary, navy, emerald, outline, danger, ghost }

enum IpButtonSize { sm, md, lg }

class IpButton extends StatelessWidget {
  const IpButton(
    this.label, {
    super.key,
    this.onPressed,
    this.variant = IpButtonVariant.primary,
    this.size = IpButtonSize.md,
    this.icon,
    this.full = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IpButtonVariant variant;
  final IpButtonSize size;
  final String? icon;
  final bool full;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final disabled = onPressed == null || loading;
    late Color bg, fg;
    Color border = Colors.transparent;
    switch (variant) {
      case IpButtonVariant.primary:
        bg = c.azure500;
        fg = Colors.white;
      case IpButtonVariant.navy:
        bg = c.isDark ? c.azure600 : c.navy800;
        fg = Colors.white;
      case IpButtonVariant.emerald:
        bg = c.emerald600;
        fg = Colors.white;
      case IpButtonVariant.outline:
        bg = c.surface;
        fg = c.text;
        border = c.line2;
      case IpButtonVariant.danger:
        bg = c.surface;
        fg = c.crimson600;
        border = c.crimson600;
      case IpButtonVariant.ghost:
        bg = Colors.transparent;
        fg = c.azure600;
    }
    final pad = switch (size) {
      IpButtonSize.lg => const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
      IpButtonSize.sm => const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      IpButtonSize.md => const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
    };
    final fs = switch (size) {
      IpButtonSize.lg => 16.0,
      IpButtonSize.sm => 13.5,
      IpButtonSize.md => 15.0,
    };
    final content = Row(
      mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(width: fs + 2, height: fs + 2, child: CircularProgressIndicator(strokeWidth: 2.4, color: fg))
        else ...[
          if (icon != null) ...[
            IpIcon(icon!, size: size == IpButtonSize.sm ? 17 : 19, color: fg),
            const SizedBox(width: 9),
          ],
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: fs, fontWeight: FontWeight.w700, letterSpacing: -.01 * fs, color: fg)),
          ),
        ],
      ],
    );
    return Opacity(
      opacity: disabled && !loading ? .5 : 1,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(padding: pad, child: content),
          ),
        ),
      ),
    );
  }
}

/* ---------- Card ---------- */

class IpCard extends StatelessWidget {
  const IpCard({super.key, required this.child, this.pad = 16, this.onTap, this.color, this.borderColor, this.radius});
  final Widget child;
  final double pad;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final r = BorderRadius.circular(radius ?? IpRadius.lg);
    return Container(
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: r,
        border: Border.all(color: borderColor ?? c.line),
        boxShadow: c.shadowSm,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: Padding(padding: EdgeInsets.all(pad), child: child),
        ),
      ),
    );
  }
}

/* ---------- Chips ---------- */

enum IpTone { amber, emerald, crimson, azure, navy }

class IpChip extends StatelessWidget {
  const IpChip(this.label, {super.key, this.tone = IpTone.navy, this.dot = false, this.small = false});
  final String label;
  final IpTone tone;
  final bool dot;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = toneColors(context, tone);
    return Container(
      padding: small ? const EdgeInsets.symmetric(horizontal: 9, vertical: 3) : const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (dot) ...[
          Container(width: 6, height: 6, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
          const SizedBox(width: 6),
        ],
        Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: small ? 11.5 : 12.5, letterSpacing: .12)),
      ]),
    );
  }
}

(Color, Color) toneColors(BuildContext context, IpTone tone) {
  final c = context.ip;
  return switch (tone) {
    IpTone.amber => (c.amber50, c.amberText),
    IpTone.emerald => (c.emerald50, c.emerald600),
    IpTone.crimson => (c.crimson50, c.crimson600),
    IpTone.azure => (c.azure100, c.azure700),
    IpTone.navy => (c.surface3, c.text2),
  };
}

/// Report status from backend (`pending` / `menunggu_admin` / `lulus` / `tolak`).
class ReportStatus {
  static String label(String? s) => switch (s) {
        'lulus' => 'Diluluskan',
        'tolak' => 'Ditolak',
        'menunggu_admin' => 'Menunggu Admin',
        _ => 'Menunggu',
      };
  static IpTone tone(String? s) => switch (s) {
        'lulus' => IpTone.emerald,
        'tolak' => IpTone.crimson,
        'menunggu_admin' => IpTone.azure,
        _ => IpTone.amber,
      };
  static bool isPending(String? s) => s == null || s == 'pending' || s == 'menunggu';
}

class IpStatusText extends StatelessWidget {
  const IpStatusText(this.status, {super.key, this.small = false});
  final String? status;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final (_, fg) = toneColors(context, ReportStatus.tone(status));
    return Text(ReportStatus.label(status),
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: small ? 12.5 : 13.5, letterSpacing: .13));
  }
}

/* ---------- Avatar ---------- */

class IpAvatar extends StatelessWidget {
  const IpAvatar({super.key, required this.name, this.size = 44, this.active = false, this.neutral = false});
  final String name;
  final double size;
  final bool active;
  final bool neutral;

  static String initialsOf(String name) {
    final skip = {'bin', 'binti', 'a/l', 'a/p', 'en.', 'pn.', 'cik', 'dr.'};
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty && !skip.contains(p.toLowerCase())).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final bg = active ? c.emerald50 : (neutral ? c.surface3 : c.azure100);
    final fg = active ? c.emerald600 : (neutral ? c.text2 : c.azure700);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * .32)),
      alignment: Alignment.center,
      child: Text(initialsOf(name), style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: size * .34)),
    );
  }
}

/* ---------- Section label ---------- */

class IpSectionLabel extends StatelessWidget {
  const IpSectionLabel(this.text, {super.key, this.icon, this.action});
  final String text;
  final String? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 10),
      child: Row(children: [
        if (icon != null) ...[IpIcon(icon!, size: 16, strokeWidth: 2.2, color: c.text3), const SizedBox(width: 7)],
        Expanded(
          child: Text(text.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: .84, color: c.text3)),
        ),
        ?action,
      ]),
    );
  }
}

class IpLinkButton extends StatelessWidget {
  const IpLinkButton(this.label, {super.key, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Text(label, style: TextStyle(color: context.ip.azure600, fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      );
}

/* ---------- Toggle ---------- */

class IpToggle extends StatelessWidget {
  const IpToggle({super.key, required this.value, required this.onChanged, this.disabled = false});
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    return Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: disabled ? null : () => onChanged(!value),
        child: Opacity(
          opacity: disabled ? .45 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 50,
            height: 30,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: value ? c.azure500 : c.line2, borderRadius: BorderRadius.circular(99)),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .25), blurRadius: 5, offset: const Offset(0, 2))],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------- Segmented control ---------- */

class IpSegmented<T> extends StatelessWidget {
  const IpSegmented({super.key, required this.options, required this.value, required this.onChanged});
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: c.surface3, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.line)),
      child: Row(
        children: [
          for (final (i, o) in options.indexed) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(o.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: o.$1 == value ? c.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: o.$1 == value ? c.shadowSm : null,
                  ),
                  child: Text(o.$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          letterSpacing: -.145,
                          color: o.$1 == value ? c.azure700 : c.text2)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/* ---------- Inputs ---------- */

class IpFieldLabel extends StatelessWidget {
  const IpFieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.ip.text, letterSpacing: -.13)),
      );
}

/// Bordered input row with optional leading icon (InputRow in the design).
class IpInput extends StatelessWidget {
  const IpInput({
    super.key,
    required this.controller,
    this.icon,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.trailing,
    this.onChanged,
    this.maxLines = 1,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? icon;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line, width: 1.5),
        borderRadius: BorderRadius.circular(14),
        boxShadow: c.shadowSm,
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Padding(
              padding: EdgeInsets.only(top: maxLines > 1 ? 15 : 0),
              child: IpIcon(icon!, size: 19, color: c.text3),
            ),
            const SizedBox(width: 11),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              keyboardType: keyboardType,
              onChanged: onChanged,
              maxLines: obscure ? 1 : maxLines,
              autofocus: autofocus,
              textInputAction: textInputAction,
              onSubmitted: onSubmitted,
              style: TextStyle(fontSize: 15.5, color: c.text),
              decoration: InputDecoration(
                isDense: true,
                hintText: hint,
                hintStyle: TextStyle(color: c.text3, fontSize: 15.5),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Compact search bar (44px, 12 radius).
class IpSearchBar extends StatelessWidget {
  const IpSearchBar({super.key, required this.controller, this.hint = 'Cari', this.onChanged});
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(12),
        boxShadow: c.shadowSm,
      ),
      child: Row(children: [
        IpIcon('search', size: 18, color: c.text3),
        const SizedBox(width: 9),
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: TextStyle(fontSize: 14.5, color: c.text),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: TextStyle(color: c.text3, fontSize: 14.5),
              border: InputBorder.none,
            ),
          ),
        ),
      ]),
    );
  }
}

/// Dropdown-style filter pill.
class IpFilterDropdown<T> extends StatelessWidget {
  const IpFilterDropdown({super.key, required this.value, required this.options, required this.onChanged});
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final label = options.firstWhere((o) => o.$1 == value, orElse: () => options.first).$2;
    return PopupMenuButton<T>(
      initialValue: value,
      onSelected: onChanged,
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: c.line)),
      itemBuilder: (_) => [
        for (final o in options)
          PopupMenuItem<T>(
            value: o.$1,
            child: Text(o.$2,
                style: TextStyle(
                    color: o.$1 == value ? c.azure700 : c.text, fontWeight: o.$1 == value ? FontWeight.w700 : FontWeight.w500)),
          ),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(12),
          boxShadow: c.shadowSm,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          IpIcon('filter', size: 15, color: c.text3),
          const SizedBox(width: 7),
          Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.text)),
          const SizedBox(width: 6),
          IpIcon('chevronDown', size: 16, color: c.text3),
        ]),
      ),
    );
  }
}

/* ---------- Bottom sheet ---------- */

Future<T?> showIpSheet<T>(BuildContext context, {String? title, required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xFF080E1A).withValues(alpha: .5),
    builder: (ctx) {
      final c = ctx.ip;
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * .88),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .3), blurRadius: 40, offset: const Offset(0, -10))],
          ),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(color: c.line2, borderRadius: BorderRadius.circular(3)),
                ),
              ),
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
                  child: Row(children: [
                    Expanded(child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.text))),
                    InkResponse(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(color: c.surface3, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: IpIcon('x', size: 18, color: c.text2),
                      ),
                    ),
                  ]),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(18, 6, 18, 22 + MediaQuery.paddingOf(ctx).bottom),
                child: builder(ctx),
              ),
            ]),
          ),
        ),
      );
    },
  );
}

/* ---------- Bottom navigation ---------- */

class IpNavItem {
  const IpNavItem(this.icon, this.label);
  final String icon;
  final String label;
}

class IpBottomNav extends StatelessWidget {
  const IpBottomNav({super.key, required this.items, required this.index, required this.onTap});
  final List<IpNavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    return Container(
      decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.line)), boxShadow: c.shadowNav),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
          child: Row(
            children: [
              for (final (i, it) in items.indexed)
                Expanded(
                  child: InkResponse(
                    onTap: () => onTap(i),
                    radius: 36,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        SizedBox(
                          width: 46,
                          height: 30,
                          child: Center(
                            child: IpIcon(it.icon,
                                size: 23, strokeWidth: i == index ? 2.4 : 2, color: i == index ? c.azure600 : c.text3),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(it.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: i == index ? FontWeight.w700 : FontWeight.w600,
                              color: i == index ? c.azure600 : c.text3,
                            )),
                      ]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------- Stat card ---------- */

class IpStatCard extends StatelessWidget {
  const IpStatCard({super.key, required this.value, required this.label, required this.icon, this.tone = IpTone.navy});
  final String value;
  final String label;
  final String icon;
  final IpTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final ic = switch (tone) {
      IpTone.navy => c.icon,
      IpTone.azure => c.azure600,
      IpTone.emerald => c.emerald600,
      IpTone.amber => c.amberText,
      IpTone.crimson => c.crimson600,
    };
    return IpCard(
      pad: 14,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        IpIcon(icon, size: 19, color: ic),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1, letterSpacing: -.9, color: c.text)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: c.text2)),
      ]),
    );
  }
}

/* ---------- Empty / loading states ---------- */

class IpEmptyState extends StatelessWidget {
  const IpEmptyState({super.key, required this.title, this.sub, this.icon = 'file'});
  final String title;
  final String? sub;
  final String icon;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: c.surface3, borderRadius: BorderRadius.circular(18)),
          alignment: Alignment.center,
          child: IpIcon(icon, size: 26, color: c.text3),
        ),
        const SizedBox(height: 14),
        Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text)),
        if (sub != null) ...[
          const SizedBox(height: 4),
          Text(sub!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: c.text2, height: 1.4)),
        ],
      ]),
    );
  }
}

class IpLoading extends StatelessWidget {
  const IpLoading({super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.6, color: context.ip.azure500)),
      );
}

class IpErrorBox extends StatelessWidget {
  const IpErrorBox(this.message, {super.key, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.crimson50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.crimson600.withValues(alpha: .3)),
      ),
      child: Row(children: [
        IpIcon('alert', size: 18, color: c.crimson600),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: TextStyle(fontSize: 13, color: c.crimson600, fontWeight: FontWeight.w600))),
        if (onRetry != null) IpLinkButton('Cuba lagi', onTap: onRetry!),
      ]),
    );
  }
}

/* ---------- Toast ---------- */

enum IpToastTone { success, danger, info }

void showIpToast(BuildContext context, String message, {IpToastTone tone = IpToastTone.success}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  final c = context.ip;
  final (bg, icon) = switch (tone) {
    IpToastTone.success => (c.emerald600, 'checkCircle'),
    IpToastTone.danger => (c.crimson600, 'xCircle'),
    IpToastTone.info => (c.isDark ? c.surface3 : c.navy800, 'info'),
  };
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => Positioned(
      left: 16,
      right: 16,
      bottom: 92 + MediaQuery.paddingOf(ctx).bottom,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          builder: (_, t, child) => Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 10 * (1 - t)), child: child)),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), boxShadow: c.shadowLg),
              child: Row(children: [
                IpIcon(icon, size: 19, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
              ]),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Timer(const Duration(milliseconds: 2300), () {
    if (entry.mounted) entry.remove();
  });
}

/* ---------- Progress bar ---------- */

class IpProgressBar extends StatelessWidget {
  const IpProgressBar({super.key, required this.value, this.color});
  final double value; // 0..1
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: 6,
        child: Stack(children: [
          Container(color: c.surface3),
          FractionallySizedBox(widthFactor: value.clamp(0, 1).toDouble(), child: Container(color: color ?? c.azure500)),
        ]),
      ),
    );
  }
}

/* ---------- Striped photo placeholder ---------- */

class IpPhotoPlaceholder extends StatelessWidget {
  const IpPhotoPlaceholder({super.key, this.label = 'gambar tapak', this.height = 150, this.radius = 14});
  final String label;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        height: height,
        decoration: BoxDecoration(border: Border.all(color: c.line), borderRadius: BorderRadius.circular(radius)),
        child: CustomPaint(
          painter: _StripePainter(c.surface3, c.surface2),
          child: Center(child: Text(label.toUpperCase(), style: ipMono(context, size: 11, color: c.text3))),
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  _StripePainter(this.a, this.b);
  final Color a, b;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = a);
    final p = Paint()
      ..color = b
      ..strokeWidth = 11;
    for (double x = -size.height; x < size.width + size.height; x += 22) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), p);
    }
  }

  @override
  bool shouldRepaint(covariant _StripePainter old) => old.a != a || old.b != b;
}
