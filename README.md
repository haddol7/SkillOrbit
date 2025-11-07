# SkillOrbit Project #3 - CLI + Server MVP

AI 기반 원형 로드맵 생성 앱의 **Project #3(중간보고)** 단계 구현입니다.
**Dart CLI + Dart Server** 기반으로 실제 OpenAI Chat Completions API를 호출하여 학습 로드맵을 생성합니다.

## 📋 프로젝트 개요

### 핵심 원칙
- ✅ LLM 모의 금지 - **실제 OpenAI Chat Completions API** 호출
- ✅ API 키 보안 - CLI는 서버 REST만 호출, 서버만 LLM 직접 호출
- ✅ 공유 기능 - 공개 전환/목록/포크 구현
- ✅ 저장소 인터페이스 - Port/Adapter 패턴으로 Firebase 전환 준비

### 기능
1. 로드맵 생성 (목표, 기간, 난이도 입력 → ChatGPT API 호출)
2. 내 로드맵 CRUD (목록, 상세, 삭제)
3. 공유 기능 (공개 전환, 공개 목록, 포크)
4. InMemory/File 저장소 (Firestore는 Project #4에서 구현)

## 🏗️ 아키텍처

### 폴더 구조
```
project3_cli_server/
├─ bin/
│  ├─ cli.dart                # CLI 진입점
│  └─ server.dart             # 서버 진입점
├─ lib/
│  ├─ domain/
│  │  ├─ models/
│  │  │  ├─ roadmap.dart      # 로드맵 모델
│  │  │  └─ node.dart         # 노드 모델
│  │  ├─ ports/
│  │  │  └─ roadmap_repository.dart  # 저장소 인터페이스
│  │  └─ services/
│  │     └─ llm_service.dart   # OpenAI Chat Completions API 호출
│  ├─ infra/
│  │  ├─ repo_memory.dart      # InMemory/File 저장소
│  │  └─ repo_firebase_stub.dart  # Firestore Stub (TODO)
│  ├─ server/
│  │  ├─ handlers.dart         # REST 핸들러
│  │  └─ dto.dart              # 요청/응답 DTO
│  └─ cli/
│     └─ cli_service.dart      # CLI 명령 로직
└─ pubspec.yaml
```

### 데이터 모델

#### Roadmap
```dart
class Roadmap {
  final String id;
  final String ownerId;       // "local" (Project #3)
  final String title;
  final int duration;         // 2 | 4 | 8 (주)
  final String difficulty;    // easy | medium | hard
  final double progress;      // 0.0 ~ 1.0
  final DateTime createdAt;
  final bool isPublic;
  final DateTime? sharedAt;
  final String? forkedFrom;
  final List<Node> nodes;     // 12개 권장
}
```

#### Node
```dart
class Node {
  final String id;
  final String title;
  final String description;
  final String status;  // locked | active | completed
}
```

### REST API 엔드포인트

| Method | Path | Description |
|--------|------|-------------|
| GET | `/roadmaps` | 내 로드맵 목록 |
| GET | `/roadmaps/:id` | 로드맵 상세 조회 |
| POST | `/roadmaps` | 로드맵 생성 (LLM 호출) |
| DELETE | `/roadmaps/:id` | 로드맵 삭제 |
| POST | `/roadmaps/:id/share` | 공개 전환 |
| GET | `/public` | 공개 로드맵 목록 |
| GET | `/public/:id` | 공개 로드맵 상세 |
| POST | `/public/:id/fork` | 공개 로드맵 포크 |

### 응답 포맷
```json
{
  "ok": true,
  "data": { ... }
}
```

```json
{
  "ok": false,
  "error": {
    "code": "NOT_FOUND",
    "message": "Roadmap not found"
  }
}
```

## 🚀 설치 및 실행

### 1. 사전 요구사항
- Dart SDK 3.0 이상
- OpenAI API 키 ([platform.openai.com](https://platform.openai.com)에서 발급)

### 2. 의존성 설치
```bash
cd project3_cli_server
dart pub get
```

### 3. 환경변수 설정

**Linux/Mac:**
```bash
export OPENAI_API_KEY=sk-...
```

**Windows (PowerShell):**
```powershell
$env:OPENAI_API_KEY="sk-..."
```

**Windows (CMD):**
```cmd
set OPENAI_API_KEY=sk-...
```

### 4. 서버 기동
```bash
dart run bin/server.dart
```

출력:
```
┌─────────────────────────────────────────┐
│  SkillOrbit Project #3 Server           │
│  AI Roadmap Generation MVP              │
└─────────────────────────────────────────┘

[INFO] Initializing server...
[INFO] API Key: sk-ant-...xxxx
[INFO] Storage: InMemory + File (roadmaps.json)

┌─────────────────────────────────────────┐
│  Server listening on:                   │
│  http://localhost:8080                    │
└─────────────────────────────────────────┘

[INFO] Press Ctrl+C to stop
```

### 5. CLI 명령어 사용

**새 터미널 열기**

#### 로드맵 생성
```bash
dart run bin/cli.dart create
```

입력 예시:
```
목표를 입력하세요: 딥러닝 기초 로드맵
기간을 선택하세요 (2/4/8주): 4
난이도를 선택하세요 (easy/medium/hard): medium

[INFO] 로드맵 생성 중... (Claude API 호출, 최대 30초 소요)

✓ 생성 완료!

ID:    r_1736123456789
제목:  딥러닝 기초 완성 로드맵
메시지: Roadmap created successfully
```

#### 내 로드맵 목록
```bash
dart run bin/cli.dart list
```

#### 로드맵 상세 조회
```bash
dart run bin/cli.dart view r_1736123456789
```

출력 예시:
```
┌─────────────────────────────────────────┐
│  로드맵 상세                            │
└─────────────────────────────────────────┘

ID:           r_1736123456789
제목:         딥러닝 기초 완성 로드맵
기간:         4주
난이도:       medium
진행률:       0%
공개:         No
생성일:       2025-01-06T12:34:56.789Z

노드 목록:
  1. [active] Python 기초 문법
     Python 3.x 기본 문법과 라이브러리 학습
  2. [locked] NumPy & Pandas
     데이터 처리 라이브러리 실습
  ...
```

#### 로드맵 공개 전환
```bash
dart run bin/cli.dart share r_1736123456789
```

#### 공개 로드맵 목록
```bash
dart run bin/cli.dart public
```

#### 공개 로드맵 포크
```bash
dart run bin/cli.dart fork r_1736123456789
```

#### 로드맵 삭제
```bash
dart run bin/cli.dart delete r_1736123456789
```

## 📊 HOW2EVALUATE (프로젝트 #3) 대응

### A. 정보 명확성
- ✅ 데이터 모델 주석 (`lib/domain/models/*.dart`)
- ✅ 저장 구조 문서화 (`lib/infra/repo_memory.dart`)
- ✅ 책임 경계 명시 (서버: LLM/CRUD, CLI: REST 호출)

### B. 정보 교환 명확성
- ✅ REST 경로/메서드 문서화 (`lib/server/handlers.dart`)
- ✅ 요청/응답 DTO (`lib/server/dto.dart`)
- ✅ 표준 에러 포맷 (`ApiResponse`, `ApiError`)

### C. 기능 명확성
- ✅ CLI 명령 분리 (create/list/view/delete/share/public/fork)
- ✅ 각 명령별 핸들러 구현
- ✅ 유효성 검증 및 에러 처리

### D. 전체 등급
- ✅ 모듈화: Port/Adapter 패턴, 계층 분리
- ✅ 실행 로그: 서버/CLI 상세 로그
- ✅ 예외 처리: HTTP 오류, JSON 파싱 실패 등
- ✅ 샘플 시연: 이 README의 실행 절차

## 🔒 보안

### API 키 관리
- 환경변수 `OPENAI_API_KEY`에서만 읽음
- CLI는 API 키를 모름 (서버만 보유)
- 로그에 키/응답 전문 출력 안 함 (마스킹)

### OpenAI API 스펙
- 엔드포인트: `POST https://api.openai.com/v1/chat/completions`
- 헤더:
  - `Authorization`: Bearer {API 키}
  - `content-type`: application/json
- 모델: `gpt-4` (또는 `gpt-3.5-turbo`)

## 🔄 Firebase 전환 준비 (Project #4)

### 현재 상태
- ✅ 저장소 인터페이스: `RoadmapRepository` (Port)
- ✅ InMemory/File 어댑터: `InMemoryRoadmapRepository`
- ✅ Firestore Stub: `lib/infra/repo_firebase_stub.dart` (TODO 주석만)

### Firestore 마이그레이션 계획
1. **컬렉션 구조**
   - 개인: `users/{uid}/roadmaps/{id}`
   - 공개: `public_roadmaps/{id}`

2. **보안 규칙**
   ```javascript
   // 개인 로드맵
   match /users/{userId}/roadmaps/{roadmapId} {
     allow read, write: if request.auth.uid == userId;
   }

   // 공개 로드맵
   match /public_roadmaps/{roadmapId} {
     allow read: if resource.data.isPublic == true;
     allow write: if request.auth.uid == resource.data.ownerId;
   }
   ```

3. **구현 TODO** (`repo_firebase_stub.dart` 참조)
   - Firebase Admin SDK 추가
   - Firestore 초기화
   - CRUD 메서드 구현
   - isPublic=true 시 자동 복제

## 🧪 테스트 시나리오

### 1. 로드맵 생성 및 조회
```bash
# 서버 기동
dart run bin/server.dart

# 새 터미널
dart run bin/cli.dart create
# 입력: "웹 개발 입문", 2주, easy

dart run bin/cli.dart list
dart run bin/cli.dart view <생성된 ID>
```

### 2. 공유 및 포크
```bash
# 로드맵 공개
dart run bin/cli.dart share <ID>

# 공개 목록 확인
dart run bin/cli.dart public

# 포크
dart run bin/cli.dart fork <ID>

# 내 목록에 포크된 로드맵 확인
dart run bin/cli.dart list
```

### 3. 삭제
```bash
dart run bin/cli.dart delete <ID>
dart run bin/cli.dart list  # 삭제 확인
```

## 📝 개발 노트

### ChatGPT API 프롬프트
서버 내부에서 사용하는 로드맵 생성 프롬프트는 `lib/domain/services/llm_service.dart`의 `_buildPrompt` 메서드에 정의되어 있습니다.

### 재시도 로직
- OpenAI API 호출 실패 시 최대 2회 재시도
- 지수 백오프 (1초, 2초)

### 파일 영속화
- 서버 종료/재시작 시에도 로드맵 유지
- 저장 위치: `roadmaps.json` (환경변수 `ROADMAPS_FILE`로 변경 가능)

## 🐛 트러블슈팅

### 서버가 시작되지 않음
```
[ERROR] OPENAI_API_KEY environment variable is required
```
→ 환경변수 설정 확인

### CLI가 서버에 연결 안 됨
```
[ERROR] 목록 조회 실패: Connection refused
```
→ 서버가 실행 중인지 확인 (`http://localhost:8080`)

### OpenAI API 호출 실패
```
[ERROR] LLM generation failed: ...
```
→ API 키 유효성 확인, 네트워크 연결 확인

## 📚 다음 단계 (Project #4)

1. **Flutter UI 구현**
   - 원형 로드맵 시각화
   - 노드 상호작용

2. **Firebase 통합**
   - Firestore 저장소 구현
   - Firebase Auth 로그인

3. **추가 기능**
   - 로드맵 진행률 업데이트
   - 노드 상태 변경
   - 공유 링크 생성

## 📄 라이선스

MIT License

---

**SkillOrbit** - AI 기반 원형 로드맵 생성 앱
Project #3 (중간보고) - Dart CLI + Server MVP
