# TopikGo - Flutter Mobile Application (topik-go)

> **TOPIK II(한국어능력시험) 맞춤형 글로벌 학습 모바일 애플리케이션**  
> Flutter 기반으로 개발되었으며, Cross-Platform(iOS/Android) 환경에서 고성능 학습 경험, 오프라인 학습 지원, 강력한 보안 인증 아키텍처를 제공합니다.

---

## 📌 목차 (Table of Contents)

1. [프로젝트 소개 (Overview)](#-프로젝트-소개-overview)
2. [핵심 기능 (Key Features)](#-핵심-기능-key-features)
3. [기술 스택 (Tech Stack)](#-기술-스택-tech-stack)
4. [아키텍처 및 폴더 구조 (Architecture & Project Structure)](#-아키텍처-및-폴더-구조-architecture--project-structure)
5. [주요 엔지니어링 및 보안 성과 (Technical Highlights & Solutions)](#-주요-엔지니어링-및-보안-성과-technical-highlights--solutions)
6. [실행 및 빌드 가이드 (Build & Run Guide)](#-실행-및-빌드-가이드-build--run-guide)
7. [품질 관리 및 검증 (Quality Checks)](#-품질-관리-및-검증-quality-checks)

---

## 📱 프로젝트 소개 (Overview)

**TopikGo**는 글로벌 한국어 학습자들이 TOPIK II 시험을 효율적으로 대비할 수 있도록 돕는 학습 스마트 앱입니다.  
사용자 수준에 맞는 맞춤형 목표 설정, 영역별(읽기·듣기·쓰기) 기출 및 연습 문제 풀이, 실전 모의고사, 어휘/문법 학습, 그리고 오프라인 동기화 기능까지 일관되고 직관적인 UX로 제공합니다.

- **개발 언어 & 프레임워크**: Dart / Flutter (Material 3)
- **대상 플랫폼**: iOS / Android
- **핵심 아키텍처**: Feature-First Clean Architecture + Riverpod 상태 관리

---

## ✨ 핵심 기능 (Key Features)

### 1. 🔐 보안 인증 & 무중단 자동 로그인 (Auth & Auto-Login)
- **다양한 로그인 수단**: 이메일/비밀번호 로컬 로그인 및 Google / Kakao 네이티브 소셜 로그인 지원.
- **안전한 토큰 암호화 보관**: iOS Keychain 및 Android Keystore-backed 저장소(`FlutterSecureStorage`)를 사용해 JWT 토큰을 암호화하여 저장.
- **무중단 자동 로그인**: 앱 실행 시 Splash 화면에서 저장된 토큰을 검증하고, 유효한 경우 로그인 화면 없이 즉시 메인 홈 화면으로 진입.
- **Silent Token Refresh (자동 토큰 갱신)**: Access Token 만료(401) 발생 시 Dio 인터셉터가 백그라운드에서 Refresh Token을 사용해 토큰을 자동 갱신하고, **실패했던 기존 요청을 자동으로 Retry**하여 사용자가 중단을 느끼지 않도록 처리.

### 2. 🌐 스마트 온보딩 (Onboarding)
- **다국어 지원**: 한국어, 영어, 타갈로그어 등 사용자의 모국어 환경에 맞춘 인앱 언어 설정.
- **목표 레벨 및 학습 모드**: TOPIK 3~6급 목표 레벨 선택 및 타임존/타이머 모드 커스터마이징.

### 3. 📚 영역별 문제 풀이 & 모의고사 (Practice & Mock Exam)
- **영역별 학습**: 읽기, 듣기(오디오 재생/TTS 연동), 쓰기 문제 풀이 및 해설 제공.
- **실전 모의고사**: 실제 시험 시간에 맞춘 타이머 및 OMR 마킹 세션 제공.
- **영상 해설 강의**: 비디오 플레이어(`chewie`, `youtube_player_flutter`)를 통한 해설 강좌 시청.

### 4. 📖 어휘 및 문법 학습 (Vocabulary & Grammar)
- TOPIK 필수 어휘/문법 리스트 조회 및 검색.
- 주요 어휘 및 문법 항목 북마크 저장 기능.

### 5. 🔄 오프라인 지원 및 자동 동기화 (Offline Sync)
- 로컬 SQLite 데이터베이스(`Drift`)에 학습 항목 저장.
- 네트워크 연결이 복원되면 오프라인 동안 쌓인 데이터 및 진행 상황을 백엔드로 자동 동기화.

---

## 🛠 기술 스택 (Tech Stack)

### Core & UI
- **Flutter** (Dart 3.x, Material 3 Design Tokens)
- **GoRouter**: `StatefulShellRoute` 기반 탭 상태 유지 라우팅 및 계층형 네비게이션 관리

### State Management & Architecture
- **Flutter Riverpod**: Compile-time safety 보장, 디펜던시 주입 및 반응형 상태 관리 (`Provider`, `FutureProvider`, `ConsumerStatefulWidget`)

### Networking & Security
- **Dio**: HTTP 통신, Request/Response/Error Custom Interceptor 적용
- **Flutter Secure Storage**: OS 수준 암호화 저장소 (iOS Keychain / Android Keystore)
- **Shared Preferences**: 온보딩 여부 등 경량 앱 설정 보관

### Local Database & Media
- **Drift (Moor)** + `sqlite3_flutter_libs`: 오프라인 렌더링용 로컬 SQLite ORM
- **Just Audio / Flutter TTS**: 듣기 영역 음성 재생 및 텍스트 음성 변환
- **Chewie / Video Player / Youtube Player**: 해설 동영상 재생

---

## 📂 아키텍처 및 폴더 구조 (Architecture & Project Structure)

도메인 및 기능 중심의 **Feature-First 모듈화 구조**를 적용하여 코드의 가독성, 유지보수성, 테스트 용이성을 극대화했습니다.

```text
lib/
├── app/                        # 앱 전역 설정
│   ├── app.dart                # MaterialApp.router 설정
│   ├── router.dart             # GoRouter 경로 및 StatefulShellRoute 정의
│   └── theme/                  # 디자인 시스템 (AppColors, AppTheme)
├── core/                       # 공통 코어 모듈
│   ├── auth/                   # SessionStore (SecureStorage 토큰 관리)
│   ├── constants/              # App Constants, PrefsKeys
│   └── network/                # DioProvider (BaseURL Probe, Auth/Refresh Interceptor)
└── features/                   # 기능별 독립 모듈 (Feature-First)
    ├── auth/                   # 인증 (Login, Register, Social Login, AuthController)
    ├── onboarding/             # 온보딩 (Splash, LanguageSelect, GoalLevel)
    ├── home/                   # 메인 대시보드
    ├── practice/               # 영역별 연습 문제
    ├── mock_exam/              # 실전 모의고사
    ├── questions/              # 문제 조회 및 오프라인 저장소
    ├── vocabulary/             # 어휘 학습
    ├── grammar/                # 문법 학습
    ├── bookmarks/              # 북마크 관리
    └── settings/               # 마이페이지 및 설정
```

각 기능(`feature`) 내부 구조:
- **`data/`**: Repositories, API Data Sources, Data Models (`fromJson`)
- **`application/`**: Controllers, State Notifiers (비즈니스 로직)
- **`presentation/`**: UI Pages, Widgets, ConsumerStatefulWidget

---

## ⚡ 주요 엔지니어링 및 보안 성과 (Technical Highlights & Solutions)

### 1. 🔒 평문 저장 위험 극복 및 SecureStorage 보안 마이그레이션
- **문제점**: 기존에는 JWT 토큰을 `SharedPreferences`에 평문으로 저장하여 장치 루팅/탈옥 시 토큰 유출 위험이 존재함.
- **해결책**: `FlutterSecureStorage`로 암호화 전환. 기존 사용자를 고려해 앱 실행 시 `SharedPreferences`의 기존 토큰을 `FlutterSecureStorage`로 안전하게 원타임 마이그레이션한 후 평문 데이터를 즉시 파기하는 로직 구축.

### 2. 🔄 401 Unauthorized 감지 및 무중단 토큰 자동 재발급 (Silent Retry)
- **문제점**: Access Token 만료 시 사용자가 작업 도중 쫓겨나거나 에러 화면을 경험함.
- **해결책**: Dio Interceptor의 `onError` 계층에서 401 에러 감지 시:
  1. 저장된 Refresh Token으로 백그라운드 `POST /auth/refresh` 요청.
  2. 신규 토큰 받아서 SecureStorage 갱신.
  3. 실패했던 원래 HTTP Request의 Authorization 헤더를 교체 후 **`dio.fetch()`로 자동 재요청(Retry)** 수행.

### 3. 🌐 동적 Base URL 자동 탐색 (Reachable Base URL Probing)
- **문제점**: 개발 시 에뮬레이터(`10.0.2.2`), 실기기 IP(`172.30.1.79`), 이전 레거시 IP 등 네트워크 환경에 따라 접속 주소가 달라짐.
- **해결책**: 앱 구동 시 후보 IP 주소들에 비동기 핑(`_probeApiBaseUrl`)을 전송하여 현재 가장 빠르게 응답하는 백엔드 서버 주소를 동적으로 자동 채택하는 부트스트랩 파이프라인 구현.

---

## 🚀 실행 및 빌드 가이드 (Build & Run Guide)

### 1. 패키지 설치
```bash
$ flutter pub get
```

### 2. 기본 앱 실행 (배포 서버 접속)
앱은 기본적으로 배포된 백엔드 API 및 CloudFront CDN을 사용하도록 설정되어 있습니다.
- **백엔드 API**: `https://topik-api.duckdns.org`
- **미디어 CDN**: `https://damqug77a9y1r.cloudfront.net`

```bash
# 단축 실행 스크립트 (Android Pixel 9 에뮬레이터 자동 실행)
$ ./scripts/run_aws.sh
# 또는 터미널 단축 명령어
$ topik-run-aws
```

### 3. 로컬 백엔드 접속 실행
로컬 개발 서버(`http://10.0.2.2:3000`)에 접속하여 실행할 때:

```bash
# 단축 실행 스크립트
$ ./scripts/run_local.sh
# 또는 터미널 단축 명령어
$ topik-run-local
```

### 4. 소셜 로그인 등 커스텀 플래그 전달 실행
```bash
$ flutter run -d android \
  --dart-define=API_BASE_URL=https://topik-api.duckdns.org \
  --dart-define=MEDIA_BASE_URL=https://damqug77a9y1r.cloudfront.net \
  --dart-define=GOOGLE_CLIENT_ID=your_google_client_id \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=your_google_server_client_id \
  --dart-define=KAKAO_NATIVE_APP_KEY=your_kakao_native_app_key \
  --dart-define=KAKAO_CUSTOM_SCHEME=kakaoYourKakaoNativeAppKey
```

---

## 🧪 품질 관리 및 검증 (Quality Checks)

프로젝트 코드의 품질과 정적 분석을 위해 아래 명령어를 활용합니다:

```bash
# 정적 코드 분석
$ flutter analyze

# 단위 및 통합 테스트 실행
$ flutter test
```

---
*TopikGo 모바일 앱은 프론트엔드/모바일 엔지니어링 모범 사례(Clean Architecture, Secure Token Management, Silent Refresh Interceptor)를 준수하여 제작되었습니다.*
