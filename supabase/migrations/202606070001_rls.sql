-- Apply these policies to an existing RailScooter database without rebuilding it.

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.app_users (id, full_name, role, is_active)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      split_part(NEW.email, '@', 1)
    ),
    CASE
      WHEN EXISTS (SELECT 1 FROM public.app_users) THEN 'operator'
      ELSE 'admin'
    END,
    true
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.app_users WHERE role IN ('admin', 'supervisor')
  ) THEN
    UPDATE public.app_users
    SET role = 'admin', updated_at = now()
    WHERE id = (
      SELECT id FROM public.app_users ORDER BY created_at ASC LIMIT 1
    );
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.current_app_user_role()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.app_users WHERE id = auth.uid()
$$;

CREATE OR REPLACE FUNCTION public.current_app_user_department()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT department_id FROM public.app_users WHERE id = auth.uid()
$$;

CREATE OR REPLACE FUNCTION public.is_fleet_manager()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(public.current_app_user_role() IN ('admin', 'supervisor'), false)
$$;

CREATE OR REPLACE FUNCTION public.can_access_vehicle(target_vehicle_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    public.is_fleet_manager()
    OR EXISTS (
      SELECT 1
      FROM public.vehicle_assignments va
      WHERE va.vehicle_id = target_vehicle_id
        AND va.is_active
        AND (
          va.assigned_user_id = auth.uid()
          OR (
            public.current_app_user_department() IS NOT NULL
            AND va.department_id = public.current_app_user_department()
          )
        )
    )
$$;

CREATE OR REPLACE FUNCTION public.protect_app_user_authorization_fields()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() = OLD.id
     AND NOT public.is_fleet_manager()
     AND (
       NEW.id IS DISTINCT FROM OLD.id
       OR NEW.role IS DISTINCT FROM OLD.role
       OR NEW.department_id IS DISTINCT FROM OLD.department_id
       OR NEW.employee_id IS DISTINCT FROM OLD.employee_id
       OR NEW.is_active IS DISTINCT FROM OLD.is_active
     )
  THEN
    RAISE EXCEPTION 'Only fleet managers can change authorization fields';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS protect_app_user_authorization_fields ON public.app_users;
CREATE TRIGGER protect_app_user_authorization_fields
  BEFORE UPDATE ON public.app_users
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_app_user_authorization_fields();

DROP POLICY IF EXISTS "dept_select" ON public.departments;
DROP POLICY IF EXISTS "dept_insert" ON public.departments;
DROP POLICY IF EXISTS "dept_update" ON public.departments;
DROP POLICY IF EXISTS "dept_delete" ON public.departments;
CREATE POLICY "dept_select" ON public.departments FOR SELECT TO authenticated
  USING (public.is_fleet_manager() OR id = public.current_app_user_department());
CREATE POLICY "dept_insert" ON public.departments FOR INSERT TO authenticated
  WITH CHECK (public.is_fleet_manager());
CREATE POLICY "dept_update" ON public.departments FOR UPDATE TO authenticated
  USING (public.is_fleet_manager()) WITH CHECK (public.is_fleet_manager());
CREATE POLICY "dept_delete" ON public.departments FOR DELETE TO authenticated
  USING (public.is_fleet_manager());

DROP POLICY IF EXISTS "users_select" ON public.app_users;
DROP POLICY IF EXISTS "users_update" ON public.app_users;
CREATE POLICY "users_select" ON public.app_users FOR SELECT TO authenticated
  USING (
    public.is_fleet_manager()
    OR id = auth.uid()
    OR (
      public.current_app_user_department() IS NOT NULL
      AND department_id = public.current_app_user_department()
    )
  );
CREATE POLICY "users_update" ON public.app_users FOR UPDATE TO authenticated
  USING (public.is_fleet_manager() OR id = auth.uid())
  WITH CHECK (public.is_fleet_manager() OR id = auth.uid());

DROP POLICY IF EXISTS "vehicles_select" ON public.vehicles;
DROP POLICY IF EXISTS "vehicles_insert" ON public.vehicles;
DROP POLICY IF EXISTS "vehicles_update" ON public.vehicles;
DROP POLICY IF EXISTS "vehicles_delete" ON public.vehicles;
CREATE POLICY "vehicles_select" ON public.vehicles FOR SELECT TO authenticated
  USING (public.can_access_vehicle(id));
CREATE POLICY "vehicles_insert" ON public.vehicles FOR INSERT TO authenticated
  WITH CHECK (public.is_fleet_manager());
CREATE POLICY "vehicles_update" ON public.vehicles FOR UPDATE TO authenticated
  USING (public.is_fleet_manager()) WITH CHECK (public.is_fleet_manager());
CREATE POLICY "vehicles_delete" ON public.vehicles FOR DELETE TO authenticated
  USING (public.is_fleet_manager());

DROP POLICY IF EXISTS "assignments_select" ON public.vehicle_assignments;
DROP POLICY IF EXISTS "assignments_insert" ON public.vehicle_assignments;
DROP POLICY IF EXISTS "assignments_update" ON public.vehicle_assignments;
DROP POLICY IF EXISTS "assignments_delete" ON public.vehicle_assignments;
CREATE POLICY "assignments_select" ON public.vehicle_assignments FOR SELECT TO authenticated
  USING (public.can_access_vehicle(vehicle_id));
CREATE POLICY "assignments_insert" ON public.vehicle_assignments FOR INSERT TO authenticated
  WITH CHECK (public.is_fleet_manager());
CREATE POLICY "assignments_update" ON public.vehicle_assignments FOR UPDATE TO authenticated
  USING (public.is_fleet_manager()) WITH CHECK (public.is_fleet_manager());
CREATE POLICY "assignments_delete" ON public.vehicle_assignments FOR DELETE TO authenticated
  USING (public.is_fleet_manager());

DROP POLICY IF EXISTS "alert_rules_insert" ON public.alert_rules;
DROP POLICY IF EXISTS "alert_rules_update" ON public.alert_rules;
DROP POLICY IF EXISTS "alert_rules_delete" ON public.alert_rules;
CREATE POLICY "alert_rules_insert" ON public.alert_rules FOR INSERT TO authenticated
  WITH CHECK (public.is_fleet_manager());
CREATE POLICY "alert_rules_update" ON public.alert_rules FOR UPDATE TO authenticated
  USING (public.is_fleet_manager()) WITH CHECK (public.is_fleet_manager());
CREATE POLICY "alert_rules_delete" ON public.alert_rules FOR DELETE TO authenticated
  USING (public.is_fleet_manager());

DROP POLICY IF EXISTS "geofences_select" ON public.geofences;
DROP POLICY IF EXISTS "geofences_insert" ON public.geofences;
DROP POLICY IF EXISTS "geofences_update" ON public.geofences;
DROP POLICY IF EXISTS "geofences_delete" ON public.geofences;
CREATE POLICY "geofences_select" ON public.geofences FOR SELECT TO authenticated
  USING (
    public.is_fleet_manager()
    OR department_id IS NULL
    OR department_id = public.current_app_user_department()
  );
CREATE POLICY "geofences_insert" ON public.geofences FOR INSERT TO authenticated
  WITH CHECK (public.is_fleet_manager());
CREATE POLICY "geofences_update" ON public.geofences FOR UPDATE TO authenticated
  USING (public.is_fleet_manager()) WITH CHECK (public.is_fleet_manager());
CREATE POLICY "geofences_delete" ON public.geofences FOR DELETE TO authenticated
  USING (public.is_fleet_manager());

DROP POLICY IF EXISTS "tracking_select" ON public.vehicle_tracking;
DROP POLICY IF EXISTS "tracking_insert" ON public.vehicle_tracking;
CREATE POLICY "tracking_select" ON public.vehicle_tracking FOR SELECT TO authenticated
  USING (public.can_access_vehicle(vehicle_id));
CREATE POLICY "tracking_insert" ON public.vehicle_tracking FOR INSERT TO authenticated
  WITH CHECK (public.can_access_vehicle(vehicle_id));

DROP POLICY IF EXISTS "alerts_select" ON public.vehicle_alerts;
DROP POLICY IF EXISTS "alerts_insert" ON public.vehicle_alerts;
DROP POLICY IF EXISTS "alerts_update" ON public.vehicle_alerts;
CREATE POLICY "alerts_select" ON public.vehicle_alerts FOR SELECT TO authenticated
  USING (public.can_access_vehicle(vehicle_id));
CREATE POLICY "alerts_insert" ON public.vehicle_alerts FOR INSERT TO authenticated
  WITH CHECK (public.can_access_vehicle(vehicle_id));
CREATE POLICY "alerts_update" ON public.vehicle_alerts FOR UPDATE TO authenticated
  USING (public.can_access_vehicle(vehicle_id))
  WITH CHECK (public.can_access_vehicle(vehicle_id));
