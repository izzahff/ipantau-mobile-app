import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/v2/ui.dart';
import 'gambar_file_pick_stub.dart'
    if (dart.library.html) 'gambar_file_pick_web.dart' as file_pick;
import 'hantar_laporan_screen.dart';

class _UploadedImage {
  final Uint8List bytes;
  final int gambarId;
  final String url;
  final DateTime capturedAt;

  _UploadedImage({
    required this.bytes,
    required this.gambarId,
    required this.url,
    required this.capturedAt,
  });
}

class GambarScreen extends StatefulWidget {
  final bool isEdit;
  final int? laporanId;
  final int? tapakId;
  final int? checkinId;
  final String? tapakNama;
  final String? initialRingkasan;
  final int? initialKemajuan;

  const GambarScreen({
    super.key,
    this.isEdit = false,
    this.laporanId,
    this.tapakId,
    this.checkinId,
    this.tapakNama,
    this.initialRingkasan,
    this.initialKemajuan,
  });

  @override
  State<GambarScreen> createState() => _GambarScreenState();
}

class _GambarScreenState extends State<GambarScreen> {
  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  bool _uploading = false;
  String? _error;

  Map<String, dynamic>? _checkin;
  int? _tapakId;
  String _tapakNama = '-';
  final List<_UploadedImage> _images = [];

  Position? _position;

