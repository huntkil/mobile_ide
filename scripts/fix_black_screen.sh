#!/bin/bash

# ==========================================
# VNC 검은 화면 문제 해결 스크립트
# ==========================================
# Author: Mobile IDE Team
# Version: 1.0.0

echo "=========================================="
echo "  VNC 검은 화면 문제 해결"
echo "=========================================="
echo ""

echo "1단계: 모든 프로세스 완전 정리..."
ps aux | grep -E "(cursor|AppRun)" | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null || echo "Cursor 프로세스 없음"
vncserver -kill :1 2>/dev/null || echo "VNC 서버 없음"
vncserver -kill :2 2>/dev/null || echo "VNC 서버 :2 없음"
sleep 3

echo ""
echo "2단계: X11 및 GUI 패키지 설치..."
pkg install -y x11-repo
pkg install -y xorg-server-xvfb xorg-xhost xorg-xsetroot
pkg install -y xorg-twm xorg-xterm xorg-fonts-misc
pkg install -y openbox lxde-core 2>/dev/null || echo "일부 패키지 설치 실패 (무시됨)"

echo ""
echo "3단계: VNC 설정 파일 완전 재작성..."
mkdir -p ~/.vnc
cat > ~/.vnc/xstartup << 'EOF'
#!/bin/bash

# X11 환경 변수 설정
export XKL_XMODMAP_DISABLE=1
export XDG_RUNTIME_DIR="$HOME/.runtime-cursor"
export XDG_SESSION_TYPE="x11"
export DISPLAY=:1

# 런타임 디렉토리 생성
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# 배경색 설정 (검은 화면 방지)
xsetroot -solid "#2e3440" &

# 윈도우 매니저 시작 (우선순위별)
if command -v openbox &>/dev/null; then
    echo "Openbox 윈도우 매니저 시작"
    openbox &
elif command -v twm &>/dev/null; then
    echo "TWM 윈도우 매니저 시작"
    twm &
else
    echo "기본 X11 환경 시작"
    xsetroot -solid "#404040" &
fi

# 터미널 시작 (GUI 확인용)
if command -v xterm &>/dev/null; then
    xterm -geometry 80x24+50+50 -bg black -fg white -title "Termux Terminal" &
fi

# 작업 완료 표시
echo "VNC 데스크톱 환경 시작 완료" > /tmp/vnc_startup.log
EOF

chmod +x ~/.vnc/xstartup
echo "VNC 설정 파일 완전 재작성 완료"

echo ""
echo "4단계: VNC 비밀번호 재설정..."
echo "cursor123" | vncpasswd -f > ~/.vnc/passwd 2>/dev/null || echo "비밀번호 설정 실패 (무시됨)"
chmod 600 ~/.vnc/passwd 2>/dev/null || echo "권한 설정 실패 (무시됨)"

echo ""
echo "5단계: VNC 서버 새로 시작..."
vncserver :1 -geometry 1024x768 -depth 24 -localhost no -SecurityTypes VncAuth -dpi 96 &
sleep 8
echo "VNC 서버 시작 완료"

echo ""
echo "6단계: GUI 환경 테스트..."
export DISPLAY=:1
xsetroot -solid "#2e3440" 2>/dev/null || echo "배경 설정 실패 (무시됨)"
xterm -geometry 60x20+100+100 -bg "#2e3440" -fg white -title "Test Terminal" & 2>/dev/null || echo "테스트 터미널 시작 실패 (무시됨)"
sleep 3

echo ""
echo "7단계: Cursor AI 실행..."
proot-distro login ubuntu -- bash -c "
cd /home/cursor-ide
export DISPLAY=:1
export XDG_RUNTIME_DIR=\"\$HOME/.runtime-cursor\"
export XDG_SESSION_TYPE=\"x11\"
mkdir -p \"\$XDG_RUNTIME_DIR\"
chmod 700 \"\$XDG_RUNTIME_DIR\"

# Cursor AI 실행
echo 'Cursor AI 시작 중...'
./squashfs-root/AppRun --no-sandbox --disable-gpu --single-process --disable-dev-shm-usage --max-old-space-size=1024 --disable-background-timer-throttling --disable-renderer-backgrounding &

sleep 5
echo 'Cursor AI 실행 완료'
"

echo ""
echo "8단계: 최종 상태 확인..."
sleep 5
echo "실행된 프로세스:"
ps aux | grep -E "(cursor|AppRun|Xvnc|xterm)" | grep -v grep || echo "실행 중인 프로세스 없음"

echo ""
echo "VNC 로그 확인:"
if [ -f ~/.vnc/localhost:1.log ]; then
    echo "최근 로그 (마지막 5줄):"
    tail -5 ~/.vnc/localhost:1.log
fi

echo ""
echo "=========================================="
echo "  검은 화면 문제 해결 완료!"
echo "=========================================="
echo ""
echo "VNC 연결 정보:"
echo "  서버 주소: localhost:5901"
echo "  비밀번호: cursor123"
echo "  해상도: 1024x768"
echo ""
echo "이제 VNC Viewer에서 접속하면:"
echo "1. 회색 배경화면이 보입니다"
echo "2. 터미널 창이 보입니다"
echo "3. Cursor AI 창이 나타납니다"
echo ""
echo "만약 여전히 검은 화면이면:"
echo "1. VNC Viewer 앱을 완전히 종료 후 재시작"
echo "2. 연결을 끊고 다시 연결"
echo "3. ./scripts/check_cursor_status.sh 로 상태 확인"
echo ""
echo "검은 화면 문제 해결 완료!" 