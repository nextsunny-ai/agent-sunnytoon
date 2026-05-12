-- ============================================================
-- agent_delete_user RPC 함수 (2026-05-12)
-- admin만 = 사용자 삭제 가능 (= auth.users + cascade로 agent_* 테이블 다 삭제)
-- 자기 자신 삭제 X (= 안전)
-- ============================================================

CREATE OR REPLACE FUNCTION public.agent_delete_user(_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- admin만
  IF NOT public.is_agent_admin() THEN
    RAISE EXCEPTION 'Admin only' USING ERRCODE = '42501';
  END IF;
  -- 자기 자신 삭제 방지
  IF _user_id = auth.uid() THEN
    RAISE EXCEPTION 'Cannot delete yourself' USING ERRCODE = '42501';
  END IF;
  -- auth.users 삭제 = cascade로 agent_memberships·subscriptions 자동 삭제
  DELETE FROM auth.users WHERE id = _user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.agent_delete_user(UUID) TO authenticated;

-- 끝
