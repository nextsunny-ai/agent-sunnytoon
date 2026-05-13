# Agent Pro 1.0 — agent.sunnytoon.com

써니팀 12명 페르소나 = 외주 에이전트 SaaS. 클라이언트별 페르소나 묶음 + BYOK + 마이크·이미지 채팅.

## 회사별 공유 URL

| 회사 | URL | 페르소나 |
|---|---|---|
| NEXTART (Director) | `agent.sunnytoon.com/?c=nextart` | 소리·리안·마루·루미·테오·카이 = 6명 |
| Birch Sound | `agent.sunnytoon.com/?c=birch` | 버치·테오·리안 = 3명 |
| Team (대표님) | `agent.sunnytoon.com/?c=sunny` 또는 `/` | 12명 전체 |

## BYOK 모델

- 사용자 본인 Anthropic API 키 입력 = 본인 결제 = 대표님 비용 0
- 키 = 브라우저 localStorage + `.sunnytoon.com` 쿠키 공유 (= home·team·agent 한 번 저장하면 다 작동)
- 키 발급: https://console.anthropic.com/settings/keys → "Create Key" → `sk-ant-api03-...` 복사

## Phase 2 (= 다음 = 인증·어드민)

- Supabase 로그인 (이메일·Google OAuth)
- 어드민 페이지 = 회사 추가·페르소나 할당·로고·컬러 입력
- RLS 권한 + 사용자별 회사 매핑

---

Generated 2026-05-12.
