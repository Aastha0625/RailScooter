import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import 'trackman_base_screen.dart';

class TrackmanGeofencingScreen extends StatefulWidget {
  const TrackmanGeofencingScreen({super.key});

  @override
  State<TrackmanGeofencingScreen> createState() =>
      _TrackmanGeofencingScreenState();
}

class _TrackmanGeofencingScreenState extends State<TrackmanGeofencingScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  bool _locationLoading = true;
  String? _locationError;

  // Fallback if GPS is unavailable
  static const _fallback = LatLng(28.6139, 77.2090);

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _locationError = 'Location permission denied.';
            _locationLoading = false;
          });
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        final latlng = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _currentLocation = latlng;
          _locationLoading = false;
        });
        _mapController.move(latlng, 15);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Could not get location: $e';
          _locationLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final position = _currentLocation ?? _fallback;

    return TrackmanBaseScreen(
      appBar: const CustomAppBar(title: 'My Current Zone'),
      body: Stack(
        children: [
          // ── Flutter Map ────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: position,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.piscoot.app',
              ),
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── Status card overlay ───────────────────────────────────────────
          Positioned(
            top: 24,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        _locationLoading
                            ? Icons.gps_not_fixed
                            : _locationError != null
                                ? Icons.location_off
                                : Icons.check_circle,
                        color: _locationLoading
                            ? Colors.orange
                            : _locationError != null
                                ? Colors.red
                                : Colors.green,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Main Station Zone',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary)),
                            Text(
                              _locationLoading
                                  ? 'Fetching your location…'
                                  : _locationError ?? 'Status: Inside Safe Zone',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: _locationLoading
                                      ? Colors.orange
                                      : _locationError != null
                                          ? Colors.red
                                          : Colors.green,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Max Speed Limit',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('20 km/h',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── My Location FAB ───────────────────────────────────────────────
          Positioned(
            bottom: 32,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: _fetchLocation,
              backgroundColor: AppColors.primary,
              tooltip: 'Centre on my location',
              child: _locationLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
