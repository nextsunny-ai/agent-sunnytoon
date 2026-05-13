-- ============================================================
-- Agent Pro 1.0 — Supabase DB Schema
-- ============================================================
-- Supabase 프로젝트: ai-pronote (pddasonkizwviwqzdhpu) 재사용
-- 접두사 = agent_* (= AI PRONOTE 회의 도구와 분리)
-- 실행 = Supabase 콘솔 → SQL Editor → 아래 전체 붙여넣기 → Run
-- 마지막 갱신: 2026-05-12
-- ============================================================

-- ============================================================
-- 1. agent_companies — 회사 (= NEXTART, BIRCH, SUNNY 등)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.agent_companies (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug        TEXT UNIQUE NOT NULL,            -- URL slug: 'nextart', 'birch', 'sunny'
  name_en     TEXT NOT NULL,                   -- 'NEXTART', 'BIRCH SOUND', 'Team'
  name_ko     TEXT NOT NULL,                   -- 'Nextart Studio', 'Birch Sound', 'Team'
  initial     TEXT NOT NULL,                   -- 'N', 'B', 'S' (= 로고 마크)
  accent      TEXT DEFAULT '#1F4D3F',          -- 메인 컬러 (CSS)
  accent_deep TEXT DEFAULT '#163A30',          -- 진한 컬러
  accent_soft TEXT DEFAULT '#E8F0EC',          -- 연한 컬러
  tagline     TEXT,                            -- 환영 메시지
  eyebrow     TEXT DEFAULT 'Welcome back',     -- Hero 위 작은 텍스트
  active      BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 2. agent_personas — 페르소나 마스터 (= 자동 업데이트 베이스)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.agent_personas (
  id           TEXT PRIMARY KEY,               -- 'sori', 'rian', 'kai' ...
  ko           TEXT NOT NULL,                  -- '소리'
  en           TEXT NOT NULL,                  -- 'SORI'
  studio       TEXT NOT NULL,                  -- 'Story Studio'
  copy         TEXT NOT NULL,                  -- 카드 설명
  sys_prompt   TEXT NOT NULL,                  -- 시스템 프롬프트 전체
  span         TEXT DEFAULT 'span 4',          -- 그리드 span
  featured     BOOLEAN DEFAULT FALSE,
  sort_order   INTEGER DEFAULT 100,
  active       BOOLEAN DEFAULT TRUE,
  updated_at   TIMESTAMPTZ DEFAULT NOW()       -- 갱신 시각 = 자동 업데이트 트리거
);

-- ============================================================
-- 3. agent_company_personas — 회사별 페르소나 매핑
-- ============================================================
CREATE TABLE IF NOT EXISTS public.agent_company_personas (
  company_id  UUID REFERENCES public.agent_companies(id) ON DELETE CASCADE,
  persona_id  TEXT REFERENCES public.agent_personas(id) ON DELETE CASCADE,
  sort_order  INTEGER DEFAULT 100,
  PRIMARY KEY (company_id, persona_id)
);

-- ============================================================
-- 4. agent_memberships — 사용자-회사 매핑 + 권한
-- ============================================================
CREATE TABLE IF NOT EXISTS public.agent_memberships (
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  company_id  UUID REFERENCES public.agent_companies(id) ON DELETE CASCADE,
  role        TEXT NOT NULL DEFAULT 'member',  -- 'admin' (대표님) / 'member' (외부 사용자)
  invited_by  UUID REFERENCES auth.users(id),
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, company_id)
);

-- ============================================================
-- 5. agent_subscriptions — 미래 결제 대비 (= 글로벌 룰 16번 BYOK 디폴트)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.agent_subscriptions (
  user_id     UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  plan        TEXT NOT NULL DEFAULT 'free',    -- 'free' / 'pro' / 'studio' / 'lifetime'
  expires_at  TIMESTAMPTZ,                     -- NULL = 영구
  jwt_license TEXT,                            -- 라이선스 JWT (= 스토리메이커 lib/license.ts 패턴)
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 6. Indexes
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_agent_memberships_user ON public.agent_memberships(user_id);
CREATE INDEX IF NOT EXISTS idx_agent_memberships_company ON public.agent_memberships(company_id);
CREATE INDEX IF NOT EXISTS idx_agent_company_personas_company ON public.agent_company_personas(company_id);

-- ============================================================
-- 7. RLS (Row Level Security) 활성화
-- ============================================================
ALTER TABLE public.agent_companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agent_personas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agent_company_personas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agent_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agent_subscriptions ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 8. RLS Policies
-- ============================================================

-- agent_personas: 모두 read OK (= 자동 동기화 = 공개 정보, sys_prompt 포함)
DROP POLICY IF EXISTS "agent_personas_read_all" ON public.agent_personas;
CREATE POLICY "agent_personas_read_all" ON public.agent_personas FOR SELECT USING (active = TRUE);

-- agent_personas: 대표님 (admin)만 수정
DROP POLICY IF EXISTS "agent_personas_admin_write" ON public.agent_personas;
CREATE POLICY "agent_personas_admin_write" ON public.agent_personas
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.agent_memberships m
      WHERE m.user_id = auth.uid() AND m.role = 'admin'
    )
  );

