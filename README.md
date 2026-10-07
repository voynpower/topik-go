# TopikGo - Flutter Mobile Application (topik-go)

<p align="center">
  <img src="https://damqug77a9y1r.cloudfront.net/assets/logo.png" alt="TopikGo Logo" width="120" onerror="this.style.display='none'"/>
</p>

<p align="center">
  <strong>글로벌 학습자를 위한 AI 기반 TOPIK I & II 맞춤형 한국어능력시험 대비 모바일 앱</strong><br>
  Cross-Platform(iOS/Android) | 1:1 맞춤형 AI 피드백 | OneVoca 스마트 단어장 | 9개 국어 다국어 지원 | 오프라인 동기화
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=flat&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.10-0175C2?style=flat&logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/Riverpod-3.3-blue?style=flat" alt="Riverpod"/>
  <img src="https://img.shields.io/badge/Google_Gemini-AI_Powered-orange?style=flat&logo=googlegemini&logoColor=white" alt="Gemini"/>
  <img src="https://img.shields.io/badge/Platform-iOS%20%7C%20Android-green?style=flat" alt="Platform"/>
  <img src="https://img.shields.io/badge/License-Proprietary-red?style=flat" alt="License"/>
</p>

---

## 📌 목차 (Table of Contents)

1. [프로젝트 소개 (Overview)](#-프로젝트-소개-overview)
2. [핵심 기능 (Key Features)](#-핵심-기능-key-features)
   - [1. 🤖 1:1 맞춤형 AI 학습 피드백 (Gemini Flash Lite)](#1--11-맞춤형-ai-학습-피드백-gemini-flash-lite)
   - [2. 🔀 TOPIK I & TOPIK II 전 영역 완벽 지원](#2--topik-i--topik-ii-전-영역-완벽-지원)
   - [3. 📖 OneVoca 스마트 단어장 (4-Mode Vocabulary)](#3--onevoca-스마트-단어장-4-mode-vocabulary)
   - [4. 🧠 OneGrammar 인터랙티브 문법 시스템](#4--onegrammar-인터랙티브-문법-시스템)
   - [5. 📝 실전 모의고사 & 복습 허브 (Mock Exam & Review Hub)](#5--실전-모의고사--복습-허브-mock-exam--review-hub)
   - [6. 🌍 9개 국어 글로벌 다국어 지원 (Multilingual Localization)](#6--9개-국어-글로벌-다국어-지원-multilingual-localization)
   - [7. 🔐 보안 인증 & Play Store 규정 준수](#7--보안-인증--play-store-규정-준수)
   - [8. 💾 Drift SQLite 기반 오프라인 학습 & 동기화](#8--drift-sqlite-기반-오프라인-학습--동기화)
3. [기술 스택 (Tech Stack)](#-기술-스택-tech-stack)
4. [아키텍처 및 폴더 구조 (Architecture & Project Structure)](#-아키텍처-및-폴더-구조-architecture--project-structure)
5. [주요 엔지니어링 성과 (Deep-Dive Engineering Highlights)](#-주요-엔지니어링-성과-deep-dive-engineering-highlights)
6. [실행 및 빌드 가이드 (Build & Run Guide)](#-실행-및-빌드-가이드-build--run-guide)
7. [품질 관리 및 테스트 (Quality Assurance & Tests)](#-품질-관리-및-테스트-quality-assurance--tests)

---

## 📱 프로젝트 소개 (Overview)

**TopikGo (topik-go)**는 전 세계 한국어 학습자들이 한국어능력시험(TOPIK I, TOPIK II)을 가장 직관적이고 과학적으로 대비할 수 있도록 제작된 크로스플랫폼 모바일 애플리케이션입니다.

단순한 문제 나열을 넘어, **Google Gemini 최신 AI 모델(`gemini-flash-lite-latest`)**을 연동하여 학생의 오답 원인을 모국어로 1:1 분석해주는 **AI 오답 과외**, 서술형 작문 문제를 정밀 첨삭해주는 **AI 쓰기 피드백**, 원형 복원 알고리즘 기반의 **스마트 단어장(OneVoca)** 및 **인터랙티브 문법(OneGrammar)** 학습 환경을 제공합니다.

- **개발 언어 & 프레임워크**: Dart / Flutter (Material 3)
- **타겟 플랫폼**: Android / iOS
- **디자인 아키텍처**: Feature-First Clean Architecture + Riverpod 반응형 상태 관리

---

## ✨ 핵심 기능 (Key Features)

### 1. 🤖 1:1 맞춤형 AI 학습 피드백 (Gemini Flash Lite)

Google Gemini 최신 경량 고속 모델을 기반으로 학생 개인별 오답 및 답안을 분석하는 1:1 AI 튜터 시스템입니다.

- **AI 맞춤형 오답 해설 (Mistake Explainer)**:
  - 읽기·듣기 문제 및 모의고사 오답 시, `AI 1:1 해설` 버튼을 통해 바텀시트에서 즉시 분석 제공.
  - **오답 원인 분석(`wrongReason`)**: 사용자가 고른 선지가 왜 매력적인 오답인지, 어떤 오개념이 있었는지 지적.
  - **정답 도출 근거(`correctReason`)**: 지문 속 핵심 단서와 정답 논리를 명쾌하게 설명.
  - **지문 핵심 어휘(`keyVocabulary`)**: 문제 해결에 결정적이었던 필수 어휘 및 모국어 번역 제공.
  - **실전 공략 꿀팁(`tip`)**: 유사 유형에 대비할 수 있는 실전 시험 팁 전수.
  - **멀티티어 캐싱**: Redis(12시간) 및 DB 영구 저장을 통해 동일 문제에 대해 0.1초 미만의 초고속 응답 보장.
- **AI 1:1 쓰기(작문) 정밀 첨삭 (Writing Feedback)**:
  - TOPIK II 쓰기 영역(51번, 52번 빈칸 완성, 53번 소작문, 54번 장작문) 제출 답안 전용 첨삭.
  - **예상 점수대 산출(`scoreEstimate`)**: 실제 채점 기준에 기반한 예상 획득 점수.
  - **문법/어휘 교정(`grammarCorrections`)**: 원문과 교정안, 구체적인 교정 이유를 시각적 디프(Diff) 카드로 비교.
  - **감점 요인 분석(`deductionPoints`)**: 조사 오류, 띄어쓰기, 문맥 불일치 등 감점 요인 명시.
  - **자연스러운 모범 답안(`polishedVersion`)**: TOPIK 고득점 기준에 맞춘 유려한 한국어 문장 제안.
  - **원어민 종합 총평(`nativeFeedback`)**: 학습 동기부여와 핵심 보완점을 담은 한국어 교사의 피드백.

---

### 2. 🔀 TOPIK I & TOPIK II 전 영역 완벽 지원

- **원터치 글로벌 모드 전환 (TopikModeToggle)**:
  - 상단 앱바/네비게이션에 배치된 토글 스위치로 **TOPIK I(초급 1~2급)**과 **TOPIK II(중고급 3~6급)**를 언제든 원터치로 전환.
  - 사용자가 선택한 모드는 `SharedPreferences`에 즉시 영구 저장되어 앱 재실행 시에도 유지.
- **영역 및 레이아웃 동적 최적화**:
  - **TOPIK I 모드**: 듣기(30문항, 40분) + 읽기(40문항, 60분) 총 70문항 (200점 만점) 구성. 쓰기 섹션은 자동으로 숨김 처리.
  - **TOPIK II 모드**: 듣기(50문항, 60분) + 쓰기(4문항, 50분) + 읽기(50문항, 70분) 총 104문항 (300점 만점) 구성.
- **102회 & 83회 최신 실전 기출 데이터 수록**:
  - TOPIK 1 제102회 및 TOPIK 2 제102회·제83회 실제 기출 문제, 원본 오디오, 지문 이미지, 공식 정답 탑재.
  - TOPIK 1 듣기 특유의 문제 묶음(1~24번 개별 문항, 25~30번 2문항 세트) 완벽 분할 렌더링.

---

### 3. 📖 OneVoca 스마트 단어장 (4-Mode Vocabulary)

- **북마크 & 단어장 일원화**:
  - 기존의 분산되어 있던 "내 단어장"과 "북마크 단어"를 하나의 직관적인 저장 단어장(`user_vocabulary`)으로 통합.
  - 저장된 단어가 있을 시 기본적으로 저장 단어 목록을 최우선으로 보여주어 학습 집중도 극대화.
- **4대 몰입형 학습 모드**:
  1. 🎴 **스와이프 플래시카드 (Swipe Flashcards)**: Tinder 스타일의 좌우 스와이프 인터랙션으로 '아는 단어'와 '모르는 단어'를 빠르게 분류 및 반복 암기.
  2. ❓ **4지선다 퀴즈 (Quiz)**: 뜻 맞추기 객관식 퀴즈 세션으로 암기력 자가 점검.
  3. ✍️ **받아쓰기 훈련 (Dictation)**: TTS 원어민 발음을 듣고 정확한 철자와 받침을 직접 타이핑하여 한국어 맞춤법 체화.
  4. 🎧 **오토플레이 연속 재생 (Autoplay)**: 이동 중에도 이어폰으로 한국어 발음과 모국어 번역을 무한 반복 청취하는 오디오 러닝 모드.
- **단어 인앱 실시간 편집 및 삭제 (3-Dots Menu)**:
  - 단어 카드에서 3-dots 메뉴를 통해 나만의 뜻, 메모를 수정하거나 삭제 가능.
  - `userVocabularyOverrideProvider`를 적용하여 네트워크 요청 전 로컬에서 즉시 변경사항을 렌더링(Optimistic Update).
- **Gemini AI 실전 예문 생성기 (Real AI Examples)**:
  - 단어 상세 화면에서 `AI 예문 보기` 아코디언을 누르면 TOPIK 실전 문맥(일상 대화, TOPIK 실전, 사회·문화, 개인 경험, 학술·시사)에 맞춘 고품질 한국어 예문과 다국어 번역 실시간 생성.
- **스마트 사전 검색 & 한국어 조사 자동 탈락 (Particle Stripping)**:
  - 문제 지문 열람 중 모르는 단어를 즉시 검색하는 빠른 팝업 시트(`WordLookupSheet`).
  - 은/는/이/가/을/를/에/에서/으로/까지/부터 등 문맥 속 굴절형 조사를 자동으로 제거하고 사전 기본형(표제어)을 찾아내어 원클릭 단어장 저장 지원.
  - HTML 엔티티 깨짐 방지 디코딩(`&#39;`, `&quot;`, `&amp;` 등) 정제 완료.

---

### 4. 🧠 OneGrammar 인터랙티브 문법 시스템

- **오늘의 문법 (Today's Grammar) 데일리 루프**:
  - 홈 대시보드에서 매일 핵심 문법 1개를 엄선하여 의미, 접속 규칙(활용법), 예문을 모국어 번역과 함께 학습하도록 유도.
- **마스터 문법 데이터셋 & 다각도 필터**:
  - TOPIK 필수 문법 전체를 레벨별(초급/중급/고급) 및 의미 카테고리별로 검색/필터링.
  - 문법 플래시카드 및 문법 사지선다 퀴즈 지원.
  - AI 문법 분석 시트(`AiGrammarSheet`)를 통해 복잡한 문법의 뉘앙스 차이와 유사 표현 비교 제공.

---

### 5. 📝 실전 모의고사 & 복습 허브 (Mock Exam & Review Hub)

- **실제 고사장 환경 시뮬레이션**:
  - 실제 시험 규정에 맞춘 실시간 카운트다운 타이머.
  - 하단 OMR 답안 마킹 시트, 문항 번호 빠른 이동 네비게이터, 자동 중간 임시저장.
- **연속 오디오 플레이리스트 (Continuous Audio Playlist)**:
  - 듣기 영역 전체를 실제 시험 방송처럼 끊김 없이 자동 연속 재생.
  - 대본(Transcript) 카드와 문제 영역 분리로 지문 중복 노출 없는 쾌적한 풀이 환경.
- **통합 복습 허브 & 시험 히스토리**:
  - 틀린 문제, 북마크한 문제, 영역별 취약 유형을 체계적으로 모아보는 복습 허브.
  - 시험 응시 일시, 소요 시간, 영역별 점수 통계를 기록하는 히스토리 관리.

---

### 6. 🌍 9개 국어 글로벌 다국어 지원 (Multilingual Localization)

글로벌 외국인 응시자를 위해 앱 UI 전체 및 주요 학습 콘텐츠를 **9개 국어**로 완벽하게 다국어화했습니다.

| 지원 언어 | 로케일 코드 | 표기명 |
| :--- | :--- | :--- |
| **한국어** | `ko` | 한국어 |
| **영어** | `en` | English |
| **우즈베크어** | `uz` | Oʻzbek tili (Lotin) |
| **러시아어** | `ru` | Русский |
| **베트남어** | `vi` | Tiếng Việt |
| **중국어** | `zh` | 简体中文 |
| **일본어** | `ja` | 日本語 |
| **프랑스어** | `fr` | Français |
| **독일어** | `de` | Deutsch |

- 온보딩 과정 및 [설정] 페이지에서 언제든 언어 변경 가능.
- 우즈베크어 등 단어 길이가 긴 언어 환경에서도 텍스트 잘림이 발생하지 않도록 **반응형 레이아웃 오버플로우 방지 처리** 완료.

---

### 7. 🔐 보안 인증 & Play Store 규정 준수

- **엔터프라이즈급 토큰 암호화 보관**:
  - iOS Keychain 및 Android Keystore 기반 `FlutterSecureStorage`로 JWT Access/Refresh Token을 안전하게 저장.
- **무중단 Silent Token Refresh**:
  - 토큰 만료(401 Unauthorized) 발생 시 Dio 커스텀 인터셉터가 백그라운드에서 Refresh Token으로 자동 재발급을 수행하고, **실패했던 원래 HTTP 요청을 자동으로 재시도(Silent Retry)**.
- **Google 네이티브 로그인 & Kakao 로그인**:
  - 플랫폼 공식 가이드라인을 준수한 전용 소셜 로그인 버튼 UI 및 네이티브 인증 플로우.
- **Google Play 스토어 규정 준수 회원 탈퇴 (Account Deletion)**:
  - 설정 화면에서 1클릭으로 계정 영구 삭제 지원.
  - 서버 측에서 사용자 계정 및 연관된 모든 학습 데이터(답안, 세션, 북마크, 다운로드 등)를 안전하게 연쇄 정리(Cascade Deletion)하고 로컬 온보딩 상태 초기화.
- **법적 고지 (Legal Documents)**:
  - 백엔드와 연동된 공식 서비스 이용약관(`Terms of Service`) 및 개인정보 처리방침(`Privacy Policy`) 다국어 인앱 모달 제공.
  - 안전한 로그아웃 확인 다이얼로그 및 상세 앱 정보 모달.

---

### 8. 💾 Drift SQLite 기반 오프라인 학습 & 동기화

- 로컬 관계형 데이터베이스(`Drift` ORM + `sqlite3_flutter_libs`)를 구축하여 다운로드한 문제, 단어장, 오프라인 학습 기록 보관.
- 네트워크가 불안정하거나 비행기 모드에서도 학습이 가능하며, 인터넷 재연결 시 오프라인 학습 이력을 서버로 자동 동기화.

---

## 🛠 기술 스택 (Tech Stack)

| 구분 | 주요 기술 & 라이브러리 | 용도 및 설명 |
| :--- | :--- | :--- |
| **Core & UI** | **Flutter 3.x**, **Dart 3.10+** | 크로스플랫폼 모바일 애플리케이션 프레임워크 |
| **Design System** | **Material 3 Design Tokens** | 모던한 색상 팔레트, 둥근 모서리, 유려한 애니메이션 |
| **Routing** | **GoRouter 17.2+** | `StatefulShellRoute` 기반 하단 탭 상태 유지 및 계층형 네비게이션 |
| **State Management**| **Flutter Riverpod 3.3+** | 컴파일 타임 안전성 보장, 선언적 상태 관리 및 의존성 주입 |
| **Networking** | **Dio 5.9+** | Base URL Probing, Auth/Refresh Interceptor, Silent Retry |
| **Security Storage**| **Flutter Secure Storage 11.1+**| OS 하드웨어 암호화 저장소 (iOS Keychain / Android Keystore) |
| **Local Database** | **Drift 2.32+ (SQLite)** | 오프라인 캐싱 및 로컬 학습 데이터 ORM |
| **Audio & Media** | **just_audio 0.10+**, **flutter_tts 4.2+**| 듣기 음성 스트리밍 재생 및 실시간 한국어 텍스트 음성 변환 |
| **Video Player** | **chewie**, **video_player**, **youtube_player**| 해설 강의 및 동영상 콘텐츠 인앱 렌더링 |
| **Social Auth** | **google_sign_in**, **kakao_flutter_sdk_user**| 구글 및 카카오 네이티브 소셜 로그인 연동 |
| **Localization** | **Custom AppStrings Provider** | 9개 국어 실시간 다국어 지원 |

---

## 📂 아키텍처 및 폴더 구조 (Architecture & Project Structure)

기능 단위로 명확하게 분리된 **Feature-First Clean Architecture**를 채택하고 있습니다.

```text
lib/
├── app/                              # 전역 애플리케이션 진입점
│   ├── app.dart                      # MaterialApp.router 및 글로벌 테마/로케일 설정
│   ├── router.dart                   # GoRouter 라우팅 테이블 & 탭 쉘 라우트 정의
│   └── theme/                        # AppColors, AppTheme (Material 3)
├── core/                             # 전역 공통 모듈
│   ├── auth/                         # SessionStore (SecureStorage 토큰 암호화 관리)
│   ├── constants/                    # API 경로, SharedPreferences 키 상수
│   ├── localization/                 # 9개 국어 AppStrings 및 실시간 Provider
│   ├── network/                      # DioProvider (Base URL 동적 탐색, Silent Refresh)
│   └── topik_mode/                   # TopikMode (TOPIK I / II) 상태 관리 및 토글 위젯
└── features/                         # 기능별 독립 모듈 (Feature-First)
    ├── auth/                         # 로그인, 회원가입, 구글/카카오 소셜 인증
    ├── onboarding/                   # 온보딩 스플래시, 언어 선택, 목표 레벨 설정
    ├── home/                         # 메인 대시보드, D-Day, 오늘의 문법
    ├── practice/                     # 영역별(읽기/듣기/쓰기) 연습 문제 허브
    ├── mock_exam/                    # 실전 모의고사, OMR 마킹 시트, 연속 오디오 플레이어
    ├── questions/                    # 문제 조회, 1:1 AI 오답 해설 및 AI 쓰기 첨삭 바텀시트
    ├── vocabulary/                   # OneVoca 스마트 단어장 (플래시카드, 퀴즈, 받아쓰기, 오토플레이, AI 예문, 조사 탈락 사전)
    ├── grammar/                      # OneGrammar (오늘의 문법, 마스터 데이터셋, 플래시카드, 퀴즈)
    ├── bookmarks/                    # 영역별 북마크 모아보기 허브
    └── settings/                     # 언어 변경, 이용약관, 개인정보처리방침, 회원 탈퇴
```

각 `feature` 내부는 계층형 아키텍처로 모듈화되어 있습니다:
- **`data/`**: Data Source, Model(DTO), Repository 구현체
- **`application/`**: Riverpod StateNotifier / Controller (비즈니스 로직)
- **`presentation/`**: UI Page, Screen, Modal Sheets, Custom Widgets

---

## ⚡ 주요 엔지니어링 성과 (Deep-Dive Engineering Highlights)

### 1. 🔄 401 Unauthorized 무중단 Silent Retry 인터셉터
사용자가 문제 풀이나 모의고사 도중 토큰 만료로 인해 튕기는 문제를 원천 차단했습니다.
1. `onError`에서 HTTP 401 수신 시 요청 일시 큐잉.
2. 백그라운드에서 저장된 Refresh Token으로 신규 토큰 발급 (`POST /auth/refresh`).
3. 갱신된 Access Token을 SecureStorage에 저장하고, 실패했던 원래 요청의 헤더를 교체한 후 `dio.fetch()`로 자동 재전송.

### 2. 🔤 한국어 조사 자동 탈락(Particle Stripping) 사전 검색
사용자가 지문 속 단어(예: `학교에서`, `선생님을`, `한국어로는`)를 클릭하거나 검색할 때:
1. 1차 원문 검색 후 결과가 없을 경우, 끝에 붙은 조사/어미(`은`, `는`, `이`, `가`, `을`, `를`, `에`, `에서`, `으로`, `까지`, `부터` 등)를 순차적으로 박리.
2. 한국어 정규 기본형(표제어, 예: `학교`, `선생님`, `한국어`)을 찾아내어 정확한 사전 정의를 매핑하고 모국어 번역을 제공.

### 3. 🌐 동적 Base URL 자동 탐색 (Reachable Probing)
로컬 에뮬레이터(`10.0.2.2`), 실기기 Wi-Fi IP, 배포 서버 등 다양한 개발/프로덕션 환경을 자동 감지합니다.
앱 부트스트랩 시 우선순위 서버 주소들에 비동기 핑(`_probeApiBaseUrl`)을 전송하여 가장 빠르게 응답하는 주소를 동적으로 바인딩합니다.

### 4. 🛡️ Google Play 컴플라이언스 준수 계정 탈퇴 파이프라인
Google Play 정책에 따라 사용자가 인앱에서 즉시 계정을 파기할 수 있도록 지원합니다.
`DELETE /users/profile` 호출 시 백엔드 MySQL에서 외래키 종속 데이터가 안전하게 연쇄 삭제되고, 로컬 기기에서는 Keychain/Keystore 및 SharedPreferences를 완전 초기화하여 클린 온보딩 상태로 안전 복귀합니다.

---

## 🚀 실행 및 빌드 가이드 (Build & Run Guide)

### 1. 의존성 패키지 설치
```bash
$ flutter pub get
```

### 2. 배포 서버(AWS EC2 & CloudFront CDN) 환경으로 실행
배포된 프로덕션 서버와 연동하여 실행합니다.
- **API URL**: `https://topik-api.duckdns.org`
- **미디어 CDN**: `https://damqug77a9y1r.cloudfront.net`

```bash
# 실행 스크립트 (Android 에뮬레이터 자동 타겟팅)
$ ./scripts/run_aws.sh

# 또는 Flutter CLI 직접 실행
$ flutter run -d android \
  --dart-define=API_BASE_URL=https://topik-api.duckdns.org \
  --dart-define=MEDIA_BASE_URL=https://damqug77a9y1r.cloudfront.net
```

### 3. 로컬 개발 서버 환경으로 실행
로컬 머신에서 구동 중인 백엔드(`http://10.0.2.2:3000`)에 연결할 때:

```bash
$ ./scripts/run_local.sh
```

### 4. Android 프로덕션 릴리즈 APK 빌드
```bash
$ ./scripts/build_apk.sh
# 빌드 결과물: build/app/outputs/flutter-apk/app-release.apk
```

---

## 🧪 품질 관리 및 테스트 (Quality Assurance & Tests)

코드의 품질과 안정성을 위해 엄격한 정적 분석 및 자동화 테스트를 수행합니다.

```bash
# 정적 코드 분석
$ flutter analyze

# 단위 및 위젯 테스트 전체 실행
$ flutter test
```

주요 테스트 커버리지:
- **`topik_mode_test.dart`**: TOPIK I / II 모드 전환 및 영구 저장 단위/위젯 테스트
- **`network_test.dart`**: Dio Interceptor, Silent Refresh, Base URL Probing 검증
- **`transcript_deduplication_test.dart`**: 듣기 대본 중복 제거 및 문항 그룹핑 로직 검증
- **`auth_test.dart`**: 세션 스토어 암호화 및 구글 로그인 컴포넌트 검증
