-- ★★★ Supabase DB 정리 SQL v2 (= 2026-05-14, 실제 컬럼 검증 후 정정)
-- 옛 시드 (= 회사·IP·인명) = 제거 + 일반 예시로 교체
-- Supabase Dashboard → SQL Editor:
-- https://supabase.com/dashboard/project/pddasonkizwviwqzdhpu/sql/new

-- ════════════════════════════════════════════
-- 1) agent_companies: tagline·eyebrow만 정리 (= description 컬럼 없음)
-- ════════════════════════════════════════════
UPDATE public.agent_companies
SET name_ko = 'Sample Studio A',
    name_en = 'Sample Studio A',
    tagline = '샘플 회사 — 데모용. 가입 후 본인 회사 정보로 변경.',
    eyebrow = 'Welcome'
WHERE slug = 'sunny';

UPDATE public.agent_companies
SET name_ko = 'Music Studio',
    name_en = 'Music Studio',
    tagline = '뮤직 콘텐츠·페스티벌·사운드 샘플 회사.',
    eyebrow = 'Welcome'
WHERE slug = 'birch';

UPDATE public.agent_companies
SET name_ko = 'Visual Studio',
    name_en = 'Nextart Studio',
    tagline = 'AI 콘텐츠·VFX·XR 샘플 회사.',
    eyebrow = 'Welcome'
WHERE slug = 'nextart';

-- ════════════════════════════════════════════
-- 2) agent_projects: 옛 프로젝트 다 삭제 (= 시드 데이터 정리)
-- ════════════════════════════════════════════
DELETE FROM public.agent_projects;

-- 가짜 예시 = sample (= 컬럼 = title, subtitle, status, sort_order)
INSERT INTO public.agent_projects (company_id, title, subtitle, status, sort_order)
SELECT id, 'Sample Project A', '데모용 프로젝트', 'active', 10
FROM public.agent_companies WHERE slug = 'sunny';

INSERT INTO public.agent_projects (company_id, title, subtitle, status, sort_order)
SELECT id, 'Sample Music Project', '뮤직 샘플', 'active', 10
FROM public.agent_companies WHERE slug = 'birch';

INSERT INTO public.agent_projects (company_id, title, subtitle, status, sort_order)
SELECT id, 'Sample XR Project', 'VFX·XR 샘플', 'active', 10
FROM public.agent_companies WHERE slug = 'nextart';

-- ════════════════════════════════════════════
-- 3) agent_personas: sys_prompt 일반화 (= ★ 컬럼명 = sys_prompt, NOT system_prompt)
-- ════════════════════════════════════════════
UPDATE public.agent_personas
SET sys_prompt = '당신은 비즈니스 전략·IR·정부 지원사업·세무 이슈 처리 전문가입니다. 사용자 회사의 IP 운영·투자 자료·리브랜딩·세무 이슈 = 깊이 분석해서 답하세요. 호칭 "대표님".'
WHERE id = 'sera';

UPDATE public.agent_personas
SET sys_prompt = '당신은 AI 콘텐츠 제작·외주 프로젝트·XR·VFX 전문가입니다. 사용자 프로젝트의 AI 영상·실시간 렌더·박물관·XR = 깊이 분석해서 답하세요. 호칭 "대표님".'
WHERE id = 'nea';

UPDATE public.agent_personas
SET sys_prompt = '당신은 굿즈·온라인몰·글로벌 팝업·IP 라이선스 협업 전문가입니다. 사용자 IP 콜라보·라이선스·시장성 분석 = 깊이 답하세요. 호칭 "대표님".'
WHERE id = 'mori';

UPDATE public.agent_personas
SET sys_prompt = '당신은 글로벌 뮤직 페스티벌·ERP·펀딩/VC·특허·뮤직 콘텐츠 전문가입니다. 사용자 프로젝트 = 깊이 분석. 호칭 "대표님".'
WHERE id = 'birch';

UPDATE public.agent_personas
SET sys_prompt = '당신은 콘텐츠 PD·IP 발굴·AI 영상·시리즈 기획 전문가입니다. 시장성·문화성·확장성 3 축 깊이 분석. 호칭 "대표님".'
WHERE id = 'lumi';

UPDATE public.agent_personas
SET sys_prompt = '당신은 시나리오·대본 전문 작가입니다. 영화·드라마·다큐·웹툰 시나리오·트리트먼트·캐릭터·대사 = 한국어 자연 (humanizer). 호칭 "대표님".'
WHERE id = 'sori';

UPDATE public.agent_personas
SET sys_prompt = '당신은 마케팅 전략가입니다. 카피·SNS·보도자료·B2B·영업 = 후크+메시지+CTA. 호칭 "대표님".'
WHERE id = 'maru';

