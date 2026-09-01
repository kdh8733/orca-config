# orca-config

**업무용 맥(macOS + Orca)의 Claude Code 운용 환경을 코드로 형상관리하는 저장소.**
행동 원칙(CLAUDE.md) · 결정론 강제(hooks) · 스킬/에이전트 · 프로젝트 지식 인덱스를
한 줄로 재구축한다.

```bash
git clone <remote> ~/workspace/orca-config && cd ~/workspace/orca-config && ./setup.sh
```

위 한 줄 + `claude` 로그인이면 끝. 모든 배포는 멱등이며 `./setup.sh --check` 가
repo ↔ live 환경의 드리프트를 감사한다.
상세 운영(Orca 공존·배포 모델·시크릿)은 [docs/operations.md](docs/operations.md).

> 개인 PC(WSL2 + aoe) 환경은 별도 저장소 `claude-config` 가 담당한다.
> 두 저장소를 합치지 않는다 - 세션 매니저가 `settings.json` 을 다루는 방식이 다르다.

## 설계 철학

1. **각 계층은 단일 책임** - 지식/규칙을 어디에 두는지는
   [docs/architecture.md](docs/architecture.md)의 결정 트리가 판정한다.
   한 지식을 두 곳에 기록하지 않는다 (drift의 근원).
2. **모델의 협조를 신뢰하지 않는 계층을 둔다** - 어겨서는 안 되는 규칙은
   hook(결정론)으로 강제한다. `guard/verify-before-claim.sh` 는 실제 오판 사고
   (2026-05-09, 검증 없는 단정) 이후 도입된 "단정 전 검증" 강제 장치다.
3. **남의 설정을 밟지 않는다** - `~/.claude/settings.json` 은 Orca·Claude Code와
   공유하는 파일이다. 복사가 아니라 병합으로 배포한다.
4. **검증 가능한 것만 지식으로 축적한다** - ontology 에는 실재하는 앵커가 있는
   엔티티만 기록한다. 앵커 없는 지식은 시간이 지나면 거짓말이 된다.
5. **빈 스켈레톤 금지** - 스킬·에이전트·플러그인·도메인은 실사용에서 필요가
   검증된 것만 추가.

## 구조

```
orca-config/
├── setup.sh                  # 멱등 부트스트랩 + --check 드리프트 감사
├── docs/
│   ├── architecture.md       # 헌법 - 계층 결정 트리 + Orca 공존 구조
│   └── operations.md         # 운영 상세 - 환경·배포·시크릿·검토 대기 항목
│
├── claude/                   # 엔진: Claude Code 하네스
│   ├── harness/              #   행동 규칙 - CLAUDE.md
│   ├── core/                 #   settings.json(병합) · statusline.sh · statusline-orca.sh(브리지)
│   ├── guard/                #   결정론 강제 - hooks (→ ~/.claude/hooks)
│   ├── skills/               #   project-init · project-plan
│   ├── agents/               #   env-auditor · fullstack-dev · perf-reviewer · code-simplifier · infra-engineer
│   ├── commands/             #   (비어 있음)
│   ├── rules/                #   경로 한정 규칙 - paths frontmatter (→ ~/.claude/rules)
│   ├── output-styles/        #   출력 스타일 - opt-in /config 활성화
│   └── plugins/              #   플러그인 명세 - 설치 7종 + 보류 목록과 사유
│
├── projects/                 # 지식: 도메인별 ontology (→ ~/.claude/knowledge)
│                             #   현재 비어 있음 - 업무/개인 분류 후 추가
└── runtime/
    ├── orca/                 #   merge-settings.py - Orca 훅을 보존하는 settings 병합기
    └── shell/                #   zshrc 통합 블록
```

## 계층별 단일 책임

| 계층 | 성격 | 현재 |
|---|---|---|
| CLAUDE.md | 항상 적용되는 행동 규칙 (150줄 이하 유지) | 비판적 검토 · 코딩 4원칙 · 워크트리(Orca 예외) · 스킬 플레이북 · 지식 인덱스 · 문서 스타일 |
| Hook (guard/) | 결정론 강제 - 모델 협조를 신뢰하지 않음 | verify-before-claim (단정 전 검증) |
| Skill | 상황 한정 절차 (트리거 = description) | project-init · project-plan |
| Sub-Agent | 컨텍스트 오염 없는 위임 - "직원" | env-auditor(읽기전용, haiku) · fullstack-dev · perf-reviewer(읽기전용, opus/xhigh) · code-simplifier · infra-engineer |
| Rules | 경로/주제 한정 규칙 | 없음 (HOWTO만) |
| Output style | 시스템 프롬프트 교체 - 명시적 opt-in (`/config`) | critical-reviewer |
| Ontology | 도메인 What/Where 인덱스 | 없음 (빈 디렉토리) |
| Plugin/MCP | 외부 도구 통합 | 7종 - 명세는 [claude/plugins/](claude/plugins/README.md) |

## Orca 와의 관계 한 장 요약

- Orca 는 `~/.claude/settings.json` 에 hook 12 이벤트 + statusLine 을 직접 써 넣어
  pane 상태를 추적한다. 이 저장소는 그 위에 **얹히기만 한다.**
- `statusLine` 슬롯은 하나뿐이라 `statusline-orca.sh` 브리지가 payload 를 Orca 와
  터미널 렌더러 양쪽에 나눠 준다.
- Orca 가 배정한 워크트리(`ORCA_WORKTREE_ID`)는 세션의 지정 작업 경로다.
  CLAUDE.md 의 워크트리 금지 조항은 이 경우를 예외로 둔다.
