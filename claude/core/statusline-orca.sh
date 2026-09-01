#!/bin/bash
# statusLine 브리지 - Orca와 자체 상태줄을 한 슬롯에서 공존시킨다.
#
# 배경: settings.json 의 statusLine 은 슬롯이 하나뿐인데, 두 소비자가 있다.
#   ① Orca      - payload 의 rate_limits 를 로컬 서버로 POST (화면 출력 없음)
#   ② statusline.sh - 모델·컨텍스트%·git·한도를 터미널에 렌더
# stdin 은 한 번만 읽을 수 있으므로 여기서 받아 두 곳에 각각 먹인다.
#
# Orca 스크립트는 15초 스로틀 + curl 0.5/1.5s 타임아웃이라 동기 호출로도 지연이 없다.
# Orca 미설치/미실행이면 조용히 건너뛰고 ②만 수행한다.

payload=$(cat)

orca_sl="$HOME/.orca/agent-hooks/claude-statusline.sh"
if [ -x "$orca_sl" ]; then
    printf '%s' "$payload" | /bin/sh "$orca_sl" >/dev/null 2>&1 || :
fi

printf '%s' "$payload" | bash "$HOME/.claude/statusline.sh"
