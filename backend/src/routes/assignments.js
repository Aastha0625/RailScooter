const express = require('express');
const router = express.Router();
const supabase = require('../config/supabase');

// GET active assignments
router.get('/', async (req, res) => {
  try {
    const { vehicle_id, department_id, user_id } = req.query;
    let query = supabase
      .from('vehicle_assignments')
      .select(`
        *,
        vehicles(id, vehicle_id, variant, battery_type, status),
        departments(id, name, code),
        app_users!vehicle_assignments_assigned_user_id_fkey(id, full_name, employee_id)
      `)
      .eq('is_active', true)
      .order('assigned_at', { ascending: false });

    if (vehicle_id) query = query.eq('vehicle_id', vehicle_id);
    if (department_id) query = query.eq('department_id', department_id);
    if (user_id) query = query.eq('assigned_user_id', user_id);

    const { data, error } = await query;
    if (error) throw error;
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST create assignment
router.post('/', async (req, res) => {
  try {
    const { vehicle_id, department_id, assigned_user_id, notes } = req.body;
    if (!vehicle_id) return res.status(400).json({ error: 'vehicle_id is required' });

    // Deactivate existing active assignments for this vehicle
    await supabase
      .from('vehicle_assignments')
      .update({ is_active: false, unassigned_at: new Date().toISOString() })
      .eq('vehicle_id', vehicle_id)
      .eq('is_active', true);

    const { data, error } = await supabase
      .from('vehicle_assignments')
      .insert({ vehicle_id, department_id, assigned_user_id, notes, is_active: true })
      .select(`
        *,
        vehicles(id, vehicle_id, variant),
        departments(id, name, code),
        app_users!vehicle_assignments_assigned_user_id_fkey(id, full_name)
      `)
      .single();

    if (error) throw error;
    res.status(201).json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE (unassign) by assignment id
router.delete('/:id', async (req, res) => {
  try {
    const { error } = await supabase
      .from('vehicle_assignments')
      .update({ is_active: false, unassigned_at: new Date().toISOString() })
      .eq('id', req.params.id);
    if (error) throw error;
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
