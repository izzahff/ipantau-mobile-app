import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/ip_format.dart';
import '../../widgets/v2/dash_widgets.dart';
import '../../widgets/v2/ui.dart';
import 'gambar_screen.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key, this.initialTapakId});

  final int? initialTapakId;

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {  final MapController _mapController = MapController();

  bool _loadingTapak = true;
  bool _loadingCheckin = true;
  bool _buttonLoading = false;
  bool _checkinBerjaya = false;

  String? _error;

  List<Map<String, dynamic>> _tapakList = [];
  int? _selectedTapakId;
  Map<String, dynamic>? _selectedTapak;

  Map<String, dynamic>? _checkinHariIni;
  Map<String, dynamic>? _activeCheckin;

  Position? _pos;
  StreamSubscription<Position>? _posSub;

  double? _jarakMeter;
  bool? _dalamGeofence;

  bool _locationFromMap = false;
  LatLng? _pickedLatLng;


  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await Future.wait([_loadTapak(), _startGps()]);
    await Future.wait([_loadCheckinHariIni(), _loadActiveCheckin()]);
    _recalcDistance();
  }

  String? _token(BuildContext context) => context.read<AuthProvider>().token;

  Future<void> _loadTapak() async {
    setState(() {
      _loadingTapak = true;
      _error = null;
    });

    final token = _token(context);
    if (token == null) {
      setState(() {
        _loadingTapak = false;
        _error = 'Sesi tamat. Sila log masuk semula.';
      });
      return;
    }

    final res = await ApiService.getTapakSaya(token);
    if (!mounted) return;

    if (res['success'] == true) {
      final list = (res['data'] as List?) ?? [];
      _tapakList =
          list.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      if (_tapakList.isNotEmpty) {
        final wanted = widget.initialTapakId;
        Map<String, dynamic>? pick;
        if (wanted != null) {
          for (final t in _tapakList) {
            if ((t['id'] as num).toInt() == wanted) {
              pick = t;
              break;
            }
          }
        }
        pick ??= _tapakList.first;
        _selectedTapakId = (pick['id'] as num).toInt();
        _selectedTapak = pick;
      }

      setState(() {
        _loadingTapak = false;
      });

      _moveMapToTapak();
      _recalcDistance();
    } else {
      setState(() {
        _loadingTapak = false;
        _error = res['message'] ?? 'Gagal muatkan senarai tapak.';
      });
    }
  }

  Future<void> _loadCheckinHariIni() async {
    setState(() {
      _loadingCheckin = true;
      _error = null;
    });

    final token = _token(context);
    if (token == null) {
      setState(() {
        _loadingCheckin = false;
        _error = 'Sesi tamat. Sila log masuk semula.';
      });
      return;
    }

    final res = await ApiService.getCheckinHariIni(token, tapakId: _selectedTapakId);
    if (!mounted) return;

    if (res['success'] == true) {
      final data = res['data'];
      setState(() {
        _checkinHariIni =
            data == null ? null : Map<String, dynamic>.from(data as Map);
        _loadingCheckin = false;
      });
    } else {
      setState(() {
        _loadingCheckin = false;
        _error = res['message'] ?? 'Gagal semak check-in hari ini.';
      });
    }
  }

  bool get _hasActiveCheckinElsewhere {
    final active = _activeCheckin;
    if (active == null) return false;
    if (active['masa_checkout'] != null) return false;
    if (_selectedTapakId == null) return false;
    return (active['tapak_id'] as num).toInt() != _selectedTapakId;
  }

  Future<void> _loadActiveCheckin() async {
    final token = _token(context);
    if (token == null) return;
    final res = await ApiService.getActiveCheckin(token);
    if (!mounted) return;
    if (res['success'] == true) {
      final data = res['data'];
      setState(() {
        _activeCheckin =
            data == null ? null : Map<String, dynamic>.from(data as Map);
      });
    }
  }

  Future<void> _startGps() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() {
          _error = 'Sila hidupkan GPS untuk check-in.';
        });
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Kebenaran lokasi disekat. Sila aktifkan dalam tetapan.';
        });
        return;
      }
      if (perm == LocationPermission.denied) {
        setState(() {
          _error = 'Kebenaran lokasi diperlukan untuk check-in.';
        });
        return;
      }

      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() => _pos = p);

      _posSub?.cancel();
      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((pos) {
        if (!mounted) return;
        setState(() => _pos = pos);
        if (!_locationFromMap) {
          _recalcDistance();
        }
      });
    } catch (_) {
      setState(() {
        _error = 'Gagal dapatkan lokasi. Cuba lagi.';
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() {
        _pos = p;
        _locationFromMap = false;
        _pickedLatLng = null;
      });
      _mapController.move(LatLng(p.latitude, p.longitude), 16);
      _recalcDistance();
    } catch (_) {
      if (!mounted) return;
      showIpToast(context, 'Gagal mendapatkan lokasi. Cuba lagi.', tone: IpToastTone.danger);
    }
  }

  Future<void> _pickOnMap() async {
    final tapak = _selectedTapak;
    if (tapak == null) return;
    final center = LatLng(
      (tapak['latitud'] as num).toDouble(),
      (tapak['longitud'] as num).toDouble(),
    );
    var draft = _pickedLatLng ?? (_pos != null ? LatLng(_pos!.latitude, _pos!.longitude) : center);

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Pilih di peta'),
              content: SizedBox(
                width: double.maxFinite,
                height: 280,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: draft,
                    initialZoom: 16,
                    onTap: (_, latlng) {
                      draft = latlng;
                      setDialogState(() {});
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'ipantau',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: draft,
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.place,
                            color: context.ip.navy800,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _pickedLatLng = draft;
                      _locationFromMap = true;
                    });
                    Navigator.pop(ctx);
                    _recalcDistance();
                  },
                  child: const Text('Guna lokasi ini'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _moveMapToTapak() {
    final tapak = _selectedTapak;
    if (tapak == null) return;
    final lat = (tapak['latitud'] as num).toDouble();
    final lon = (tapak['longitud'] as num).toDouble();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapController.move(LatLng(lat, lon), 16);
    });
  }

  LatLng? get _effectiveLatLng {
    if (_locationFromMap && _pickedLatLng != null) return _pickedLatLng;
    final pos = _pos;
    if (pos == null) return null;
    return LatLng(pos.latitude, pos.longitude);
  }

  void _recalcDistance() {
    final tapak = _selectedTapak;
    final ll = _effectiveLatLng;
    if (tapak == null || ll == null) return;

    final lat2 = (tapak['latitud'] as num).toDouble();
    final lon2 = (tapak['longitud'] as num).toDouble();
    final radius = (tapak['radius_geofence'] as num).toDouble();

    final d =
        Geolocator.distanceBetween(ll.latitude, ll.longitude, lat2, lon2);
    setState(() {
      _jarakMeter = d;
      _dalamGeofence = d <= radius;
    });
  }

  Future<void> _confirmCheckin() async {
    final tapak = _selectedTapak;
    final ll = _effectiveLatLng;
    if (tapak == null || ll == null) return _doCheckin();
    final ok = await showIpSheet<bool>(
      context,
      title: 'Sahkan check-in',
      builder: (ctx) => _ConfirmBody(
        icon: 'pin',
        iconColor: ctx.ip.azure600,
        title: _namaTapak(tapak),
        sub: '${_kodTapak(tapak)} · ${IpFormat.coord(ll.latitude, ll.longitude)}',
        info: 'Lokasi dan masa anda akan direkodkan untuk ${IpFormat.today()}.',
        button: IpButton('Sahkan Check-In',
            full: true, size: IpButtonSize.lg, variant: IpButtonVariant.emerald, icon: 'check',
            onPressed: () => Navigator.pop(ctx, true)),
      ),
    );
    if (ok == true) await _doCheckin();
  }

  Future<void> _confirmCheckout() async {
    final tapak = _selectedTapak;
    final masuk = CheckinState.from(_checkinHariIni).masuk;
    final ok = await showIpSheet<bool>(
      context,
      title: 'Sahkan check-out',
      builder: (ctx) => _ConfirmBody(
        icon: 'logout',
        iconColor: ctx.ip.icon,
        title: tapak == null ? 'Tapak' : _namaTapak(tapak),
        sub: '${tapak == null ? '' : '${_kodTapak(tapak)} · '}check-in ${IpFormat.time(masuk)}',
        info: 'Masa tamat kerja akan direkodkan dan sesi anda ditutup.',
        button: IpButton('Sahkan Check-Out',
            full: true, size: IpButtonSize.lg, variant: IpButtonVariant.navy, icon: 'check',
            onPressed: () => Navigator.pop(ctx, true)),
      ),
    );
    if (ok == true) await _doCheckout();
  }

  void _selectTapak(int val) {
    setState(() {
      _selectedTapakId = val;
      _selectedTapak = _tapakList.firstWhere(
        (t) => (t['id'] as num).toInt() == val,
        orElse: () => _tapakList.first,
      );
      _checkinBerjaya = false;
    });
    _moveMapToTapak();
    _recalcDistance();
    _loadCheckinHariIni();
    _loadActiveCheckin();
  }

  Future<void> _pickTapakSheet() async {
    if (_tapakList.isEmpty) return;
    final picked = await showIpSheet<int>(
      context,
      title: 'Pilih Tapak',
      builder: (ctx) {
        final c = ctx.ip;
        return Column(children: [
          for (final t in _tapakList)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: IpCard(
                pad: 14,
                borderColor: (t['id'] as num).toInt() == _selectedTapakId ? c.azure500 : null,
                color: (t['id'] as num).toInt() == _selectedTapakId ? c.azure50 : null,
                onTap: () => Navigator.pop(ctx, (t['id'] as num).toInt()),
                child: Row(children: [
                  IpIcon('pin', size: 22, color: c.azure600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_namaTapak(t), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text)),
                      Text(_kodTapak(t), style: ipMono(ctx, size: 12, color: c.text3)),
                    ]),
                  ),
                  if ((t['id'] as num).toInt() == _selectedTapakId) IpIcon('checkCircle', size: 20, color: c.azure600),
                ]),
              ),
            ),
        ]);
      },
    );
    if (picked != null && picked != _selectedTapakId) _selectTapak(picked);
  }

  static String _namaTapak(Map<String, dynamic> t) => (t['nama_tapak'] ?? t['nama'])?.toString() ?? '-';
  static String _kodTapak(Map<String, dynamic> t) => t['kod_tapak']?.toString() ?? '-';

  Future<void> _doCheckin() async {
    final token = _token(context);
    final tapak = _selectedTapak;
    final ll = _effectiveLatLng;

    if (token == null) {
      setState(() => _error = 'Sesi tamat. Sila log masuk semula.');
      return;
    }
    if (tapak == null) {
      setState(() => _error = 'Sila pilih tapak.');
      return;
    }
    if (ll == null) {
      setState(() => _error =
          'Lokasi belum tersedia. Pilih "Lokasi semasa" atau "Pilih di peta".');
      return;
    }

    if (_dalamGeofence != true) {
      setState(() => _error =
          'Anda berada di luar kawasan tapak. Check-in tidak dibenarkan.');
      return;
    }

    setState(() {
      _buttonLoading = true;
      _error = null;
    });

    final tapakId = (tapak['id'] as num).toInt();
    final res = await ApiService.createCheckin(
      token: token,
      tapakId: tapakId,
      lat: ll.latitude,
      lon: ll.longitude,
    );

    if (!mounted) return;
    setState(() => _buttonLoading = false);

    if (res['success'] == true) {
      if (!mounted) return;
      showIpToast(context, 'Berjaya check-in · ${IpFormat.time(DateTime.now())}');
      setState(() {
        _checkinHariIni = {
          'id': res['checkin_id'],
          'masa_checkin': DateTime.now().toIso8601String(),
          'masa_checkout': null,
          'dalam_geofence': res['dalam_geofence'] ?? false,
          'tapak': res['tapak'],
        };
        _checkinBerjaya = true;
      });
    } else {
      final data = res['data'];
      if (data != null && data['active_tapak'] != null) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Check-in Tidak Dibenarkan'),
            content: Text(
              'Anda masih check-in di ${data['active_tapak']}. '
              'Sila check-out terlebih dahulu sebelum check-in di tapak lain.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Faham'),
              ),
            ],
          ),
        );
        await _loadActiveCheckin();
      } else {
        setState(() {
          _error = res['message'] ?? 'Check-in gagal.';
        });
      }
    }
  }

  Future<void> _doCheckout() async {
    final token = _token(context);
    final checkin = _checkinHariIni;
    if (token == null) {
      setState(() => _error = 'Sesi tamat. Sila log masuk semula.');
      return;
    }
    if (checkin == null) return;

    final checkinId = (checkin['id'] as num).toInt();

    setState(() {
      _buttonLoading = true;
      _error = null;
    });

    final res =
        await ApiService.checkout(token: token, checkinId: checkinId);
    if (!mounted) return;

    setState(() => _buttonLoading = false);

    if (res['success'] == true) {
      await Future.wait([_loadCheckinHariIni(), _loadActiveCheckin()]);
      if (!mounted) return;
      setState(() => _checkinBerjaya = false);
      showIpToast(context, 'Berjaya check-out · ${IpFormat.time(DateTime.now())}');
    } else {
      setState(() => _error = res['message'] ?? 'Checkout gagal.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    final tapak = _selectedTapak;
    final ll = _effectiveLatLng;
    final within = _dalamGeofence == true;
    final ci = CheckinState.from(_checkinHariIni);
    final hasCheckin = _checkinHariIni != null;
    final hasCheckout = ci.checkedOut;
    final activeElsewhere = _hasActiveCheckinElsewhere;
    final radius = tapak?['radius_geofence'];
    final loading = _loadingTapak || _loadingCheckin;

    return IpPushedScaffold(
      title: 'GPS Check-In',
      sub: tapak == null ? null : '${_kodTapak(tapak)} · radius ${radius ?? '-'}m',
      body: RefreshIndicator(
        color: c.azure500,
        onRefresh: () async {
          await _loadTapak();
          await Future.wait([_loadCheckinHariIni(), _loadActiveCheckin()]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) ...[IpErrorBox(_error!), const SizedBox(height: 14)],
            if (activeElsewhere) ...[_activeElsewhereBanner(context), const SizedBox(height: 14)],
            const IpSectionLabel('Pilih Tapak', icon: 'building'),
            _siteSelector(context, tapak),
            const SizedBox(height: 16),
            _map(context, tapak, ll, within),
            const SizedBox(height: 14),
            _statusBanner(context, ll, within),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: IpButton('Lokasi semasa',
                    full: true, variant: IpButtonVariant.outline, icon: 'crosshair', onPressed: _useCurrentLocation),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: IpButton('Pilih di peta',
                    full: true, variant: IpButtonVariant.outline, icon: 'map', onPressed: tapak == null ? null : _pickOnMap),
              ),
            ]),
            const SizedBox(height: 18),
            if (loading && !hasCheckin)
              const IpLoading()
            else if (!hasCheckin)
              IpButton(
                within ? 'Check-In Sekarang' : 'Masuk radius untuk check-in',
                full: true,
                size: IpButtonSize.lg,
                icon: 'pin',
                loading: _buttonLoading,
                onPressed: within && !activeElsewhere && !_checkinBerjaya ? _confirmCheckin : null,
              )
            else if (hasCheckout)
              IpCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    IpIcon('checkCircle', size: 22, color: c.emerald600),
                    const SizedBox(width: 10),
                    Text('Sesi kerja selesai', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.text)),
                  ]),
                  const SizedBox(height: 13),
                  Row(children: [
                    Expanded(child: _SessionStat(label: 'Check-in', value: IpFormat.time(ci.masuk))),
                    const SizedBox(width: 10),
                    Expanded(child: _SessionStat(label: 'Check-out', value: IpFormat.time(ci.keluar))),
                  ]),
                ]),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.emerald50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.emerald500.withValues(alpha: .35)),
                ),
                child: Row(children: [
                  IpIcon('checkCircle', size: 26, color: c.emerald600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Berjaya check-in', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.emerald600)),
                      Text('${tapak == null ? '' : '${_kodTapak(tapak)} · '}${IpFormat.time(ci.masuk)}',
                          style: ipMono(context, size: 13, color: c.text2)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: IpButton('Ambil gambar',
                      full: true,
                      icon: 'camera',
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GambarScreen()))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: IpButton('Check-Out',
                      full: true,
                      variant: IpButtonVariant.navy,
                      icon: 'logout',
                      loading: _buttonLoading,
                      onPressed: _confirmCheckout),
                ),
              ]),
            ],
            const SizedBox(height: 18),
            const IpSectionLabel('Status Hari Ini', icon: 'clock'),
            IpCard(
              pad: 14,
              child: Row(children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasCheckout ? c.text3 : (hasCheckin ? c.emerald500 : c.amber500),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    hasCheckout
                        ? 'Check-in ${IpFormat.time(ci.masuk)} · Check-out ${IpFormat.time(ci.keluar)}'
                        : hasCheckin
                            ? 'Sudah check-in hari ini · ${IpFormat.time(ci.masuk)}'
                            : 'Belum check-in hari ini.',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _siteSelector(BuildContext context, Map<String, dynamic>? tapak) {
    final c = context.ip;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: c.line, width: 1.5)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _loadingTapak ? null : _pickTapakSheet,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            SizedBox(width: 38, height: 38, child: Center(child: IpIcon('pin', size: 22, color: c.azure600))),
            const SizedBox(width: 12),
            Expanded(
              child: _loadingTapak
                  ? Text('Memuatkan tapak…', style: TextStyle(fontSize: 14, color: c.text3))
                  : tapak == null
                      ? Text('Tiada tapak ditugaskan', style: TextStyle(fontSize: 14, color: c.text3))
                      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_namaTapak(tapak), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text)),
                          Text(_kodTapak(tapak), style: ipMono(context, size: 12, color: c.text3)),
                        ]),
            ),
            IpIcon('chevronDown', size: 20, color: c.text3),
          ]),
        ),
      ),
    );
  }

  Widget _map(BuildContext context, Map<String, dynamic>? tapak, LatLng? ll, bool within) {
    final c = context.ip;
    if (tapak == null) {
      return Container(
        height: 252,
        decoration: BoxDecoration(
          color: c.surface3,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.line),
        ),
        alignment: Alignment.center,
        child: Text('Sila pilih tapak.', style: TextStyle(color: c.text3)),
      );
    }
    final site = LatLng((tapak['latitud'] as num).toDouble(), (tapak['longitud'] as num).toDouble());
    final userColor = within ? c.azure500 : c.crimson500;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 252,
        decoration: BoxDecoration(border: Border.all(color: c.line), borderRadius: BorderRadius.circular(18)),
        child: Stack(children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: site, initialZoom: 16),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'ipantau'),
              CircleLayer(circles: [
                CircleMarker(
                  point: site,
                  radius: (tapak['radius_geofence'] as num).toDouble(),
                  useRadiusInMeter: true,
                  color: const Color(0xFF2F7BEF).withValues(alpha: .13),
                  borderColor: const Color(0xFF2F7BEF).withValues(alpha: .55),
                  borderStrokeWidth: 2,
                ),
              ]),
              if (ll != null && !within)
                PolylineLayer(polylines: [
                  Polyline(
                    points: [ll, site],
                    color: c.crimson500.withValues(alpha: .75),
                    strokeWidth: 2,
                    pattern: StrokePattern.dashed(segments: const [4, 5]),
                  ),
                ]),
              MarkerLayer(markers: [
                Marker(
                  point: site,
                  width: 30,
                  height: 38,
                  alignment: Alignment.topCenter,
                  child: CustomPaint(painter: _SitePinPainter(c.navy800)),
                ),
                if (ll != null) Marker(point: ll, width: 40, height: 40, child: _PulseDot(color: userColor)),
              ]),
            ],
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .85), borderRadius: BorderRadius.circular(7)),
              child: Text('© OpenStreetMap', style: ipMono(context, size: 9.5, color: const Color(0xFF8794AA))),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _statusBanner(BuildContext context, LatLng? ll, bool within) {
    final c = context.ip;
    if (ll == null || _jarakMeter == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.line)),
        child: Row(children: [
          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: c.azure600)),
          const SizedBox(width: 10),
          Text('Mencari lokasi…', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: c.text2)),
        ]),
      );
    }
    final fg = within ? c.emerald600 : c.crimson600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: within ? c.emerald50 : c.crimson50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: within ? c.emerald500.withValues(alpha: .35) : c.crimson600.withValues(alpha: .28)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IpIcon(within ? 'checkCircle' : 'xCircle', size: 20, color: fg),
          const SizedBox(width: 9),
          Text(within ? 'Dalam kawasan' : 'Di luar kawasan',
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, letterSpacing: -.15, color: fg)),
          if (_locationFromMap) ...[
            const SizedBox(width: 8),
            const IpChip('dipilih di peta', small: true),
          ],
        ]),
        const SizedBox(height: 9),
        Text(IpFormat.coord(ll.latitude, ll.longitude), style: ipMono(context, size: 13, color: c.text2)),
        const SizedBox(height: 4),
        Text(within ? 'Anda berada dalam radius tapak' : '${_jarakMeter!.toStringAsFixed(0)} meter dari tapak',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: fg)),
      ]),
    );
  }

  Widget _activeElsewhereBanner(BuildContext context) {
    final c = context.ip;
    final tapakData = _activeCheckin?['tapak'];
    final tapakName = tapakData is Map ? (tapakData['nama_tapak'] as String?) ?? 'tapak lain' : 'tapak lain';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.amber50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.amber500.withValues(alpha: .5)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        IpIcon('alert', size: 18, color: c.amberText),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Anda masih check-in di $tapakName. Sila check-out dahulu sebelum check-in di tapak lain.',
            style: TextStyle(fontSize: 13, color: c.amberText, fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    );
  }
}

