# Testbank Inc. Repository 구성 가이드

## 조직 개요

**Testbank Inc.** (`testbank-inc`)는 교육/시험 플랫폼 **Solve(쏠브)** 를 개발하는 조직입니다.

- 홈페이지: https://testbank.ai
- 주요 제품: **Solve** — 모바일 앱(React Native), 데스크톱 앱(macOS/Windows), 웹 서비스로 구성

---

## Repository 목록 및 역할

| Repository | 언어 | 유형 | 설명 |
|---|---|---|---|
| `.github` | — | 조직 프로필 | GitHub 조직 프로필 페이지 README |
| `nit-cli` | TypeScript | 개발 도구 (npm) | Notion Issue Tracker CLI — 이슈 기반 Git 워크플로우 자동화 |
| `aws-cf-signed-url` | JavaScript | 인프라 라이브러리 | AWS CloudFront Signed URL 생성 유틸리티 |
| `screen-capture-secure-view` | TypeScript | 모바일 라이브러리 (npm) | React Native iOS 화면 캡처/녹화 방지 컴포넌트 |
| `tbk-excalidraw` | TypeScript | Fork | Excalidraw 커스텀 포크 — 화이트보드 기능 |
| `solve-desktop-releases` | — | 배포 전용 | Solve 데스크톱 앱 릴리즈 배포 (macOS dmg, Windows exe) |

---

## 각 Repository 상세

### 1. `.github` — 조직 프로필

GitHub 조직 페이지(`github.com/testbank-inc`)에 표시되는 프로필 README를 관리합니다. `profile/README.md` 파일이 조직 메인 페이지에 렌더링됩니다.

### 2. `nit-cli` — Notion Issue Tracker CLI

개발팀의 이슈 관리 워크플로우를 자동화하는 CLI 도구입니다.

**주요 기능:**
- Notion DB에서 할당된 이슈 목록 조회
- 이슈 선택 시 자동으로 Git 브랜치 생성 및 checkout
- 원격 브랜치 push 및 Graphite(`gt`) 초기화
- Notion 이슈 상태를 "개발 중(In Progress)"으로 자동 변경

**설치:** `npm install -g @testbank-inc/nit-cli`

### 3. `aws-cf-signed-url` — CloudFront Signed URL

AWS CloudFront의 서명된 URL을 생성하는 유틸리티 라이브러리입니다. 콘텐츠(이미지, 문서 등)에 대한 접근 제어가 필요할 때 시간 제한이 있는 인증된 URL을 생성합니다.

### 4. `screen-capture-secure-view` — 캡처 방지 컴포넌트

React Native 앱에서 iOS 화면 캡처 및 녹화를 방지하는 네이티브 컴포넌트입니다.

**주요 API:**
- `enableSecureView()` / `disableSecureView()` — 캡처 방지 활성화/비활성화
- `addScreenCaptureListener(callback)` — 스크린샷 감지 리스너
- `isSecure()` — 현재 보안 상태 확인

**설치:** `npm install @testbank-inc/screen-capture-secure-view`

### 5. `tbk-excalidraw` — Excalidraw 커스텀 포크

오픈소스 화이트보드 도구 [Excalidraw](https://excalidraw.com)의 포크입니다. Solve 서비스 내에서 손그림 스타일의 다이어그램/화이트보드 기능을 제공하기 위해 커스터마이징되었습니다.

### 6. `solve-desktop-releases` — 데스크톱 배포

Solve 데스크톱 앱의 릴리즈 바이너리를 배포하는 전용 저장소입니다. GitHub Releases를 통해 자동 업데이트를 지원합니다.

**지원 플랫폼:**
- macOS: `aarch64` (Apple Silicon), `x64` (Intel) — `.dmg` 형식
- Windows: `x64` — `.exe` 설치 파일

**최신 버전:** v2.2.4 (2025-11-27 기준)

---

## Repository 관계도

```
testbank-inc 조직
│
├─ 제품 (Solve / 쏠브)
│   ├─ 모바일 앱 (React Native)
│   │   └── screen-capture-secure-view ··· 캡처 방지 보안 모듈
│   │
│   ├─ 데스크톱 앱 (macOS / Windows)
│   │   └── solve-desktop-releases ······ 빌드 배포 및 자동 업데이트
│   │
│   └─ 웹 서비스
│       ├── tbk-excalidraw ·············· 화이트보드 기능
│       └── aws-cf-signed-url ··········· 콘텐츠 보안 전달 (CDN)
│
├─ 개발 인프라
│   └── nit-cli ·························· Notion 이슈 ↔ Git 워크플로우 자동화
│
└─ 조직 관리
    └── .github ·························· 조직 프로필 페이지
```

### 의존 관계 흐름

```
[Notion Issue DB]
       │
       ▼
   nit-cli ──────────► Git 브랜치 생성 / Notion 상태 변경
                        (개발 워크플로우 시작)
                              │
                ┌─────────────┼─────────────┐
                ▼             ▼             ▼
         모바일 앱        데스크톱 앱      웹 서비스
              │             │             │
              │             │             ├── tbk-excalidraw
              │             │             │   (화이트보드)
              │             │             │
              │             │             └── aws-cf-signed-url
              │             │                 (보안 콘텐츠 URL)
              │             │
              │             └── solve-desktop-releases
              │                 (릴리즈 배포)
              │
              └── screen-capture-secure-view
                  (화면 캡처 방지)
```

---

## 기술 스택 요약

| 영역 | 기술 |
|---|---|
| 모바일 앱 | React Native (iOS/Android) |
| 데스크톱 앱 | Tauri (Rust + WebView), macOS / Windows |
| 프론트엔드 | TypeScript |
| CDN / 인프라 | AWS CloudFront |
| 이슈 관리 | Notion DB + nit-cli |
| 버전 관리 도구 | Git + Graphite |
| 패키지 레지스트리 | npm (`@testbank-inc/*`) |
