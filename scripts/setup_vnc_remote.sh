#!/bin/bash

# Android Termux용 VNC 원격 접속 설정 스크립트
# Author: Mobile IDE Team
# Version: 1.0.0
# Description: VNC 서버를 설정하여 GUI 원격 접속을 가능하게 합니다

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

log_debug() {
    echo -e "${PURPLE}[DEBUG]${NC} $1"
}

# 시스템 정보 수집
collect_system_info() {
    log_info "시스템 정보 수집 중..."
    
    echo "=========================================="
    echo "  시스템 정보"
    echo "=========================================="
    echo "Android 버전: $(getprop ro.build.version.release)"
    echo "Android API: $(getprop ro.build.version.sdk)"
    echo "아키텍처: $(uname -m)"
    echo "호스트명: $(hostname)"
    echo "IP 주소: $(hostname -I)"
    echo "메모리: $(free -h | awk 'NR==2{print $2}')"
    echo "저장공간: $(df -h /data | awk 'NR==2{print $4}') 사용 가능"
    echo "=========================================="
    echo ""
}

# VNC 서버 설치 및 설정
setup_vnc_server() {
    log_info "VNC 서버 설치 및 설정 중..."
    
    # 1. 필수 패키지 설치
    log_info "필수 패키지 설치 중..."
    pkg update -y
    pkg install -y x11vnc tigervnc xorg-server xfce4 openbox twm xterm
    
    # 2. VNC 디렉토리 생성
    log_info "VNC 디렉토리 생성 중..."
    mkdir -p ~/.vnc
    chmod 700 ~/.vnc
    
    # 3. VNC 비밀번호 설정
    log_info "VNC 비밀번호 설정 중..."
    echo "mobile_ide_vnc" | vncpasswd -f > ~/.vnc/passwd
    chmod 600 ~/.vnc/passwd
    
    # 4. xstartup 파일 생성
    log_info "xstartup 파일 생성 중..."
    cat > ~/.vnc/xstartup << 'EOF'
#!/bin/bash
export XKL_XMODMAP_DISABLE=1
export XDG_CURRENT_DESKTOP="XFCE"
export XDG_SESSION_DESKTOP="xfce"
export XDG_SESSION_TYPE="x11"
export XDG_SESSION_CLASS="user"
export XDG_RUNTIME_DIR="/tmp/runtime-$(whoami)"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# X11 환경 설정
xrdb $HOME/.Xresources
xsetroot -solid grey
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce

# 윈도우 매니저 시작
openbox &
# 또는 twm &
# 또는 startxfce4 &

# 터미널 시작
xterm -geometry 80x24+10+10 -ls -title "$VNCDESKTOP Desktop" &
xterm -geometry 80x24+10+100 -ls -title "Cursor AI Terminal" &

# Cursor AI 시작 (선택사항)
# cd ~/squashfs-root && ./AppRun --no-sandbox --disable-gpu --single-process --max-old-space-size=512 &
EOF
    
    chmod +x ~/.vnc/xstartup
    
    # 5. VNC 서버 설정 파일 생성
    log_info "VNC 서버 설정 파일 생성 중..."
    cat > ~/.vnc/config << 'EOF'
$geometry = "1024x768";
$localhost = "no";
$SecurityTypes = "VncAuth";
$passwordFile = "/data/data/com.termux/files/home/.vnc/passwd";
$Log = "*:stderr:100";
EOF
    
    log_success "VNC 서버 설정 완료"
}

# VNC 서버 시작
start_vnc_server() {
    log_info "VNC 서버 시작 중..."
    
    # 기존 VNC 프로세스 종료
    pkill vncserver 2>/dev/null || true
    pkill x11vnc 2>/dev/null || true
    
    # VNC 서버 시작
    vncserver :1 -geometry 1024x768 -depth 24 -localhost no -SecurityTypes VncAuth -dpi 96 &
    
    # 프로세스 확인
    sleep 3
    if pgrep vncserver > /dev/null; then
        log_success "VNC 서버가 성공적으로 시작되었습니다"
    else
        log_error "VNC 서버 시작 실패"
        return 1
    fi
}

# X11VNC 서버 시작 (대안)
start_x11vnc_server() {
    log_info "X11VNC 서버 시작 중..."
    
    # X11VNC 서버 시작
    x11vnc -display :1 -forever -shared -rfbauth ~/.vnc/passwd -rfbport 5901 &
    
    # 프로세스 확인
    sleep 2
    if pgrep x11vnc > /dev/null; then
        log_success "X11VNC 서버가 성공적으로 시작되었습니다"
    else
        log_warning "X11VNC 서버 시작 실패"
    fi
}

