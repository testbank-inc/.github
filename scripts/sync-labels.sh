#!/usr/bin/env bash
# TestBank 공통 이슈 라벨을 대상 레포에 생성/갱신한다.
# 사용법: ./scripts/sync-labels.sh testbank-inc/solve [testbank-inc/web ...]
set -euo pipefail

if [ $# -eq 0 ]; then
  echo "사용법: $0 <owner/repo> [owner/repo ...]" >&2
  exit 1
fi

# name|color|description
LABELS=$(cat <<'EOF'
priority/ship-blocker|B60205|출시/심사 차단, 즉시
priority/critical|D93F0B|1주 내 해결
priority/high|FBCA04|다음 릴리스
priority/medium|C2E0C6|백로그
priority/low|EEEEEE|여유 시
status/in-progress|1D76DB|작업 중 — 다른 세션은 픽업 금지
status/blocked|E99695|다른 이슈/외부 요인 대기
status/needs-decision|D876E3|사람(오너) 결정 필요
from/cs|0E8A16|CS/유저 제보 유래
EOF
)

for REPO in "$@"; do
  echo "== $REPO =="
  while IFS='|' read -r NAME COLOR DESC; do
    gh label create "$NAME" --repo "$REPO" --color "$COLOR" --description "$DESC" --force \
      && echo "  ✓ $NAME"
  done <<< "$LABELS"
done
echo "완료. area/* 라벨은 레포별로 직접 정의하세요."
