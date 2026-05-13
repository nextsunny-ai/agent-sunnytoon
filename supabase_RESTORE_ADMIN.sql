-- ★★★ 긴급 정정 (2026-05-14)
-- 옛 sanitize 시 = nextsunny@gmail.com → admin@example.com 치환됨
-- = 사장님 본인 = admin 권한 잃음 = 정정 필요
--
-- 실행: https://supabase.com/dashboard/project/pddasonkizwviwqzdhpu/sql/new

-- is_agent_admin() = 사장님 이메일로 정정
CREATE OR REPLACE FUNCTION public.is_agent_admin()
RETURNS BOOLEAN AS $$
  SELECT (auth.jwt() ->> 'email') = 'nextsunny@gmail.com';
$$ LANGUAGE sql STABLE;

-- 검증
SELECT public.is_agent_admin() AS admin_status_for_current_user;

-- = TRUE 이면 = 사장님 = admin 복원 OK
-- = FALSE 이면 = SQL Editor에서 다른 계정으로 실행됨 = 함수만 정정됐으면 OK
