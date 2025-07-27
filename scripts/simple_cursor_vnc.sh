#!/bin/bash

# ==========================================
# Cursor AI + VNC 간단 실행 스크립트
# ==========================================
# Author: Mobile IDE Team
# Version: 1.0.0

echo "=========================================="
echo "  Cursor AI + VNC 간단 실행"
echo "=========================================="
echo ""

echo "1단계: 기존 프로세스 정리..."
pkill -f "cursor" 2>/dev/null || echo "Cursor 프로세스 없음"
pkill -f "AppRun" 2>/dev/null || echo "AppRun 프로세스 없음"
vncserver -kill :1 2>/dev/null || echo "VNC 서버 없음"
sleep 2

echo ""
echo "2단계: VNC 서버 시작..."
if command -v vncserver &>/dev/null; then
    echo "TigerVNC 서버 시작 중..."
    vncserver :1 -geometry 1024x768 -depth 24 -localhost no -SecurityTypes VncAuth &
    sleep 5
    echo "VNC 서버 시작 완료"
else
    echo "VNC 서버를 찾을 수 없습니다."
    echo "VNC 서버를 먼저 설치하세요: ./scripts/install_vnc_server.sh"
    exit 1
fi

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
echo "관리 명령어:"
echo "  프로세스 확인: ps aux | grep -E '(cursor|AppRun|Xvnc)' | grep -v grep"
echo "  프로세스 종료: pkill -f 'cursor' && vncserver -kill :1"
echo "  재시작: ./simple_cursor_vnc.sh"
echo ""
echo "Cursor AI + VNC 서버 실행 완료!"
echo "이제 VNC Viewer에서 localhost:5901에 접속하면 Cursor AI 화면을 볼 수 있습니다." 