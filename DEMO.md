# SkillOrbit Project #3 - 데모 시연 가이드

이 문서는 프로젝트를 빠르게 시연하기 위한 단계별 가이드입니다.

## 📋 사전 준비

### 1. OpenAI API 키 발급
1. https://platform.openai.com/ 접속
2. 계정 생성/로그인
3. API Keys 메뉴에서 새 키 생성
4. 키를 안전한 곳에 복사 (sk-...)

### 2. 프로젝트 준비
```bash
cd project3_cli_server
dart pub get
```

## 🎬 데모 시나리오 1: 로드맵 생성 및 조회

### 단계 1: 서버 기동

**Windows:**
```cmd
set OPENAI_API_KEY=sk-...
dart run bin/server.dart
```

**Linux/Mac:**
```bash
export OPENAI_API_KEY=sk-...
dart run bin/server.dart
```

**또는 스크립트 사용:**
```bash
# Windows
run_server.bat

# Linux/Mac
chmod +x run_server.sh
./run_server.sh
```

**예상 출력:**
```
┌─────────────────────────────────────────┐
│  SkillOrbit Project #3 Server           │
│  AI Roadmap Generation MVP              │
└─────────────────────────────────────────┘

[INFO] Initializing server...
[INFO] API Key: sk-...xxxx
[INFO] Storage: InMemory + File (roadmaps.json)

┌─────────────────────────────────────────┐
│  Server listening on:                   │
│  http://localhost:8080                    │
└─────────────────────────────────────────┘
```

### 단계 2: 로드맵 생성 (새 터미널)

```bash
dart run bin/cli.dart create
```

**입력 예시 1 - 웹 개발:**
```
목표를 입력하세요: 웹 개발 입문 로드맵
기간을 선택하세요 (2/4/8주): 2
난이도를 선택하세요 (easy/medium/hard): easy
```

**입력 예시 2 - 데이터 사이언스:**
```
목표를 입력하세요: Python 데이터 분석 마스터
기간을 선택하세요 (2/4/8주): 4
난이도를 선택하세요 (easy/medium/hard): medium
```

**입력 예시 3 - AI/ML:**
```
목표를 입력하세요: 딥러닝 기초부터 실전까지
기간을 선택하세요 (2/4/8주): 8
난이도를 선택하세요 (easy/medium/hard): hard
```

**예상 출력:**
```
[INFO] 로드맵 생성 중... (ChatGPT API 호출, 최대 30초 소요)

✓ 생성 완료!

ID:    r_1736123456789
제목:  웹 개발 입문 완성 로드맵
메시지: Roadmap created successfully
```

> **💡 Tip:** ID를 복사해두세요. 다음 단계에서 사용합니다.

### 단계 3: 로드맵 목록 확인

```bash
dart run bin/cli.dart list
```

**예상 출력:**
```
┌─────────────────────────────────────────┐
│  내 로드맵 목록                         │
└─────────────────────────────────────────┘

ID:       r_1736123456789
제목:     웹 개발 입문 완성 로드맵
기간:     2주
난이도:   easy
진행률:   0%
공개:     No
생성일:   2025-01-06T12:34:56.789Z
─────────────────────────────────────────
```

### 단계 4: 상세 조회

```bash
dart run bin/cli.dart view r_1736123456789
```

**예상 출력:**
```
┌─────────────────────────────────────────┐
│  로드맵 상세                            │
└─────────────────────────────────────────┘

ID:           r_1736123456789
제목:         웹 개발 입문 완성 로드맵
기간:         2주
난이도:       easy
진행률:       0%
공개:         No
생성일:       2025-01-06T12:34:56.789Z

노드 목록:
  1. [active] HTML 기본 구조
     웹 페이지의 기본 구조 이해하기
  2. [locked] CSS 스타일링
     웹 페이지 꾸미기 기초
  3. [locked] JavaScript 기초
     동적 웹 페이지 만들기
  ...
```

## 🎬 데모 시나리오 2: 공유 및 포크

### 단계 1: 로드맵 공개

```bash
dart run bin/cli.dart share r_1736123456789
```

**예상 출력:**
```
✓ Roadmap is now public

ID:        r_1736123456789
공개 상태: Public
공개 일시: 2025-01-06T12:40:00.000Z
```

### 단계 2: 공개 로드맵 목록 확인

