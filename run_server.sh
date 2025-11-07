#!/bin/bash
# SkillOrbit Project #3 - Server 실행 스크립트 (Linux/Mac)

echo ""
echo "========================================"
echo "  SkillOrbit Project #3 Server"
echo "========================================"
echo ""

# API 키 확인
if [ -z "$OPENAI_API_KEY" ]; then
    echo "[ERROR] OPENAI_API_KEY 환경변수가 설정되지 않았습니다."
    echo ""
    echo "사용법:"
    echo "  export OPENAI_API_KEY=sk-..."
    echo "  ./run_server.sh"
    echo ""
    exit 1
fi

# API 키 마스킹 출력
KEY_START="${OPENAI_API_KEY:0:7}"
KEY_END="${OPENAI_API_KEY: -4}"
echo "[INFO] API Key: ${KEY_START}...${KEY_END}"
echo ""

# 의존성 설치
echo "[INFO] 의존성 설치 중..."
dart pub get
if [ $? -ne 0 ]; then
    echo "[ERROR] 의존성 설치 실패"
    exit 1
fi

echo ""
echo "[INFO] 서버 시작..."
echo ""

# 서버 실행
dart run bin/server.dart
