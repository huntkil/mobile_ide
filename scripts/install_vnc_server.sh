#!/bin/bash

# ==========================================
# VNC 서버 설치 및 설정 스크립트
# ==========================================
# Author: Mobile IDE Team
# Version: 1.0.0

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 로그 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 안전한 명령어 실행 함수
safe_run() {
    local cmd="$1"
    local description="$2"
    
    log_info "$description"
    if eval "$cmd" 2>/dev/null; then
        log_success "$description 완료"
        return 0
    else
        log_warning "$description 실패 (무시됨)"
        return 1
    fi
}

# 메인 함수
main() {
    echo "=========================================="
    echo "  VNC 서버 설치 및 설정 스크립트"
    echo "=========================================="
    echo ""
    
    log_info "VNC 서버 설치 시작..."
    
    # 1. Termux에서 VNC 서버 설치
    log_info "Termux에서 VNC 서버 설치 중..."
    safe_run "pkg install -y tigervnc" "TigerVNC 서버 설치"
    safe_run "pkg install -y x11vnc" "x11vnc 서버 설치"
    safe_run "pkg install -y tightvnc" "TightVNC 서버 설치"
    
    # 2. Ubuntu 환경에서 VNC 서버 설치
    log_info "Ubuntu 환경에서 VNC 서버 설치 중..."
    proot-distro login ubuntu -- bash -c "
        apt update -y || echo '패키지 업데이트 실패 (무시됨)'
        apt install -y tigervnc-standalone-server tigervnc-common || echo 'TigerVNC 설치 실패 (무시됨)'
        apt install -y x11vnc || echo 'x11vnc 설치 실패 (무시됨)'
        apt install -y tightvncserver || echo 'TightVNC 설치 실패 (무시됨)'
        apt install -y xvfb x11-apps x11-utils x11-xserver-utils dbus-x11 || echo 'X11 패키지 설치 실패 (무시됨)'
        echo 'Ubuntu VNC 서버 설치 완료'
    " || log_warning "Ubuntu VNC 서버 설치 중 일부 오류 발생 (무시됨)"
    
    # 3. VNC 비밀번호 설정
    log_info "VNC 비밀번호 설정 중..."
    mkdir -p ~/.vnc
    echo "cursor123" | vncpasswd -f > ~/.vnc/passwd 2>/dev/null || log_warning "VNC 비밀번호 설정 실패 (무시됨)"
    chmod 600 ~/.vnc/passwd 2>/dev/null || log_warning "VNC 비밀번호 파일 권한 설정 실패 (무시됨)"
    
    # 4. VNC 설정 파일 생성
    log_info "VNC 설정 파일 생성 중..."
    cat > ~/.vnc/xstartup << 'EOF'
#!/bin/bash
export XKL_XMODMAP_DISABLE=1
export XDG_CURRENT_DESKTOP="XFCE"
export XDG_SESSION_DESKTOP="xfce"
export XDG_MENU_PREFIX="xfce-"
export XDG_CONFIG_DIRS="/etc/xdg/xdg-xfce:/etc/xdg"
export XDG_DATA_DIRS="/usr/share/xfce4:/usr/share/xdg:/usr/share"
export DESKTOP_SESSION="xfce"
export XDG_SESSION_TYPE="x11"
export XDG_SESSION_CLASS="user"
export XDG_RUNTIME_DIR="$HOME/.runtime-cursor"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# Xfce4 시작 (가능한 경우)
if command -v startxfce4 &>/dev/null; then
    startxfce4 &
elif command -v xfce4-session &>/dev/null; then
    xfce4-session &
else
    # 기본 터미널 시작
    xterm -geometry 80x24+10+10 -ls -title "$VNCDESKTOP Desktop" &
    twm &
fi
EOF
    
    chmod +x ~/.vnc/xstartup
    log_success "VNC 설정 파일 생성 완료"
    
    # 5. VNC 서버 시작 스크립트 업데이트
    log_info "VNC 서버 시작 스크립트 업데이트 중..."
    cat > ./start_vnc.sh << 'EOF'
#!/bin/bash
echo "=========================================="
echo "  VNC 서버 시작 중..."
echo "=========================================="

# 기존 VNC 서버 종료
vncserver -kill :1 2>/dev/null || true
x11vnc -kill 2>/dev/null || true

# VNC 서버 시작 (여러 방법 시도)
echo "VNC 서버 시작 중..."

# 방법 1: TigerVNC
if command -v vncserver &>/dev/null; then
    echo "TigerVNC 서버 시작 중..."
    vncserver :1 -geometry 1024x768 -depth 24 -localhost no -SecurityTypes VncAuth &
    sleep 3
    echo "TigerVNC 서버 시작 완료"
elif command -v tightvncserver &>/dev/null; then
    echo "TightVNC 서버 시작 중..."
    tightvncserver :1 -geometry 1024x768 -depth 24 -localhost no &
    sleep 3
    echo "TightVNC 서버 시작 완료"
elif command -v x11vnc &>/dev/null; then
    echo "x11vnc 서버 시작 중..."
    x11vnc -display :0 -rfbport 5901 -forever -shared -localhost no &
    sleep 3
    echo "x11vnc 서버 시작 완료"
else
    echo "VNC 서버를 찾을 수 없습니다."
    echo "VNC 서버 설치를 확인하세요."
    exit 1
fi

echo "VNC 서버가 시작되었습니다."
echo "Android VNC Viewer 앱에서 localhost:5901에 접속하세요."
echo "비밀번호: cursor123"
echo ""
echo "VNC 서버 상태 확인:"
ps aux | grep -E "(vnc|x11vnc)" | grep -v grep || echo "VNC 서버가 실행되지 않았습니다."
EOF
    
    chmod +x ./start_vnc.sh
    log_success "VNC 서버 시작 스크립트 업데이트 완료"
    
    # 6. VNC 서버 상태 확인
    log_info "VNC 서버 설치 확인 중..."
    echo ""
    echo "설치된 VNC 서버:"
    command -v vncserver && echo "✓ TigerVNC 서버"
    command -v tightvncserver && echo "✓ TightVNC 서버"
    command -v x11vnc && echo "✓ x11vnc 서버"
    
    # 7. 설치 완료 메시지
    echo ""
    echo "=========================================="
    echo "  VNC 서버 설치 완료!"
    echo "=========================================="
    echo ""
    echo "사용 가능한 VNC 명령어:"
    echo ""
    echo "1. VNC 서버 시작:"
    echo "   ./start_vnc.sh"
    echo ""
    echo "2. 직접 VNC 서버 시작:"
    echo "   vncserver :1 -geometry 1024x768 -depth 24 -localhost no"
    echo "   tightvncserver :1 -geometry 1024x768 -depth 24 -localhost no"
    echo "   x11vnc -display :0 -rfbport 5901 -forever -shared -localhost no"
    echo ""
    echo "3. VNC 서버 종료:"
    echo "   vncserver -kill :1"
    echo ""
    echo "4. VNC 서버 상태 확인:"
    echo "   ps aux | grep -E '(vnc|x11vnc)' | grep -v grep"
    echo ""
    echo "5. Android VNC Viewer 앱에서 localhost:5901 접속"
    echo "   비밀번호: cursor123"
    echo ""
    
    log_success "VNC 서버 설치 및 설정 완료!"
}

# 스크립트 실행
main "$@" 