/**
 * haversine.js — Utility to compute great-circle distance between two GPS coordinates.
 * Used by the geofence breach detection engine.
 *
 * Formula: Haversine
 * Returns distance in metres.
 */

const EARTH_RADIUS_METRES = 6_371_000;

/**
 * @param {number} lat1 - Latitude of point A (degrees)
 * @param {number} lng1 - Longitude of point A (degrees)
 * @param {number} lat2 - Latitude of point B (degrees)
 * @param {number} lng2 - Longitude of point B (degrees)
 * @returns {number} Distance in metres
 */
function haversineDistance(lat1, lng1, lat2, lng2) {
  const toRad = (deg) => (deg * Math.PI) / 180;

  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);

  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return EARTH_RADIUS_METRES * c;
}

module.exports = { haversineDistance };
