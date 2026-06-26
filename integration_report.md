# Railway Routing Service Integration Report

This report outlines the technical details and results of replacing Google Maps with `flutter_map` (OpenStreetMap) and integrating the production Railway Routing Service.

## Architecture Changes

1. **Map Engine Migration**:
   - Replaced `google_maps_flutter` with `flutter_map` (version `8.3.0`) and `latlong2` (version `0.9.1`). This solves map loading issues on mobile devices caused by native Google Maps API keys or billing configuration.
   - Migrated all screen modules to use open OpenStreetMap tile layers, markers, circles, and polylines.

2. **Snapping & Routing Engine**:
   - Switched coordinate model globally to use `latlong2`'s `LatLng` class.
   - Updated `RailwayRoutingService` (built with Dio, connecting to `https://anveshr312-railway-routing-service.hf.space` with 120s timeout limits) to snap locations and draw physical railway routes.

3. **Supervisor View Enhancements**:
   - Added automatic railway-snapping (`/nearest-track`) inside both the initial load (`_load`) and periodic 10-second polling (`_pollSilent`) on the live map view.

---

## Endpoint Usage

1. **Railway Route Calculation (`POST /rail-route`)**:
   - Used when calculating tracks from the Accident Relief Train (ART) location to the incident location.
   - Request Body:
     ```json
     {
       "start_lat": double,
       "start_lng": double,
       "end_lat": double,
       "end_lng": double
     }
     ```

2. **Nearest Physical Railway Track Snapping (`POST /nearest-track`)**:
   - Used to snap generic operator and vehicle GPS coordinates to the physical railway track for supervisor/live views.
   - Request Body:
     ```json
     {
       "lat": double,
       "lng": double
     }
     ```

---

## Modified Files

- [pubspec.yaml](file:///d:/TryingStuff/RailScooter1/flutter_app/pubspec.yaml): Added `flutter_map` & `latlong2` dependencies; removed `google_maps_flutter`.
- [app_constants.dart](file:///d:/TryingStuff/RailScooter1/flutter_app/lib/constants/app_constants.dart): Switched imports and default backend URLs.
- [railway_routing_service.dart](file:///d:/TryingStuff/RailScooter1/flutter_app/lib/services/railway_routing_service.dart): Migrated to `latlong2`'s coordinate models.
- [map_selection_screen.dart](file:///d:/TryingStuff/RailScooter1/flutter_app/lib/widgets/map_selection_screen.dart): Rewritten using `flutter_map` widget tree.
- [map_picker_screen.dart](file:///d:/TryingStuff/RailScooter1/flutter_app/lib/screens/trackman/map_picker_screen.dart): Rewritten using `flutter_map` widget tree.
- [trackman_geofencing_screen.dart](file:///d:/TryingStuff/RailScooter1/flutter_app/lib/screens/trackman/trackman_geofencing_screen.dart): Rewritten using `flutter_map` widget tree.
- [geofence_tracking_screen.dart](file:///d:/TryingStuff/RailScooter1/flutter_app/lib/screens/tracking/geofence_tracking_screen.dart): Rewritten using `flutter_map`, snapped live coordinates dynamically.
- [manager_issues_screen.dart](file:///d:/TryingStuff/RailScooter1/flutter_app/lib/screens/manager/manager_issues_screen.dart): Integrated routing endpoint (`/rail-route`), removed direct straight-line fallbacks, added proper snapped location markers and text displaying distance and ETA.
- [admin_vehicle_detail_screen.dart](file:///d:/TryingStuff/RailScooter1/flutter_app/lib/screens/admin/admin_vehicle_detail_screen.dart): Rewritten vehicle details mini-map.
- [trackman_report_issue_screen.dart](file:///d:/TryingStuff/RailScooter1/flutter_app/lib/screens/trackman/trackman_report_issue_screen.dart) & [manager_task_assignment_screen.dart](file:///d:/TryingStuff/RailScooter1/flutter_app/lib/screens/manager/manager_task_assignment_screen.dart): Updated coordinate model imports.

---

## Verification Results

1. **Routing Verification**:
   - GeoJSON is parsed correctly.
   - Fallback logic drawing straight lines is completely removed; if the routing request fails, a user-friendly error is shown, and no lines are drawn.
2. **Snapping Verification**:
   - Live tracking coordinates are snapped accurately on initial load and updates.
3. **Static Analysis**:
   - `flutter analyze` runs successfully with no errors or warnings in the modified files.
