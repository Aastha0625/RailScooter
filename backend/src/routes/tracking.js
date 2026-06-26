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

    // Get most recent tracking per vehicle using the latest_vehicle_tracking view
    const { data, error } = await supabase
      .from('latest_vehicle_tracking')
      .select(`
        *,
        vehicles(id, vehicle_id, variant, status, gps_enabled)
      `);

    if (error) throw error;

    try { await redis.setex(cacheKey, CACHE_TTL.TRACKING, JSON.stringify(data)); } catch (_) {}
    res.json(data);
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

    // Evaluate active alert rules and generate events
    try {
      const { data: rules } = await supabase
        .from('alert_rules')
        .select('*')
        .eq('is_active', true);

      if (rules && rules.length > 0) {
        for (const rule of rules) {
          let triggered = false;
          let val = null;
          const condVal = parseFloat(rule.condition_value);

          if (rule.rule_type === 'speed' && speed_kmh !== undefined) {
            val = speed_kmh;
            if (rule.condition_operator === 'gt' && speed_kmh > condVal) triggered = true;
            if (rule.condition_operator === 'lt' && speed_kmh < condVal) triggered = true;
          } else if (rule.rule_type === 'battery' && battery_percent !== undefined) {
            val = battery_percent;
            if (rule.condition_operator === 'lt' && battery_percent < condVal) triggered = true;
            if (rule.condition_operator === 'gt' && battery_percent > condVal) triggered = true;
          }

          if (triggered) {
            // Check if there is already an unacknowledged alert for this rule & vehicle to avoid spam
            const { data: existingAlert } = await supabase
              .from('vehicle_alerts')
              .select('id')
              .eq('vehicle_id', vehicle_id)
              .eq('alert_rule_id', rule.id)
              .eq('is_acknowledged', false)
              .limit(1)
              .maybeSingle();

            if (!existingAlert) {
              await supabase
                .from('vehicle_alerts')
                .insert({
                  vehicle_id,
                  alert_rule_id: rule.id,
                  alert_type: rule.rule_type,
                  severity: rule.severity || 'medium',
                  message: `${rule.name}: Vehicle triggered alert (Value: ${val}, Threshold: ${rule.condition_operator} ${condVal})`,
                  latitude,
                  longitude,
                  is_acknowledged: false
                });
            }
          }
        }
      }
    } catch (evalErr) {
      console.error('[Alerts Evaluation] Error:', evalErr.message);
    }

    // Broadcast the new tracking update to all active WebSocket connections
    if (global.broadcastTracking) {
      global.broadcastTracking(data);
    }

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
      .select('*')
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
