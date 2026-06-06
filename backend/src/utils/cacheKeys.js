/**
 * cacheKeys.js — Centralised Redis cache key builder.
 *
 * All cache key strings live here so they are consistent across routes
 * and can be invalidated precisely without string duplication.
 */

const CacheKeys = {
  // Vehicle list — includes all filter/pagination combos
  vehicleList: (query = {}) => `vehicles:${JSON.stringify(query)}`,
  vehicleListAll: () => 'vehicles:{}',

  // Live tracking — latest position of all vehicles
  trackingLive: () => 'tracking:live',

  // Latest single-vehicle position
  vehiclePosition: (vehicleId) => `vehicle:location:${vehicleId}`,

  // Previous single-vehicle position (for geofence enter/exit detection)
  vehiclePrevPosition: (vehicleId) => `vehicle:prev_position:${vehicleId}`,

  // Dashboard stats
  dashboardStats: () => 'stats:dashboard',

  // Alert rules (cached for engine evaluation)
  alertRules: () => 'alert_rules:active',

  // Geofences (cached for engine evaluation)
  geofences: () => 'geofences:active',
};

module.exports = { CacheKeys };
