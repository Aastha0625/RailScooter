import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../theme/app_theme.dart';
import '../../models/geofence.dart';
import '../../models/vehicle_location.dart';
import '../../services/api_service.dart';
import '../../services/railway_routing_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../admin/admin_base_screen.dart';
import '../manager/manager_base_screen.dart';
import '../trackman/trackman_base_screen.dart';
import '../trackman/map_picker_screen.dart';

class GeofenceTrackingScreen extends StatefulWidget {
  final String userRole;
  const GeofenceTrackingScreen({super.key, this.userRole = 'admin'});

  @override
  State<GeofenceTrackingScreen> createState() => _GeofenceTrackingScreenState();
}

class _GeofenceTrackingScreenState extends State<GeofenceTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Geofence> _geofences = [];
  List<VehicleLocation> _liveLocations = [];
  bool _loading = true;
  final MapController _mapController = MapController();
  Timer? _pollingTimer;
  LatLng? _userLocation;

  static const _defaultCenter = LatLng(28.6139, 77.2090); // New Delhi fallback

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(_handleTabChange);
    _fetchUserLocation();
    _load();
    _startPolling();
  }

  /// Requests GPS permission and fetches the device's current position.
  /// Animates the map camera to it once the map is ready.
  Future<void> _fetchUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) { return; }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latlng = LatLng(pos.latitude, pos.longitude);
      if (mounted) setState(() => _userLocation = latlng);

      // If the map is already created, jump to the user's position
      _mapController.move(latlng, 14);
    } catch (e) {
      debugPrint('Could not get user location: $e');
    }
  }

  /// Re-centres the camera on the user's live GPS position.
  Future<void> _goToMyLocation() async {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 15);
    } else {
      await _fetchUserLocation();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tabs.removeListener(_handleTabChange);
    _tabs.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _pollSilent();
    });
  }

  Future<void> _pollSilent() async {
    try {
      final rawLocations = await ApiService.fetchLiveTracking();
      final routingService = RailwayRoutingService();
      final snappedLocations = <VehicleLocation>[];
      for (final loc in rawLocations) {
        final snapped = await routingService.snapToTrack(
            LatLng(loc.latitude, loc.longitude));
        if (snapped != null) {
          snappedLocations.add(VehicleLocation(
            vehicleId: loc.vehicleId,
            vehicleLabel: loc.vehicleLabel,
            latitude: snapped.latitude,
            longitude: snapped.longitude,
            speedKmh: loc.speedKmh,
            batteryPercent: loc.batteryPercent,
            isOnline: loc.isOnline,
            recordedAt: loc.recordedAt,
          ));
        } else {
          snappedLocations.add(loc);
        }
      }
      if (mounted) {
        setState(() {
          _liveLocations = snappedLocations;
        });
      }
    } catch (e) {
      debugPrint('Silent poll error: $e');
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.fetchGeofences(),
        ApiService.fetchLiveTracking(),
      ]);
      final rawLocations = results[1] as List<VehicleLocation>;

      final routingService = RailwayRoutingService();
      final snappedLocations = <VehicleLocation>[];
      for (final loc in rawLocations) {
        final snapped = await routingService.snapToTrack(
            LatLng(loc.latitude, loc.longitude));
        if (snapped != null) {
          snappedLocations.add(VehicleLocation(
            vehicleId: loc.vehicleId,
            vehicleLabel: loc.vehicleLabel,
            latitude: snapped.latitude,
            longitude: snapped.longitude,
            speedKmh: loc.speedKmh,
            batteryPercent: loc.batteryPercent,
            isOnline: loc.isOnline,
            recordedAt: loc.recordedAt,
          ));
        } else {
          snappedLocations.add(loc);
        }
      }

      if (mounted) {
        setState(() {
          _geofences = results[0] as List<Geofence>;
          _liveLocations = snappedLocations;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load tracking data: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
            action: SnackBarAction(
                label: 'Retry', textColor: Colors.white, onPressed: _load),
          ),
        );
      }
    }
  }

  // Build markers from live vehicle locations
  List<Marker> _buildMarkers() {
    return _liveLocations.map((loc) {
      return Marker(
        point: LatLng(loc.latitude, loc.longitude),
        width: 40,
        height: 40,
        child: Tooltip(
          message: '${loc.vehicleLabel}\n${loc.speedKmh.toStringAsFixed(1)} km/h · Battery ${loc.batteryPercent}%',
          child: Icon(
            Icons.location_on,
            color: loc.isOnline ? Colors.green : Colors.red,
            size: 32,
          ),
        ),
      );
    }).toList();
  }

  // Build circles from active geofences
  List<CircleMarker> _buildCircles() {
    return _geofences.where((g) => g.isActive).map((g) {
      final color = _hexToColor(g.colorHex);
      return CircleMarker(
        point: LatLng(g.centerLat, g.centerLng),
        radius: g.radiusMeters,
        useRadiusInMeter: true,
        color: color.withValues(alpha: 0.15),
        borderColor: color,
        borderStrokeWidth: 2,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appBar = CustomAppBar(
      title: 'GeoFence & Tracking',
      bottom: TabBar(
        controller: _tabs,
        indicatorColor: AppColors.accent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        tabs: const [
          Tab(text: 'Live Map'),
          Tab(text: 'Geofences'),
        ],
      ),
    );

    final floatingActionButton = FloatingActionButton(
      onPressed: () => _tabs.index == 1 ? _showAddGeofence() : _load(),
      backgroundColor: AppColors.accent,
      child: Icon(_tabs.index == 1 ? Icons.add : Icons.refresh,
          color: Colors.white),
    );

    final body = _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
        : TabBarView(
            controller: _tabs,
            children: [
              _buildLiveMap(),
              _buildGeofenceList(),
            ],
          );

    if (widget.userRole == 'manager') {
      return ManagerBaseScreen(
          appBar: appBar,
          body: body,
          floatingActionButton: floatingActionButton);
    } else if (widget.userRole == 'trackman') {
      return TrackmanBaseScreen(
          appBar: appBar,
          body: body,
          floatingActionButton: floatingActionButton);
    }
    return AdminBaseScreen(
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton);
  }

  Widget _buildLiveMap() {
    // Start at user's GPS position; fall back to first vehicle or New Delhi
    final initialPosition = _userLocation ??
        (_liveLocations.isNotEmpty
            ? LatLng(_liveLocations.first.latitude, _liveLocations.first.longitude)
            : _defaultCenter);

    return Column(
      children: [
        _buildLiveStats(),
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialPosition,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.piscoot.app',
              ),
              CircleLayer(
                circles: _buildCircles(),
              ),
              MarkerLayer(
                markers: _buildMarkers(),
              ),
            ],
          ),
        ),
        if (_liveLocations.isNotEmpty) _buildVehicleBottomSheet(),
      ],
    );
  }

  Widget _buildLiveStats() {
    final online = _liveLocations.where((l) => l.isOnline).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          _statPill(Icons.circle, '$online Online', AppColors.statusActive),
          const SizedBox(width: 8),
          _statPill(Icons.electric_scooter_outlined,
              '${_liveLocations.length} Tracked', AppColors.primary),
          const SizedBox(width: 8),
          _statPill(Icons.pentagon_outlined,
              '${_geofences.length} Zones', AppColors.accent),
          const Spacer(),
          // My Location button — centres camera on device GPS
          IconButton(
            icon: const Icon(Icons.my_location, size: 20),
            onPressed: _goToMyLocation,
            tooltip: 'My Location',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: AppColors.accent,
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _load,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }


  Widget _statPill(IconData icon, String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ],
      );

  Widget _buildVehicleBottomSheet() {
    return Container(
      height: 100,
      color: Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        itemCount: _liveLocations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final loc = _liveLocations[i];
          return GestureDetector(
            onTap: () {
              _mapController.move(
                  LatLng(loc.latitude, loc.longitude), 16);
            },
            child: Container(
              width: 130,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: loc.isOnline
                              ? AppColors.statusActive
                              : AppColors.statusOffline,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(loc.vehicleLabel,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${loc.speedKmh.toStringAsFixed(1)} km/h',
                      style: AppTextStyles.caption),
                  Text('Battery: ${loc.batteryPercent}%',
                      style: AppTextStyles.caption),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGeofenceList() {
    if (_geofences.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pentagon_outlined, size: 56, color: AppColors.textLight),
            SizedBox(height: 12),
            Text('No geofences defined', style: AppTextStyles.heading3),
            Text('Tap + to add a geofence zone', style: AppTextStyles.bodySmall),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.accent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _geofences.length,
        itemBuilder: (_, i) => _GeofenceCard(
          geofence: _geofences[i],
          onViewOnMap: () {
            _tabs.animateTo(0);
            Future.delayed(const Duration(milliseconds: 300), () {
              _mapController.move(
                  LatLng(_geofences[i].centerLat, _geofences[i].centerLng),
                  15);
            });
          },
        ),
      ),
    );
  }

  void _showAddGeofence() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final radiusCtrl = TextEditingController(text: '500');
    String fenceType = 'operational';
    bool alertOnExit = true;
    bool alertOnEnter = false;
    final formKey = GlobalKey<FormState>();
    
    LatLng? _selectedLocation;
    bool _fetchingLocation = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add Geofence Zone', style: AppTextStyles.heading2),
                  const SizedBox(height: 20),
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const ['Depot A', 'Depot B', 'Station 1', 'Maintenance Zone', 'Hazard Zone'];
                      }
                      return const ['Depot A', 'Depot B', 'Station 1', 'Maintenance Zone', 'Hazard Zone']
                          .where((String option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (String selection) {
                      nameCtrl.text = selection;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      // Attach our controller if they type manually
                      controller.addListener(() {
                        nameCtrl.text = controller.text;
                      });
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        decoration: const InputDecoration(labelText: 'Zone Name * (Type or select)'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: fenceType,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                              value: 'operational', child: Text('Operational')),
                          DropdownMenuItem(
                              value: 'restricted', child: Text('Restricted')),
                          DropdownMenuItem(
                              value: 'depot', child: Text('Depot')),
                        ],
                        onChanged: (v) => setModal(() => fenceType = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Zone Center Location *', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            setModal(() => _fetchingLocation = true);
                            try {
                              final permission = await Geolocator.checkPermission();
                              if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
                                final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
                                setModal(() => _selectedLocation = LatLng(pos.latitude, pos.longitude));
                              }
                            } catch (_) {}
                            setModal(() => _fetchingLocation = false);
                          },
                          icon: _fetchingLocation 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                            : const Icon(Icons.my_location),
                          label: const Text('Live GPS'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            LatLng startingLocation = _selectedLocation ?? const LatLng(51.509865, -0.118092);
                            if (_selectedLocation == null) {
                              try {
                                final permission = await Geolocator.checkPermission();
                                if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
                                  final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
                                  startingLocation = LatLng(pos.latitude, pos.longitude);
                                }
                              } catch (_) {}
                            }
                            if (!mounted) return;
                            final selected = await Navigator.push<LatLng>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MapPickerScreen(initialLocation: startingLocation),
                              ),
                            );
                            if (selected != null) {
                              setModal(() => _selectedLocation = selected);
                            }
                          },
                          icon: const Icon(Icons.map),
                          label: const Text('Map Pin'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusIdle),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedLocation != null) ...[
                    const SizedBox(height: 8),
                    Text('Location Set: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}', 
                         style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: radiusCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Radius (meters)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Expanded(
                        child: Text('Alert on Exit', style: AppTextStyles.body)),
                    Switch(
                        value: alertOnExit,
                        onChanged: (v) => setModal(() => alertOnExit = v),
                        activeThumbColor: AppColors.accent),
                  ]),
                  Row(children: [
                    const Expanded(
                        child:
                            Text('Alert on Enter', style: AppTextStyles.body)),
                    Switch(
                        value: alertOnEnter,
                        onChanged: (v) => setModal(() => alertOnEnter = v),
                        activeThumbColor: AppColors.accent),
                  ]),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        if (_selectedLocation == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a zone location on the map.')));
                          return;
                        }
                        await ApiService.createGeofence({
                          'name': nameCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'fence_type': fenceType,
                          'center_lat': _selectedLocation!.latitude,
                          'center_lng': _selectedLocation!.longitude,
                          'radius_meters':
                              double.tryParse(radiusCtrl.text) ?? 500,
                          'is_active': true,
                          'alert_on_exit': alertOnExit,
                          'alert_on_enter': alertOnEnter,
                        });
                        if (mounted) {
                          Navigator.pop(context);
                          _load();
                        }
                      },
                      child: const Text('Add Geofence'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}

