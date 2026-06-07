const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');
const { getRedis, CACHE_TTL } = require('../config/redis');

// GET /api/tracking/live - latest position of all active vehicles (Redis cached)
router.get('/live', async (req, res) => {
  try {
    const cacheKey = `user:${req.user.id}:tracking:live`;
    const redis = getRedis();

    try {
      const cached = await redis.get(cacheKey);
      if (cached) return res.json(JSON.parse(cached));
    } catch (_) {}

    // Get most recent tracking per vehicle using a subquery
    const { data, error } = await supabase
      .from('vehicle_tracking')
      .select(`
        *,
        vehicles(id, vehicle_id, variant, status, gps_enabled)
      `)
      .order('recorded_at', { ascending: false })
      .limit(200);

    if (error) throw error;

    // Deduplicate: keep only latest per vehicle
    const latestMap = {};
    for (const row of data) {
      const vid = row.vehicle_id;
      if (!latestMap[vid]) latestMap[vid] = row;
    }
    const result = Object.values(latestMap);

    try { await redis.setex(cacheKey, CACHE_TTL.TRACKING, JSON.stringify(result)); } catch (_) {}
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/tracking - ingest new tracking point
router.post('/', async (req, res) => {
  try {
    const { vehicle_id, latitude, longitude, speed_kmh, heading_degrees, battery_percent, signal_strength } = req.body;
    if (!vehicle_id || latitude === undefined || longitude === undefined) {
      return res.status(400).json({ error: 'vehicle_id, latitude, longitude are required' });
    }

    const { data, error } = await supabase
      .from('vehicle_tracking')
      .insert({ vehicle_id, latitude, longitude, speed_kmh, heading_degrees, battery_percent, signal_strength, is_online: true })
      .select()
      .single();

    if (error) throw error;

    // Cache the latest position in Redis (fast lookup)
    try {
      const redis = getRedis();
      await redis.setex(`user:${req.user.id}:vehicle:location:${vehicle_id}`, CACHE_TTL.TRACKING, JSON.stringify(data));
      await redis.del(`user:${req.user.id}:tracking:live`);
    } catch (_) {}

    res.status(201).json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/tracking/geofences
router.get('/geofences/all', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('geofences')
      .select('*, departments(id, name, code)')
      .order('created_at', { ascending: false });
    if (error) throw error;
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/tracking/geofences
router.post('/geofences', async (req, res) => {
  try {
    const {
      name, description, fence_type, center_lat, center_lng,
      radius_meters, is_active, alert_on_enter, alert_on_exit,
      color_hex, department_id
    } = req.body;

    if (!name || center_lat === undefined || center_lng === undefined) {
      return res.status(400).json({ error: 'name, center_lat, center_lng are required' });
    }

    const { data, error } = await supabase
      .from('geofences')
      .insert({
        name, description, fence_type, center_lat, center_lng,
        radius_meters, is_active, alert_on_enter, alert_on_exit,
        color_hex, department_id
      })
      .select()
      .single();

    if (error) throw error;
    res.status(201).json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/tracking/geofences/:id
router.delete('/geofences/:id', async (req, res) => {
  try {
    const { error } = await supabase.from('geofences').delete().eq('id', req.params.id);
    if (error) throw error;
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/tracking/:vehicleId/history
router.get('/:vehicleId/history', async (req, res) => {
  try {
    const { hours = 24 } = req.query;
    const since = new Date(Date.now() - parseInt(hours) * 3600000).toISOString();

    const { data, error } = await supabase
      .from('vehicle_tracking')
      .select('*')
      .eq('vehicle_id', req.params.vehicleId)
      .gte('recorded_at', since)
      .order('recorded_at', { ascending: true });

    if (error) throw error;
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
