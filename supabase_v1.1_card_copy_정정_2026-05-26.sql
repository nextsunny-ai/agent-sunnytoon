-- ============================================================
-- ★ v1.1 카드 copy 영업 톤 정정 (= 2026-05-26)
-- ============================================================
-- 사유: agent_personas.copy = 사용자 첫 시각 = 영업 톤 ("전담·풀스택·즉시 처리·돌립니다·발휘") 잔존
-- 정정: 정보만 박힘 = "X·Y·Z 담당" 표준 (= 글로벌 룰 20 = 영업·홍보 톤 금지)
--
-- 실행: Supabase Dashboard → SQL Editor → 본 SQL 전체 → Run
-- 의존: supabase_schema.sql (= agent_personas 테이블 박힘)
-- ============================================================

-- 12 페르소나 copy 정정 (= 영업 톤 제거)

UPDATE public.agent_personas SET copy = '일정·메일·뉴스·건강·자기개발·영어·브랜딩·개인 비서 영역', updated_at = NOW()
WHERE id = 'genie';

UPDATE public.agent_personas SET copy = '비즈니스 전략·IR·정부 지원사업·세무 영역', updated_at = NOW()
WHERE id = 'sera';

UPDATE public.agent_personas SET copy = 'AI 콘텐츠·외주 프로젝트·XR·VFX 영역', updated_at = NOW()
WHERE id = 'nea';

UPDATE public.agent_personas SET copy = '굿즈·온라인몰·글로벌 팝업·IP 라이선스 영역', updated_at = NOW()
WHERE id = 'mori';

UPDATE public.agent_personas SET copy = '글로벌 뮤직 페스티벌·ERP·뮤직 콘텐츠 영역', updated_at = NOW()
WHERE id = 'birch';

UPDATE public.agent_personas SET copy = '시나리오·트리트먼트·캐릭터·대사 (한국어 자연도)', updated_at = NOW()
WHERE id = 'sori';

UPDATE public.agent_personas SET copy = 'PPT·웹·이미지·CI/BI·모션 (디자인 시스템 17부 기반)', updated_at = NOW()
WHERE id = 'rian';

UPDATE public.agent_personas SET copy = 'SEO·전략·실행·KPI·캠페인 사이클', updated_at = NOW()
WHERE id = 'maru';

UPDATE public.agent_personas SET copy = '드라마·애니·전시·AR/VR·IP 콘텐츠 PD', updated_at = NOW()
WHERE id = 'lumi';

UPDATE public.agent_personas SET copy = '코드·자동화·인프라·사이트·서버', updated_at = NOW()
WHERE id = 'teo';

UPDATE public.agent_personas SET copy = '회계·법무·세무·미수금·계약서 검토', updated_at = NOW()
WHERE id = 'hana';

UPDATE public.agent_personas SET copy = '게임 기획·Phaser·Godot·디자인·사운드·시나리오·출시', updated_at = NOW()
WHERE id = 'kai';

-- ============================================================
-- 회사 tagline 도 정정 (= 영업 톤 잔존 확인 후)
-- ============================================================

-- SUNNY = 일반화된 표현 (= 옛 sanitize에서 박힘) 그대로 유지
-- NEXTART·BIRCH = 옛 영업 톤 ("전담 외주 스튜디오가 통째로 돌봅니다") 정정
UPDATE public.agent_companies
SET tagline = 'AI · XR · VFX 콘텐츠 제작 영역',
    updated_at = NOW()
WHERE slug = 'nextart' AND tagline LIKE '%외주 스튜디오%';

UPDATE public.agent_companies
SET tagline = '뮤직 콘텐츠·페스티벌·라이센싱·ERP 영역',
    updated_at = NOW()
WHERE slug = 'birch' AND tagline LIKE '%전담 팀이%';

-- ============================================================
-- 검증 = 영업 톤 키워드 잔존 확인
-- ============================================================

SELECT 'personas_copy' AS source, id, copy
FROM public.agent_personas
WHERE copy LIKE '%전담%' OR copy LIKE '%풀스택%' OR copy LIKE '%즉시%'
   OR copy LIKE '%돌립%' OR copy LIKE '%발휘%' OR copy LIKE '%한 손%'
   OR copy LIKE '%한 줄 책임%' OR copy LIKE '%끝까지%';

SELECT 'companies_tagline' AS source, slug, tagline
FROM public.agent_companies
WHERE tagline LIKE '%외주 스튜디오%' OR tagline LIKE '%전담 팀%'
   OR tagline LIKE '%통째로%' OR tagline LIKE '%돌봅니다%';

-- = 모두 0 row = 정정 완료
-- = row 있음 = 추가 정정 필요

-- 끝