-- agent_companies: 로그인한 사용자가 = 본인 소속 회사만 read
DROP POLICY IF EXISTS "agent_companies_read_own" ON public.agent_companies;
CREATE POLICY "agent_companies_read_own" ON public.agent_companies FOR SELECT USING (
  active = TRUE AND (
    EXISTS (
      SELECT 1 FROM public.agent_memberships m
      WHERE m.company_id = agent_companies.id AND m.user_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.agent_memberships m
      WHERE m.user_id = auth.uid() AND m.role = 'admin'
    )
  )
);

-- agent_companies: admin만 수정
DROP POLICY IF EXISTS "agent_companies_admin_write" ON public.agent_companies;
CREATE POLICY "agent_companies_admin_write" ON public.agent_companies
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.agent_memberships m
      WHERE m.user_id = auth.uid() AND m.role = 'admin'
    )
  );

-- agent_company_personas: 본인 소속 회사 매핑만 read
DROP POLICY IF EXISTS "agent_company_personas_read_own" ON public.agent_company_personas;
CREATE POLICY "agent_company_personas_read_own" ON public.agent_company_personas FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.agent_memberships m
    WHERE m.company_id = agent_company_personas.company_id AND m.user_id = auth.uid()
  )
  OR EXISTS (
    SELECT 1 FROM public.agent_memberships m
    WHERE m.user_id = auth.uid() AND m.role = 'admin'
  )
);

-- agent_company_personas: admin만 수정
DROP POLICY IF EXISTS "agent_company_personas_admin_write" ON public.agent_company_personas;
CREATE POLICY "agent_company_personas_admin_write" ON public.agent_company_personas
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.agent_memberships m
      WHERE m.user_id = auth.uid() AND m.role = 'admin'
    )
  );

-- agent_memberships: 본인 row만 read
DROP POLICY IF EXISTS "agent_memberships_read_own" ON public.agent_memberships;
CREATE POLICY "agent_memberships_read_own" ON public.agent_memberships FOR SELECT USING (
  user_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM public.agent_memberships m
    WHERE m.user_id = auth.uid() AND m.role = 'admin'
  )
);

-- agent_memberships: admin만 수정
DROP POLICY IF EXISTS "agent_memberships_admin_write" ON public.agent_memberships;
CREATE POLICY "agent_memberships_admin_write" ON public.agent_memberships
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.agent_memberships m
      WHERE m.user_id = auth.uid() AND m.role = 'admin'
    )
  );

-- agent_subscriptions: 본인 row만
DROP POLICY IF EXISTS "agent_subscriptions_read_own" ON public.agent_subscriptions;
CREATE POLICY "agent_subscriptions_read_own" ON public.agent_subscriptions FOR SELECT USING (
  user_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM public.agent_memberships m
    WHERE m.user_id = auth.uid() AND m.role = 'admin'
  )
);

-- ============================================================
-- 9. 시드 데이터 — 12명 페르소나 + 3개 회사 (NEXTART·BIRCH·SUNNY)
-- ============================================================

-- 12명 페르소나
INSERT INTO public.agent_personas (id, ko, en, studio, copy, sys_prompt, span, featured, sort_order) VALUES
('genie', '지니', 'GENIE', 'Personal Assistant', '일정·메일·뉴스·건강·자기개발·영어·브랜딩. 대표님 개인 비서. 텔레그램 단일 창구.',
 '당신은 Team 지니(GENIE), 대표님 개인 비서. 일정·메일·뉴스·건강·자기개발·영어·브랜딩·개인 재무. 호칭 "대표님".', 'span 4', FALSE, 10),