// ─── Supporting widgets (unchanged) ──────────────────────────────────────────

class _GeofenceCard extends StatelessWidget {
  final Geofence geofence;
  final VoidCallback onViewOnMap;

  const _GeofenceCard({
    required this.geofence,
    required this.onViewOnMap,
  });

  Color get _typeColor {
    switch (geofence.fenceType) {
      case 'restricted':
        return AppColors.severityCritical;
      case 'depot':
        return AppColors.statusIdle;
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onViewOnMap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration:
                      BoxDecoration(color: _typeColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                    child:
                        Text(geofence.name, style: AppTextStyles.heading3)),
                _TypeBadge(type: geofence.fenceType, color: _typeColor),
              ],
            ),
            if (geofence.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(geofence.description, style: AppTextStyles.bodySmall),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 13, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(
                    '${geofence.centerLat.toStringAsFixed(4)}, ${geofence.centerLng.toStringAsFixed(4)}',
                    style: AppTextStyles.caption),
                const SizedBox(width: 8),
                const Icon(Icons.radio_button_unchecked,
                    size: 13, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text('${geofence.radiusMeters.round()}m',
                    style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (geofence.alertOnExit) const _AlertTag(label: 'Exit Alert'),
                if (geofence.alertOnEnter) ...[
                  const SizedBox(width: 6),
                  const _AlertTag(label: 'Entry Alert'),
                ],
                const Spacer(),
                TextButton.icon(
                  onPressed: onViewOnMap,
                  icon: const Icon(Icons.map_outlined, size: 14),
                  label: const Text('Map',
                      style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 28),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
}

class _TypeBadge extends StatelessWidget {
  final String type;
  final Color color;
  const _TypeBadge({required this.type, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(type,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      );
}

class _AlertTag extends StatelessWidget {
  final String label;
  const _AlertTag({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.severityMedium.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 9,
                color: AppColors.severityMedium,
                fontWeight: FontWeight.w600)),
      );
}
