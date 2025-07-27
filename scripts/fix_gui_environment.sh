#!/bin/bash

# ==========================================
# GUI 환경 수정 및 Cursor AI 실행 스크립트
# ==========================================
# Author: Mobile IDE Team
# Version: 1.0.0

echo "=========================================="
echo "  GUI 환경 수정 및 Cursor AI 실행"
echo "=========================================="
echo ""

echo "1단계: 윈도우 매니저 설치..."
pkg install -y x11-repo
pkg install -y xorg-twm xorg-xterm xorg-fonts-misc 2>/dev/null || echo "일부 패키지 설치 실패 (무시됨)"

echo ""
echo "2단계: VNC 설정 파일 수정..."
cat > ~/.vnc/xstartup << 'EOF'
#!/bin/bash
export XKL_XMODMAP_DISABLE=1
export XDG_RUNTIME_DIR="$HOME/.runtime-cursor"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# 간단한 윈도우 매니저 시작
if command -v twm &>/dev/null; then
    twm &
elif command -v openbox &>/dev/null; then
    openbox &
else
    # 기본 X11 환경만 시작
    xsetroot -solid grey &
fi

# 터미널 시작 (선택사항)
if command -v xterm &>/dev/null; then
    xterm -geometry 80x24+10+10 &
fi
EOF

chmod +x ~/.vnc/xstartup
echo "VNC 설정 파일 수정 완료"

echo ""
echo "3단계: VNC 서버 재시작..."
vncserver -kill :1 2>/dev/null || echo "기존 VNC 서버 없음"
sleep 2
vncserver :1 -geometry 1024x768 -depth 24 -localhost no -SecurityTypes VncAuth &
sleep 5
echo "VNC 서버 재시작 완료"

echo ""
echo "4단계: Cursor AI 실행..."
proot-distro login ubuntu -- bash -c "
cd /home/cursor-ide
export DISPLAY=:1
export XDG_RUNTIME_DIR=\"\$HOME/.runtime-cursor\"
mkdir -p \"\$XDG_RUNTIME_DIR\"
chmod 700 \"\$XDG_RUNTIME_DIR\"

# Cursor AI 실행
./squashfs-root/AppRun --no-sandbox --disable-gpu --single-process --disable-dev-shm-usage --max-old-space-size=1024 &

echo 'Cursor AI 실행 완료'
"

echo ""
echo "5단계: 프로세스 확인..."
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
echo "이제 GUI 환경과 Cursor AI가 모두 실행됩니다."
echo ""
echo "GUI 환경 수정 및 Cursor AI 실행 완료!" 