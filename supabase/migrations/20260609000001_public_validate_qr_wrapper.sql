-- Expose bookings.validate_qr in the public schema so the qr-validate Edge
-- Function can reach it via /rest/v1/rpc/validate_qr (no Content-Profile header).
CREATE OR REPLACE FUNCTION public.validate_qr(p_qr_token uuid)
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = bookings, business, admin, auth, public
AS $$
  SELECT bookings.validate_qr(p_qr_token);
$$;
