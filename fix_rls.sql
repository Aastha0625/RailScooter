-- 1. Drop the broken function that relies on department_id
DROP FUNCTION IF EXISTS public.current_app_user_department() CASCADE;

-- 2. Drop the old broken policies
DROP POLICY IF EXISTS "users_select" ON public.app_users;
DROP POLICY IF EXISTS "geofences_select" ON public.geofences;

-- 3. Recreate the policy for app_users WITHOUT using department_id
-- This allows trackmen to see their own profile, and fleet managers to see everyone
CREATE POLICY "users_select" ON public.app_users FOR SELECT TO authenticated
  USING (
    public.is_fleet_manager()
    OR id = auth.uid()
  );

-- 4. Recreate the policy for geofences
-- Allow all authenticated users to read geofences so the map loads properly
CREATE POLICY "geofences_select" ON public.geofences FOR SELECT TO authenticated
  USING (true);

-- 5. Fix the user authorization protection trigger to remove department_id checks
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
       OR NEW.employee_id IS DISTINCT FROM OLD.employee_id
       OR NEW.is_active IS DISTINCT FROM OLD.is_active
     )
  THEN
     RAISE EXCEPTION 'Users cannot modify their own authorization fields. Only Fleet Managers can do this.';
  END IF;
  RETURN NEW;
END;
$$;

-- 6. Update can_access_vehicle to remove department_id logic
-- Trackmen only have access to vehicles explicitly assigned to them
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
        AND va.assigned_user_id = auth.uid()
    )
$$;
