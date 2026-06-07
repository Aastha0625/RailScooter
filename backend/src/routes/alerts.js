const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');

// GET /api/alerts/rules
router.get('/rules', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('alert_rules')
      .select('*')
      .order('created_at', { ascending: false });
    if (error) throw error;
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/alerts/rules
router.post('/rules', async (req, res) => {
  try {
    const {
      name, description, rule_type, severity,
      condition_operator, condition_value, condition_unit,
      is_active, notification_email, notification_push, notification_sms
    } = req.body;

    if (!name || !rule_type) return res.status(400).json({ error: 'name and rule_type are required' });

    const { data, error } = await supabase
      .from('alert_rules')
      .insert({
        name, description, rule_type, severity,
        condition_operator, condition_value, condition_unit,
        is_active: is_active !== undefined ? is_active : true,
        notification_email, notification_push, notification_sms
      })
      .select()
      .single();

    if (error) throw error;
    res.status(201).json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/alerts/rules/:id
router.put('/rules/:id', async (req, res) => {
  try {
    const updates = { ...req.body, updated_at: new Date().toISOString() };
    delete updates.id;
    const { data, error } = await supabase.from('alert_rules').update(updates).eq('id', req.params.id).select().single();
    if (error) throw error;
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/alerts/rules/:id
router.delete('/rules/:id', async (req, res) => {
  try {
    const { error } = await supabase.from('alert_rules').delete().eq('id', req.params.id);
    if (error) throw error;
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/alerts/events
router.get('/events', async (req, res) => {
  try {
    const { vehicle_id, is_acknowledged } = req.query;
    let query = supabase
      .from('vehicle_alerts')
      .select(`
        *,
        vehicles(id, vehicle_id, variant),
        alert_rules(id, name, rule_type)
      `)
      .order('created_at', { ascending: false })
      .limit(100);

    if (vehicle_id) query = query.eq('vehicle_id', vehicle_id);
    if (is_acknowledged !== undefined) query = query.eq('is_acknowledged', is_acknowledged === 'true');

    const { data, error } = await query;
    if (error) throw error;
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/alerts/events/:id/acknowledge
router.put('/events/:id/acknowledge', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('vehicle_alerts')
      .update({ is_acknowledged: true, acknowledged_at: new Date().toISOString() })
      .eq('id', req.params.id)
      .select()
      .single();
    if (error) throw error;
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
