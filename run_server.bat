@echo off
REM SkillOrbit Project #3 - Server 실행 스크립트 (Windows)

echo.
echo ========================================
echo  SkillOrbit Project #3 Server
echo ========================================
echo.

REM API 키 확인
if "%OPENAI_API_KEY%"=="" (
    echo [ERROR] OPENAI_API_KEY 환경변수가 설정되지 않았습니다.
    echo.
    echo 사용법:
    echo   set OPENAI_API_KEY=sk-...
    echo   run_server.bat
    echo.
    pause
    exit /b 1
)

echo [INFO] API Key: %OPENAI_API_KEY:~0,7%...%OPENAI_API_KEY:~-4%
echo.

REM 의존성 설치
echo [INFO] 의존성 설치 중...
call dart pub get
if errorlevel 1 (
    echo [ERROR] 의존성 설치 실패
    pause
    exit /b 1
)

echo.
echo [INFO] 서버 시작...
echo.

REM 서버 실행
dart run bin/server.dart

pause
