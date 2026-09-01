# projects/ - 프로젝트별 지식 인덱스 (현재 비어 있음)

`setup.sh` 가 이 디렉토리를 `~/.claude/knowledge` 로 심링크한다. 세션은 도메인 작업 시
`~/.claude/knowledge/<domain>/ontology.yaml` 을 먼저 읽고 코드로 들어간다.

## 지금 비어 있는 이유

이 머신은 업무용이고, 기존 ontology(gpu-infra·invest·job·aoe-remote 등)는 개인 PC의
`claude-config` 저장소에 있는 개인 프로젝트 지식이다. 무엇을 업무용 머신에 올릴지는
사용자가 분류한 뒤에 추가한다. 자동 이관하지 않는다.

## 규약 (도메인을 추가할 때)

1. **검증 가능한 앵커가 없는 엔티티는 기록하지 않는다.** 앵커는 실재하는 파일 경로
   (`path:`) 또는 문서 페이지 ID만. 검증 못 하는 항목은 시간이 지나면 거짓말이 된다.
2. 내용을 복제하지 않는다. Goal의 원천은 `<root>/ROADMAP.md` 1곳, 결정은
   `<root>/docs/decisions/` 1곳이고 ontology는 앵커로 가리키기만 한다.
3. 새 도메인은 실제 작업이 생긴 뒤에 추가한다. 빈 스켈레톤 금지.
4. 새 도메인 생성은 `/project-init` 이 담당한다.
