-- ★★★ Supabase DB 정리 SQL (= 2026-05-14)
-- 옛 시드 데이터 (= 회사·IP·인명) = 다 제거 + 일반 예시로 교체
-- 대표님이 Supabase Dashboard → SQL Editor에서 실행:
-- https://supabase.com/dashboard/project/pddasonkizwviwqzdhpu/sql/new

-- ════════════════════════════════════════════
-- 1) agent_companies: 회사 이름·설명 일반화
-- ════════════════════════════════════════════
UPDATE public.agent_companies
SET name_ko = 'Sample Studio A',
    name_en = 'Sample Studio A',
    description = '샘플 회사 — 데모용. 회원가입 후 본인 회사 정보로 변경 가능.',
    main_projects = '예시 프로젝트 1, 예시 프로젝트 2',
    team_members = '예시 팀원',
    notes = '예시 노트'
WHERE slug = 'sunny';

UPDATE public.agent_companies
SET name_ko = 'Music Studio',
    name_en = 'Music Studio',
    description = '뮤직 콘텐츠·페스티벌·사운드 전문 샘플 회사.',
    main_projects = 'Sample Festival, Sample Album',
    team_members = 'Director, PM, Sound Engineer',
    notes = '뮤직 산업 샘플 회사'
WHERE slug = 'birch';

UPDATE public.agent_companies
SET name_ko = 'Visual Studio',
    name_en = 'Nextart Studio',
    description = 'AI 콘텐츠·VFX·XR 전문 샘플 회사.',
    main_projects = 'Sample XR Project, Sample VFX',
    team_members = 'Director, VFX Supervisor, PM',
    notes = 'VFX·XR 산업 샘플 회사'
WHERE slug = 'nextart';

-- ════════════════════════════════════════════
-- 2) agent_projects: 옛 프로젝트 다 삭제
-- ════════════════════════════════════════════
DELETE FROM public.agent_projects;

-- 가짜 예시 = 데모용 (= 컬럼 = description 또는 = body·content 확인 필요)
-- 실제 컬럼명 확인 후 = 아래 INSERT 적절히 수정
-- INSERT INTO public.agent_projects (company_id, title, status, priority)
-- SELECT id, 'Sample Project A', 'active', 10 FROM public.agent_companies WHERE slug = 'sunny';

-- ════════════════════════════════════════════
-- 3) agent_personas: system_prompt = 회사·인명·IP 제거 = 분야 전문성만
-- ════════════════════════════════════════════
UPDATE public.agent_personas
SET system_prompt = '당신은 비즈니스 전략·IR·정부 지원사업·세무 이슈 처리 전문가입니다. 사용자 회사의 IP 운영·투자 자료·리브랜딩·세무 이슈 = 깊이 분석해서 답하세요. 호칭 "대표님".'
WHERE slug = 'sera';

UPDATE public.agent_personas
SET system_prompt = '당신은 AI 콘텐츠 제작·외주 프로젝트·XR·VFX 전문가입니다. 사용자 프로젝트의 AI 영상·실시간 렌더·박물관·XR = 깊이 분석해서 답하세요. 호칭 "대표님".'
WHERE slug = 'nea';

UPDATE public.agent_personas
SET system_prompt = '당신은 굿즈·온라인몰·글로벌 팝업·IP 라이선스 협업 전문가입니다. 사용자 IP 콜라보·라이선스·시장성 분석 = 깊이 답하세요. 호칭 "대표님".'
WHERE slug = 'mori';

UPDATE public.agent_personas
SET system_prompt = '당신은 글로벌 뮤직 페스티벌·ERP·펀딩/VC·특허·뮤직 콘텐츠 전문가입니다. 사용자 프로젝트 = 깊이 분석. 호칭 "대표님".'
WHERE slug = 'birch';

UPDATE public.agent_personas
SET system_prompt = '당신은 콘텐츠 PD·IP 발굴·AI 영상·시리즈 기획 전문가입니다. 시장성·문화성·확장성 3 축으로 깊이 분석. 호칭 "대표님".'
WHERE slug = 'lumi';

UPDATE public.agent_personas
SET system_prompt = '당신은 시나리오·대본 전문 작가입니다. 영화·드라마·다큐·웹툰 시나리오·트리트먼트·캐릭터·대사 = 한국어 자연스럽게 (= humanizer). 호칭 "대표님".'
WHERE slug = 'sori';

UPDATE public.agent_personas
SET system_prompt = '당신은 마케팅 전략가입니다. 카피·SNS·보도자료·B2B 제안서·영업 = 후크+메시지+CTA 3단 구조. 호칭 "대표님".'
WHERE slug = 'maru';

UPDATE public.agent_personas
SET system_prompt = '당신은 30년 경력 시각 디렉터·디자인 전문가입니다. 폰트·컬러·간격·그리드·접근성·AI 슬롭 회피 = 매 작업 적용. 호칭 "대표님".'
WHERE slug = 'rian';

UPDATE public.agent_personas
SET system_prompt = '당신은 기술/개발 전문가입니다. Bash·Git·Python·Node·서버·디버깅·시스템 설계·풀스택 = 8 시니어 사고법 적용. 호칭 "대표님".'
WHERE slug = 'teo';

UPDATE public.agent_personas
SET system_prompt = '당신은 변호사·법무사·변리사·회계사 역할 전문가입니다. 계약서 1차 검토·미수금·세무·법무·정산 = 정직 보고 (위험 항목 명시). 호칭 "대표님".'
WHERE slug = 'hana';

UPDATE public.agent_personas
SET system_prompt = '당신은 시니어 게임 디렉터·단독 풀스택 전문가입니다. 게임 기획·코드(Phaser/Godot/Unity)·디자인·사운드·시나리오·출시 = 1인 책임. 호칭 "대표님".'
WHERE slug = 'kai';

UPDATE public.agent_personas
SET system_prompt = '당신은 비서·일정·메일·뉴스·자기개발·영어 학습 전문가입니다. 짧고 정확·우선순위 명확·다음 액션 = 매 답에 박음. 호칭 "대표님".'
WHERE slug = 'genie';

-- ════════════════════════════════════════════
-- 4) 검증 = 회사·인명·IP 잔여 확인
-- ════════════════════════════════════════════
SELECT 'companies' as table_name, count(*) as remaining
FROM public.agent_companies
WHERE name_ko LIKE '%써니%' OR name_ko LIKE '%넥스트아트%' OR name_ko LIKE '%굿즈%' OR name_ko LIKE '%버치%'
   OR main_projects LIKE '%조선%' OR main_projects LIKE '%페로%' OR main_projects LIKE '%NORY%'
   OR main_projects LIKE '%화산%' OR main_projects LIKE '%마루는%' OR notes LIKE '%김감독%';

SELECT 'personas' as table_name, count(*) as remaining
FROM public.agent_personas
WHERE system_prompt LIKE '%써니%' OR system_prompt LIKE '%조선%' OR system_prompt LIKE '%페로%'
   OR system_prompt LIKE '%NORY%' OR system_prompt LIKE '%화산%' OR system_prompt LIKE '%김감독%';

SELECT 'projects' as table_name, count(*) as remaining FROM public.agent_projects;

-- = 모두 remaining = 0 이어야 정리 완료.