# 방화벽 설정
setup_firewall() {
    log_info "방화벽 설정 중..."
    
    # VNC 포트 열기 (선택사항)
    log_warning "방화벽 설정은 선택사항입니다. 필요시 수동으로 설정하세요."
    log_info "VNC 포트 5901을 열어야 합니다."
}

# 연결 정보 표시
show_connection_info() {
    log_info "연결 정보:"
    echo "=========================================="
    echo "  VNC 연결 정보"
    echo "=========================================="
    echo "호스트: $(hostname -I | awk '{print $1}')"
    echo "포트: 5901"
    echo "비밀번호: mobile_ide_vnc"
    echo "연결 명령어: vncviewer $(hostname -I | awk '{print $1}'):5901"
    echo ""
    echo "  클라이언트 연결 방법"
    echo "=========================================="
    echo "1. PC에서 VNC Viewer 설치"
    echo "2. 새 연결 생성"
    echo "3. 주소: $(hostname -I | awk '{print $1}'):5901"
    echo "4. 비밀번호: mobile_ide_vnc"
    echo "5. 연결 클릭"
    echo ""
    echo "  모바일 VNC 클라이언트"
    echo "=========================================="
    echo "Android: VNC Viewer (Google Play)"
    echo "iOS: VNC Viewer (App Store)"
    echo "Windows: RealVNC Viewer"
    echo "macOS: Screen Sharing"
    echo "Linux: Remmina, Vinagre"
    echo "=========================================="
}

# 원격 접속 테스트
test_vnc_access() {
    log_info "VNC 원격 접속 테스트 중..."
    
    # VNC 포트 확인
    if netstat -tlnp 2>/dev/null | grep -q ":5901"; then
        log_success "VNC 포트 5901이 열려있습니다"
    else
        log_warning "VNC 포트 5901이 열려있지 않습니다"
    fi
    
    # VNC 프로세스 확인
    if pgrep vncserver > /dev/null; then
        log_success "VNC 서버가 실행 중입니다"
    else
        log_warning "VNC 서버가 실행되지 않았습니다"
    fi
}

# 자동 시작 스크립트 생성
create_autostart_script() {
    log_info "자동 시작 스크립트 생성 중..."
    
    cat > ~/start_vnc_remote.sh << 'EOF'
#!/bin/bash
# VNC 원격 접속 자동 시작 스크립트

echo "🚀 VNC 원격 접속 시작..."

# VNC 서버 시작
vncserver :1 -geometry 1024x768 -depth 24 -localhost no -SecurityTypes VncAuth -dpi 96 &

# X11VNC 서버 시작
x11vnc -display :1 -forever -shared -rfbauth ~/.vnc/passwd -rfbport 5901 &

echo "✅ VNC 서버가 시작되었습니다"
echo "📱 연결 정보:"
echo "호스트: $(hostname -I | awk '{print $1}')"
echo "포트: 5901"
echo "비밀번호: mobile_ide_vnc"
echo ""
echo "🔧 서버 중지: pkill vncserver && pkill x11vnc"
EOF
    
    chmod +x ~/start_vnc_remote.sh
    log_success "자동 시작 스크립트 생성 완료"
}

# 메인 실행 함수
main() {
    echo "🚀 Android Termux VNC 원격 접속 설정 시작..."
    echo ""
    
    # 시스템 정보 수집
    collect_system_info
    
    # 저장공간 확인
    local available_space=$(df /data | awk 'NR==2{printf "%.0f", $4/1024/1024}')
    if [ "$available_space" -lt 2 ]; then
        log_error "저장공간이 부족합니다 (${available_space}GB). 최소 2GB 필요."
        return 1
    fi
    
    # VNC 서버 설치 및 설정
    setup_vnc_server
    
    # VNC 서버 시작
    start_vnc_server
    
    # X11VNC 서버 시작
    start_x11vnc_server
    
    # 방화벽 설정
    setup_firewall
    
    # 자동 시작 스크립트 생성
    create_autostart_script
    
    # 연결 정보 표시
    show_connection_info
    
    # 원격 접속 테스트
    test_vnc_access
    
    echo ""
    log_success "VNC 원격 접속 설정이 완료되었습니다!"
    echo ""
    echo "📱 다음 단계:"
    echo "1. PC에서 VNC Viewer로 연결"
    echo "2. 주소: $(hostname -I | awk '{print $1}'):5901"
    echo "3. 비밀번호: mobile_ide_vnc"
    echo ""
    echo "🔧 VNC 서버 관리:"
    echo "- 시작: ./start_vnc_remote.sh"
    echo "- 중지: pkill vncserver && pkill x11vnc"
    echo "- 상태 확인: pgrep vncserver && pgrep x11vnc"
}

# 스크립트 실행
main "$@" 