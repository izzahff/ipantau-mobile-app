import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  // true = live server, false = local dev (10.0.2.2)
  static const bool _isProduction = true;

  static const String baseUrl = _isProduction
      ? 'https://ipantau-backend-baru.onrender.com/api'
      : 'http://10.0.2.2:3001/api';

  static const Duration _timeout = Duration(seconds: 30);

  static Map<String, dynamic> _noInternet() => {
        'success': false,
        'message': 'Gagal sambung ke pelayan. Semak sambungan internet.',
      };

  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      // e.g. Express "Cannot POST /api/..." HTML page when a route is missing
      if (response.statusCode == 404) {
        return {
          'success': false,
          'notFound': true,
          'message': 'Ciri ini belum tersedia di pelayan.',
        };
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> _get(
    String path, {
    String? token,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(Uri.parse('$baseUrl$path'), headers: headers)
          .timeout(_timeout);
      return _handleResponse(response);
    } on http.ClientException {
      return _noInternet();
    } on FormatException {
      return {'success': false, 'message': 'Ralat format data dari pelayan.'};
    } catch (_) {
      return _noInternet();
    }
  }

  static Future<Map<String, dynamic>> _post(
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: headers,
            body: jsonEncode(body ?? {}),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } on http.ClientException {
      return _noInternet();
    } on FormatException {
      return {'success': false, 'message': 'Ralat format data dari pelayan.'};
    } catch (_) {
      return _noInternet();
    }
  }

  static Future<Map<String, dynamic>> _put(
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .put(
            Uri.parse('$baseUrl$path'),
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } on http.ClientException {
      return _noInternet();
    } on FormatException {
      return {'success': false, 'message': 'Ralat format data dari pelayan.'};
    } catch (_) {
      return _noInternet();
    }
  }

  // ignore: unused_element
  static Future<Map<String, dynamic>> _delete(
    String path, {
    String? token,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final response = await http
          .delete(Uri.parse('$baseUrl$path'), headers: headers)
          .timeout(_timeout);
      return _handleResponse(response);
    } on http.ClientException {
      return _noInternet();
    } on FormatException {
      return {'success': false, 'message': 'Ralat format data dari pelayan.'};
    } catch (_) {
      return _noInternet();
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String kataLaluan,
  }) async {
    try {
      return await _post(
        '/auth/login',
        body: {
          'email': email.trim().toLowerCase(),
          'kata_laluan': kataLaluan,
        },
      );
    } catch (_) {
      return _noInternet();
    }
  }

  static Future<Map<String, dynamic>> getMe(String token) async {
    return _get('/auth/me', token: token);
  }

  static Future<Map<String, dynamic>> updateProfil({
    required String token,
    required String nama,
    required String noTelefon,
  }) async {
    return _put(
      '/auth/profil',
      token: token,
      body: {
        'nama': nama,
        'no_telefon': noTelefon,
      },
    );
  }

  static Future<Map<String, dynamic>> tukarKataLaluan({
    required String token,
    required String kataLaluanLama,
    required String kataLaluanBaru,
  }) async {
    return _put(
      '/auth/tukar-kata-laluan',
      token: token,
      body: {
        'kata_laluan_lama': kataLaluanLama,
        'kata_laluan_baru': kataLaluanBaru,
      },
    );
  }

  /// Step 1 of password reset: ask the server to email a 6-digit code.
  /// The server should answer success even for unknown emails.
  static Future<Map<String, dynamic>> lupaKataLaluan({required String email}) async {
    return _post('/auth/lupa-kata-laluan', body: {'email': email.trim().toLowerCase()});
  }

  /// Step 2 of password reset: verify the code and set a new password.
  static Future<Map<String, dynamic>> resetKataLaluan({
    required String email,
    required String kod,
    required String kataLaluanBaru,
  }) async {
    return _post('/auth/reset-kata-laluan', body: {
      'email': email.trim().toLowerCase(),
      'kod': kod.trim(),
      'kata_laluan_baru': kataLaluanBaru,
    });
  }

  static Future<Map<String, dynamic>> getPekerjaKehadiranHariIni(String token) async {
    return _get('/pekerja/kehadiran-hari-ini', token: token);
  }

  static Future<Map<String, dynamic>> getTapakSaya(String token) async {
    return _get('/tapak/saya', token: token);
  }

  static Future<Map<String, dynamic>> getCheckinHariIni(String token, {int? tapakId}) async {
    final path = tapakId != null ? '/checkin/hari-ini?tapak_id=$tapakId' : '/checkin/hari-ini';
    return _get(path, token: token);
  }

  static Future<Map<String, dynamic>> getActiveCheckin(String token) async {
    return _get('/checkin/active', token: token);
  }

  static Future<Map<String, dynamic>> createCheckin({
    required String token,
    required int tapakId,
    required double lat,
    required double lon,
  }) async {
    return _post(
      '/checkin',
      token: token,
      body: {
        'tapak_id': tapakId,
        'latitud_checkin': lat,
        'longitud_checkin': lon,
      },
    );
  }

  static Future<Map<String, dynamic>> checkout({
    required String token,
    required int checkinId,
  }) async {
    return _put('/checkin/$checkinId/checkout', token: token);
  }

  static Future<Map<String, dynamic>> uploadGambar({
    required String token,
    required int tapakId,
    required Uint8List bytes,
    required String fileName,
    required String capturedAtIso,
    double? latitud,
    double? longitud,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/gambar'));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['tapak_id'] = '$tapakId';
      request.fields['captured_at'] = capturedAtIso;
      if (latitud != null) request.fields['latitud'] = '$latitud';
      if (longitud != null) request.fields['longitud'] = '$longitud';

      final ext = fileName.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';

      request.files.add(
        http.MultipartFile.fromBytes(
          'gambar',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      return _handleResponse(response);
    } on http.ClientException {
      return _noInternet();
    } on FormatException {
      return {'success': false, 'message': 'Ralat format data dari pelayan.'};
    } catch (_) {
      return _noInternet();
    }
  }

  static Future<Map<String, dynamic>> createLaporan({
    required String token,
    required int tapakId,
    required int checkinId,
    required String ringkasan,
    required int kemajuanPeratus,
    required String jenisLaporan,
    required List<int> gambarIds,
  }) async {
    return _post(
      '/laporan',
      token: token,
      body: {
        'tapak_id': tapakId,
        'checkin_id': checkinId,
        'ringkasan': ringkasan,
        'kemajuan_peratus': kemajuanPeratus,
        'jenis_laporan': jenisLaporan,
        'gambar_ids': gambarIds,
      },
    );
  }

  static Future<Map<String, dynamic>> getLaporanSaya(String token) async {
    return _get('/laporan/saya', token: token);
  }

  static Future<Map<String, dynamic>> getAktivitiTerkini(String token) async {
    return _get('/laporan/aktiviti-terkini', token: token);
  }

  static Future<Map<String, dynamic>> updateLaporan({
    required String token,
    required int laporanId,
    required String ringkasan,
    required int kemajuanPeratus,
    required List<int> gambarIds,
  }) async {
    return _put(
      '/laporan/$laporanId',
      token: token,
      body: {
        'ringkasan': ringkasan,
        'kemajuan_peratus': kemajuanPeratus,
        'gambar_ids': gambarIds,
      },
    );
  }

  static Future<Map<String, dynamic>> getLaporanTapak(String token) async {
    return _get('/laporan/tapak', token: token);
  }

  static Future<Map<String, dynamic>> semakLaporan({
    required String token,
    required int laporanId,
    required String status,
    required String nota,
  }) async {
    return _put(
      '/laporan/$laporanId/semak',
      token: token,
      body: {
        'status': status,
        'nota_admin': nota,
      },
    );
  }

  static Future<Map<String, dynamic>> getGambarLaporan({
    required String token,
    required int laporanId,
  }) async {
    return _get('/laporan/$laporanId/gambar', token: token);
  }
}
