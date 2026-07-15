# TestBank GitHub Issues 컨벤션

> 대상 레포: `solve`(iOS) · `web`(모노레포/API) · `solve-android`
> 1차 소비자는 **AI 에이전트**(Claude Code, Codex)다. 사람이 훑기 좋은 것보다 **에이전트가 이슈만 읽고 착수할 수 있는 것**이 우선이다.
> 마지막 업데이트: 2026-07-15

---

## 0. 원칙

1. **이슈 = 스펙 + 결정 로그.** 세션(대화) 컨텍스트는 휘발되므로, 작업 정의·중간 결정·발견 사항은 전부 이슈에 남긴다. 새 세션·다른 에이전트가 `gh issue view N`만으로 이어받을 수 있어야 한다.
2. **그때그때 등록.** 미리 기획해서 티켓을 쌓는 방식이 아니다. 작업 중 발견한 후속 작업, 리뷰 중 나온 2차 이슈(스코프 밖), CS/데이터에서 발견한 문제를 **발견 즉시** 등록한다.
3. **추적 사슬 유지.** PR 본문에 `Closes #N` → 머지 시 자동 close. `git blame → 커밋 → PR → 이슈(스펙+결정 로그)`로 언제든 역추적 가능해야 한다.

## 1. 언제 이슈를 만드나

| 상황 | 만든다? |
|---|---|
| 지금 이 세션에서 바로 끝낼 일 | ❌ 그냥 한다 |
| 지금 안 하기로 한 일 (백로그) | ✅ |
| 리뷰/작업 중 발견한 스코프 밖 2차 이슈 | ✅ (스코프 확장 대신 별도 이슈+별도 PR) |
| 2세션 이상 걸칠 큰 작업 | ✅ (필요 시 서브이슈로 분해) |
| CS·데이터·크래시에서 발견된 문제 | ✅ (`from/cs` 라벨) |
| 사람 결정이 필요해 멈춘 일 | ✅ (`status/needs-decision`) |

## 2. 이슈 생성

### 제목
`영역: 한 줄 요약` — 예: `canvas: 지우개 redo 시 eraserMask 유실`, `offline: 델타 매니페스트 도입`
우선순위·타입을 제목에 넣지 않는다(`[P0]`, `[HIGH]` 금지 — 라벨/타입으로).

### 타입 (org Issue Type, 필수)
- `Bug` — 잘못 동작하는 것
- `Feature` — 새 기능/개선
- `Task` — 그 외 작업 (리팩토링, 조사, 운영, 문서)

### 본문 구조 (에이전트 파싱 표준)
```markdown
## 배경
왜 필요한가. 관련 CS/데이터/링크/발견 경위.

## 작업 내용
무엇을 할지. 알고 있는 접근 방법이 있으면 적는다.

## 완료 조건
- [ ] 검증 가능한 조건 1
- [ ] 검증 가능한 조건 2

## 참고
관련 파일 경로(`Features/CanvasV5/...`), 관련 이슈/PR(#N), 문서 포인터.

## 검증
어떻게 확인하는지 — 테스트 스위트, 빌드, 실기기 필요 여부 등.
```
- **완료 조건**은 필수. 에이전트가 "끝났다"를 판단하는 기준이다.
- **참고**에 파일 경로를 적어두면 다음 에이전트의 탐색 비용이 크게 준다. 알면 적는다.

### gh CLI 레시피
```bash
gh issue create --type Bug \
  --title "canvas: 지우개 redo 시 eraserMask 유실" \
  --label "priority/high,area/canvas" \
  --body "$(cat <<'EOF'
## 배경
...
EOF
)"
```

## 3. 라벨 체계

| 그룹 | 값 | 의미 |
|---|---|---|
| `priority/` | `ship-blocker` | 출시/심사 차단, 즉시 |
| | `critical` | 1주 내 |
| | `high` | 다음 릴리스 |
| | `medium` | 백로그 |
| | `low` | 여유 시 |
| `status/` | `in-progress` | 착수됨 (누군가 작업 중 — 건드리지 말 것) |
| | `blocked` | 다른 이슈/외부 요인 대기 (`--add-blocked-by`와 함께) |
| | `needs-decision` | 사람(오너) 결정 필요 |
| `from/` | `cs` | CS/유저 제보 유래 |
| `area/` | 레포별 정의 | 기능 영역 (solve: `area/canvas`, `area/noteviewer` 등) |

- `priority/`는 생성 시 하나 붙인다. 모르겠으면 `medium`.
- 캠페인성 라벨(`audit/2026-05-01` 같은)은 필요 시 자유롭게 추가.

## 4. 착수 → 진행 → 종료

1. **픽업 전 확인**: assignee 있고 `status/in-progress`면 잡지 않는다 (동시 다작업 충돌 방지).
2. **착수 마킹**:
   ```bash
   gh issue edit N --add-assignee @me --add-label status/in-progress
   gh issue comment N --body "착수. 접근: ..."
   ```
3. **진행 중**: 방향 전환·중요 발견·사람 결정은 이슈 코멘트로 남긴다. 결정이 필요하면 `status/needs-decision` 붙이고 다른 작업으로.
4. **종료**: PR 본문에 `Closes #N`. 머지로 자동 close. PR 없이 끝나는 작업(조사 등)은 결과를 코멘트로 남기고 close.
5. **안 하기로 한 이슈**: 사유 코멘트 후 `close --reason "not planned"`.

## 5. 큰 작업: 서브이슈와 의존성 (gh ≥ 2.94)

```bash
gh issue create --type Task --parent 100 --title "..."   # 서브이슈
gh issue edit 123 --add-blocked-by 200                   # 의존성
gh issue list --type Bug                                  # 타입 필터
```
2~3개 세션으로 나뉘는 작업은 부모 이슈 1개 + 서브이슈로 분해한다. 부모 이슈가 오케스트레이션 로그가 된다.

## 6. 조회 레시피 (세션 시작 시)

```bash
gh issue list --state open --limit 50                                  # 전체
gh issue list --assignee @me --state open                              # 내 것
gh issue list --label priority/ship-blocker,priority/critical          # 급한 것
gh issue list --label status/needs-decision                            # 결정 대기
gh issue list --search "sort:updated-desc" --limit 20                  # 최근 움직임
```

## 7. Triage

- 분기 1회: `status/needs-decision` 소진, 6개월 이상 방치 이슈 close-or-recommit.
- close할 때는 반드시 사유 코멘트 (다음 에이전트가 같은 이슈를 다시 파지 않게).

## 8. 셋업 (새 레포 추가 시)

```bash
./scripts/sync-labels.sh <owner/repo>   # 공통 라벨 생성
```
이슈 폼 템플릿은 이 레포(`testbank-inc/.github`)의 `.github/ISSUE_TEMPLATE/`이 org 전체 기본값으로 적용된다. 레포 고유 템플릿이 필요하면 해당 레포에 두면 우선한다.
