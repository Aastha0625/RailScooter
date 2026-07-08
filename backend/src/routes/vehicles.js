const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');
const { getRedis, CACHE_TTL } = require('../config/redis');

// GET /api/vehicles - list with filters
router.get('/', async (req, res) => {
  try {
    const { status, variant, search, page = 1, limit = 20 } = req.query;
    const cacheKey = `user:${req.user.id}:vehicles:${JSON.stringify(req.query)}`;

    const redis = getRedis();
    try {
      const cached = await redis.get(cacheKey);
      if (cached) return res.json(JSON.parse(cached));
    } catch (_) {}

    let allQuery = supabase.from('vehicles').select(`
      *,
      vehicle_assignments(
        id, is_active, assigned_at,
        app_users!vehicle_assignments_assigned_user_id_fkey(id, full_name, employee_id)
      )
    `, { count: 'exact' }).order('created_at', { ascending: false });
    if (status) allQuery = allQuery.eq('status', status);
    if (variant) allQuery = allQuery.ilike('variant', `%${variant}%`);
    if (search) allQuery = allQuery.or(`vehicle_id.ilike.%${search}%,variant.ilike.%${search}%`);

    const offset = (parseInt(page) - 1) * parseInt(limit);
    allQuery = allQuery.range(offset, offset + parseInt(limit) - 1);

    const { data: vehicles, error: err2, count: total } = await allQuery;
    if (err2) throw err2;

    const result = { data: vehicles, total, page: parseInt(page), limit: parseInt(limit) };

    try {
      await redis.setex(cacheKey, CACHE_TTL.VEHICLES, JSON.stringify(result));
    } catch (_) {}

    res.json(result);
  } catch (err) {
    console.error("VEHICLES API ERROR:", err.stack || err.message || err);
    res.status(500).json({ error: err.message });
  }
});

// GET /api/vehicles/:id
router.get('/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('vehicles')
      .select(`
        *,
        vehicle_assignments(
          id, is_active, assigned_at, notes,
          app_users!vehicle_assignments_assigned_user_id_fkey(id, full_name, employee_id, role, phone)
        ),
        vehicle_tracking(latitude, longitude, speed_kmh, battery_percent, recorded_at)
      `)
      .eq('id', req.params.id)
      .order('recorded_at', { foreignTable: 'vehicle_tracking', ascending: false })
      .limit(1, { foreignTable: 'vehicle_tracking' })
      .maybeSingle();

    if (error) throw error;
    if (!data) return res.status(404).json({ error: 'Vehicle not found' });
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/vehicles
router.post('/', async (req, res) => {
  try {
    const {
      vehicle_id, variant, battery_type, battery_capacity,
      manufacturing_date, firmware_version, gps_enabled,
      trackman_enabled, trackman_safety_enabled, notes
    } = req.body;

    if (!vehicle_id || !variant || !battery_type) {
      return res.status(400).json({ error: 'vehicle_id, variant, and battery_type are required' });
    }

    const { data, error } = await supabase
      .from('vehicles')
      .insert({
        vehicle_id, variant, battery_type, battery_capacity,
        manufacturing_date, firmware_version, gps_enabled,
        trackman_enabled, trackman_safety_enabled, notes,
        status: 'active'
      })
      .select()
      .single();

    if (error) throw error;

    // Invalidate cache
    try { await getRedis().del(`user:${req.user.id}:vehicles:{}`); } catch (_) {}

    res.status(201).json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/vehicles/:id
router.put('/:id', async (req, res) => {
  try {
    const updates = { ...req.body, updated_at: new Date().toISOString() };
    delete updates.id;
    delete updates.created_at;

    const { data, error } = await supabase
      .from('vehicles')
      .update(updates)
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/vehicles/:id
router.delete('/:id', async (req, res) => {
  try {
    const { error } = await supabase.from('vehicles').delete().eq('id', req.params.id);
    if (error) throw error;
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
