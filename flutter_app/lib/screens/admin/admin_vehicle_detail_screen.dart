import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/app_theme.dart';
import '../../models/vehicle.dart';
import '../../services/api_service.dart';
import 'tabs/admin_fleet_tab.dart';

class AdminVehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;
  const AdminVehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<AdminVehicleDetailScreen> createState() => _AdminVehicleDetailScreenState();
}

class _AdminVehicleDetailScreenState extends State<AdminVehicleDetailScreen> {
  late Vehicle _vehicle;
  bool _loading = false;
  
  // Dummy telemetry data
  late final double _dummySpeed;
  late final int _dummyBattery;
  late final LatLng _dummyLatLng;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
    
    // Generate static dummy telemetry so it stays consistent for this screen instance
    final rand = Random(_vehicle.id.hashCode);
    _dummySpeed = 10.0 + rand.nextDouble() * 15.0; // 10 to 25 km/h
    _dummyBattery = 50 + rand.nextInt(45); // 50% to 95%
    
    // Random offset around New Delhi (28.6139, 77.2090)
    final latOffset = (rand.nextDouble() - 0.5) * 0.015;
    final lngOffset = (rand.nextDouble() - 0.5) * 0.015;
    _dummyLatLng = LatLng(28.6139 + latOffset, 77.2090 + lngOffset);
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final detail = await ApiService.fetchVehicleDetail(_vehicle.id);
      if (mounted) {
        setState(() {
          _vehicle = Vehicle.fromJson(detail);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openEdit() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VehicleEditSheet(
        vehicle: _vehicle,
        onUpdated: () {
          _refresh();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(_vehicle.status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_vehicle.vehicleId),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Vehicle',
            onPressed: _openEdit,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : Column(
              children: [
                _buildTelemetrySummary(statusColor),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildMapSection(),
                        _buildDetailsCard(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTelemetrySummary(Color statusColor) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(_vehicle.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Spacer(),
              const Text('TELEMETRY STATUS: ONLINE', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTelemetryItem(Icons.speed_rounded, '${_dummySpeed.toStringAsFixed(1)} km/h', 'Current Speed'),
              _buildTelemetryItem(Icons.battery_charging_full_rounded, '$_dummyBattery%', 'Battery Charge'),
              _buildTelemetryItem(Icons.signal_cellular_alt_rounded, 'Excellent', 'GPS Signal'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  Widget _buildMapSection() {
    return Container(
      height: 260,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: _dummyLatLng,
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  // Using Google Maps tiles template
                  urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                  userAgentPackageName: 'com.piscoot.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _dummyLatLng,
                      width: 50,
                      height: 50,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(_vehicle.vehicleId, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                          const Icon(Icons.location_on, color: AppColors.accent, size: 28),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: Colors.white.withValues(alpha: 0.8),
                child: const Text('Google Maps Layer', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vehicle Specifications', style: AppTextStyles.heading3),
          const SizedBox(height: 16),
          _buildInfoRow('Variant', _vehicle.variant),
          const Divider(height: 24),
          _buildInfoRow('Battery Type', _vehicle.batteryType),
          const Divider(height: 24),
          _buildInfoRow('Battery Capacity', _vehicle.batteryCapacity),
          const Divider(height: 24),
          _buildInfoRow('Firmware Version', _vehicle.firmwareVersion),
          const Divider(height: 24),
          _buildInfoRow('GPS Tracker', _vehicle.gpsEnabled ? 'ENABLED' : 'DISABLED'),
          const Divider(height: 24),
          _buildInfoRow('Notes', _vehicle.notes.isNotEmpty ? _vehicle.notes : 'No maintenance notes available.'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          flex: 3,
          child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':      return AppColors.statusActive;
      case 'idle':        return AppColors.statusIdle;
      case 'maintenance': return AppColors.statusMaintenance;
      default:            return AppColors.statusOffline;
    }
  }
}