('sera', '세라', 'SERA', 'Company A', 'Company A 팀장. KOFIC·KOCCA·Sample IP 2·Sample IP 1·IR.',
 '당신은 Team 세라(SERA), Company A 팀장. KOFIC·KOCCA·Sample IP 2·Sample IP 1·IR·지원사업. 호칭 "대표님".', 'span 4', FALSE, 20),
('nea', '네아', 'NEA', 'Nextart', 'Nextart Studio 팀장. AI 콘텐츠·Outdoor Media Project·Tourism Media Project·XR.',
 '당신은 Team 네아(NEA), Nextart Studio 팀장. AI 콘텐츠 제작·Outdoor Media Project·Tourism Media Project·XR·외주. 호칭 "대표님".', 'span 4', FALSE, 30),
('mori', '모리', 'MORI', 'Goodz', 'Goodz Moment 팀장. Sample Webtoon·Sample Animation·팝업·온라인몰.',
 '당신은 Team 모리(MORI), Goodz Moment 팀장. Sample Webtoon·Sample Animation·팝업·온라인몰·글로벌. 호칭 "대표님".', 'span 4', FALSE, 40),
('birch', '버치', 'BIRCH', 'Birch Sound', 'Birch Sound 팀장. Sample Music Project·Sample Festival·페스티벌·ERP.',
 '당신은 Team 버치(BIRCH), Birch Sound 팀장. Sample Music Project·Sample Festival·페스티벌·ERP·뮤직콘텐츠. 호칭 "대표님".', 'span 4', FALSE, 50),
('sori', '소리', 'SORI', 'Story Studio', '시나리오 · 트리트먼트 · 캐릭터 · 대사. 당신의 이야기를 끝까지 함께 다듬는 전담 작가.',
 '당신은 Team 소리(SORI), 시나리오 작가. 트리트먼트·캐릭터·대사·작법 매트릭스. 호칭 "대표님".', 'span 7', FALSE, 60),
('rian', '리안', 'RIAN', 'Design Studio', 'PPT · 웹 · 이미지 · CI/BI · 모션. 30년 CD 감각의 전담 비주얼 디렉터가 한 손에 다 봅니다.',
 '당신은 Team 리안(RIAN), 디자인·비주얼. PPT·웹·UI·CI/BI·이미지·영상·visual-maker. 30년 CD 감각. 호칭 "대표님".', 'span 5 / span 2', TRUE, 70),
('maru', '마루', 'MARU', 'Marketing Studio', 'SEO · 전략 · 실행 · KPI. 풀스택 마케터가 캠페인 한 사이클을 돌립니다.',
 '당신은 Team 마루(MARU), 마케팅·PR. 제안서·보도자료·SNS·영업·SEO·KPI. 호칭 "대표님".', 'span 4', FALSE, 80),
('lumi', '루미', 'LUMI', 'Content Studio', '드라마 · 애니 · 전시 · AR/VR. 콘텐츠 PD가 IP 한 줄 책임집니다.',
 '당신은 Team 루미(LUMI), 콘텐츠 PD. IP 발굴·AI 영상·드라마·애니·전시·AR/VR. 호칭 "대표님".', 'span 3', FALSE, 90),
('teo', '테오', 'TEO', 'Tech Studio', '코드 · 자동화 · 인프라. 풀스택 개발자가 사이트·자동화·서버를 즉시 처리합니다.',
 '당신은 Team 테오(TEO), 기술·개발. 앱·웹·API·서버·LIDAR·자동화·Bash·Python. 호칭 "대표님".', 'span 7', FALSE, 100),
('hana', '하나', 'HANA', 'Legal & Finance', '회계 · 법무 · 세무 · 미수금 · 계약서. 변호사·법무사·변리사·회계사 역할.',
 '당신은 Team 하나(HANA), 회계·법무·세무. 4사 회계·재무·법무·세무·미수금·사기 방지·계약서 1차 검토. 호칭 "대표님".', 'span 5', FALSE, 110),
('kai', '카이', 'KAI', 'Game Studio', '게임 디렉터. Phaser·Godot 풀스택. 코드·디자인·사운드·시나리오·출시 1인 책임.',
 '당신은 Team 카이(KAI), 게임 디렉터. Phaser·Godot 풀스택. 디자인 시스템 v1 [15부 게임] 의무. Game Feel 7원칙. 호칭 "대표님".', 'span 4', FALSE, 120)
