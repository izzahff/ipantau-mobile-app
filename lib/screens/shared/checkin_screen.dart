import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ipantau_app_bar.dart';
import 'gambar_screen.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key, this.initialTapakId, this.appBarColor});

  final int? initialTapakId;
  final Color? appBarColor;

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  final MapController _mapController = MapController();

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

  Color _resolvedAppBarColor(BuildContext context) {
    if (widget.appBarColor != null) return widget.appBarColor!;
    return AppTheme.navy;
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mendapatkan lokasi. Cuba lagi.'),
        ),
      );
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
                          child: const Icon(
                            Icons.place,
                            color: AppTheme.navy,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Check-in berjaya.')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Checkout berjaya.')),
      );
    } else {
      setState(() => _error = res['message'] ?? 'Checkout gagal.');
    }
  }

  String _formatTime(dynamic iso) {
    if (iso == null) return '-';
    final dt = DateTime.tryParse(iso.toString());
    if (dt == null) return '-';
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final tapak = _selectedTapak;
    final ll = _effectiveLatLng;
    final within = _dalamGeofence == true;
    final hasCheckin = _checkinHariIni != null;
    final hasCheckout = _checkinHariIni?['masa_checkout'] != null;
    final activeElsewhere = _hasActiveCheckinElsewhere;
    final mapHeight = MediaQuery.of(context).size.height * 0.40;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: IpantauAppBar(
        title: 'GPS Check-in',
        backgroundColor: _resolvedAppBarColor(context),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadTapak();
            await Future.wait([_loadCheckinHariIni(), _loadActiveCheckin()]);
          },
          color: AppTheme.navy,
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.md,
              vertical: AppTheme.md,
            ),
            children: [
              if (_error != null) ...[
                _errorBanner(),
                const SizedBox(height: AppTheme.md),
              ],

              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih Tapak',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.sm + 2),
                    if (_loadingTapak)
                      const LinearProgressIndicator(
                        minHeight: 4,
                        color: AppTheme.navy,
                      )
                    else
                      DropdownButtonFormField<int>(
                        initialValue: _selectedTapakId,
                        items: _tapakList
                            .map(
                              (t) => DropdownMenuItem<int>(
                                value: (t['id'] as num).toInt(),
                                child: Text(
                                  '${t['kod_tapak']} — ${t['nama_tapak']}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val == null) return;
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
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppTheme.surface,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            borderSide:
                                const BorderSide(color: AppTheme.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            borderSide:
                                const BorderSide(color: AppTheme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            borderSide: const BorderSide(
                                color: AppTheme.navyLight, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                      ),
                  ],
                ),
              ),
              if (activeElsewhere) ...[
                const SizedBox(height: AppTheme.sm + 4),
                _buildActiveCheckinWarning(),
              ],
              const SizedBox(height: AppTheme.md),

              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: Container(
                  height: mapHeight,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: tapak == null
                      ? const Center(
                          child: Text(
                            'Sila pilih tapak.',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        )
                      : FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _pos != null
                                ? LatLng(_pos!.latitude, _pos!.longitude)
                                : LatLng(
                                    (tapak['latitud'] as num).toDouble(),
                                    (tapak['longitud'] as num).toDouble(),
                                  ),
                            initialZoom: 16,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'ipantau',
                            ),
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: LatLng(
                                    (tapak['latitud'] as num).toDouble(),
                                    (tapak['longitud'] as num).toDouble(),
                                  ),
                                  radius: (tapak['radius_geofence'] as num)
                                      .toDouble(),
                                  useRadiusInMeter: true,
                                  color:
                                      AppTheme.navy.withValues(alpha: 0.10),
                                  borderColor:
                                      AppTheme.navy.withValues(alpha: 0.45),
                                  borderStrokeWidth: 2,
                                ),
                              ],
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                    (tapak['latitud'] as num).toDouble(),
                                    (tapak['longitud'] as num).toDouble(),
                                  ),
                                  width: 46,
                                  height: 46,
                                  child: const Icon(
                                    Icons.location_pin,
                                    size: 46,
                                    color: AppTheme.navy,
                                  ),
                                ),
                                if (ll != null)
                                  Marker(
                                    point: ll,
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.my_location,
                                      size: 26,
                                      color: AppTheme.gold,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: AppTheme.md),

              _buildLocationInfoCard(ll: ll, tapak: tapak, within: within),
              const SizedBox(height: AppTheme.sm + 4),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _useCurrentLocation,
                      icon: const Icon(Icons.my_location, size: 16),
                      label: const Text('Lokasi semasa'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.navy,
                        side: const BorderSide(color: AppTheme.navy),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.sm + 4),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: tapak == null ? null : _pickOnMap,
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: const Text('Pilih di peta'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: const BorderSide(color: AppTheme.border),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.md),

              _buildStatusCard(
                hasCheckin: hasCheckin,
                hasCheckout: hasCheckout,
              ),
              const SizedBox(height: AppTheme.md),

              _buildPrimaryButton(
                hasCheckin: hasCheckin,
                hasCheckout: hasCheckout,
                hasActiveCheckinElsewhere: activeElsewhere,
              ),

              if (_checkinBerjaya) ...[
                const SizedBox(height: AppTheme.sm + 4),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    boxShadow: AppTheme.buttonShadow,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const GambarScreen()),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.navy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                      child: const Text(
                        'Seterusnya',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],

              if (hasCheckin && !hasCheckout) ...[
                const SizedBox(height: AppTheme.sm + 4),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _buttonLoading ? null : _doCheckout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: const BorderSide(color: AppTheme.border),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    child: _buttonLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.navy,
                            ),
                          )
                        : const Text(
                            'Check-Out',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],

              const SizedBox(height: AppTheme.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInfoCard({
    required LatLng? ll,
    required Map<String, dynamic>? tapak,
    required bool within,
  }) {
    final hasData = _jarakMeter != null && tapak != null;
    final statusColor = within ? AppTheme.success : AppTheme.error;
    final statusBg = within ? AppTheme.successLight : AppTheme.errorLight;
    final statusText = within ? 'Dalam kawasan geofence' : 'Di luar kawasan';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                within ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: statusColor,
                size: 18,
              ),
              const SizedBox(width: AppTheme.sm),
              Text(
                hasData ? statusText : 'Menunggu lokasi...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: hasData ? statusColor : AppTheme.textMuted,
                ),
              ),
            ],
          ),
          if (ll != null) ...[
            const SizedBox(height: AppTheme.sm - 2),
            Text(
              '${ll.latitude.toStringAsFixed(6)}, ${ll.longitude.toStringAsFixed(6)}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
          if (hasData) ...[
            const SizedBox(height: AppTheme.xs),
            Text(
              '${_jarakMeter!.toStringAsFixed(0)} meter dari tapak',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required bool hasCheckin,
    required bool hasCheckout,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Hari Ini',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.sm + 2),
          if (_loadingCheckin)
            const LinearProgressIndicator(minHeight: 4, color: AppTheme.navy)
          else if (!hasCheckin)
            const Text(
              'Belum check-in hari ini.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            )
          else ...[
            _statusRow(
              icon: Icons.login_rounded,
              label: 'Masa check-in',
              value: _formatTime(_checkinHariIni?['masa_checkin']),
              color: AppTheme.success,
            ),
            const SizedBox(height: AppTheme.xs),
            _statusRow(
              icon: Icons.logout_rounded,
              label: 'Masa checkout',
              value: hasCheckout
                  ? _formatTime(_checkinHariIni?['masa_checkout'])
                  : 'Belum checkout',
              color: hasCheckout ? AppTheme.textSecondary : AppTheme.textMuted,
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: AppTheme.sm - 2),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required bool hasCheckin,
    required bool hasCheckout,
    required bool hasActiveCheckinElsewhere,
  }) {
    final isDisabled =
        (hasCheckin && !hasCheckout) || _checkinBerjaya || hasActiveCheckinElsewhere;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: isDisabled ? [] : AppTheme.buttonShadow,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _buttonLoading || isDisabled ? null : _doCheckin,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE67E22),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.grey.shade500,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
          child: _buttonLoading && !isDisabled
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Check-In',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildActiveCheckinWarning() {
    final tapakData = _activeCheckin?['tapak'];
    final tapakName = tapakData is Map
        ? (tapakData['nama_tapak'] as String?) ?? 'tapak lain'
        : 'tapak lain';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFF92400E), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Anda masih check-in di $tapakName. Sila check-out dahulu sebelum check-in di tapak lain.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
            ),
          ),
        ],
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

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(AppTheme.md),
      child: child,
    );
  }
}
