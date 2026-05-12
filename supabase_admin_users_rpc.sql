-- ============================================================
-- agent_list_users RPC 함수 (2026-05-12)
-- admin만 = 가입자 풀세트 (이메일·preferred_company·plan) 조회 가능
-- ============================================================

CREATE OR REPLACE FUNCTION public.agent_list_users()
RETURNS TABLE (
  user_id UUID,
  email TEXT,
  created_at TIMESTAMPTZ,
  last_sign_in_at TIMESTAMPTZ,
  preferred_company TEXT,
  plan TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- admin만 호출 가능
  IF NOT public.is_agent_admin() THEN
    RAISE EXCEPTION 'Admin only' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    u.id AS user_id,
    u.email::TEXT,
    u.created_at,
    u.last_sign_in_at,
    (u.raw_user_meta_data->>'preferred_company')::TEXT AS preferred_company,
    COALESCE(s.plan, 'free')::TEXT AS plan
  FROM auth.users u
  LEFT JOIN public.agent_subscriptions s ON s.user_id = u.id
  ORDER BY u.created_at DESC;
END;
$$;

-- 권한 = 인증된 사용자만 호출 가능 (= 내부 = admin 체크)
GRANT EXECUTE ON FUNCTION public.agent_list_users() TO authenticated;

-- 검증
-- SELECT * FROM public.agent_list_users();

-- 끝
