import 'package:flutter_test/flutter_test.dart';
import 'package:ipantau/utils/ip_format.dart';
import 'package:ipantau/widgets/v2/dash_widgets.dart';
import 'package:ipantau/widgets/v2/password_rules.dart';
import 'package:ipantau/widgets/v2/report_widgets.dart';
import 'package:ipantau/widgets/v2/ui.dart';

void main() {
  group('IpFormat', () {
    final d = DateTime(2026, 6, 8, 9, 5);

    test('dates always include the year with Malay months', () {
      expect(IpFormat.date(d), '8 Jun 2026');
      expect(IpFormat.date(DateTime(2026, 8, 1)), '1 Ogo 2026');
      expect(IpFormat.dateTime(d), '8 Jun 2026, 09:05');
    });

    test('today label uses Malay weekday', () {
      expect(IpFormat.today(d), 'Isnin, 8 Jun 2026');
      expect(IpFormat.today(DateTime(2026, 6, 14)), 'Ahad, 14 Jun 2026');
    });

    test('day grouping', () {
      final now = DateTime(2026, 6, 8, 18);
      expect(IpFormat.dayGroup(DateTime(2026, 6, 8, 7), now), 'Hari ini');
      expect(IpFormat.dayGroup(DateTime(2026, 6, 7, 23), now), 'Semalam');
      expect(IpFormat.dayGroup(DateTime(2026, 6, 1), now), '1 Jun 2026');
    });

    test('coords and durations', () {
      expect(IpFormat.coord(3.07164, 101.527163), '3.071640, 101.527163');
      expect(IpFormat.coord(null, 1), '-');
      expect(IpFormat.duration(const Duration(hours: 9, minutes: 25)), '9j 25m');
    });

    test('missing values are safe', () {
      expect(IpFormat.time(null), '--:--');
      expect(IpFormat.date('bukan tarikh'), '-');
    });
  });

  group('password rules', () {
    test('all five rules', () {
      expect(pwAllMet('Pantau#2026'), isTrue);
      expect(pwAllMet('pantau#2026'), isFalse); // no uppercase
      expect(pwAllMet('Pantau2026'), isFalse); // no symbol
      expect(pwCriteria('Ab1#').first.$2, isFalse); // too short
      expect(pwCriteria('').length, 5);
    });
  });

  group('report status', () {
    test('labels and pending detection', () {
      expect(ReportStatus.label('lulus'), 'Diluluskan');
      expect(ReportStatus.label('tolak'), 'Ditolak');
      expect(ReportStatus.label('pending'), 'Menunggu');
      expect(ReportStatus.label('menunggu_admin'), 'Menunggu Admin');
      expect(ReportStatus.isPending('pending'), isTrue);
      expect(ReportStatus.isPending(null), isTrue);
      expect(ReportStatus.isPending('lulus'), isFalse);
    });

    test('filters and search', () {
      final l = <String, dynamic>{'status': 'tolak', 'tapak_nama': 'Space u8', 'id': 41, 'pekerja_nama': 'Ali bin Ahmad'};
      expect(matchesFilter(l, ReportFilter.tolak), isTrue);
      expect(matchesFilter(l, ReportFilter.lulus), isFalse);
      expect(matchesFilter(l, ReportFilter.semua), isTrue);
      expect(matchesQuery(l, 'space'), isTrue);
      expect(matchesQuery(l, 'RPT-41'), isTrue);
      expect(matchesQuery(l, 'ali'), isTrue);
      expect(matchesQuery(l, 'klang'), isFalse);
    });

    test('groups newest first by day', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 10);
      final yesterday = today.subtract(const Duration(days: 1));
      final groups = groupReports([
        <String, dynamic>{'id': 1, 'submitted_at': yesterday.toIso8601String()},
        <String, dynamic>{'id': 2, 'submitted_at': today.toIso8601String()},
        <String, dynamic>{'id': 3, 'submitted_at': today.add(const Duration(hours: 2)).toIso8601String()},
      ]);
      expect(groups.map((g) => g.$1).toList(), ['Hari ini', 'Semalam']);
      expect(groups.first.$2.map((l) => l['id']).toList(), [3, 2]);
    });
  });

  group('check-in state', () {
    test('reads either v1 field name', () {
      expect(CheckinState.from(null).checkedIn, isFalse);
      final a = CheckinState.from({'waktu_masuk': '2026-06-08T08:00:00'});
      expect(a.checkedIn, isTrue);
      expect(a.checkedOut, isFalse);
      final b = CheckinState.from({'masa_checkin': '2026-06-08T08:00:00', 'masa_checkout': '2026-06-08T17:00:00'});
      expect(b.checkedOut, isTrue);
    });
  });

  test('avatar initials skip bin/binti', () {
    expect(IpAvatar.initialsOf('Ali bin Ahmad'), 'AA');
    expect(IpAvatar.initialsOf('Amanda Binti Salahuddin'), 'AS');
    expect(IpAvatar.initialsOf('Razif'), 'R');
  });
}