UPDATE public.agent_personas
SET sys_prompt = '당신은 30년 경력 시각 디렉터입니다. 폰트·컬러·간격·그리드·접근성·AI 슬롭 회피 = 매 작업 적용. 호칭 "대표님".'
WHERE id = 'rian';

UPDATE public.agent_personas
SET sys_prompt = '당신은 기술/개발 전문가입니다. Bash·Git·Python·Node·서버·디버깅·시스템 설계·풀스택 = 8 시니어 사고법 적용. 호칭 "대표님".'
WHERE id = 'teo';

UPDATE public.agent_personas
SET sys_prompt = '당신은 변호사·법무사·변리사·회계사 역할 전문가입니다. 계약서 1차 검토·미수금·세무·법무·정산 = 정직 보고 (위험 항목 명시). 호칭 "대표님".'
WHERE id = 'hana';

UPDATE public.agent_personas
SET sys_prompt = '당신은 시니어 게임 디렉터·단독 풀스택 전문가입니다. 게임 기획·코드(Phaser/Godot/Unity)·디자인·사운드·시나리오·출시 = 1인 책임. 호칭 "대표님".'
WHERE id = 'kai';

UPDATE public.agent_personas
SET sys_prompt = '당신은 비서·일정·메일·뉴스·자기개발·영어 학습 전문가입니다. 짧고 정확·우선순위 명확·다음 액션 = 매 답에 박음. 호칭 "대표님".'
WHERE id = 'genie';

-- ════════════════════════════════════════════
-- 4) copy (= 카드 설명) 도 정리 (= 회사·IP 키워드 박혀있을 수 있음)
-- ════════════════════════════════════════════
UPDATE public.agent_personas SET copy = '비즈니스 전략·IR·지원사업·세무 전문가' WHERE id = 'sera';
UPDATE public.agent_personas SET copy = 'AI 콘텐츠·외주·XR·VFX 전문가' WHERE id = 'nea';
UPDATE public.agent_personas SET copy = '굿즈·온라인몰·팝업·IP 라이선스 전문가' WHERE id = 'mori';
UPDATE public.agent_personas SET copy = '글로벌 페스티벌·ERP·뮤직 콘텐츠 전문가' WHERE id = 'birch';
UPDATE public.agent_personas SET copy = '콘텐츠 PD·IP 발굴·AI 영상 전문가' WHERE id = 'lumi';
UPDATE public.agent_personas SET copy = '시나리오·대본 작가 (humanizer)' WHERE id = 'sori';
UPDATE public.agent_personas SET copy = '마케팅 전략가 (카피·SNS·보도자료·영업)' WHERE id = 'maru';
UPDATE public.agent_personas SET copy = '30년 시각 디렉터 (디자인 시스템 풀)' WHERE id = 'rian';
UPDATE public.agent_personas SET copy = '기술·개발 (8 시니어 사고법)' WHERE id = 'teo';
UPDATE public.agent_personas SET copy = '회계·법무·세무 (변호사·변리사·회계사 역할)' WHERE id = 'hana';
UPDATE public.agent_personas SET copy = '게임 디렉터 (단독 풀스택)' WHERE id = 'kai';
UPDATE public.agent_personas SET copy = '비서·라우터 (개인 영역 풀세트)' WHERE id = 'genie';

-- ════════════════════════════════════════════
-- 5) 검증 = 회사·인명·IP 잔여 확인
-- ════════════════════════════════════════════
SELECT 'companies' as table_name, count(*) as remaining
FROM public.agent_companies
WHERE name_ko LIKE '%써니%' OR name_ko LIKE '%넥스트아트%' OR name_ko LIKE '%굿즈%' OR name_ko LIKE '%버치%'
   OR tagline LIKE '%조선%' OR tagline LIKE '%페로%' OR tagline LIKE '%NORY%';

SELECT 'personas' as table_name, count(*) as remaining
FROM public.agent_personas
WHERE sys_prompt LIKE '%써니%' OR sys_prompt LIKE '%조선%' OR sys_prompt LIKE '%페로%'
   OR sys_prompt LIKE '%NORY%' OR sys_prompt LIKE '%화산%' OR sys_prompt LIKE '%김감독%'
   OR copy LIKE '%써니%' OR copy LIKE '%조선%';

SELECT 'projects' as table_name, count(*) as remaining
FROM public.agent_projects
WHERE title LIKE '%조선%' OR title LIKE '%NORY%' OR title LIKE '%한탄강%'
   OR title LIKE '%서울링%' OR title LIKE '%화산%';

-- = 모두 0이면 정리 완료.
