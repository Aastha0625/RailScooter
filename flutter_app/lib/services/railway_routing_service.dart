import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RailwayRouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double etaMinutes;
  final LatLng snappedStart;
  final LatLng snappedEnd;

  RailwayRouteResult({
    required this.points,
    required this.distanceMeters,
    required this.etaMinutes,
    required this.snappedStart,
    required this.snappedEnd,
  });
}

class RailwayRoutingService {
  static const String _baseUrl = 'https://anveshr312-railway-routing-service.hf.space';
  
  final Dio _dio;

  RailwayRoutingService()
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
        ));

  /// Calculates a railway-bound route between two GPS coordinates.
  Future<RailwayRouteResult?> getRoute(LatLng start, LatLng end) async {
    try {
      final response = await _dio.post(
        '/rail-route',
        data: {
          'start_lat': start.latitude,
          'start_lng': start.longitude,
          'end_lat': end.latitude,
          'end_lng': end.longitude,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Parse snapped points (API returns [lng, lat])
        final snappedStartList = data['snapped_start'] as List;
        final snappedEndList = data['snapped_end'] as List;
        
        final snappedStart = LatLng(snappedStartList[1], snappedStartList[0]);
        final snappedEnd = LatLng(snappedEndList[1], snappedEndList[0]);

        // Parse GeoJSON coordinates
        final features = data['geojson'];
        final geometry = features['geometry'];
        final coordinates = geometry['coordinates'] as List;

        final List<LatLng> points = coordinates.map((coord) {
          final lng = (coord[0] as num).toDouble();
          final lat = (coord[1] as num).toDouble();
          return LatLng(lat, lng);
        }).toList();

        return RailwayRouteResult(
          points: points,
          distanceMeters: (data['distance_meters'] as num).toDouble(),
          etaMinutes: (data['eta_minutes'] as num).toDouble(),
          snappedStart: snappedStart,
          snappedEnd: snappedEnd,
        );
      }
    } catch (e) {
      debugPrint('RailwayRoutingService getRoute error: $e');
    }
    return null;
  }

  /// Snaps a generic GPS coordinate to the nearest physical railway track.
  Future<LatLng?> snapToTrack(LatLng location) async {
    try {
      final response = await _dio.post(
        '/nearest-track',
        data: {
          'lat': location.latitude,
          'lng': location.longitude,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final snappedPoint = data['snapped_point'] as List;
        // API returns [lng, lat]
        return LatLng(snappedPoint[1], snappedPoint[0]);
      }
    } catch (e) {
      debugPrint('RailwayRoutingService snapToTrack error: $e');
    }
    return null; // Fallback gracefully if snapping fails
  }
}
