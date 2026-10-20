import 'package:flutter/material.dart';

import '../../utils/ip_format.dart';
import 'ui.dart';

/// Today's check-in state derived from `/checkin/hari-ini` data.
class CheckinState {
  const CheckinState({this.masuk, this.keluar, this.tapakNama});
  final DateTime? masuk;
  final DateTime? keluar;
  final String? tapakNama;

  bool get checkedIn => masuk != null;
  bool get checkedOut => keluar != null;

  factory CheckinState.from(Map<String, dynamic>? d) {
    if (d == null) return const CheckinState();
    return CheckinState(
      masuk: IpFormat.parse(d['waktu_masuk'] ?? d['masa_checkin']),
      keluar: IpFormat.parse(d['masa_checkout'] ?? d['waktu_keluar']),
      tapakNama: (d['tapak_nama'] ?? d['nama_tapak'])?.toString(),
    );
  }
}

class CheckinBadge extends StatelessWidget {
  const CheckinBadge({super.key, required this.state});
  final CheckinState state;

  @override
  Widget build(BuildContext context) {
    late Color bg, border, fg;
    late String text;
    if (state.checkedOut) {
      bg = Colors.white.withValues(alpha: .1);
      border = Colors.white.withValues(alpha: .25);
      fg = Colors.white;
      text = 'Sesi tamat · ${IpFormat.time(state.keluar)}';
    } else if (state.checkedIn) {
      bg = const Color(0xFF18B478).withValues(alpha: .18);
      border = const Color(0xFF18B478).withValues(alpha: .4);
      fg = const Color(0xFF7FF0C0);
      text = 'Sudah check-in · ${IpFormat.time(state.masuk)}';
    } else {
      bg = Colors.white.withValues(alpha: .08);
      border = Colors.white.withValues(alpha: .22);
      fg = Colors.white;
      text = 'Belum check-in';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99), border: Border.all(color: border)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w700)),
    );
  }
}

/// Navy dashboard header: logo row, greeting, date, check-in badge.
class DashHeader extends StatelessWidget {
  const DashHeader({super.key, required this.nama, required this.syarikat, required this.checkin});
  final String nama;
  final String syarikat;
  final CheckinState checkin;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    return Container(
      decoration: BoxDecoration(
        gradient: c.headerGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [BoxShadow(color: const Color(0xFF0C1628).withValues(alpha: .2), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      padding: EdgeInsets.fromLTRB(18, MediaQuery.paddingOf(context).top + 12, 12, 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const IpLogoMark(size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(TextSpan(
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -.17, color: Colors.white),
              children: [TextSpan(text: 'i', style: TextStyle(color: c.azure400)), const TextSpan(text: 'PANTAU')],
            )),
          ),
          const IpHeaderBell(),
        ]),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Selamat datang,', style: TextStyle(fontSize: 13.5, color: c.onNavy2)),
                const SizedBox(height: 2),
                Text(nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -.42, height: 1.15, color: Colors.white)),
                const SizedBox(height: 3),
                Text(syarikat, maxLines: 1, overflow: TextOverflow.ellipsis, style: ipMono(context, size: 12.5, color: c.onNavy2)),
              ]),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 92),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(IpFormat.today(),
                    textAlign: TextAlign.right,
                    style: ipMono(context, size: 11, color: c.onNavy2).copyWith(height: 1.3)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        CheckinBadge(state: checkin),
      ]),
    );
  }
}

/// One step of the "Tugasan Hari Ini" stepper.
class FlowStep {
  const FlowStep(this.title, this.sub);
  final String title;
  final String sub;
}

enum FlowState { done, active, ready, locked }

