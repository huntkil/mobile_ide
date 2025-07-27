#!/bin/bash

# ==========================================
# Cursor AI GUI 시작 스크립트
# ==========================================
# Author: Mobile IDE Team
# Version: 1.0.0

echo "=========================================="
echo "  Cursor AI GUI 시작"
echo "=========================================="
echo ""

echo "1단계: 기존 프로세스 정리..."
ps aux | grep -E "(cursor|AppRun)" | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null || echo "프로세스 없음"
vncserver -kill :1 2>/dev/null || echo "VNC 서버 없음"
sleep 2

echo ""
echo "2단계: VNC 서버 시작..."
vncserver :1 -geometry 1024x768 -depth 24 -localhost no -SecurityTypes VncAuth &
sleep 5
echo "VNC 서버 시작 완료"

echo ""
echo "3단계: Cursor AI 실행..."
proot-distro login ubuntu -- bash -c "
cd /home/cursor-ide
export DISPLAY=:1
export XDG_RUNTIME_DIR=\"\$HOME/.runtime-cursor\"
mkdir -p \"\$XDG_RUNTIME_DIR\"
chmod 700 \"\$XDG_RUNTIME_DIR\"
./squashfs-root/AppRun --no-sandbox --disable-gpu --single-process --disable-dev-shm-usage --max-old-space-size=1024 &
echo 'Cursor AI 실행 완료'
"

echo ""
echo "4단계: 프로세스 확인..."
sleep 3
echo "실행된 프로세스:"
ps aux | grep -E "(cursor|AppRun|Xvnc)" | grep -v grep || echo "실행 중인 프로세스 없음"

echo ""
echo "=========================================="
echo "  연결 정보"
echo "=========================================="
echo ""
echo "VNC 서버 정보:"
echo "  서버 주소: localhost:5901"
echo "  비밀번호: cursor123"
echo "  해상도: 1024x768"
echo ""
echo "Android VNC Viewer 앱에서 위 정보로 접속하세요."
echo ""
echo "Cursor AI GUI 시작 완료!" 