-- ============================================================
-- 구독 자동 생성 트리거 (2026-05-12)
-- 가입 시 = 자동으로 agent_subscriptions = free plan row 생성
-- 미래 결제 도입 시 = plan = 'pro' / 'studio' / 'lifetime'로 업그레이드
-- ============================================================

-- 1. 가입 시 자동 free row 트리거
CREATE OR REPLACE FUNCTION public.handle_new_agent_subscription()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.agent_subscriptions (user_id, plan, created_at, updated_at)
  VALUES (NEW.id, 'free', NOW(), NOW())
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created_subscription ON auth.users;
CREATE TRIGGER on_auth_user_created_subscription
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_agent_subscription();

-- 2. 옛 사용자 = free plan row 자동 생성 (= 트리거 이전 가입자 처리)
INSERT INTO public.agent_subscriptions (user_id, plan, created_at, updated_at)
SELECT id, 'free', NOW(), NOW()
FROM auth.users
WHERE NOT EXISTS (
  SELECT 1 FROM public.agent_subscriptions WHERE user_id = auth.users.id
)
ON CONFLICT (user_id) DO NOTHING;

-- 3. agent_subscriptions = admin 수정 가능 정책
DROP POLICY IF EXISTS "agent_subscriptions_admin_write" ON public.agent_subscriptions;
CREATE POLICY "agent_subscriptions_admin_write" ON public.agent_subscriptions
  FOR ALL USING (public.is_agent_admin())
  WITH CHECK (public.is_agent_admin());

-- 4. updated_at 자동 갱신 트리거
CREATE OR REPLACE FUNCTION public.update_agent_subscription_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_agent_subscription_update ON public.agent_subscriptions;
CREATE TRIGGER on_agent_subscription_update
  BEFORE UPDATE ON public.agent_subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.update_agent_subscription_timestamp();

-- 끝
