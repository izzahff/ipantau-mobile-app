import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Stroke icon set ported 1:1 from the v2 design handoff (icons.jsx).
/// 24x24 grid, round caps/joins, tinted with [color].
const Map<String, String> _kIconPaths = {
  'home': '<path d="M3 10.5 12 3l9 7.5"/><path d="M5 9.5V20a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V9.5"/><path d="M9.5 21v-6h5v6"/>',
  'grid': '<rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/>',
  'building': '<rect x="4" y="3" width="16" height="18" rx="1.5"/><path d="M9 7h.01M15 7h.01M9 11h.01M15 11h.01M9 15h.01M15 15h.01"/><path d="M10 21v-3h4v3"/>',
  'clipboardCheck': '<rect x="5" y="4" width="14" height="17" rx="2"/><path d="M9 4V3a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v1"/><path d="M9 13.5l2 2 4-4.5"/>',
  'settings': '<circle cx="12" cy="12" r="3.2"/><path d="M19.4 13a1.6 1.6 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.6 1.6 0 0 0-2.7 1.1V20a2 2 0 0 1-4 0v-.1A1.6 1.6 0 0 0 7 18.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1A1.6 1.6 0 0 0 4 12.9H4a2 2 0 0 1 0-4h.1A1.6 1.6 0 0 0 5.6 7a1.6 1.6 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1A1.6 1.6 0 0 0 11 3.7V4a2 2 0 0 1 4 0v.1a1.6 1.6 0 0 0 2.7 1.1l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.6 1.6 0 0 0 1.1 2.7H20a2 2 0 0 1 0 4h-.6z"/>',
  'bell': '<path d="M6 9a6 6 0 0 1 12 0c0 5 2 6 2 6H4s2-1 2-6"/><path d="M10.5 19a1.8 1.8 0 0 0 3 0"/>',
  'back': '<path d="M19 12H5"/><path d="m11 18-6-6 6-6"/>',
  'chevronRight': '<path d="m9 6 6 6-6 6"/>',
  'chevronDown': '<path d="m6 9 6 6 6-6"/>',
  'pin': '<path d="M12 21s7-5.4 7-11a7 7 0 1 0-14 0c0 5.6 7 11 7 11Z"/><circle cx="12" cy="10" r="2.6"/>',
  'camera': '<path d="M4 8h3l1.4-2h7.2L17 8h3a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1Z"/><circle cx="12" cy="13" r="3.4"/>',
  'file': '<path d="M14 3H7a1.5 1.5 0 0 0-1.5 1.5v15A1.5 1.5 0 0 0 7 21h10a1.5 1.5 0 0 0 1.5-1.5V8L14 3Z"/><path d="M14 3v5h4.5"/><path d="M9 13h6M9 16.5h4"/>',
  'user': '<circle cx="12" cy="8" r="3.6"/><path d="M5 20c0-3.4 3-5.6 7-5.6s7 2.2 7 5.6"/>',
  'users': '<circle cx="9" cy="8" r="3.2"/><path d="M3.5 19.5c0-3 2.6-5 5.5-5s5.5 2 5.5 5"/><path d="M16 5.2a3.2 3.2 0 0 1 0 5.9M17.5 14.7c2.3.5 4 2.4 4 4.8"/>',
  'search': '<circle cx="11" cy="11" r="6.5"/><path d="m20 20-3.6-3.6"/>',
  'eye': '<path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12Z"/><circle cx="12" cy="12" r="2.8"/>',
  'eyeOff': '<path d="M10.6 6.7A8.9 8.9 0 0 1 12 6.5c6 0 9.5 5.5 9.5 5.5a16 16 0 0 1-3 3.4M6.5 7.6A15.7 15.7 0 0 0 2.5 12S6 18.5 12 18.5a8.7 8.7 0 0 0 3.4-.7"/><path d="M9.9 9.9a2.8 2.8 0 0 0 4 4"/><path d="m3 3 18 18"/>',
  'lock': '<rect x="4.5" y="10.5" width="15" height="10" rx="2"/><path d="M8 10.5V7.5a4 4 0 0 1 8 0v3"/><circle cx="12" cy="15.5" r="1.2"/>',
  'mail': '<rect x="3" y="5" width="18" height="14" rx="2"/><path d="m3.5 6.5 8.5 6 8.5-6"/>',
  'crosshair': '<circle cx="12" cy="12" r="7.5"/><path d="M12 1.5v4M12 18.5v4M1.5 12h4M18.5 12h4"/><circle cx="12" cy="12" r="2.3"/>',
  'map': '<path d="M9 4 3.5 6v14L9 18l6 2 5.5-2V4L15 6 9 4Z"/><path d="M9 4v14M15 6v14"/>',
  'calendar': '<rect x="3.5" y="5" width="17" height="16" rx="2"/><path d="M3.5 9.5h17M8 3v4M16 3v4"/>',
  'clock': '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>',
  'check': '<path d="m5 12.5 4.5 4.5L19 7"/>',
  'checkCircle': '<circle cx="12" cy="12" r="8.5"/><path d="m8.5 12 2.4 2.4L15.8 9.5"/>',
  'x': '<path d="M6 6 18 18M18 6 6 18"/>',
  'xCircle': '<circle cx="12" cy="12" r="8.5"/><path d="m9 9 6 6M15 9l-6 6"/>',
  'plus': '<path d="M12 5v14M5 12h14"/>',
  'globe': '<circle cx="12" cy="12" r="8.5"/><path d="M3.5 12h17M12 3.5c2.4 2.3 3.7 5.3 3.7 8.5S14.4 18.2 12 20.5C9.6 18.2 8.3 15.2 8.3 12S9.6 5.8 12 3.5Z"/>',
  'sun': '<circle cx="12" cy="12" r="4"/><path d="M12 2v2.5M12 19.5V22M4.2 4.2l1.8 1.8M18 18l1.8 1.8M2 12h2.5M19.5 12H22M4.2 19.8 6 18M18 6l1.8-1.8"/>',
  'moon': '<path d="M20 14.5A8.5 8.5 0 0 1 9.5 4 8.5 8.5 0 1 0 20 14.5Z"/>',
  'logout': '<path d="M14 20H6a1.5 1.5 0 0 1-1.5-1.5v-13A1.5 1.5 0 0 1 6 4h8"/><path d="M17 8.5 20.5 12 17 15.5M9.5 12h11"/>',
  'image': '<rect x="3.5" y="4.5" width="17" height="15" rx="2"/><circle cx="8.5" cy="9.5" r="1.8"/><path d="m4 17 4.5-4.5 4 3.5L16 12l4 4"/>',
  'alert': '<path d="M12 3.5 22 19H2L12 3.5Z"/><path d="M12 10v4M12 17h.01"/>',
  'info': '<circle cx="12" cy="12" r="8.5"/><path d="M12 11v5M12 8h.01"/>',
  'shield': '<path d="M12 3 5 5.5v5c0 4.6 3 8 7 9.5 4-1.5 7-4.9 7-9.5v-5L12 3Z"/><path d="m9 11.5 2 2 4-4"/>',
  'route': '<circle cx="6" cy="18" r="2.4"/><circle cx="18" cy="6" r="2.4"/><path d="M8.4 18H14a3.5 3.5 0 0 0 0-7H10a3.5 3.5 0 0 1 0-7h5.6"/>',
  'edit': '<path d="M16.5 4.5 19.5 7.5 8 19l-4 1 1-4 11.5-11.5Z"/><path d="m14.5 6.5 3 3"/>',
  'send': '<path d="M21 3 10.5 13.5"/><path d="M21 3 14.5 21l-4-7.5L3 9.5 21 3Z"/>',
  'filter': '<path d="M4 5h16l-6.4 8v6l-3.2-2v-4L4 5Z"/>',
  'refresh': '<path d="M20 11a8 8 0 0 0-14-4.5L4 8"/><path d="M4 4v4h4"/><path d="M4 13a8 8 0 0 0 14 4.5L20 16"/><path d="M20 20v-4h-4"/>',
  'star': '<path d="M12 3.5l2.6 5.3 5.9.9-4.3 4.1 1 5.8-5.2-2.7-5.2 2.7 1-5.8L3.5 9.7l5.9-.9L12 3.5Z"/>',
  'chevronStat': '<path d="m8 10 4 4 4-4"/>',
};

class IpIcon extends StatelessWidget {
  const IpIcon(this.name, {super.key, this.size = 24, this.color, this.strokeWidth = 2});

  final String name;
  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? Colors.black;
    final paths = _kIconPaths[name] ?? _kIconPaths['info']!;
    final svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
        'stroke="#000" stroke-width="$strokeWidth" stroke-linecap="round" '
        'stroke-linejoin="round">$paths</svg>';
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
    );
  }
}
