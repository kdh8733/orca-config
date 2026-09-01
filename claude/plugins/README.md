# plugins/ - 플러그인 명세

설치 형상의 원천은 `claude/core/settings.json` 의 `enabledPlugins` + `setup.sh` 의
플러그인 단계다. 이 디렉토리는 배포 대상이 아니라 **명세** - 각 플러그인을 왜 쓰고
언제 쓰는지를 사람과 세션이 읽는 곳. MCP 서버는 전부 이 플러그인 계층 소속이다.

> 플러그인을 설치/제거하면 live `~/.claude/settings.json` 이 먼저 바뀐다.
> repo의 `claude/core/settings.json` 에 반영하고 이 명세를 갱신할 것.
> `./setup.sh --check` 가 드리프트를 잡아준다.

## 이 머신의 런타임 제약 (2026-09-01 확인)

`node` · `npx` · `bun` · `uv/uvx` · `brew` 모두 **없음**. `jq` · `python3` · `git` ·
`gh` 는 있음. 따라서 로컬 런타임을 요구하는 MCP 서버형 플러그인은 설치해도 서버가
기동하지 않는다. 초기 세트는 **런타임 의존이 없는 스킬형만** 넣었다.

## 설치 세트 (7종, 마켓플레이스 1곳)

| 플러그인 | 언제 쓰나 |
|---|---|
| superpowers | 워크플로우 스킬 모음 - brainstorming->writing-plans(설계), test-driven-development(코드), systematic-debugging(버그), verification-before-completion(완료 선언 전). 사용 조건은 CLAUDE.md "스킬 활용 판단" 플레이북이 정의. `using-git-worktrees` 는 CLAUDE.md 워크트리 조항에 따라 사용하지 않는다 |
| ralph-loop | `/ralph-loop` `/cancel-ralph` - 같은 태스크를 자기참조 루프로 반복 개선. 명확한 완료 기준이 있는 장시간 반복 작업에. 기준 없는 루프는 토큰 낭비 |
| hookify | 대화에서 반복된 실수/지시를 훅으로 변환 - `/hookify`. guard/ 계층의 공급선 |
| skill-creator | 반복 작업의 스킬화 - `/skill-creator`. skills/ 계층의 공급선 |
| claude-md-management | CLAUDE.md 감사·개선(`/revise-claude-md`). 150줄 원칙 보조 |
| session-report | 세션 사용량 HTML 리포트(토큰·캐시·서브에이전트·고비용 프롬프트) |
| frontend-design | 웹 컴포넌트/페이지 구현 시 제네릭 AI 미감을 피한 프로덕션급 UI 생성 |

## 제외한 것과 그 이유

### 내장으로 대체됨 (설치하면 중복)
Claude Code 2.1.252 에서는 플러그인 0개 상태에서도 `/code-review` 와 `/simplify`
스킬이 노출된다. 따라서 `code-review` · `code-simplifier` 플러그인은 설치하지 않는다.
(서브에이전트 `claude/agents/code-simplifier.md` 는 별개 - 이 repo가 소유한다.)

### 런타임/시크릿이 필요해 보류 (필요해지면 그때 설치)

| 플러그인 | 필요한 것 | 근거 |
|---|---|---|
| serena | `uvx` (uv) | `external_plugins/serena/.mcp.json` 의 `command: uvx` 확인 |
| playwright | `npx` | `external_plugins/playwright/.mcp.json` 의 `command: npx` 확인 |
| telegram | `bun` | `external_plugins/telegram/.mcp.json` 의 `command: bun` 확인. 개인 봇 생태계라 업무 머신에는 부적합 |
| context7 | `CONTEXT7_API_KEY` | HTTP MCP(`mcp.context7.com`) - 로컬 런타임은 불필요하나 키가 있어야 함 |
| github | `GITHUB_PERSONAL_ACCESS_TOKEN` | HTTP MCP(`api.githubcopilot.com`) - 업무 계정 토큰을 만들 것인지 판단 필요. 지금은 `gh` CLI로 충분 |
| figma · slack · supabase · vercel | 미확인 | 공식 마켓플레이스가 외부 git repo로 참조만 하고 로컬 캐시가 없어 런타임 요구사항을 확인하지 못했다. 설치 전 해당 repo의 `.mcp.json` 을 직접 확인할 것 |
| understand-anything · watch | 별도 마켓플레이스 | 개인 PC 세트. 필요가 생기면 마켓플레이스 추가부터 |

## 운용 규칙

- 신규 설치 절차: `claude plugin install <name>@<marketplace>` -> repo
  `claude/core/settings.json` 의 enabledPlugins 반영 -> `setup.sh` 의 설치 목록 갱신
  -> 이 명세 갱신 -> commit.
- 제안 전 실재 확인: 로컬 캐시
  `~/.claude/plugins/marketplaces/claude-plugins-official/.claude-plugin/marketplace.json`
  (291종)을 조회한다. 기억만으로 플러그인 이름을 제안하지 않는다.
- 무거운 멀티에이전트 플러그인을 trivial 작업에 돌리지 않는다.