class TodayFlowCard extends StatelessWidget {
  const TodayFlowCard({super.key, required this.steps, required this.stateOf, required this.actions});
  final List<FlowStep> steps;
  final FlowState Function(int) stateOf;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    return IpCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final (i, st) in steps.indexed)
          Opacity(
            opacity: stateOf(i) == FlowState.locked ? .5 : 1,
            child: IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Column(children: [
                  _dot(context, i, stateOf(i)),
                  if (i < steps.length - 1)
                    Expanded(
                      child: Container(
                        width: 2,
                        constraints: const BoxConstraints(minHeight: 14),
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        color: stateOf(i) == FlowState.done ? c.emerald600 : c.line,
                      ),
                    ),
                ]),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 4, bottom: i < steps.length - 1 ? 14 : 0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(st.title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: c.text)),
                      const SizedBox(height: 2),
                      Text(st.sub,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: stateOf(i) == FlowState.done ? c.emerald600 : c.text3,
                            fontWeight: stateOf(i) == FlowState.done ? FontWeight.w600 : FontWeight.w400,
                          )),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        const SizedBox(height: 16),
        actions,
      ]),
    );
  }

  Widget _dot(BuildContext context, int i, FlowState s) {
    final c = context.ip;
    final done = s == FlowState.done;
    final active = s == FlowState.active;
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: done ? c.emerald600 : (active ? c.azure600 : c.surface2),
        shape: BoxShape.circle,
        border: done || active ? null : Border.all(color: c.line2, width: 1.5),
      ),
      alignment: Alignment.center,
      child: done
          ? const IpIcon('check', size: 16, strokeWidth: 2.8, color: Colors.white)
          : Text('${i + 1}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: active ? Colors.white : c.text3)),
    );
  }
}

class SessionDoneBanner extends StatelessWidget {
  const SessionDoneBanner({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    return Container(
      height: 48,
      decoration: BoxDecoration(color: c.emerald50, borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IpIcon('checkCircle', size: 18, color: c.emerald600),
        const SizedBox(width: 8),
        Text('Sesi hari ini selesai', style: TextStyle(color: c.emerald600, fontSize: 14, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

/// Supervisor task row: icon, title, sub, count badge, chevron.
class TaskRow extends StatelessWidget {
  const TaskRow({
    super.key,
    required this.icon,
    required this.title,
    required this.sub,
    this.count,
    this.urgent = false,
    this.last = false,
    required this.onTap,
  });
  final String icon, title, sub;
  final int? count;
  final bool urgent, last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: c.line))),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: urgent ? c.amber50 : c.azure50, borderRadius: BorderRadius.circular(13)),
            alignment: Alignment.center,
            child: IpIcon(icon, size: 21, color: urgent ? c.amberText : c.azure700),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: c.text)),
              const SizedBox(height: 2),
              Text(sub,
                  style: TextStyle(
                      fontSize: 12.5,
                      color: urgent ? c.amberText : c.text3,
                      fontWeight: urgent ? FontWeight.w600 : FontWeight.w400)),
            ]),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              constraints: const BoxConstraints(minWidth: 28),
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(color: urgent ? c.amber500 : c.surface2, borderRadius: BorderRadius.circular(99)),
              alignment: Alignment.center,
              child: Text('$count',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: urgent ? Colors.white : c.text2)),
            ),
          ],
          const SizedBox(width: 6),
          IpIcon('chevronRight', size: 18, color: c.text3),
        ]),
      ),
    );
  }
}

/// Recent report row used on dashboards.
class ActivityRow extends StatelessWidget {
  const ActivityRow({super.key, required this.title, required this.sub, required this.status, required this.onTap, this.last = false});
  final String title, sub;
  final String? status;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
        decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: c.line))),
        child: Row(children: [
          SizedBox(width: 40, height: 40, child: Center(child: IpIcon('file', size: 20, color: c.icon))),
          const SizedBox(width: 13),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
              const SizedBox(height: 2),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: ipMono(context, size: 11.5, color: c.text3)),
            ]),
          ),
          const SizedBox(width: 8),
          IpStatusText(status, small: true),
        ]),
      ),
    );
  }
}

/// Dashed empty-state card.
class DashEmpty extends StatelessWidget {
  const DashEmpty({super.key, required this.title, this.sub, this.icon = 'route'});
  final String title;
  final String? sub;
  final String icon;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(IpRadius.lg),
        border: Border.all(color: c.line2),
      ),
      child: Column(children: [
        IpIcon(icon, size: 30, color: c.text3),
        const SizedBox(height: 12),
        Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text)),
        if (sub != null) ...[
          const SizedBox(height: 3),
          Text(sub!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: c.text2)),
        ],
      ]),
    );
  }
}

/// Helpers shared by both dashboards.
String laporanTarikh(Map<String, dynamic> l) =>
    (l['submitted_at'] ?? l['created_at'] ?? l['tarikh'])?.toString() ?? '';

bool isTodayIso(String iso) {
  final d = IpFormat.parse(iso);
  if (d == null) return false;
  final n = DateTime.now();
  return d.year == n.year && d.month == n.month && d.day == n.day;
}

String laporanKod(Map<String, dynamic> l) => 'RPT-${l['id'] ?? '?'}';
