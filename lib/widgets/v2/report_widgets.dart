import 'package:flutter/material.dart';

import '../../utils/ip_format.dart';
import 'dash_widgets.dart';
import 'ui.dart';

/// Status filter keys used by both report lists.
enum ReportFilter { semua, menunggu, lulus, tolak }

const reportFilterLabels = {
  ReportFilter.semua: 'Semua',
  ReportFilter.menunggu: 'Menunggu',
  ReportFilter.lulus: 'Diluluskan',
  ReportFilter.tolak: 'Ditolak',
};

bool matchesFilter(Map<String, dynamic> l, ReportFilter f) {
  final s = l['status']?.toString();
  return switch (f) {
    ReportFilter.semua => true,
    ReportFilter.menunggu => ReportStatus.isPending(s) || s == 'menunggu_admin',
    ReportFilter.lulus => s == 'lulus',
    ReportFilter.tolak => s == 'tolak',
  };
}

bool matchesQuery(Map<String, dynamic> l, String q) {
  final ql = q.trim().toLowerCase();
  if (ql.isEmpty) return true;
  final hay = [
    l['tapak_nama'],
    l['nama_tapak'],
    l['kod_tapak'],
    laporanKod(l),
    l['ringkasan'],
    l['pekerja_nama'],
  ].whereType<Object>().join(' ').toLowerCase();
  return hay.contains(ql);
}

/// Filter + sort newest first + group by day ("Hari ini", "Semalam", date).
List<(String, List<Map<String, dynamic>>)> groupReports(List<Map<String, dynamic>> list) {
  final sorted = [...list]
    ..sort((a, b) {
      final da = IpFormat.parse(laporanTarikh(a)) ?? DateTime(1970);
      final db = IpFormat.parse(laporanTarikh(b)) ?? DateTime(1970);
      return db.compareTo(da);
    });
  final groups = <(String, List<Map<String, dynamic>>)>[];
  for (final l in sorted) {
    final label = IpFormat.dayGroup(laporanTarikh(l));
    if (groups.isNotEmpty && groups.last.$1 == label) {
      groups.last.$2.add(l);
    } else {
      groups.add((label, [l]));
    }
  }
  return groups;
}

class StatusPills extends StatelessWidget {
  const StatusPills({super.key, required this.value, required this.onChanged});
  final ReportFilter value;
  final ValueChanged<ReportFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final active = c.isDark ? c.azure600 : c.navy800;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final f in ReportFilter.values) ...[
          GestureDetector(
            onTap: () => onChanged(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: f == value ? active : c.surface,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: f == value ? active : c.line2, width: 1.5),
              ),
              child: Text(reportFilterLabels[f]!,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: f == value ? Colors.white : c.text2)),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ]),
    );
  }
}

class GroupHeader extends StatelessWidget {
  const GroupHeader({super.key, required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 9),
      child: Row(children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: .6, color: c.text3)),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: c.line)),
        const SizedBox(width: 8),
        Text('$count', style: ipMono(context, size: 12, weight: FontWeight.w700, color: c.text3)),
      ]),
    );
  }
}

class LihatButton extends StatelessWidget {
  const LihatButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    return Material(
      color: c.azure50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: c.azure100, width: 1.5)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Lihat', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.azure700)),
            const SizedBox(width: 4),
            IpIcon('chevronRight', size: 16, strokeWidth: 2.5, color: c.azure700),
          ]),
        ),
      ),
    );
  }
}

/// Watermark stamp drawn over a work photo (site · worker · time · coords).
class WatermarkStamp extends StatelessWidget {
  const WatermarkStamp({super.key, required this.kodTapak, required this.pekerja, required this.masa, this.coord});
  final String kodTapak, pekerja, masa;
  final String? coord;

