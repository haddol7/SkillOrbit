# SkillOrbit - AI 기반 원형 로드맵 생성 앱

## 프로젝트 개요
- **목적**: AI(ChatGPT)를 활용한 학습 로드맵 자동 생성 및 시각화
- **현재 단계**: Project #3 (중간보고) - Dart CLI + Server MVP
- **다음 단계**: Project #4 - Flutter UI + Firebase 통합

## 프로젝트 구조

```
skillorbit/
├─ project3_cli_server/          # 메인 프로젝트 (Dart)
│  ├─ bin/
│  │  ├─ server.dart             # REST API 서버 진입점 (포트 8080)
│  │  └─ cli.dart                # CLI 클라이언트 진입점
│  ├─ lib/
│  │  ├─ domain/
│  │  │  ├─ models/
│  │  │  │  ├─ roadmap.dart     # 로드맵 모델 (id, title, duration, difficulty, nodes 등)
│  │  │  │  └─ node.dart        # 노드 모델 (id, title, description, status)
│  │  │  ├─ ports/
│  │  │  │  └─ roadmap_repository.dart  # 저장소 인터페이스 (Port)
│  │  │  └─ services/
│  │  │     └─ llm_service.dart  # OpenAI API 호출 서비스
│  │  ├─ infra/
│  │  │  ├─ repo_memory.dart     # InMemory + File 저장소 (roadmaps.json)
│  │  │  └─ repo_firebase_stub.dart  # Firestore Stub (미구현)
│  │  ├─ server/
│  │  │  ├─ handlers.dart        # REST API 핸들러
│  │  │  └─ dto.dart             # 요청/응답 DTO
│  │  └─ cli/
│  │     └─ cli_service.dart     # CLI 명령 로직
│  ├─ run_server.bat             # Windows 서버 실행 스크립트
│  ├─ run_server.sh              # Linux/Mac 서버 실행 스크립트
│  └─ README.md                  # 상세 문서
└─ .claude/
   └─ context.md                 # 이 파일
```

## 핵심 설정

### API 설정
- **사용 API**: OpenAI Chat Completions API
- **현재 모델**: `gpt-3.5-turbo` (lib/domain/services/llm_service.dart:20)
- **환경변수**: `OPENAI_API_KEY` (필수)
- **엔드포인트**: `https://api.openai.com/v1/chat/completions`

### 서버 설정
- **포트**: 8080
- **저장소**: InMemory + File (roadmaps.json)
- **아키텍처**: Port/Adapter 패턴 (Firebase 전환 준비)

## 데이터 모델

### Roadmap
```dart
{
  id: String,           // "r_1736123456789"
  ownerId: String,      // "local" (현재)
  title: String,        // "딥러닝 기초 완성 로드맵"
  duration: int,        // 2 | 4 | 8 (주)
  difficulty: String,   // "easy" | "medium" | "hard"
  progress: double,     // 0.0 ~ 1.0
  createdAt: DateTime,
  isPublic: bool,       // 공개 여부
  sharedAt: DateTime?,  // 공개 시점
  forkedFrom: String?,  // 원본 로드맵 ID
  nodes: List<Node>     // 12개 권장
}
```

### Node
```dart
{
  id: String,           // "n1", "n2", ...
  title: String,        // "Python 기초 문법"
  description: String,  // "Python 3.x 기본 문법과 라이브러리 학습"
  status: String        // "locked" | "active" | "completed"
}
```

## REST API 엔드포인트

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

## 실행 방법

### 서버 실행 (먼저!)
```bash
cd project3_cli_server
dart run bin/server.dart
# 또는: run_server.bat (Windows)
```

### CLI 명령어 (새 터미널)
```bash
cd project3_cli_server

# 로드맵 생성
dart run bin/cli.dart create

# 내 로드맵 목록
dart run bin/cli.dart list

# 상세 조회
dart run bin/cli.dart view <ID>

# 공개 전환
dart run bin/cli.dart share <ID>

# 공개 목록
dart run bin/cli.dart public

# 포크
dart run bin/cli.dart fork <ID>

# 삭제
dart run bin/cli.dart delete <ID>
```

## 최근 변경사항

### 2025-11-06: gpt-4 → gpt-3.5-turbo 변경
- **파일**: `lib/domain/services/llm_service.dart:20`
- **이유**: gpt-4 접근 권한 없는 API 키 대응
- **변경**: `_model = 'gpt-4'` → `_model = 'gpt-3.5-turbo'`

## 다음 할 일 (Project #4)

1. Flutter UI 구현
   - 원형 로드맵 시각화
   - 노드 상호작용

2. Firebase 통합
   - Firestore 저장소 구현 (repo_firebase_stub.dart)
   - Firebase Auth 로그인
   - 컬렉션 구조:
     - `users/{uid}/roadmaps/{id}` (개인)
     - `public_roadmaps/{id}` (공개)

3. 추가 기능
   - 로드맵 진행률 업데이트
   - 노드 상태 변경
   - 공유 링크 생성

## 문제 해결

### 자주 발생하는 오류

1. **모델 접근 권한 오류**
   ```
   [ERROR] The model `gpt-4` does not exist or you do not have access to it.
   ```
   → `llm_service.dart`에서 모델을 `gpt-3.5-turbo`로 변경

2. **API 키 미설정**
   ```
   [ERROR] OPENAI_API_KEY environment variable is required
   ```
   → 환경변수 설정: `set OPENAI_API_KEY=sk-...` (Windows CMD)

3. **서버 연결 실패**
   ```
   [ERROR] Connection refused
   ```
   → 서버가 실행 중인지 확인 (http://localhost:8080)

## 추가 참고사항

- **보안**: CLI는 API 키를 모름, 서버만 보유
- **재시도 로직**: OpenAI API 호출 실패 시 최대 2회 재시도
- **파일 영속화**: roadmaps.json에 자동 저장
- **아키텍처 패턴**: Clean Architecture + Port/Adapter
