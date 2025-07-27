#!/bin/bash

echo "=========================================="
echo "  Termux + Termux:X11 완전 새로 시작"
echo "=========================================="

echo "1단계: 기존 프로세스 완전 정리..."
# 모든 관련 프로세스 종료
ps aux | grep -E "(cursor|AppRun|Xvnc|vncserver)" | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null || echo "기존 프로세스 없음"

# VNC 서버 종료
vncserver -kill :1 2>/dev/null || echo "VNC 서버 없음"
vncserver -kill :2 2>/dev/null || echo "VNC 서버 없음"

echo ""
echo "2단계: 패키지 업데이트 및 필수 패키지 설치..."
pkg update -y
pkg upgrade -y

# 필수 패키지 설치
echo "필수 패키지 설치 중..."
pkg install -y \
  proot-distro \
  wget \
  curl \
  git \
  vim \
  nano \
  htop \
  tree \
  unzip \
  tar \
  xz-utils

echo ""
echo "3단계: Termux:X11 설치 및 설정..."
# Termux:X11 설치 (이미 설치되어 있을 수 있음)
pkg install -y x11-repo

# X11 관련 패키지 설치
pkg install -y \
  tigervnc \
  xorg-twm \
  xorg-xterm \
  xorg-fonts-misc \
  openbox \
  lxde-core \
  xsetroot \
  xmessage

echo ""
echo "4단계: Ubuntu 환경 설정..."
# Ubuntu 설치 (이미 설치되어 있을 수 있음)
proot-distro install ubuntu

# Ubuntu 환경 설정
proot-distro login ubuntu -- bash -c "
apt update -y
apt upgrade -y
apt install -y \
  curl \
  wget \
  git \
  vim \
  nano \
  htop \
  tree \
  unzip \
  tar \
  xz-utils \
  dbus \
  dbus-x11 \
  xvfb \
  x11-apps
"

echo ""
echo "5단계: 프로젝트 폴더 정리 및 재설정..."
cd ~
rm -rf mobile_ide 2>/dev/null || echo "기존 프로젝트 폴더 없음"

# Git에서 프로젝트 다시 다운로드
echo "프로젝트 다시 다운로드 중..."
git clone https://github.com/huntkil/mobile_ide.git
cd mobile_ide

echo ""
echo "6단계: VNC 서버 설정..."
# VNC 비밀번호 설정
mkdir -p ~/.vnc
echo "cursor123" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

# VNC 시작 스크립트 생성
cat > ~/.vnc/xstartup << 'EOF'
#!/bin/bash
export XKL_XMODMAP_DISABLE=1
export XDG_RUNTIME_DIR="$HOME/.runtime-cursor"
export XDG_SESSION_TYPE="x11"
export DISPLAY=:1

# 런타임 디렉토리 생성
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# 배경색 설정
xsetroot -solid "#2e3440" &

# 윈도우 매니저 시작
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

# 터미널 시작
if command -v xterm &>/dev/null; then
    xterm -geometry 80x24+50+50 -bg black -fg white -title "Termux Terminal" &
fi

echo "VNC 데스크톱 환경 시작 완료" > /tmp/vnc_startup.log
EOF

chmod +x ~/.vnc/xstartup

echo ""
echo "7단계: Cursor AI AppImage 확인..."
# AppImage 파일이 있는지 확인
if [ -f "./Cursor-1.2.1-aarch64.AppImage" ]; then
    echo "✅ Cursor AI AppImage 발견"
    chmod +x ./Cursor-1.2.1-aarch64.AppImage
    
    # AppImage 추출
    echo "AppImage 추출 중..."
    ./Cursor-1.2.1-aarch64.AppImage --appimage-extract
    
    if [ -d "squashfs-root" ]; then
        echo "✅ AppImage 추출 완료"
    else
        echo "❌ AppImage 추출 실패"
    fi
else
    echo "❌ Cursor AI AppImage 파일이 없습니다"
    echo "WSL에서 ~/mobile_ide 폴더로 Cursor-1.2.1-aarch64.AppImage 파일을 복사해주세요"
fi

echo ""
echo "8단계: 실행 스크립트 생성..."
# VNC 시작 스크립트
cat > start_vnc.sh << 'EOF'
#!/bin/bash
echo "VNC 서버 시작 중..."
vncserver -kill :1 2>/dev/null || echo "기존 VNC 서버 없음"
sleep 2
vncserver :1 -geometry 1024x768 -depth 24 -localhost no -SecurityTypes VncAuth -dpi 96
echo "VNC 서버 시작 완료"
echo "VNC Viewer에서 localhost:5901 접속"
echo "비밀번호: cursor123"
EOF

# Cursor AI 실행 스크립트
cat > run_cursor.sh << 'EOF'
#!/bin/bash
echo "Cursor AI 실행 중..."

# VNC 서버 시작
vncserver :1 -geometry 1024x768 -depth 24 -localhost no -SecurityTypes VncAuth -dpi 96 &
sleep 5

# 환경 변수 설정
export DISPLAY=:1
export XDG_RUNTIME_DIR="$HOME/.runtime-cursor"
export XDG_SESSION_TYPE=x11
export NO_AT_BRIDGE=1
export ELECTRON_DISABLE_SECURITY_WARNINGS=true

# 런타임 디렉토리 생성
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# Cursor AI 실행
if [ -d "squashfs-root" ]; then
    cd squashfs-root
    ./AppRun --no-sandbox --disable-gpu --single-process --max-old-space-size=512 &
    echo "Cursor AI 시작됨"
else
    echo "❌ squashfs-root 폴더가 없습니다. AppImage를 먼저 추출해주세요"
fi

echo "VNC Viewer에서 localhost:5901 접속하세요"
echo "비밀번호: cursor123"
EOF

# 상태 확인 스크립트
cat > check_status.sh << 'EOF'
#!/bin/bash
echo "=== 시스템 상태 확인 ==="
echo ""
echo "실행 중인 프로세스:"
ps aux | grep -E "(cursor|AppRun|Xvnc)" | grep -v grep || echo "실행 중인 프로세스 없음"
echo ""
echo "VNC 포트 확인:"
netstat -tlnp 2>/dev/null | grep 5901 || echo "VNC 포트 5901 비활성"
echo ""
echo "VNC 로그:"
if [ -f ~/.vnc/localhost:1.log ]; then
    tail -5 ~/.vnc/localhost:1.log
else
    echo "VNC 로그 파일 없음"
fi
EOF

# 모든 스크립트에 실행 권한 부여
chmod +x start_vnc.sh run_cursor.sh check_status.sh

echo ""
echo "9단계: 최종 설정 완료..."
echo ""
echo "=========================================="
echo "  Termux + Termux:X11 완전 새로 시작 완료!"
echo "=========================================="
echo ""
echo "사용 가능한 명령어:"
echo "1. VNC 서버 시작: ./start_vnc.sh"
echo "2. Cursor AI 실행: ./run_cursor.sh"
echo "3. 상태 확인: ./check_status.sh"
echo ""
echo "VNC 연결 정보:"
echo "  서버 주소: localhost:5901"
echo "  비밀번호: cursor123"
echo "  해상도: 1024x768"
echo ""
echo "다음 단계:"
echo "1. ./start_vnc.sh 실행"
echo "2. VNC Viewer에서 localhost:5901 접속"
echo "3. ./run_cursor.sh 실행"
echo ""
echo "완전 새로 시작 완료!" 