#!/bin/bash
cd ~

echo "[INFO] Cursor AI 실행 중 (권한 문제 해결)..."

# 안전한 환경 변수 설정
export DISPLAY=:0
export LIBGL_ALWAYS_SOFTWARE=1
export XDG_RUNTIME_DIR="$HOME/.runtime-cursor"

# 런타임 디렉토리 생성
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

echo "[INFO] 환경 변수 설정 완료"
echo "DISPLAY: $DISPLAY"
echo "XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"

# Xvfb 시작 (가능한 경우)
if command -v Xvfb > /dev/null 2>&1; then
    if ! pgrep -x "Xvfb" > /dev/null; then
        echo "[INFO] Xvfb 시작 중..."
        Xvfb :0 -screen 0 1024x768x16 -ac +extension GLX +render -noreset &
        sleep 3
        echo "[INFO] Xvfb 시작됨"
    else
        echo "[INFO] Xvfb가 이미 실행 중"
    fi
else
    echo "[INFO] Xvfb 없음 - 소프트웨어 렌더링 모드"
fi

# Cursor AI 실행
if [ -f "./squashfs-root/AppRun" ]; then
    echo "[INFO] Cursor AI 실행 중..."
    ./squashfs-root/AppRun --no-sandbox --disable-gpu --single-process --disable-dev-shm-usage &
    CURSOR_PID=$!
    echo "[SUCCESS] Cursor AI 실행됨 (PID: $CURSOR_PID)"
    echo "[INFO] 종료하려면: kill $CURSOR_PID"
else
    echo "[ERROR] 실행 파일을 찾을 수 없습니다."
    echo "AppImage 추출: ./cursor.AppImage --appimage-extract"
    exit 1
fi

# 프로세스 상태 확인
sleep 3
if ps -p $CURSOR_PID > /dev/null; then
    echo "[SUCCESS] Cursor AI가 정상적으로 실행 중입니다!"
else
    echo "[WARNING] Cursor AI 프로세스 상태를 확인하세요."
fi 