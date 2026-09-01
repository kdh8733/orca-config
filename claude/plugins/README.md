# plugins/ - 플러그인 명세

설치 형상의 원천은 `claude/core/settings.json` 의 `enabledPlugins` + `setup.sh` 의
플러그인 단계다. 이 디렉토리는 배포 대상이 아니라 **명세** - 각 플러그인을 왜 쓰고
언제 쓰는지, 무엇이 있어야 동작하는지를 사람과 세션이 읽는 곳.
MCP 서버는 전부 이 플러그인 계층 소속이다.

> 플러그인을 설치/제거하면 live `~/.claude/settings.json` 이 먼저 바뀐다.
> repo의 `claude/core/settings.json` 에 반영하고 이 명세를 갱신할 것.
> `./setup.sh --check` 가 드리프트를 잡아준다.

현재 형상: **20종 · 마켓플레이스 3곳**

## 워크플로우 / 메타 (6)

| 플러그인 | 언제 쓰나 | 런타임 |
|---|---|---|
| superpowers | 워크플로우 스킬 모음 - brainstorming->writing-plans(설계), test-driven-development(코드), systematic-debugging(버그), verification-before-completion(완료 선언 전). 사용 조건은 CLAUDE.md "스킬 활용 판단" 플레이북이 정의. `using-git-worktrees` 는 CLAUDE.md 워크트리 조항에 따라 사용하지 않는다 | 불필요 |
| ralph-loop | `/ralph-loop` `/cancel-ralph` - 같은 태스크를 자기참조 루프로 반복 개선. 명확한 완료 기준이 있는 장시간 반복 작업에. 기준 없는 루프는 토큰 낭비 | 불필요 |
| hookify | 대화에서 반복된 실수/지시를 훅으로 변환 - `/hookify`. guard/ 계층의 공급선 | 불필요 |
| skill-creator | 반복 작업의 스킬화 - `/skill-creator`. skills/ 계층의 공급선 | 불필요 |
| claude-md-management | CLAUDE.md 감사·개선(`/revise-claude-md`). 150줄 원칙 보조 | 불필요 |
| session-report | 세션 사용량 HTML 리포트(토큰·캐시·서브에이전트·고비용 프롬프트) | 불필요 |

## 코드 품질 / 리뷰 (2)

| 플러그인 | 언제 쓰나 | 런타임 |
|---|---|---|
| code-review | `/code-review` - PR·diff의 정합성 버그 리뷰. `ultra` 인자로 심층 리뷰 | 불필요 |
| code-simplifier | `/simplify` - 변경분의 단순화·재사용·고도(altitude) 정리 후 적용. 버그 헌팅은 안 함(그건 code-review) | 불필요 |

> 참고: Claude Code 2.1.252 에서는 플러그인 없이도 `/code-review` 와 `/simplify` 가
> 내장 스킬로 노출된다. 두 플러그인은 상위 호환 진입점으로 함께 두되, 슬래시 커맨드가
> 중복 노출될 수 있다는 점만 알고 쓴다.

## 코드 / 문서 이해 (3)

| 플러그인 | 언제 쓰나 | 런타임 |
|---|---|---|
| serena | LSP 기반 시멘틱 코드 도구(MCP) - 심볼 탐색·참조 추적·심볼 단위 편집. 대형 코드베이스에서 grep 대신 | **uvx** (`.mcp.json` 확인) |
| understand-anything | `/understand` 계열 - 멀티에이전트 코드베이스 지식그래프·투어. 무거움 - 처음 보는 큰 코드베이스 전용 | 불필요 |
| context7 | 라이브러리 최신 공식 문서 조회(MCP) - 학습 컷오프 이후의 API·버전 정확성이 필요할 때 | HTTP MCP + `CONTEXT7_API_KEY` |

## 외부 통합 - MCP (7)

| 플러그인 | 언제 쓰나 | 런타임 |
|---|---|---|
| github | GitHub 연동 - PR·이슈·리포 작업을 gh CLI보다 구조화된 도구로 | HTTP MCP + `GITHUB_PERSONAL_ACCESS_TOKEN` |
| playwright | 브라우저 자동화(MCP) - JS 렌더 페이지 조작·검증·스크린샷 | **npx** (`.mcp.json` 확인) |
| slack | 채널 다이제스트·토픽 검색·스탠드업 생성·공지 초안 | 미확인 (외부 repo - 설치 후 `.mcp.json` 확인) |
| telegram | Claude를 텔레그램 봇 채널로 연결(`/configure` 로 토큰 등록, 페어링·allowlist 관리) | **bun** (`.mcp.json` 확인) |
| figma | Figma MCP+스킬 - 다이어그램 생성, 디자인↔코드, 디자인시스템 | 미확인 (외부 repo) |
| supabase | Supabase 전반(DB·Auth·RLS·마이그레이션) + Postgres 베스트 프랙티스 스킬 | 미확인 (외부 repo) |
| vercel | Vercel 배포·Next.js·AI SDK 전문 스킬+서브에이전트 | 미확인 (외부 repo) |

## 프론트엔드 / 미디어 (2)

| 플러그인 | 언제 쓰나 | 런타임 |
|---|---|---|
| frontend-design | 웹 컴포넌트/페이지 구현 시 제네릭 AI 미감을 피한 프로덕션급 UI 생성 | 불필요 |
| watch | `/watch <URL/경로>` - 영상 내용 분석(자막 우선, Whisper 폴백 키는 `~/.config/watch/.env`) | 자막 추출 도구(yt-dlp 등) 필요 가능 |

## 런타임 설치 - 필요할 때만

이 머신에는 초기 상태에서 `node/npx` · `bun` · `uv/uvx` · `brew` 가 없다.
플러그인 설치 자체는 런타임 없이도 성공하고, **스킬은 그대로 쓸 수 있다.**
없는 것은 MCP **서버**뿐이라 그 도구만 조용히 빠진다. 그래서 미리 다 깔지 않고
해당 도구가 실제로 필요해진 시점에 설치한다. `./setup.sh` 가 매번 무엇이 없는지
NOTE 로 알려준다.

| 필요한 것 | 설치 | 이걸 살리는 플러그인 |
|---|---|---|
| Homebrew | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` | 아래 셋의 전제(원하면 각 공식 설치 경로를 써도 된다) |
| node/npx | `brew install node` | playwright, (미확인) figma·supabase·vercel·slack |
| uv/uvx | `brew install uv` | serena |
| bun | `brew install oven-sh/bun/bun` | telegram |

설치 후에는 `claude` 세션을 새로 띄우면 MCP 서버가 붙는다. 토큰이 필요한 것
(`CONTEXT7_API_KEY`, `GITHUB_PERSONAL_ACCESS_TOKEN`)은 시크릿이므로 repo에 넣지 않고
셸 환경변수로 준다. 업무 계정 토큰 발급은 회사 정책 확인 후에 한다.

## 운용 규칙

- 신규 설치 절차: `claude plugin install <name>@<marketplace>` -> repo
  `claude/core/settings.json` 의 enabledPlugins 반영 -> `setup.sh` 의 설치 목록 갱신
  -> 이 명세 갱신 -> commit.
- 제안 전 실재 확인: 로컬 캐시
  `~/.claude/plugins/marketplaces/claude-plugins-official/.claude-plugin/marketplace.json`
  (291종)을 조회한다. 기억만으로 플러그인 이름을 제안하지 않는다.
- 무거운 멀티에이전트 플러그인(understand-anything 등)을 trivial 작업에 돌리지 않는다.
