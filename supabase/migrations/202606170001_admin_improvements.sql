-- Add age column to app_users
ALTER TABLE public.app_users ADD COLUMN IF NOT EXISTS age integer DEFAULT 25;

-- Update auth user created trigger to capture phone number from raw_user_meta_data
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  is_first_user boolean;
BEGIN
  SELECT NOT EXISTS (SELECT 1 FROM public.app_users) INTO is_first_user;

  INSERT INTO public.app_users (id, full_name, role, is_active, approval_status, phone)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      split_part(NEW.email, '@', 1)
    ),
    CASE WHEN is_first_user THEN 'admin' ELSE 'trackman' END,
    CASE WHEN is_first_user THEN true ELSE false END,   -- pending users start inactive
    CASE WHEN is_first_user THEN 'approved' ELSE 'pending' END,
    COALESCE(NEW.raw_user_meta_data->>'phone', '')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;