```bash
dart run bin/cli.dart public
```

**예상 출력:**
```
┌─────────────────────────────────────────┐
│  공개 로드맵 목록                       │
└─────────────────────────────────────────┘

ID:       r_1736123456789
제목:     웹 개발 입문 완성 로드맵
기간:     2주
난이도:   easy
진행률:   0%
생성일:   2025-01-06T12:34:56.789Z
─────────────────────────────────────────
```

### 단계 3: 로드맵 포크 (다른 사용자 시뮬레이션)

```bash
dart run bin/cli.dart fork r_1736123456789
```

**예상 출력:**
```
[INFO] 로드맵 포크 중...
✓ Roadmap forked successfully

새 ID:     r_1736123999999
원본 ID:   r_1736123456789
제목:      웹 개발 입문 완성 로드맵
```

### 단계 4: 포크된 로드맵 확인

```bash
dart run bin/cli.dart list
```

이제 2개의 로드맵이 보여야 합니다:
- 원본 (isPublic: Yes)
- 포크된 로드맵 (isPublic: No, forkedFrom 필드 포함)

```bash
dart run bin/cli.dart view r_1736123999999
```

출력에서 `포크 원본: r_1736123456789` 확인

## 🎬 데모 시나리오 3: 삭제

### 로드맵 삭제

```bash
dart run bin/cli.dart delete r_1736123999999
```

**예상 출력:**
```
정말로 삭제하시겠습니까? (y/N): y
✓ Roadmap deleted successfully
```

### 삭제 확인

```bash
dart run bin/cli.dart list
```

포크된 로드맵이 사라지고 원본만 남아있어야 합니다.

## 🎬 데모 시나리오 4: 파일 영속화 테스트

### 단계 1: 서버 종료
서버 터미널에서 `Ctrl+C` 누르기

### 단계 2: roadmaps.json 확인

```bash
# Windows
type roadmaps.json

# Linux/Mac
cat roadmaps.json
```

JSON 파일에 로드맵 데이터가 저장되어 있는지 확인

### 단계 3: 서버 재시작

```bash
dart run bin/server.dart
```

**예상 출력:**
```
[Repo] Loaded 1 roadmaps from file
```

### 단계 4: 데이터 유지 확인

```bash
dart run bin/cli.dart list
```

서버 재시작 전의 로드맵이 그대로 로드되어야 합니다.

## 🎯 체크리스트

다음을 모두 확인했다면 데모 성공입니다:

- ✅ 서버가 정상 기동됨
- ✅ Claude API 호출로 로드맵 생성 성공
- ✅ 목록/상세 조회 동작
- ✅ 로드맵 공개 전환 동작
- ✅ 공개 로드맵 목록 조회 동작
- ✅ 포크 기능 동작 (forkedFrom 필드 확인)
- ✅ 삭제 기능 동작
- ✅ 파일 영속화 동작 (서버 재시작 후 데이터 유지)

## 📊 서버 로그 확인 포인트

서버 터미널에서 다음 로그를 확인하세요:

### 로드맵 생성 시
```
[Handler] Generating roadmap via LLM...
  Goal: 웹 개발 입문 로드맵
  Duration: 2 weeks
  Difficulty: easy
[Handler] Roadmap created: r_1736123456789
```

### 공개 전환 시
```
[Handler] Roadmap shared: r_1736123456789
```

### 포크 시
```
[Handler] Roadmap forked: r_1736123456789 -> r_1736123999999
```

## 🐛 문제 해결

### "Connection refused" 에러
→ 서버가 실행 중인지 확인하세요.

### "ANTHROPIC_API_KEY environment variable is required"
→ 환경변수 설정을 확인하세요.

### "LLM generation failed"
→ API 키가 유효한지, 네트워크 연결이 정상인지 확인하세요.

### 로드맵 생성이 30초 이상 걸림
→ 정상입니다. Claude API 응답은 10-30초 소요될 수 있습니다.

## 📸 스크린샷 촬영 포인트

프로젝트 발표 시 다음 화면을 캡처하면 좋습니다:

1. 서버 기동 화면
2. 로드맵 생성 성공 화면
3. 로드맵 상세 조회 (노드 목록 포함)
4. 공개 로드맵 목록
5. roadmaps.json 파일 내용

---

**Happy Demo! 🚀**
