<p align="center">
  <img src="assets/icon/app_icon.png" width="120" alt="Dot Logo" />
</p>

<h1 align="center">Dot</h1>

<p align="center">
  <b>AI 기반 스마트 보안 스캐너</b><br/>
  온디바이스 임베딩 + 벡터 DB로 스팸/피싱/악성 URL을 실시간 탐지합니다.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10.7-02569B?logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart" alt="Dart" />
  <img src="https://img.shields.io/badge/ONNX_Runtime-On--device_AI-FF6F00" alt="ONNX" />
  <img src="https://img.shields.io/badge/Supabase-pgvector-3ECF8E?logo=supabase" alt="Supabase" />
</p>

---

## 주요 기능

### 1. 문자 메시지 분석 (Message Scan)
수신된 문자 메시지의 스팸/피싱 여부를 **2단계 하이브리드 분석**으로 판별합니다.
- **1단계**: 텍스트 유사도 기반 스팸 DB 매칭 (`search_spam_text` RPC, 유사도 80% 이상 탐지)
- **2단계**: ONNX 온디바이스 임베딩 추출 후 pgvector 벡터 유사도 검색 (`match_messages` RPC)
- 메시지 내 URL 자동 추출 및 위험도 분석

### 2. 전화번호 조회 (Phone Number Scan)
수신된 전화번호가 공공기관 번호인지 실시간으로 확인합니다.
- 대한민국 공공기관 전화번호 데이터베이스 조회 (`search_clean_phone` RPC)
- 기관명, 부서, 팩스번호, 주소 등 상세 정보 제공

### 3. 웹사이트 안전성 검사 (Website Scan)
URL/도메인의 안전성을 다중 소스로 교차 검증합니다.
- **블랙리스트/화이트리스트** 데이터베이스 조회
- **Google Safe Browsing API v4** 연동 (멀웨어, 피싱, 소셜 엔지니어링 탐지)
- **WHOIS 조회** (KISA 공공데이터 포털 API) - 48시간 이내 신규 등록 도메인 경고

---

## 아키텍처

### 엔지니어링 파이프라인

```
[문자 수신] → [WordPiece 토크나이징] → [ONNX 임베딩 추출 (On-device)]
                                              │
                                    임베딩 벡터만 전송 (원본 텍스트 미전송)
                                              │
                                              ▼
                                   [Supabase pgvector]
                                   [코사인 유사도 연산]
                                   [HNSW/IVFFlat 인덱싱]
                                              │
                                              ▼
                                   [스팸 확률 점수 산출]
                                    (0 ~ 100점 위험도)
```

### Privacy by Design
- 문자 메시지 원본 텍스트는 **외부로 전송되지 않습니다.**
- 네트워크를 통해 전달되는 것은 기기 내에서 비가역적으로 변환된 **임베딩 벡터(Float Array)** 뿐입니다.

### 스팸 회피 기법 무력화
키워드 사이 특수문자 삽입, 의도적 오타, 띄어쓰기 변형(예: `ㄷH.출`, `바.카.라`) 등의 회피 기법을 사용하더라도, 언어 모델이 문맥적 차원(Contextual Space)에서 동일한 벡터 군집으로 묶어 탐지합니다.

---

## 기술 스택

| 카테고리 | 기술 |
|---------|------|
| **Framework** | Flutter SDK ^3.10.7 |
| **상태 관리** | [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) |
| **라우팅** | [go_router](https://pub.dev/packages/go_router) |
| **HTTP 클라이언트** | [dio](https://pub.dev/packages/dio) |
| **백엔드** | [Supabase](https://pub.dev/packages/supabase_flutter) (pgvector, Edge Functions, RPC) |
| **보안 저장소** | [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) |
| **온디바이스 ML** | [onnxruntime](https://pub.dev/packages/onnxruntime) (양자화 모델) |
| **함수형 프로그래밍** | [fpdart](https://pub.dev/packages/fpdart) (Either 패턴 에러 핸들링) |
| **코드 생성** | [freezed](https://pub.dev/packages/freezed), [json_serializable](https://pub.dev/packages/json_serializable) |
| **애니메이션** | [lottie](https://pub.dev/packages/lottie) |
| **외부 API** | Google Safe Browsing API v4, KISA 공공데이터 포털 |

---

## 프로젝트 구조

Clean Architecture + Feature-First 패턴을 적용하여 계층 간 의존성 방향을 엄격히 분리합니다.

```text
lib/
├── main.dart                          # Supabase 초기화 및 앱 진입점
├── app/
│   ├── app.dart                       # MaterialApp.router, 테마 설정
│   ├── router.dart                    # GoRouter 라우트 정의
│   └── bootstrap.dart                 # 앱 초기화 (API 키, 테이블 카운트)
├── core/
│   ├── constants/                     # 전역 상수, Supabase 설정
│   ├── design_system/                 # 테마, 버튼, 다이얼로그, 반응형 레이아웃
│   ├── network/                       # DioClient, NetworkException
│   ├── security/                      # SecureStorageService
│   └── utils/                         # URL 유틸리티
└── features/
    └── scan/
        ├── domain/
        │   ├── scan_type.dart         # ScanType enum (phoneNumber, message, address)
        │   ├── scan_result.dart       # Freezed 결과 모델
        │   ├── scan_repository.dart   # 리포지토리 인터페이스
        │   └── scan_text_usecase.dart # 비즈니스 로직
        ├── data/
        │   ├── scan_repository_impl.dart    # 다중 소스 위험도 분석
        │   ├── scan_remote_datasource.dart  # API/RPC 호출
        │   ├── onnx_embedding_service.dart  # ONNX 모델 추론
        │   └── wordpiece_tokenizer.dart     # NLP 토크나이저
        └── presentation/
            ├── scan_screen.dart       # 메인 UI (메뉴/입력/결과 레이아웃)
            ├── scan_controller.dart   # StateNotifier 뷰모델
            ├── scan_providers.dart    # Riverpod DI 설정
            ├── dot_animation.dart     # 상태별 애니메이션 인디케이터
            └── widgets/              # 통계, 메뉴 카드, 카운터 위젯
```

---

## 시작하기

### 사전 요구사항
- Flutter SDK ^3.10.7
- Dart SDK ^3.x
- Android SDK (minSdk 21) 또는 Xcode (iOS)

### 설치 및 실행

```bash
# 의존성 설치
flutter pub get

# Freezed 및 JSON Serializable 코드 생성
dart run build_runner build -d

# 프로젝트 실행
flutter run
```

### 앱 아이콘 생성

```bash
dart run flutter_launcher_icons
```

---

## 빌드 정보

| 항목 | 값 |
|-----|---|
| **App ID** | `com.dotprotect.app` |
| **App Name** | Dot |
| **Min Android SDK** | 21 |
| **Java/Kotlin** | Java 17 / Kotlin JVM 17 |
| **iOS Bundle ID** | `com.dotprotect.app` |
