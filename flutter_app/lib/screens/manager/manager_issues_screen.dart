import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../services/railway_routing_service.dart';
import '../../widgets/custom_app_bar.dart';
import 'manager_base_screen.dart';

class ManagerIssuesScreen extends StatefulWidget {
  const ManagerIssuesScreen({super.key});

  @override
  State<ManagerIssuesScreen> createState() => _ManagerIssuesScreenState();
}

class _ManagerIssuesScreenState extends State<ManagerIssuesScreen> {
  bool _loading = true;
  List<dynamic> _issues = [];

  @override
  void initState() {
    super.initState();
    _fetchIssues();
  }

  Future<void> _fetchIssues() async {
    try {
      final data = await Supabase.instance.client
          .from('trackman_issues')
          .select('''
            id,
            category,
            severity,
            description,
            status,
            location_lat,
            location_lng,
            image_url,
            created_at,
            app_users:reporter_id(full_name),
            vehicles:vehicle_id(vehicle_id)
          ''')
          .eq('status', 'open')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _issues = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading issues: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _resolveIssue(String issueId) async {
    try {
      await Supabase.instance.client
          .from('trackman_issues')
          .update({'status': 'resolved', 'resolved_at': DateTime.now().toIso8601String()})
          .eq('id', issueId);
      
      _fetchIssues(); // Refresh list
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Issue resolved successfully.'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error resolving issue: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Critical': return AppColors.severityCritical;
      case 'Medium': return AppColors.severityMedium;
      case 'Low': return AppColors.statusIdle;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ManagerBaseScreen(
      appBar: const CustomAppBar(title: 'Reported Issues'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _issues.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
                      SizedBox(height: 16),
                      Text('All Clear!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      SizedBox(height: 8),
                      Text('There are no open trackman issues.', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _issues.length,
                  itemBuilder: (context, index) {
                    final issue = _issues[index];
                    return _buildIssueCard(issue);
                  },
                ),
    );
  }

  Widget _buildIssueCard(dynamic issue) {
    final severity = issue['severity'] ?? 'Unknown';
    final severityColor = _getSeverityColor(severity);
    final reporterName = issue['app_users'] != null ? issue['app_users']['full_name'] : 'Unknown';
    final vehicleId = issue['vehicles'] != null ? issue['vehicles']['vehicle_id'] : 'Unknown Vehicle';
    final lat = issue['location_lat'];
    final lng = issue['location_lng'];
    final imageUrl = issue['image_url'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    issue['category'] ?? 'General Issue',
                    style: TextStyle(color: severityColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: severityColor, borderRadius: BorderRadius.circular(20)),
                  child: Text(severity.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(reporterName, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(width: 16),
                    const Icon(Icons.electric_scooter, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(vehicleId, style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13)),
                const SizedBox(height: 4),
                Text(issue['description'] ?? 'No description provided.', style: const TextStyle(color: AppColors.textSecondary)),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                
                // Location & Image Evidence
                if (lat != null && lng != null || imageUrl != null) ...[
                  const Text('Evidence & Context', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    child: Row(
                      children: [
                        if (lat != null && lng != null)
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    insetPadding: const EdgeInsets.all(16),
                                    backgroundColor: Colors.transparent,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: SizedBox(
                                            width: double.infinity,
                                            height: MediaQuery.of(context).size.height * 0.7,
                                            child: _IssueMapWidget(lat: lat, lng: lng),
                                          ),
                                        ),
                                        Positioned(
                                          top: -10,
                                          right: -10,
                                          child: IconButton(
                                            icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                            onPressed: () => Navigator.pop(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: IgnorePointer(
                                  child: _IssueMapWidget(lat: lat, lng: lng),
                                ),
                              ),
                            ),
                          ),
                        if (lat != null && lng != null && imageUrl != null) const SizedBox(width: 12),
                          if (imageUrl != null)
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          InteractiveViewer(
                                            child: Image.network(imageUrl),
                                          ),
                                          Positioned(
                                            top: -10,
                                            right: -10,
                                            child: IconButton(
                                              icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                              onPressed: () => Navigator.pop(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(child: CircularProgressIndicator());
                                    },
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _resolveIssue(issue['id']),
                    icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                    label: const Text('Mark as Resolved', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Issue mini-map with flutter_map + route polyline ────────────────────────

class _IssueMapWidget extends StatefulWidget {
  final double lat;
  final double lng;
  const _IssueMapWidget({required this.lat, required this.lng});

  @override
  State<_IssueMapWidget> createState() => _IssueMapWidgetState();
}

class _IssueMapWidgetState extends State<_IssueMapWidget> {
  bool _loadingRoute = true;
  RailwayRouteResult? _routeResult;
  String? _errorMessage;
  final MapController _mapController = MapController();

  late LatLng _artLocation;
  late LatLng _incidentLocation;

  @override
  void initState() {
    super.initState();
    _incidentLocation = LatLng(widget.lat, widget.lng);
    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (serviceEnabled && (permission == LocationPermission.whileInUse || permission == LocationPermission.always)) {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        _artLocation = LatLng(position.latitude, position.longitude);
      } else {
        _artLocation = const LatLng(28.6139, 77.2090); // Fallback to HQ
      }
    } catch (e) {
      _artLocation = const LatLng(28.6139, 77.2090);
    }

    final service = RailwayRoutingService();
    final result = await service.getRoute(_artLocation, _incidentLocation);
    if (mounted) {
      setState(() {
        _loadingRoute = false;
        if (result != null && result.points.isNotEmpty) {
          _routeResult = result;
        } else {
          _errorMessage = 'Could not calculate railway route.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _routeResult?.snappedEnd ?? _incidentLocation;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 12.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.piscoot.app',
            ),
            if (_routeResult != null) ...[
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routeResult!.points,
                    color: Colors.blueAccent,
                    strokeWidth: 4.0,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Incident marker (Red)
                  Marker(
                    point: _routeResult!.snappedEnd,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                  // ART train marker (Blue)
                  Marker(
                    point: _routeResult!.snappedStart,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.train,
                      color: Colors.blue,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ] else ...[
              MarkerLayer(
                markers: [
                  Marker(
                    point: _incidentLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        if (_loadingRoute)
          const Center(child: CircularProgressIndicator())
        else if (_errorMessage != null)
          Positioned(
            bottom: 8, left: 8, right: 8,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.center),
            ),
          )
        else if (_routeResult != null)
          Positioned(
            top: 8, right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
              child: Text(
                '${(_routeResult!.distanceMeters / 1000).toStringAsFixed(1)} km • ${_routeResult!.etaMinutes.toStringAsFixed(0)} min',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
              ),
            ),
          ),
      ],
    );
  }
}