  static const int _maxImages = 5;
  static const double _mockLat = 3.1390;
  static const double _mockLon = 101.6869;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.isEdit) {
      setState(() {
        _tapakId = widget.tapakId;
        _tapakNama = widget.tapakNama ?? '-';
        _checkin = {
          'id': widget.checkinId,
          'tapak_id': widget.tapakId,
        };
        _loading = false;
      });
      await _getLocation();
      return;
    }

    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() {
        _loading = false;
        _error = 'Sesi tamat. Sila log masuk semula.';
      });
      return;
    }

    final checkinRes = await ApiService.getCheckinHariIni(token);
    if (checkinRes['success'] != true || checkinRes['data'] == null) {
      setState(() {
        _loading = false;
        _error = 'Anda perlu check-in dahulu sebelum hantar laporan.';
      });
      return;
    }

    final c = Map<String, dynamic>.from(checkinRes['data'] as Map);
    final tapak = Map<String, dynamic>.from(c['tapak'] as Map);

    await _getLocation();

    setState(() {
      _checkin = c;
      _tapakId = (c['tapak_id'] as num).toInt();
      _tapakNama = tapak['nama_tapak']?.toString() ?? '-';
      _loading = false;
    });
  }

  Future<void> _getLocation() async {
    if (kIsWeb) return;
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      _position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (_) {
      // optional metadata
    }
  }

  double? get _uploadLat {
    if (kIsWeb) return _mockLat;
    return _position?.latitude;
  }

  double? get _uploadLon {
    if (kIsWeb) return _mockLon;
    return _position?.longitude;
  }

  bool get _gpsActive {
    if (kIsWeb) return true;
    return _position != null;
  }

  String get _gpsShort {
    if (kIsWeb) {
      return '${_mockLat.toStringAsFixed(4)}, ${_mockLon.toStringAsFixed(4)}';
    }
    final p = _position;
    if (p == null) return '—';
    return '${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}';
  }

  String _formatTimestampShort(DateTime d) {
    final l = d.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _uploadPickedBytes(Uint8List bytes, String fileName) async {
    final token = context.read<AuthProvider>().token;
    if (token == null || _tapakId == null) return;

    if (_images.length >= _maxImages) {
      if (mounted) {
        showIpToast(context, 'Maksimum $_maxImages gambar sahaja.', tone: IpToastTone.danger);
      }
      return;
    }

    final capturedAt = DateTime.now();

    setState(() {
      _uploading = true;
      _error = null;
    });

    final result = await ApiService.uploadGambar(
      token: token,
      tapakId: _tapakId!,
      bytes: bytes,
      fileName: fileName.isEmpty
          ? 'gambar_${capturedAt.millisecondsSinceEpoch}.jpg'
          : fileName,
      capturedAtIso: capturedAt.toIso8601String(),
      latitud: _uploadLat,
      longitud: _uploadLon,
    );

    if (!mounted) return;
    setState(() => _uploading = false);

    if (result['success'] == true) {
      final item = _UploadedImage(
        bytes: bytes,
        gambarId: (result['gambar_id'] as num).toInt(),
        url: result['url']?.toString() ?? '',
        capturedAt: capturedAt,
      );
      setState(() => _images.add(item));
      showIpToast(context, 'Gambar berjaya dimuat naik.');
      return;
    }

    setState(() =>
        _error = result['message']?.toString() ?? 'Gagal muat naik gambar.');
  }

  Future<void> _pickFromWebFile() async {
    final bytes = await file_pick.pickImageBytesFromBrowserFileInput();
    if (bytes == null || !mounted) return;
    await _uploadPickedBytes(
        bytes, 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg');
  }

  Future<void> _pickFromCamera() async {
    final xfile =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (xfile == null || !mounted) return;
    final bytes = await xfile.readAsBytes();
    await _uploadPickedBytes(bytes, xfile.name);
  }

  Future<void> _pickFromGallery() async {
    final xfile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xfile == null || !mounted) return;
    final bytes = await xfile.readAsBytes();
    await _uploadPickedBytes(bytes, xfile.name);
  }

  Future<void> _handleAddPhoto() async {
    if (_uploading || _images.length >= _maxImages || _loading) return;
    if (kIsWeb) {
      await _pickFromWebFile();
      return;
    }
    if (!mounted) return;
    final source = await showIpSheet<ImageSource>(
      context,
      title: 'Tambah gambar',
      builder: (ctx) {
        final c = ctx.ip;
        Widget row(String icon, String title, String sub, ImageSource s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: IpCard(
                pad: 14,
                onTap: () => Navigator.pop(ctx, s),
                child: Row(children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: c.azure50, borderRadius: BorderRadius.circular(13)),
                    alignment: Alignment.center,
                    child: IpIcon(icon, size: 21, color: c.azure700),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text)),
                      Text(sub, style: TextStyle(fontSize: 12.5, color: c.text3)),
                    ]),
                  ),
                  IpIcon('chevronRight', size: 18, color: c.text3),
                ]),
              ),
            );
        return Column(children: [
          row('camera', 'Kamera', 'Ambil gambar baharu di tapak', ImageSource.camera),
          row('image', 'Galeri', 'Pilih gambar sedia ada', ImageSource.gallery),
        ]);
      },
    );
    if (source == ImageSource.camera) await _pickFromCamera();
    if (source == ImageSource.gallery) await _pickFromGallery();
  }

  void _goNext() {
    if (_checkin == null || _tapakId == null) return;
    if (_images.isEmpty) {
      setState(() => _error = 'Sila ambil sekurang-kurangnya satu gambar.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HantarLaporanScreen(
          tapakId: _tapakId!,
          checkinId: (_checkin!['id'] as num).toInt(),
          tapakNama: _tapakNama,
          gambarIds: _images.map((e) => e.gambarId).toList(),
          isEdit: widget.isEdit,
          laporanId: widget.laporanId,
          initialRingkasan: widget.initialRingkasan,
          initialKemajuan: widget.initialKemajuan,
        ),
      ),
    );
  }

  void _removeImage(int i) => setState(() => _images.removeAt(i));

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final canAdd = !_uploading && !_loading && _images.length < _maxImages && _tapakId != null;
    final hasPhotos = _images.isNotEmpty;

    return IpPushedScaffold(
      title: widget.isEdit ? 'Edit Gambar' : 'Ambil Gambar',
      sub: _loading ? null : _tapakNama,
      bottom: _loading || _checkin == null
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
              decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.line))),
              child: IpButton(
                hasPhotos ? 'Seterusnya · ${_images.length} gambar' : 'Ambil sekurang-kurangnya 1 gambar',
                full: true,
                size: IpButtonSize.lg,
                icon: 'send',
                onPressed: hasPhotos && !_uploading ? _goNext : null,
              ),
            ),
      body: _loading
          ? const IpLoading()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) ...[IpErrorBox(_error!), const SizedBox(height: 14)],
                if (_checkin != null) ...[
                  IpCard(
                    pad: 14,
                    child: Row(children: [
                      SizedBox(width: 38, height: 38, child: Center(child: IpIcon('pin', size: 22, color: c.azure600))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_tapakNama, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text)),
                          Text(_gpsActive ? _gpsShort : 'Lokasi GPS tidak tersedia',
                              style: ipMono(context, size: 12, color: c.text3)),
                        ]),
                      ),
                      IpChip(_gpsActive ? 'GPS aktif' : 'Tiada GPS',
                          small: true, dot: true, tone: _gpsActive ? IpTone.emerald : IpTone.amber),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  IpSectionLabel('Gambar (${_images.length}/$_maxImages)', icon: 'image'),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1,
                    children: [
                      for (final (i, img) in _images.indexed) _thumb(context, i, img),
                      if (_images.length < _maxImages) _addTile(context, canAdd),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(padding: const EdgeInsets.only(top: 1), child: IpIcon('info', size: 14, color: c.text3)),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text('Timestamp & koordinat GPS akan ditera secara automatik.',
                          style: TextStyle(fontSize: 12, color: c.text3)),
                    ),
                  ]),
                ],
              ],
            ),
    );
  }

  Widget _thumb(BuildContext context, int i, _UploadedImage img) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(fit: StackFit.expand, children: [
        Image.memory(img.bytes, fit: BoxFit.cover),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [const Color(0xFF080E1A).withValues(alpha: .8), Colors.transparent],
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_formatTimestampShort(img.capturedAt), style: ipMono(context, size: 10, color: Colors.white)),
              Text(_gpsShort, style: ipMono(context, size: 9.5, color: const Color(0xFF9EC1FF))),
            ]),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: Material(
            color: Colors.black.withValues(alpha: .55),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _removeImage(i),
              child: const SizedBox(width: 32, height: 32, child: Center(child: IpIcon('x', size: 16, color: Colors.white))),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _addTile(BuildContext context, bool enabled) {
    final c = context.ip;
    return Material(
      color: c.surface2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: c.line2, width: 1.5)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? _handleAddPhoto : null,
        child: Stack(children: [
          Center(
            child: _uploading
                ? CircularProgressIndicator(strokeWidth: 2.4, color: c.azure500)
                : Column(mainAxisSize: MainAxisSize.min, children: [
                    IpIcon('camera', size: 26, color: enabled ? c.azure600 : c.text3),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('Ketuk untuk ambil / letak gambar',
                          textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: c.text2, fontWeight: FontWeight.w600)),
                    ),
                  ]),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF080E1A).withValues(alpha: .7), borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const IpIcon('pin', size: 11, color: Color(0xFF5798FF)),
                const SizedBox(width: 5),
                Text('Tera GPS auto', style: ipMono(context, size: 9.5, color: Colors.white)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
