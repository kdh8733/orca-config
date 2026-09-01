# Claude Code 확장 계층 아키텍처 (macOS + Orca)

> 원칙: 각 계층은 단일 책임. "어디에 두나"를 아래 결정 트리로 판정하고,
> 한 지식을 두 곳에 중복 기록하지 않는다 (drift의 근원).

## 1. 결정 트리 - 지식/규칙을 어디에 두나

```
이 지식은 ...
├─ 모든 작업에 항상 적용되는 행동 규칙인가?
│   → CLAUDE.md  (글로벌. 항상 컨텍스트에 로드되므로 150줄 이하 유지 - 비대해지면 Skill로 강등)
├─ 특정 경로/언어에만 걸리는 규칙인가?
│   → Rules  (claude/rules/<주제>.md - paths frontmatter 로 lazy 로드)
├─ 특정 상황에서만 필요한 절차(how-to)인가?
│   → Skill  (claude/skills/<name>/SKILL.md - description의 트리거 조건이 품질의 전부)
├─ 메인 컨텍스트를 오염시키지 않고 위임할 역할인가?
│   → Sub-Agent  (claude/agents/<name>.md - 도구 제한·모델 지정 가능, 결과만 회수)
├─ 모델이 어겨서는 안 되는 강제사항인가?
│   → Hook  (claude/guard/ + settings.json hooks - 유일한 결정론 계층)
├─ 자주 반복하는 진입점(명령)인가?
│   → Slash Command  (claude/commands/<name>.md)
├─ 도메인의 What/Where 인덱스인가? (어떤 엔티티가 어디에 있나)
│   → Ontology  (projects/<domain>/ontology.yaml - 검증 가능한 앵커만 기록)
└─ 진행 중 작업의 맥락인가?
    → Memory  (자동 관리 - 수동 운용 대상 아님)
```

MCP 서버는 별도 디렉토리를 두지 않는다 - 전부 플러그인 계층 소속이며
`claude/plugins/README.md` 가 역할·런타임 의존성을 명세한다.

## 2. 계층별 현황

| 계층 | 현황 | 비고 |
|---|---|---|
| CLAUDE.md | 6섹션 (비판적 검토 / 코딩 4원칙 / 워크트리 / 스킬 플레이북 / 지식 인덱스 / 문서 스타일) | 워크트리 조항은 Orca 배정 워크트리를 예외로 둔다 |
| Rules | HOWTO만 (규칙 파일 없음) | 경로 한정 규칙이 실제로 필요해지면 추가 |
| Skill | project-init · project-plan | 개인 PC의 notion-kb 는 개인 토큰 의존이라 이관하지 않음 |
| Sub-Agent | env-auditor(haiku, 읽기전용) · fullstack-dev · perf-reviewer(opus/xhigh, 읽기전용) · code-simplifier(opus/xhigh) · infra-engineer | |
| Hook | verify-before-claim (SessionStart) + Orca 훅 12종(외부 소유) | |
| Command | 없음 (디렉토리만) | 후보: /sync-env |
| Ontology | 없음 (빈 디렉토리) | 업무/개인 분류 후 사용자가 추가 |
| Plugin | 20종 · 마켓플레이스 3곳 | MCP 런타임(npx·uvx·bun)이 없으면 스킬만 동작한다. 런타임별 설치법은 plugins/README.md |

원칙: 추측성 다작은 단순성 원칙 위반. 실사용에서 필요가 검증된 것만 추가한다.

## 3. 이 환경의 특수성 - settings.json 은 공유 자원이다

개인 PC(WSL)의 `claude-config` 에서는 세션 매니저(aoe)의 훅을 repo settings.json 에
그대로 박아 두고 파일을 통째 복사 배포했다. 이 머신에서는 그 방식을 쓸 수 없다.

`~/.claude/settings.json` 에 쓰는 주체가 셋이다:

| 주체 | 무엇을 쓰나 | 시점 |
|---|---|---|
| Orca | hooks 12 이벤트 + statusLine (`~/.orca/agent-hooks/*` 호출) | 앱이 훅을 설치/갱신할 때 |
| Claude Code | enabledPlugins, theme, 기타 `/config` 설정 | 플러그인 토글·설정 변경 시 |
| 이 저장소 | model · statusLine · SessionStart 훅 · 플러그인 형상 | `./setup.sh` |

그래서 배포는 **복사가 아니라 병합**이다(`runtime/orca/merge-settings.py`).
소유권은 훅 커맨드 문자열로 판정한다: `.orca/agent-hooks` 를 부르면 Orca 것이라
보존하고, `.claude/hooks/` 를 부르면 이 repo 것이라 매번 교체한다. 그 외는 보존.

statusLine 슬롯은 하나뿐인데 소비자가 둘(Orca 전송 + 터미널 렌더)이라
`claude/core/statusline-orca.sh` 가 stdin 을 받아 양쪽에 먹이는 브리지 역할을 한다.

## 4. 배포 모델

```
orca-config/  (원천, ~/workspace/orca-config)
├── setup.sh                  # 멱등 부트스트랩 + --check(드리프트 감사)
├── docs/                     # architecture.md(이 문서) · operations.md(운영 상세)
├── claude/                   # 엔진 - Claude Code 하네스
│   ├── harness/CLAUDE.md     # 행동 규칙
│   ├── core/                 # settings.json(병합 배포) · statusline.sh · statusline-orca.sh
│   ├── guard/                # 훅 (→ ~/.claude/hooks)
│   ├── skills/ agents/ commands/ rules/ output-styles/
│   └── plugins/README.md     # 플러그인 명세 (배포 대상 아님)
├── projects/                 # 지식 계층 (→ ~/.claude/knowledge). 현재 비어 있음
└── runtime/
    ├── orca/merge-settings.py   # settings 병합기
    └── shell/zshrc-claude-mac.sh
```

- 콘텐츠 파일은 symlink 배포 - live 편집이 곧 repo 변경이라 동기화 단계가 없다.
  commit 만 하면 형상이 유지된다.
- `settings.json` 만 병합 배포(위 3절). `--check` 는 "repo 정책이 live 에 반영돼
  있는가"로 판정하므로, Orca가 자기 훅을 추가해도 드리프트로 잡히지 않는다.
- 배포 타겟 이름은 Claude Code 관례를 따른다: `claude/guard` → `~/.claude/hooks`,
  `projects/` → `~/.claude/knowledge` (`~/.claude/projects` 는 Claude Code가 세션
  기록용으로 점유하므로 사용 금지).
