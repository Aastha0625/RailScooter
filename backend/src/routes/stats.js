const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');
const { getRedis, CACHE_TTL } = require('../config/redis');

// GET /api/stats - dashboard summary stats
router.get('/', async (req, res) => {
  try {
    const cacheKey = `user:${req.user.id}:stats:dashboard`;
    const redis = getRedis();

    try {
      const cached = await redis.get(cacheKey);
      if (cached) return res.json(JSON.parse(cached));
    } catch (_) {}
    const [vehicles, departments, users, alerts, activeAssignments] = await Promise.all([
      supabase.from('vehicles').select('status', { count: 'exact' }),
      supabase.from('departments').select('*', { count: 'exact', head: true }).eq('is_active', true),
      supabase.from('app_users').select('*', { count: 'exact', head: true }).eq('is_active', true),
      supabase.from('vehicle_alerts').select('*', { count: 'exact', head: true }).eq('is_acknowledged', false),
      supabase.from('vehicle_assignments').select('*', { count: 'exact', head: true }).eq('is_active', true),
    ]);

    const vehicleData = vehicles.data || [];
    const byStatus = vehicleData.reduce((acc, v) => {
      acc[v.status] = (acc[v.status] || 0) + 1;
      return acc;
    }, {});

    const result = {
      total_vehicles: vehicles.count || 0,
      active_vehicles: byStatus.active || 0,
      idle_vehicles: byStatus.idle || 0,
      maintenance_vehicles: byStatus.maintenance || 0,
      offline_vehicles: byStatus.offline || 0,
      total_departments: departments.count || 0,
      total_users: users.count || 0,
      unacknowledged_alerts: alerts.count || 0,
      active_assignments: activeAssignments.count || 0,
    };

    try { await redis.setex(cacheKey, CACHE_TTL.STATS, JSON.stringify(result)); } catch (_) {}
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
