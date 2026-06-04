import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ipantau_app_bar.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Maksimum $_maxImages gambar sahaja.')),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gambar berjaya dimuat naik.')),
      );
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
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppTheme.sm),
                decoration: BoxDecoration(
                  color: AppTheme.navy.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    color: AppTheme.navy, size: 20),
              ),
              title: const Text('Kamera',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromCamera();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppTheme.sm),
                decoration: BoxDecoration(
                  color: AppTheme.navy.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_outlined,
                    color: AppTheme.navy, size: 20),
              ),
              title: const Text('Galeri',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromGallery();
              },
            ),
            const SizedBox(height: AppTheme.md),
          ],
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final canAdd = !_uploading && !_loading && _images.length < _maxImages;
    final hasPhotos = _images.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const IpantauAppBar(title: 'Ambil Gambar'),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.navy))
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.md,
                AppTheme.md,
                AppTheme.md,
                100,
              ),
              children: [
                _buildTopRow(),
                const SizedBox(height: AppTheme.md),

                if (_error != null) ...[
                  _errorBanner(),
                  const SizedBox(height: AppTheme.md),
                ],

                _buildUploadButton(canAdd: canAdd),
                const SizedBox(height: AppTheme.md),

                _buildPhotoGrid(canAdd: canAdd),
              ],
            ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          AppTheme.md,
          AppTheme.sm,
          AppTheme.md,
          MediaQuery.of(context).padding.bottom + AppTheme.sm + 4,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: hasPhotos ? AppTheme.buttonShadow : [],
          ),
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed:
                  (_loading || _uploading || !hasPhotos) ? null : _goNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navy,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.border,
                disabledForegroundColor: AppTheme.textMuted,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              child: _uploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Seterusnya',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        Text(
          '${_images.length}/$_maxImages gambar',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const Spacer(),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.navyLight.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            border: Border.all(
                color: AppTheme.navyLight.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _gpsActive ? Icons.gps_fixed : Icons.gps_not_fixed,
                size: 12,
                color: AppTheme.navyLight,
              ),
              const SizedBox(width: 4),
              Text(
                _gpsActive ? 'GPS aktif' : 'GPS —',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.navyLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadButton({required bool canAdd}) {
    if (kIsWeb) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: canAdd ? AppTheme.buttonShadow : [],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: canAdd ? _pickFromWebFile : null,
            icon: const Icon(Icons.upload_outlined, size: 18),
            label: const Text(
              'Pilih Gambar dari Fail',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.navy,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.border,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: canAdd ? AppTheme.buttonShadow : [],
            ),
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: canAdd ? _pickFromCamera : null,
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: _uploading
                    ? const Text('Memuat naik...',
                        style: TextStyle(fontWeight: FontWeight.w700))
                    : const Text('Kamera',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.navy,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.border,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.sm + 4),
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: canAdd ? _pickFromGallery : null,
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text('Galeri',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.navy,
                side: const BorderSide(color: AppTheme.navy),
                disabledForegroundColor: AppTheme.textMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoGrid({required bool canAdd}) {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: AppTheme.sm,
      mainAxisSpacing: AppTheme.sm,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(_maxImages, (i) {
        if (i < _images.length) return _filledCell(i);
        return _emptyCell(i, canAdd: canAdd);
      }),
    );
  }

  Widget _filledCell(int index) {
    final img = _images[index];
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(img.bytes, fit: BoxFit.cover),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      _gpsShort,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatTimestampShort(img.capturedAt),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _images.removeAt(index)),
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCell(int index, {required bool canAdd}) {
    final isNext = index == _images.length;
    final tappable = canAdd;
    return GestureDetector(
      onTap: tappable ? _handleAddPhoto : null,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: tappable ? AppTheme.navy.withValues(alpha: 0.30) : AppTheme.border,
        ),
        child: Center(
          child: _uploading && isNext
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.navy),
                )
              : Icon(
                  isNext ? Icons.camera_alt_outlined : Icons.add_rounded,
                  color: tappable ? AppTheme.navy.withValues(alpha: 0.40) : AppTheme.border,
                  size: 24,
                ),
        ),
      ),
    );
  }

  Widget _errorBanner() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.sm + 4),
      decoration: BoxDecoration(
        color: AppTheme.errorLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 16),
          const SizedBox(width: AppTheme.sm),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(fontSize: 12, color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dashed border painter ─────────────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dash = 5.0;
    const gap = 3.5;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
        Radius.circular(8.0),
      ));
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        final end = (dist + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(dist, end), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color;
}
