# SUNNY Agent Pro v1.1.0 — agent.sunnytoon.com

12명 SUNNY 에이전트 SaaS = 본인 Claude Pro/Max 구독 기반. 회사별 페르소나 묶음 + 마이크·이미지·텔레그램 통합.

## 핵심 모델 (= v1.1.0)

★ 사용자 본인 Claude Pro/Max 구독 + Claude Code CLI = 본인 비용으로 답변.
- 우리 = 12 페르소나 SKILL (= 학습 노하우) + 회사별 묶음 제공
- 사용자 = 본인 Claude CLI subprocess로 SKILL을 system prompt로 받아 사용
- 비용 = 사용자 본인 Claude 구독 (= 우리 0원, BYOK)
- 호출 = Anthropic API 직접 X = `claude --print --system-prompt-file` subprocess

## 회사별 공유 URL

| 회사 | URL | 페르소나 |
|---|---|---|
| NEXTART (Director) | `agent.sunnytoon.com/?c=nextart` | 소리·리안·마루·루미·테오·카이 = 6명 |
| Birch Sound | `agent.sunnytoon.com/?c=birch` | 버치·테오·리안 = 3명 |
| SUNNY Team (대표님) | `agent.sunnytoon.com/?c=sunny` 또는 `/` | 12명 전체 |

## 사용자 7단계 (= 비기술자 첫 셋업)

1. 위 URL 클릭 → 가입 (= Email·Google·매직 링크 = 셋 중 1)
2. macOS·Windows 데스크탑 앱 다운로드 (= 위 URL 페이지 안 카드)
3. 다운로드한 파일 더블클릭 → 설치
4. **Claude Code CLI 설치** (= 한 번만, 약 2분):
   - 노드 14+ 설치: https://nodejs.org/ko 에서 LTS 받음
   - 터미널: `npm install -g @anthropic-ai/claude-code`
5. **Claude 로그인** (= 한 번만): 터미널 `claude /login` → 본인 Pro/Max 계정
6. **Claude Pro 또는 Max 구독** (= 필수, claude.ai/upgrade):
   - Pro $20/월 = 일반 사용 OK
   - Max $200/월 = 대량 사용
7. 데스크탑 앱 실행 → 페르소나 클릭 → 채팅

> 첫 셋업 = 약 10분. 이후 = 앱 실행만 = 즉시 채팅.

## 인프라

- **Frontend**: GitHub Pages (`agent.sunnytoon.com`) + Tauri 데스크탑 앱
- **Auth**: Supabase (`pddasonkizwviwqzdhpu`, 접두사 `agent_*`)
- **SMTP**: Resend (`sunnytoon.com` 도메인) = 한국어 템플릿
- **자동 업데이터**: Tauri updater + Vercel API + minisign 서명
- **Build**: GitHub Actions (`release-*` 태그 push 시 macOS arm/intel + Windows 자동 빌드)

## v1.1.0 변경 (= 2026-05-26)

- ★ 버전 라벨 v1.0.0-beta-2 → v1.1.0 (= 모든 .html 정정)
- ★ 다운로드 link = 옛 zip → 새 .dmg·.exe 단독
- ★ 영업 톤 일부 제거 (= "30년 CD 노하우 100% 발휘" → "표준 모델")
- ★ CRITICAL-1 CSP 박힘 (= XSS 방어, tauri.conf.json)
- ★ CRITICAL-2 ADMIN_EMAIL 클라이언트 평문 제거 (= `is_agent_admin()` RPC 호출로 교체)
- ★ CRITICAL-3 JWT 라이선스 = 비활성 상태 명시 + RS256 path 박힘 의무 주석
- ★ sys_prompt v2 풀세트 (= 12 페르소나 SUNNY + 8 페르소나 BIRCH) DB UPDATE SQL 신규 박힘 = `supabase_v2_sys_prompts_2026-05-26.sql`
- ★ README v1.1 갱신 = BYOK 모델 정정 (= Anthropic API 키 → Claude Code CLI 구독)

## CRITICAL 정정 진행 (= 출시 전 의무)

| # | 항목 | 상태 |
|---|---|---|
| C-1 CSP | tauri.conf.json | ✅ 박힘 |
| C-2 ADMIN 평문 | index.html·admin.html | ✅ 박힘 (= RPC 호출 + 평문 제거) |
| C-3 JWT 서명 | license.rs | ⏳ 비활성 + 미래 path 주석 (= 결제 시점에 RS256 박힘 의무) |
| C-4 sys_prompt RLS | `supabase_fix_C4_sysprompt_RLS_2026-05-26.sql` | ⏳ Supabase Console 실행 필요 |
| C-5 repo private | GitHub repo | ⏳ 대표님 직접 = 웹 1분 |

## SQL 적용 순서 (= 출시 전 의무)

Supabase Dashboard → SQL Editor → 순서대로:

1. `supabase_fix_C2_admin_rpc_2026-05-26.sql` (= `is_agent_admin()` RPC + `agent_list_users()` is_admin 필드)
2. `supabase_fix_C4_sysprompt_RLS_2026-05-26.sql` (= RLS 비로그인 차단)
3. `supabase_v2_sys_prompts_2026-05-26.sql` (= 12 페르소나 풀세트 sys_prompt UPDATE)

## License

Proprietary © 2026 SUNNY Entertainment. All rights reserved.

---

*v1.1.0 (2026-05-26). 옛 v1.0.1 = `D:\WORK\agent-sunnytoon\` 보존 (= 룰 17).*
