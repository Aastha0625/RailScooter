/*
  # PiScoot - Seed Sample Data

  Inserts sample departments, vehicles with realistic railway data
  for development and demo purposes.
  No auth-linked data (app_users) seeded since that requires real auth accounts.
*/

INSERT INTO departments (name, code, description, head_name, contact_email, location, is_active) VALUES
  ('Mechanical Department', 'MECH', 'Handles mechanical maintenance and operations', 'Rajesh Kumar', 'mech@railway.in', 'Platform A', true),
  ('Electrical Department', 'ELEC', 'Manages electrical systems and charging', 'Priya Singh', 'elec@railway.in', 'Platform B', true),
  ('Operations Department', 'OPS', 'Day-to-day railway operations', 'Anand Mehta', 'ops@railway.in', 'Main Office', true),
  ('Safety Department', 'SAFE', 'Safety inspections and compliance', 'Sunita Rao', 'safe@railway.in', 'Safety Block', true),
  ('Logistics Department', 'LOG', 'Cargo and goods movement', 'Vikram Patel', 'log@railway.in', 'Warehouse', true)
ON CONFLICT (code) DO NOTHING;

INSERT INTO vehicles (vehicle_id, variant, battery_type, battery_capacity, manufacturing_date, firmware_version, last_maintenance_date, status, gps_enabled, trackman_enabled, trackman_safety_enabled) VALUES
  ('PS001', 'PiScoot', 'LiFe', '48V 25Ah', '2024-01-15', 'v2.1.0', '2024-02-20', 'active', true, true, true),
  ('PSB002', 'PiScoot-Bolt', 'LiPo', '48V 30Ah', '2024-02-01', 'v2.0.8', '2024-03-10', 'idle', true, true, false),
  ('PSA003', 'PiScoot-Aegis', 'NMC', '52V 28Ah', '2024-01-20', 'v1.9.5', '2024-02-28', 'maintenance', true, false, false),
  ('PS004', 'PiScoot', 'LiFe', '48V 25Ah', '2024-03-05', 'v2.1.0', null, 'active', true, true, true),
  ('PSB005', 'PiScoot-Bolt', 'LiPo', '48V 30Ah', '2024-03-15', 'v2.0.8', '2024-04-01', 'offline', false, false, false)
ON CONFLICT (vehicle_id) DO NOTHING;

INSERT INTO alert_rules (name, description, rule_type, severity, condition_operator, condition_value, condition_unit, is_active) VALUES
  ('Over Speed Alert', 'Trigger when scooter exceeds speed limit', 'speed', 'high', 'gt', 25, 'km/h', true),
  ('Low Battery Warning', 'Alert when battery drops below threshold', 'battery', 'medium', 'lt', 20, '%', true),
  ('Geofence Exit', 'Alert when vehicle exits operational zone', 'geofence', 'critical', 'eq', 1, 'exit', true),
  ('Idle Too Long', 'Alert when vehicle idle for extended time', 'idle_time', 'low', 'gt', 30, 'minutes', true),
  ('Unauthorized Movement', 'Alert for movement outside working hours', 'movement', 'high', 'eq', 1, 'after_hours', true)
ON CONFLICT DO NOTHING;

INSERT INTO geofences (name, description, fence_type, center_lat, center_lng, radius_meters, is_active, alert_on_exit, color_hex) VALUES
  ('Main Station Zone', 'Primary operational area around main station', 'operational', 28.6139, 77.2090, 500, true, true, '#F58220'),
  ('Platform A Depot', 'Charging depot for Platform A vehicles', 'depot', 28.6145, 77.2085, 100, true, false, '#0D2F4F'),
  ('Restricted Maintenance Bay', 'Only authorized maintenance vehicles', 'restricted', 28.6132, 77.2095, 150, true, true, '#DC2626')
ON CONFLICT DO NOTHING;
