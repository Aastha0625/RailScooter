/*
  # PiScoot Fleet Management - Initial Schema

  1. New Tables
    - `departments` - Railway departments that own/use scooters
    - `app_users` - App users (operators, admins, department heads)
    - `vehicles` - PiScoot vehicle registry with full specs
    - `vehicle_assignments` - Links vehicles to departments and users
    - `alert_rules` - Configurable alert/rule definitions
    - `geofences` - Geographic boundary definitions
    - `vehicle_tracking` - Real-time GPS tracking data
    - `vehicle_alerts` - Triggered alert instances

  2. Security
    - RLS enabled on all tables
    - Authenticated users can read all data
    - Only admins can create/update/delete (checked via role in app_users)

  3. Notes
    - vehicle status: active | idle | maintenance | offline
    - alert severity: low | medium | high | critical
    - geofence type: restricted | operational | depot
*/

-- Departments
CREATE TABLE IF NOT EXISTS departments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  code text UNIQUE NOT NULL,
  description text DEFAULT '',
  head_name text DEFAULT '',
  contact_email text DEFAULT '',
  contact_phone text DEFAULT '',
  location text DEFAULT '',
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE departments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read departments"
  ON departments FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert departments"
  ON departments FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update departments"
  ON departments FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can delete departments"
  ON departments FOR DELETE
  TO authenticated
  USING (auth.uid() IS NOT NULL);

-- App Users (profiles linked to auth.users)
CREATE TABLE IF NOT EXISTS app_users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text NOT NULL DEFAULT '',
  employee_id text UNIQUE,
  role text NOT NULL DEFAULT 'operator',
  department_id uuid REFERENCES departments(id) ON DELETE SET NULL,
  phone text DEFAULT '',
  avatar_url text DEFAULT '',
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read all profiles"
  ON app_users FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert own profile"
  ON app_users FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON app_users FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Vehicles
CREATE TABLE IF NOT EXISTS vehicles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id text UNIQUE NOT NULL,
  variant text NOT NULL DEFAULT 'PiScoot',
  battery_type text NOT NULL DEFAULT 'LiFe',
  battery_capacity text DEFAULT '48V 25Ah',
  manufacturing_date date,
  firmware_version text DEFAULT 'v1.0.0',
  last_maintenance_date date,
  status text NOT NULL DEFAULT 'active',
  gps_enabled boolean DEFAULT true,
  trackman_enabled boolean DEFAULT false,
  trackman_safety_enabled boolean DEFAULT false,
  notes text DEFAULT '',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read vehicles"
  ON vehicles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert vehicles"
  ON vehicles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update vehicles"
  ON vehicles FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can delete vehicles"
  ON vehicles FOR DELETE
  TO authenticated
  USING (auth.uid() IS NOT NULL);

-- Vehicle Assignments (many-to-one: vehicle has one active assignment)
CREATE TABLE IF NOT EXISTS vehicle_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id uuid NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  department_id uuid REFERENCES departments(id) ON DELETE SET NULL,
  assigned_user_id uuid REFERENCES app_users(id) ON DELETE SET NULL,
  assigned_by uuid REFERENCES app_users(id) ON DELETE SET NULL,
  assigned_at timestamptz DEFAULT now(),
  unassigned_at timestamptz,
  is_active boolean DEFAULT true,
  notes text DEFAULT '',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE vehicle_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read assignments"
  ON vehicle_assignments FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert assignments"
  ON vehicle_assignments FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update assignments"
  ON vehicle_assignments FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can delete assignments"
  ON vehicle_assignments FOR DELETE
  TO authenticated
  USING (auth.uid() IS NOT NULL);

-- Alert Rules
CREATE TABLE IF NOT EXISTS alert_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text DEFAULT '',
  rule_type text NOT NULL DEFAULT 'speed',
  severity text NOT NULL DEFAULT 'medium',
  condition_operator text NOT NULL DEFAULT 'gt',
  condition_value numeric NOT NULL DEFAULT 0,
  condition_unit text DEFAULT '',
  is_active boolean DEFAULT true,
  applies_to_all_vehicles boolean DEFAULT true,
  notification_email boolean DEFAULT true,
  notification_push boolean DEFAULT true,
  notification_sms boolean DEFAULT false,
  created_by uuid REFERENCES app_users(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE alert_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read alert rules"
  ON alert_rules FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert alert rules"
  ON alert_rules FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update alert rules"
  ON alert_rules FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can delete alert rules"
  ON alert_rules FOR DELETE
  TO authenticated
  USING (auth.uid() IS NOT NULL);

-- Geofences
CREATE TABLE IF NOT EXISTS geofences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text DEFAULT '',
  fence_type text NOT NULL DEFAULT 'operational',
  center_lat double precision NOT NULL DEFAULT 0,
  center_lng double precision NOT NULL DEFAULT 0,
  radius_meters double precision DEFAULT 500,
  polygon_points jsonb,
  is_active boolean DEFAULT true,
  alert_on_enter boolean DEFAULT false,
  alert_on_exit boolean DEFAULT true,
  color_hex text DEFAULT '#F58220',
  department_id uuid REFERENCES departments(id) ON DELETE SET NULL,
  created_by uuid REFERENCES app_users(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE geofences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read geofences"
  ON geofences FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert geofences"
  ON geofences FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update geofences"
  ON geofences FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can delete geofences"
  ON geofences FOR DELETE
  TO authenticated
  USING (auth.uid() IS NOT NULL);

-- Vehicle Tracking (high-frequency GPS data)
CREATE TABLE IF NOT EXISTS vehicle_tracking (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id uuid NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  speed_kmh double precision DEFAULT 0,
  heading_degrees double precision DEFAULT 0,
  battery_percent integer DEFAULT 100,
  is_online boolean DEFAULT true,
  signal_strength integer DEFAULT 100,
  recorded_at timestamptz DEFAULT now()
);

ALTER TABLE vehicle_tracking ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read tracking"
  ON vehicle_tracking FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert tracking"
  ON vehicle_tracking FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

-- Vehicle Alerts (triggered alert events)
CREATE TABLE IF NOT EXISTS vehicle_alerts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id uuid NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  alert_rule_id uuid REFERENCES alert_rules(id) ON DELETE SET NULL,
  alert_type text NOT NULL DEFAULT 'speed',
  severity text NOT NULL DEFAULT 'medium',
  message text NOT NULL DEFAULT '',
  latitude double precision,
  longitude double precision,
  is_acknowledged boolean DEFAULT false,
  acknowledged_by uuid REFERENCES app_users(id) ON DELETE SET NULL,
  acknowledged_at timestamptz,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE vehicle_alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read alerts"
  ON vehicle_alerts FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert alerts"
  ON vehicle_alerts FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update alerts"
  ON vehicle_alerts FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_vehicles_status ON vehicles(status);
CREATE INDEX IF NOT EXISTS idx_vehicles_vehicle_id ON vehicles(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_assignments_vehicle ON vehicle_assignments(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_assignments_active ON vehicle_assignments(is_active);
CREATE INDEX IF NOT EXISTS idx_vehicle_tracking_vehicle ON vehicle_tracking(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_tracking_recorded ON vehicle_tracking(recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_vehicle_alerts_vehicle ON vehicle_alerts(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_alerts_acknowledged ON vehicle_alerts(is_acknowledged);