  @override
  Widget build(BuildContext context) {
    TextStyle s(Color c, {FontWeight w = FontWeight.w400}) => ipMono(context, size: 10.5, weight: w, color: c);
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.fromLTRB(18, 18, 10, 8),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(14)),
        gradient: LinearGradient(
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
          colors: [
            const Color(0xFF080E1A).withValues(alpha: .82),
            const Color(0xFF080E1A).withValues(alpha: .5),
            Colors.transparent,
          ],
          stops: const [0, .55, 1],
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xFF5798FF), shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Flexible(child: Text('iPANTAU · $kodTapak', overflow: TextOverflow.ellipsis, style: s(Colors.white, w: FontWeight.w600))),
        ]),
        const SizedBox(height: 2),
        Text(pekerja, overflow: TextOverflow.ellipsis, style: s(const Color(0xFFDFE8F5))),
        const SizedBox(height: 1),
        Text(masa, style: s(const Color(0xFFDFE8F5))),
        if (coord != null) ...[const SizedBox(height: 1), Text(coord!, style: s(const Color(0xFF9EC1FF)))],
      ]),
    );
  }
}

/// Network photo with the v2 watermark stamp and striped placeholder.
class WatermarkedPhoto extends StatelessWidget {
  const WatermarkedPhoto({super.key, this.url, required this.stamp, this.height = 210, this.onTap});
  final String? url;
  final WatermarkStamp stamp;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(fit: StackFit.expand, children: [
            const IpPhotoPlaceholder(label: 'gambar kerja', height: double.infinity, radius: 0),
            if (url != null)
              Image.network(
                url!,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, p) =>
                    p == null ? child : Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: c.azure500)),
                errorBuilder: (_, _, _) => Center(child: IpIcon('image', size: 26, color: c.text3)),
              ),
            Positioned(right: 0, bottom: 0, child: stamp),
          ]),
        ),
      ),
    );
  }
}

/// Fullscreen photo viewer (swipe between photos).
class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen({super.key, required this.urls, this.initialIndex = 0, this.stampBuilder});
  final List<String> urls;
  final int initialIndex;
  final WatermarkStamp Function(int index)? stampBuilder;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _page = PageController(initialPage: widget.initialIndex);
  late int _i = widget.initialIndex;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05080E),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Material(
                color: Colors.white.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pop(context),
                  child: const SizedBox(width: 44, height: 44, child: Center(child: IpIcon('back', size: 21, color: Colors.white))),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Gambar Kerja', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              if (widget.urls.length > 1)
                Text('${_i + 1} / ${widget.urls.length}', style: ipMono(context, size: 12.5, color: Colors.white70)),
            ]),
          ),
          Expanded(
            child: PageView.builder(
              controller: _page,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _i = i),
              itemBuilder: (_, i) => Stack(children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    child: Image.network(
                      widget.urls[i],
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Center(child: IpIcon('image', size: 32, color: Colors.white54)),
                    ),
                  ),
                ),
                if (widget.stampBuilder != null) Positioned(right: 12, bottom: 12, child: widget.stampBuilder!(i)),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
            child: Text('Tera auto · GPS & masa terkunci pada imej',
                textAlign: TextAlign.center, style: ipMono(context, size: 11.5, color: const Color(0xFF9EC1FF))),
          ),
        ]),
      ),
    );
  }
}

/// Generic labelled info line (icon · label · value).
class InfoLine extends StatelessWidget {
  const InfoLine({super.key, required this.icon, required this.label, required this.value, this.last = false, this.mono = false});
  final String icon, label, value;
  final bool last, mono;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: c.line))),
      child: Row(children: [
        IpIcon(icon, size: 18, color: c.text3),
        const SizedBox(width: 11),
        SizedBox(width: 78, child: Text(label, style: TextStyle(fontSize: 13.5, color: c.text3))),
        Expanded(
          child: Text(value,
              style: mono
                  ? ipMono(context, size: 13.5, weight: FontWeight.w700, color: c.text)
                  : TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: c.text)),
        ),
      ]),
    );
  }
}