ON CONFLICT (id) DO UPDATE SET
  ko = EXCLUDED.ko, en = EXCLUDED.en, studio = EXCLUDED.studio,
  copy = EXCLUDED.copy, sys_prompt = EXCLUDED.sys_prompt,
  span = EXCLUDED.span, featured = EXCLUDED.featured, sort_order = EXCLUDED.sort_order,
  updated_at = NOW();

-- 3개 회사
INSERT INTO public.agent_companies (slug, name_en, name_ko, initial, accent, accent_deep, accent_soft, tagline) VALUES
('nextart', 'NEXTART', 'Nextart Studio', 'N', '#1F4D3F', '#163A30', '#E8F0EC',
 'AI · XR · VFX Production. 전담 외주 스튜디오가 통째로 Director님 프로젝트만 돌봅니다.'),
('birch', 'BIRCH SOUND', 'Birch Sound', 'B', '#C72A1F', '#8E1E15', '#FCE4E1',
 'Music Project · Sample Festival · 페스티벌 · ERP. 전담 팀이 Birch Sound 프로젝트를 함께 만듭니다.'),
('sunny', 'Team', 'Team', 'S', '#FF8C42', '#E05A1B', '#FFF0E2',
 '12명 페르소나 풀세트. 대표님 전용.')
ON CONFLICT (slug) DO UPDATE SET
  name_en = EXCLUDED.name_en, name_ko = EXCLUDED.name_ko, initial = EXCLUDED.initial,
  accent = EXCLUDED.accent, accent_deep = EXCLUDED.accent_deep, accent_soft = EXCLUDED.accent_soft,
  tagline = EXCLUDED.tagline, updated_at = NOW();

-- 회사별 페르소나 매핑
-- NEXTART = 소리·리안·마루·루미·테오·카이 (6명)
INSERT INTO public.agent_company_personas (company_id, persona_id, sort_order)
SELECT c.id, p, ROW_NUMBER() OVER ()
FROM public.agent_companies c, UNNEST(ARRAY['sori','rian','maru','lumi','teo','kai']) AS p
WHERE c.slug = 'nextart'
ON CONFLICT DO NOTHING;

-- BIRCH = 버치·테오·리안 (3명)
INSERT INTO public.agent_company_personas (company_id, persona_id, sort_order)
SELECT c.id, p, ROW_NUMBER() OVER ()
FROM public.agent_companies c, UNNEST(ARRAY['birch','teo','rian']) AS p
WHERE c.slug = 'birch'
ON CONFLICT DO NOTHING;

-- SUNNY = 12명 전체 (대표님)
INSERT INTO public.agent_company_personas (company_id, persona_id, sort_order)
SELECT c.id, p, ROW_NUMBER() OVER ()
FROM public.agent_companies c, UNNEST(ARRAY['genie','sera','nea','mori','birch','sori','rian','maru','lumi','teo','hana','kai']) AS p
WHERE c.slug = 'sunny'
ON CONFLICT DO NOTHING;

-- ============================================================
-- 10. 대표님 admin membership 자동 등록 트리거
-- = admin@example.com으로 처음 로그인하면 자동으로 = admin 권한 + SUNNY 회사 소속
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_agent_user()
RETURNS TRIGGER AS $$
DECLARE
  sunny_company_id UUID;
BEGIN
  -- 대표님 이메일이면 = admin + SUNNY 소속 자동
  IF NEW.email = 'admin@example.com' THEN
    SELECT id INTO sunny_company_id FROM public.agent_companies WHERE slug = 'sunny';
    IF sunny_company_id IS NOT NULL THEN
      INSERT INTO public.agent_memberships (user_id, company_id, role)
      VALUES (NEW.id, sunny_company_id, 'admin')
      ON CONFLICT (user_id, company_id) DO UPDATE SET role = 'admin';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created_agent ON auth.users;
CREATE TRIGGER on_auth_user_created_agent
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_agent_user();

-- ============================================================
-- 11. 검증 쿼리 (= 실행 후 확인용)
-- ============================================================
-- SELECT slug, name_en, name_ko FROM public.agent_companies;
-- SELECT id, ko, studio FROM public.agent_personas ORDER BY sort_order;
-- SELECT c.slug, COUNT(*) FROM public.agent_companies c JOIN public.agent_company_personas cp ON c.id = cp.company_id GROUP BY c.slug;

-- 끝
