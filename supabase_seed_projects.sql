-- ============================================================
-- 시범 프로젝트 시드 데이터 (2026-05-12)
-- NEXTART·BIRCH·SUNNY 각자 3개씩
-- ============================================================

-- 옛 시드 다 삭제 후 새로 = 깨끗
DELETE FROM public.agent_projects;

-- NEXTART (= Director)
INSERT INTO public.agent_projects (company_id, title, subtitle, status, sort_order)
SELECT id, 'Tourism Media Project XR 영상', '몰입형 XR 콘텐츠 = AI 컴포지팅·실시간 렌더', 'active', 10 FROM public.agent_companies WHERE slug = 'nextart'
UNION ALL
SELECT id, 'Outdoor Media Project 분수쇼 시안', '미디어아트·분수·조명 통합 연출', 'completed', 20 FROM public.agent_companies WHERE slug = 'nextart'
UNION ALL
SELECT id, 'AI 콘텐츠 시리즈', '바이럴 숏폼·SNS 캠페인 = AI 영상', 'active', 30 FROM public.agent_companies WHERE slug = 'nextart';

-- BIRCH SOUND (= 버치)
INSERT INTO public.agent_projects (company_id, title, subtitle, status, sort_order)
SELECT id, 'Sample Music Project 학습 매니저', '아동·청소년 AI 학습 동반자 = V8 진행 중', 'active', 10 FROM public.agent_companies WHERE slug = 'birch'
UNION ALL
SELECT id, 'Sample Festival 페스티벌', '몰입형 사운드·라이트 페스티벌 기획', 'active', 20 FROM public.agent_companies WHERE slug = 'birch'
UNION ALL
SELECT id, 'AETER 글로벌 뮤직&아트', '뮤직 + 아트 페스티벌 브랜딩', 'paused', 30 FROM public.agent_companies WHERE slug = 'birch';

-- Team (= 대표님)
INSERT INTO public.agent_projects (company_id, title, subtitle, status, url, sort_order)
SELECT id, 'Sample IP 1', 'IP 시나리오·웹툰·드라마 = valuable IP', 'active', NULL, 10 FROM public.agent_companies WHERE slug = 'sunny'
UNION ALL
SELECT id, 'Story Maker V2', '작가용 AI 협업 도구 = 출시 준비', 'active', 'https://story.sunnytoon.com', 20 FROM public.agent_companies WHERE slug = 'sunny'
UNION ALL
SELECT id, 'Agent Pro 1.0', '12명 페르소나 SaaS = 본 시스템', 'active', 'https://agent.sunnytoon.com', 30 FROM public.agent_companies WHERE slug = 'sunny';

-- 검증
SELECT c.name_en, COUNT(p.*) AS projects FROM public.agent_companies c LEFT JOIN public.agent_projects p ON p.company_id = c.id GROUP BY c.name_en ORDER BY c.name_en;
