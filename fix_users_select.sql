-- Drop the restrictive policy
DROP POLICY IF EXISTS "users_select" ON public.app_users;

-- Recreate it to allow all authenticated employees to view user profiles
-- This is necessary so Trackmen can see the name of the Manager who assigned them tasks.
CREATE POLICY "users_select" ON public.app_users FOR SELECT TO authenticated
  USING (true);
