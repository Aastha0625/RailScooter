const express = require('express');
const router = express.Router();
const supabase = require('../config/supabase');
const { getRedis, CACHE_TTL } = require('../config/redis');

router.get('/', async (req, res) => {
  try {
    const cacheKey = 'departments:all';
    const redis = getRedis();
    try {
      const cached = await redis.get(cacheKey);
      if (cached) return res.json(JSON.parse(cached));
    } catch (_) {}

    const { data, error } = await supabase
      .from('departments')
      .select('*')
      .order('name');

    if (error) throw error;

    try { await redis.setex(cacheKey, CACHE_TTL.DEPARTMENTS, JSON.stringify(data)); } catch (_) {}
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const { name, code, description, head_name, contact_email, contact_phone, location } = req.body;
    if (!name || !code) return res.status(400).json({ error: 'name and code are required' });

    const { data, error } = await supabase
      .from('departments')
      .insert({ name, code: code.toUpperCase(), description, head_name, contact_email, contact_phone, location })
      .select()
      .single();

    if (error) throw error;
    try { await getRedis().del('departments:all'); } catch (_) {}
    res.status(201).json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const updates = { ...req.body, updated_at: new Date().toISOString() };
    delete updates.id;
    const { data, error } = await supabase.from('departments').update(updates).eq('id', req.params.id).select().single();
    if (error) throw error;
    try { await getRedis().del('departments:all'); } catch (_) {}
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const { error } = await supabase.from('departments').delete().eq('id', req.params.id);
    if (error) throw error;
    try { await getRedis().del('departments:all'); } catch (_) {}
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
