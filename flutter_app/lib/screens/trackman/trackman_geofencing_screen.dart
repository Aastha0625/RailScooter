import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';

class TrackmanGeofencingScreen extends StatelessWidget {
  const TrackmanGeofencingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy coordinates for the demonstration map
    const currentLocation = LatLng(51.509865, -0.118092); // Example: London Waterloo area
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'My Current Zone'),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: currentLocation,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.pisolve.railscooter',
              ),
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: [
                      const LatLng(51.512, -0.122),
                      const LatLng(51.512, -0.112),
                      const LatLng(51.505, -0.112),
                      const LatLng(51.505, -0.122),
                    ],
                    color: Colors.green.withValues(alpha: 0.2),
                    isFilled: true,
                    borderColor: Colors.green,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentLocation,
                    width: 60,
                    height: 60,
                    child: const Icon(Icons.electric_scooter, color: AppColors.accent, size: 40),
                  ),
                ],
              ),
            ],
          ),
          
          // Overlay Status Card
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
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Main Station Zone', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            Text('Status: Inside Safe Zone', style: TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Max Speed Limit', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                      Text('20 km/h', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
