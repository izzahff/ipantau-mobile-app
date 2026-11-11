/// Date/time/coord helpers. Dates always include the year (design rule).
class IpFormat {
  static const months = ['Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun', 'Jul', 'Ogo', 'Sep', 'Okt', 'Nov', 'Dis'];
  static const days = ['Isnin', 'Selasa', 'Rabu', 'Khamis', 'Jumaat', 'Sabtu', 'Ahad']; // DateTime.weekday 1..7

  static DateTime? parse(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v.toLocal();
    return DateTime.tryParse(v.toString())?.toLocal();
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static String date(dynamic v) {
    final d = parse(v);
    if (d == null) return '-';
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  static String time(dynamic v) {
    final d = parse(v);
    if (d == null) return '--:--';
    return '${_pad(d.hour)}:${_pad(d.minute)}';
  }

  static String dateTime(dynamic v) {
    final d = parse(v);
    if (d == null) return '-';
    return '${date(d)}, ${time(d)}';
  }

  static String today([DateTime? now]) {
    final d = now ?? DateTime.now();
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  /// "Hari ini" / "Semalam" / "8 Jun 2026" for grouping lists by day.
  static String dayGroup(dynamic v, [DateTime? now]) {
    final d = parse(v);
    if (d == null) return 'Tarikh tidak diketahui';
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Semalam';
    return date(d);
  }

  static String coord(dynamic lat, dynamic lng) {
    final a = double.tryParse('$lat');
    final b = double.tryParse('$lng');
    if (a == null || b == null) return '-';
    return '${a.toStringAsFixed(6)}, ${b.toStringAsFixed(6)}';
  }

  /// "Xj Ym"
  static String duration(Duration d) {
    final mins = d.inMinutes.abs();
    return '${mins ~/ 60}j ${mins % 60}m';
  }
}