class _SessionStat extends StatelessWidget {
  const _SessionStat({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 11, color: c.text3, fontWeight: FontWeight.w700, letterSpacing: .55)),
        const SizedBox(height: 3),
        Text(value, style: ipMono(context, size: 18, weight: FontWeight.w800, color: c.text)),
      ]),
    );
  }
}

class _ConfirmBody extends StatelessWidget {
  const _ConfirmBody({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.sub,
    required this.info,
    required this.button,
  });
  final String icon, title, sub, info;
  final Color iconColor;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    final c = context.ip;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 6, 0, 16),
        child: Row(children: [
          SizedBox(width: 46, height: 46, child: Center(child: IpIcon(icon, size: 24, color: iconColor))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: c.text)),
              Text(sub, style: ipMono(context, size: 12.5, color: c.text3)),
            ]),
          ),
        ]),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(12)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 1), child: IpIcon('info', size: 17, color: c.azure600)),
          const SizedBox(width: 9),
          Expanded(child: Text(info, style: TextStyle(fontSize: 13, color: c.text2))),
        ]),
      ),
      const SizedBox(height: 16),
      button,
    ]);
  }
}

/// Navy site pin with white centre (map marker).
class _SitePinPainter extends CustomPainter {
  _SitePinPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final kx = s.width / 24, ky = s.height / 30;
    final path = Path()
      ..moveTo(12 * kx, 29 * ky)
      ..cubicTo(12 * kx, 29 * ky, 21 * kx, 21.5 * ky, 21 * kx, 13 * ky)
      ..arcToPoint(Offset(3 * kx, 13 * ky), radius: Radius.elliptical(9 * kx, 9 * ky), largeArc: true, clockwise: false)
      ..cubicTo(3 * kx, 21.5 * ky, 12 * kx, 29 * ky, 12 * kx, 29 * ky)
      ..close();
    canvas.drawShadow(path, Colors.black, 3, false);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawCircle(Offset(12 * kx, 12 * ky), 3.6 * kx, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _SitePinPainter old) => old.color != color;
}

/// User location dot with pulse ring (ip-pulse-ring).
class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});
  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Stack(alignment: Alignment.center, children: [
      if (!reduce)
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, _) {
            final t = (_ctrl.value / .7).clamp(0.0, 1.0);
            return Transform.scale(
              scale: .7 + .8 * t,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withValues(alpha: .55 * (1 - t))),
              ),
            );
          },
        ),
      Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 8, offset: const Offset(0, 2))],
        ),
      ),
    ]);
  }
}
