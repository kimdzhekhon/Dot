# Dot

**Dot**은 온디바이스(On-device) 텍스트 임베딩 모델을 활용해 수신된 텍스트를 실시간(Real-time)으로 분석하고, 벡터 데이터베이스와의 **코사인 유사도(Cosine Similarity)**를 연산하여 스팸 가능성을 판별하는 지능형 필터링 애플리케이션입니다.

`onnxruntime`을 통해 모바일 기기 내부에서 자연어 텍스트를 다차원 벡터로 즉각 변환하며, 추출된 벡터 데이터를 원격 벡터 DB(Supabase pgvector 등)에 실시간으로 질의합니다. 이를 통해 기존 키워드 매칭 방식의 한계를 극복하고, 문맥적 의미를 파악하여 고도화된 스팸 메시지를 선제적으로 차단합니다.

---

## ⚙️ 핵심 기술 및 엔지니어링 파이프라인 (Deep Dive)

**Dot** 앱은 서버 부하를 최소화하면서도 텍스트 분류 성능을 끌어올리기 위해, 추론(Inference) 단계 중 형태소 분석 및 임베딩 추출 과정을 전면 클라이언트 사이드(Client-side)로 이전했습니다. 전체 파이프라인은 다음과 같이 동작합니다.

### 1. 온디바이스 텍스트 토크나이징 및 임베딩 (On-device Inference via ONNX)
- **경량화된 자연어 텍스트 처리**: 메시지가 기기에 수신되면 즉각 백그라운드 스레드에서 서브워드(Subword) 기반 토크나이징(예: BPE, WordPiece 등)이 분리되어 수행됩니다.
- **ONNX Runtime 연산 최적화**: 모바일 환경(CPU/NPU) 리소스에 최적화된 양자화(Quantized) 언어 모델(.onnx 포맷)을 구동합니다. 이 모델을 거친 자연어 텍스트는 수백 차원(예: 384 ~ 768 차원)의 밀집 벡터(Dense Vector) 공간 수치로 매핑됩니다.
- **완전한 프라이버시 보호 (Data-Privacy by Design)**: 문자 메시지의 원본 텍스트는 **절대로 외부 클라우드로 전송되지 않습니다.** 네트워크를 통해 전송되는 것은 기기 내에서 비가역적으로 암호화된 기계 수학적 실수 배열(Embedding Float Array)뿐입니다.

### 2. 코사인 유사도(Cosine Similarity)와 고속 벡터 디비 질의
- **Supabase pgvector 확장**: 모바일 기기로부터 전달받은 질의 벡터($V_Q$)는 Supabase에 구축된 백엔드 `pgvector` 확장 모듈로 전달됩니다.
- **HNSW / IVFFlat 인덱싱 연산**: 데이터베이스 내부에서는 기존에 수집/학습된 수십만 건의 악성 스팸 텍스트 벡터($V_S$) 풀과 쿼리 벡터 간의 유사성을 대조합니다. 단순한 RDBMS 텍스트 매칭이 아닌 거리 측정(Distance Metric, `1 - (V_Q <=> V_S)`) 방식을 수행하며, HNSW(Hierarchical Navigable Small World)와 같은 근사 최근접 이웃(ANN) 인덱싱을 통해 **ms 단위**의 초고속 실시간 조회가 이루어집니다.

### 3. 문맥 의미론적 스팸 확률론 (Semantic Spam Probability)
- **Top-K 기반 확률 산정 알고리즘**: 가장 코사인 유사도가 높은 군집(K-Nearest Neighbors) 결과들을 바탕으로, 해당 텍스트의 최종 **스팸 확률(Spam Probability 점수, 0.0 ~ 1.0)**을 연산합니다.
- **어뷰징 및 회피 기법 무력화**: 스패머가 키워드 사이에 특수문자를 집어넣거나, 의도적 오타, 띄어쓰기 변형(예: "ㄷH.출", "바.카.라")을 시도하더라도, 자연어 모델이 문맥적 차원(Contextual Space)에서 이를 동일한 벡터 군집으로 가깝게 묶어버리므로 전통적인 정규식/키워드 룰 엔진을 완벽하게 압도합니다.

---

## 🛠 기술 스택 (Tech Stack)

### Core
- **Framework**: Flutter (SDK ^3.10.7)
- **State Management**: [flutter_riverpod](https://pub.dev/packages/flutter_riverpod)
- **Routing**: [go_router](https://pub.dev/packages/go_router)

### Network & Backend
- **HTTP Client**: [dio](https://pub.dev/packages/dio)
- **Backend as a Service**: [Supabase](https://pub.dev/packages/supabase_flutter)
- **Authentication**: Kakao, Apple, Google 소셜 로그인 지원
- **Push Notification**: Firebase Cloud Messaging (FCM)
- **Security**: [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)

### Utilities
- **Functional Programming**: [fpdart](https://pub.dev/packages/fpdart)
- **Code Generation**: [freezed](https://pub.dev/packages/freezed), [json_serializable](https://pub.dev/packages/json_serializable)
- **Machine Learning**: [onnxruntime](https://pub.dev/packages/onnxruntime)

---

## 📁 디렉터리 구조 (Directory Structure)

본 프로젝트는 의존성의 방향 붕괴를 방지하기 위해 엄격한 디렉터리 분리 체계를 따릅니다.

```text
lib/
 ├─ app/           # 앱 진입점, 라우터, 테마, 로컬라이제이션 설정
 ├─ core/          # 전역 상수, 보안, 네트워크 클라이언트, 디자인 시스템, 공통 UI 컴포넌트
 └─ features/      # 도메인별 기능 구획 (Feature-First 패턴 적용)
     └─ {feature_name}/
         ├─ domain/       # 엔티티, 유즈케이스, 리포지토리 인터페이스 (순수 Dart)
         ├─ data/         # 데이터 소스, DTO 모델, 리포지토리 구현체
         └─ presentation/ # Riverpod ViewModel, 스크린, 위젯
```

---

## 🚀 시작하기 (Getting Started)

이 프로젝트를 로컬에서 구동하기 위한 기본 명령어입니다.

```bash
# 의존성 설치
flutter pub get

# Freezed 및 JSON Serializable 코드 생성
dart run build_runner build -d

# 프로젝트 실행
flutter run
```
