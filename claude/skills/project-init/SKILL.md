---
name: project-init
description: 신규 프로젝트/워크스페이스를 시작할 때 사용. "새 프로젝트 세팅", "/project-init", "프로젝트 초기화" 류 요청에서 호출. Q&A로 목표·지식·도구를 확정하고 ontology 시드 + ROADMAP 스텁 + 도구 추천/설치까지 초기 형상을 구성한다. 일회성 소규모 작업(스크립트 하나, 단발 조사)에는 적용하지 않는다.
---

# /project-init - 신규 프로젝트 초기 세팅

목적: 새 프로젝트의 진입 비용을 자산으로 바꾼다. 산출물은 4개다:
① `orca-config/projects/<name>/ontology.yaml` ② `<root>/ROADMAP.md` 스텁
③ (선택) `<root>/CLAUDE.md` ④ 도구 추천/설치 및 형상 반영.

## 진행 순서

### 1. 정체 확정 (질문 최소화 - 아는 건 묻지 않는다)
- 프로젝트 이름(kebab-case 도메인명), 루트 경로, 한 줄 정의.
- 사용자가 이미 말한 내용에서 추출하고, 빈 것만 묻는다.
- 업무용 머신이므로 **업무/개인 구분을 한 번 확인한다.** 개인 프로젝트면 ontology를
  이 repo에 넣을지 사용자에게 확인받고 진행한다.

### 2. Goal (목표 기반 실행 원칙 적용)
- 최종 목표를 **검증 가능한 완료 기준**과 함께 확정한다.
  "동작하게 만들기" 같은 약한 기준이 오면 측정 가능한 형태로 재질문.
- Goal의 원천은 ROADMAP.md 헤더 1곳. ontology는 앵커로 가리키기만 한다.

### 3. 기존 지식 확인 (묻기 전에 먼저 찾는다)
- `~/.claude/knowledge/` 의 기존 도메인과 겹치는지 확인한다.
- 문서 커넥터(Notion 등)가 세션에 붙어 있으면 프로젝트 주제로 검색해 관련 문서
  후보를 찾고 "이런 기존 지식이 있는데 참고 대상인가"를 **제안형으로** 확인한다.
  커넥터가 없으면 이 단계는 건너뛴다(추측으로 페이지를 지어내지 말 것).

### 4. 도구 추천 (Skill / Agent / Plugin)
- 프로젝트 성격을 분석해 추천 후보를 만들고 AskUserQuestion(multiSelect)으로
  여러 개 선택받는다. 후보는 두 풀에서:
  - **설치됨**: `claude/plugins/README.md` 의 설치 목록 + 기존 skills/agents 중 적합한 것.
  - **미설치**: 반드시 실재 검증 후 제안 - 로컬 마켓플레이스 캐시
    (`~/.claude/plugins/marketplaces/claude-plugins-official/.claude-plugin/marketplace.json`)
    또는 공식 json 실조회 + 필요시 WebSearch. **기억만으로 플러그인 이름을 제안하는 것
    금지**(환각 위험). 서드파티는 "설치 전 소스 리뷰 필요" 라벨.
  - **런타임 의존성 확인 필수**: 이 머신에는 node/npx·bun·uv가 없다. 후보 플러그인의
    `.mcp.json` 을 열어 `command` 를 확인하고, 없는 런타임이 필요하면 그 사실과
    설치 비용을 함께 제시한다 (plugins/README.md "런타임 의존" 표 참고).
- 선택된 미설치 플러그인은: 설치 -> `claude/core/settings.json` 의 enabledPlugins 반영
  -> setup.sh 목록 갱신 -> plugins/README.md 명세 갱신까지가 한 묶음.
- 프로젝트 전용 스킬/에이전트가 필요해 보이면 skill-creator 사용을 제안하되,
  "필요가 검증된 것만" 원칙대로 init 시점 추측성 생성은 하지 않는다.

### 4.5 개발 스택 선정 (fullstack-dev 위임)
- 개발이 수반되는 프로젝트면 언어·프레임워크·핵심 도구 선정을 `fullstack-dev`
  서브에이전트에 위임한다: Goal·제약을 전달 -> 후보 리스트업 + 정량/정성 비교분석 ->
  `<root>/docs/decisions/001-stack.md`(상태: 제안) 산출.
- 결과의 권고+차선을 사용자에게 선택지로 제시하고, 선택된 결정의 상태를
  '승인'으로 갱신한 뒤 ontology에 `decisions/` 앵커를 추가한다.
- 스택이 자명한 경우(단일 스크립트, 기존 스택 연장)는 위임 생략 - 한 줄 언급만.

### 5. 산출물 생성
- `projects/<name>/ontology.yaml`: 생성 시점에 **실재하는 앵커만**
  (root 경로, ROADMAP.md). 빈 엔티티 금지 - 엔티티는 산출물이 생길 때마다
  추가한다는 규약 주석 포함.
- `<root>/ROADMAP.md`: Goal + 완료 기준 + "마일스톤은 /project-plan 으로" 스텁.
- `<root>/CLAUDE.md`(선택): 프로젝트 한정 행동 규칙이 실제로 있을 때만
  (글로벌 CLAUDE.md와 중복 금지 - 차이만 기록).
- orca-config 변경분 commit, `./setup.sh --check` 통과 확인.

### 6. 다음 단계 안내
- 작업 분해가 필요하면 `/project-plan` 으로. 구현에 들어가면 글로벌
  플레이북(brainstorming -> writing-plans -> TDD)이 이어받는다.
