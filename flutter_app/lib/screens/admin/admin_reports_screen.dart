import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/vehicle_alert.dart';
import '../../services/api_service.dart';
import '../../utils/formatters.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/railway_routing_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_base_screen.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<VehicleAlert> _alerts = [];
  List<dynamic> _issues = [];
  bool _loading = true;
  bool _showOnlyUnack = false;
  String _filterSeverity = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final alerts = await ApiService.fetchAlertEvents();
      final issuesData = await Supabase.instance.client
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
            resolved_at,
            app_users(full_name),
            vehicles(vehicle_id)
          ''')
          .order('created_at', ascending: false);
          
      if (mounted) {
        setState(() { 
        _alerts = alerts; 
        _issues = issuesData;
        _loading = false; 
      });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<VehicleAlert> get _filtered {
    var list = _alerts;
    if (_showOnlyUnack) list = list.where((a) => !a.isAcknowledged).toList();
    if (_filterSeverity != 'all') list = list.where((a) => a.severity == _filterSeverity).toList();
    return list;
  }

  Future<void> _acknowledge(VehicleAlert alert) async {
    await ApiService.acknowledgeAlert(alert.id);
    await ApiService.logActivity(
      eventType: 'alert_acknowledged',
      description: 'Alert on ${alert.vehicleId} acknowledged (${alert.alertType})',
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return AdminBaseScreen(
      title: 'Incident Reports',
      body: Column(
        children: [
          _buildTopBar(),
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accent,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'Vehicle Alerts'),
                Tab(text: 'Reported Issues'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAlertsTab(),
                      _buildIssuesTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsTab() {
    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: _filtered.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 56, color: AppColors.statusActive),
                      SizedBox(height: 12),
                      Text('No alerts found', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.accent,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _AlertCard(
                      alert: _filtered[i],
                      onAcknowledge: () => _acknowledge(_filtered[i]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildIssuesTab() {
    if (_issues.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.thumb_up_alt_outlined, size: 56, color: AppColors.statusActive),
            SizedBox(height: 12),
            Text('No issues reported', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.accent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: _issues.length,
        itemBuilder: (context, index) {
          final issue = _issues[index];
          return _IssueCard(issue: issue);
        },
      ),
    );
  }

  Widget _buildTopBar() {
    final unackCount = _alerts.where((a) => !a.isAcknowledged).length;
    return Container(
      padding: const EdgeInsets.only(
        top: 0,
        left: 20, right: 20, bottom: 16,
      ),
      color: AppColors.primary,
      child: Row(
        children: [
          const Icon(Icons.report_problem_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reports & Alerts', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                Text('$unackCount unacknowledged', style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          if (unackCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.severityCritical,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$unackCount OPEN',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white70), onPressed: _load),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    const severities = [
      ('all', 'All'),
      ('critical', 'Critical'),
      ('high', 'High'),
      ('medium', 'Medium'),
      ('low', 'Low'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: severities.map((f) {
                      final isSelected = _filterSeverity == f.$1;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _filterSeverity = f.$1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected ? _severityColor(f.$1) : AppColors.background,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? _severityColor(f.$1) : AppColors.cardBorder),
                            ),
                            child: Text(f.$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : AppColors.textSecondary)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _showOnlyUnack,
                  onChanged: (v) => setState(() => _showOnlyUnack = v),
                  activeThumbColor: AppColors.accent,
                ),
              ),
              const Text('Unack only', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }

  Color _severityColor(String s) {
    switch (s) {
      case 'critical': return AppColors.severityCritical;
      case 'high':     return AppColors.severityHigh;
      case 'medium':   return AppColors.severityMedium;
      case 'low':      return AppColors.severityLow;
      default:         return AppColors.textSecondary;
    }
  }
}

class _AlertCard extends StatelessWidget {
  final VehicleAlert alert;
  final VoidCallback onAcknowledge;

  const _AlertCard({required this.alert, required this.onAcknowledge});

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(alert.severity);
    final timeAgo = _timeAgo(alert.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(_alertIcon(alert.alertType), color: color, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(Formatters.formatAlertMessage(alert.alertType, alert.message.isEmpty ? alert.alertType : alert.message),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                      Text('Vehicle: ${alert.vehicleId.substring(0, 8)}...',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _SeverityBadge(severity: alert.severity),
                    const SizedBox(height: 4),
                    Text(timeAgo, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                  ],
                ),
              ],
            ),
            if (!alert.isAcknowledged) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Acknowledge', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.statusActive,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: const Size(0, 32),
                  ),
                  onPressed: onAcknowledge,
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 13, color: AppColors.statusActive),
                  SizedBox(width: 4),
                  Text('Acknowledged', style: TextStyle(fontSize: 11, color: AppColors.statusActive, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _severityColor(String s) {
    switch (s) {
      case 'critical': return AppColors.severityCritical;
      case 'high':     return AppColors.severityHigh;
      case 'medium':   return AppColors.severityMedium;
      case 'low':      return AppColors.severityLow;
      default:         return AppColors.textSecondary;
    }
  }

  IconData _alertIcon(String type) {
    switch (type) {
      case 'speed':     return Icons.speed_rounded;
      case 'battery':   return Icons.battery_alert_rounded;
      case 'geofence':  return Icons.fence_rounded;
      case 'idle_time': return Icons.timer_off_rounded;
      case 'movement':  return Icons.warning_rounded;
      default:          return Icons.notifications_active_rounded;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60)  return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)    return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _SeverityBadge extends StatelessWidget {
  final String severity;
  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (severity) {
      case 'critical': color = AppColors.severityCritical; break;
      case 'high':     color = AppColors.severityHigh; break;
      case 'medium':   color = AppColors.severityMedium; break;
      default:         color = AppColors.severityLow;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(severity.toUpperCase(), style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700)),
    );
  }
}
class _IssueCard extends StatelessWidget {
  final dynamic issue;
  const _IssueCard({required this.issue});

  Color _severityColor(String s) {
    switch (s) {
      case 'critical': return AppColors.severityCritical;
      case 'high':     return AppColors.severityHigh;
      case 'medium':   return AppColors.severityMedium;
      case 'low':      return AppColors.severityLow;
      default:         return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final severity = issue['severity'] ?? 'Unknown';
    final severityColor = _severityColor(severity);
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: severityColor, borderRadius: BorderRadius.circular(12)),
                  child: Text(severity.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(issue['description'] ?? 'No description provided.', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.4)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: AppColors.textLight),
                    const SizedBox(width: 6),
                    Text(reporterName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(width: 16),
                    const Icon(Icons.electric_scooter, size: 16, color: AppColors.textLight),
                    const SizedBox(width: 6),
                    Text(vehicleId, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 16),

                // Map and Image Row
                if ((lat != null && lng != null) || imageUrl != null) ...[
                  SizedBox(
                    height: 120,
                    child: Row(
                      children: [
                        if (lat != null && lng != null)
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
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
                                child: AbsorbPointer(
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
                
                // Status badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: issue['status'] == 'resolved' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: issue['status'] == 'resolved' ? Colors.green : Colors.orange),
                      ),
                      child: Text(
                        (issue['status'] ?? 'pending').toString().toUpperCase(),
                        style: TextStyle(
                          color: issue['status'] == 'resolved' ? Colors.green : Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
              child: const Text(
                ' km -  min',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
              ),
            ),
          ),
      ],
    );
  }
}
