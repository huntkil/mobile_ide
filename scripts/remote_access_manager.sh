#!/bin/bash

# Android Termux용 통합 원격 접속 관리 스크립트
# Author: Mobile IDE Team
# Version: 1.0.0
# Description: SSH와 VNC를 통합 관리하여 완전한 원격 접속 환경을 제공합니다

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

# 메뉴 표시
show_menu() {
    echo ""
    echo "=========================================="
    echo "  🚀 원격 접속 관리 시스템"
    echo "=========================================="
    echo "1. SSH 서버 설정 및 시작"
    echo "2. VNC 서버 설정 및 시작"
    echo "3. 통합 원격 접속 설정 (SSH + VNC)"
    echo "4. 서버 상태 확인"
    echo "5. 서버 중지"
    echo "6. 연결 정보 표시"
    echo "7. 원격 접속 테스트"
    echo "8. 시스템 정보 확인"
    echo "9. 자동 시작 스크립트 생성"
    echo "0. 종료"
    echo "=========================================="
    echo ""
}

# 시스템 정보 확인
check_system_info() {
    log_info "시스템 정보 확인 중..."
    
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

# SSH 서버 설정 및 시작
setup_ssh_server() {
    log_info "SSH 서버 설정 및 시작 중..."
    
    # OpenSSH 설치
    pkg update -y
    pkg install openssh -y
    
    # SSH 디렉토리 생성
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    # SSH 키 생성 (없는 경우)
    if [ ! -f ~/.ssh/id_rsa ]; then
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    fi
    
    # SSH 서버 시작
    pkill sshd 2>/dev/null || true
    sshd -p 8022 -D &
    
    sleep 2
    if pgrep sshd > /dev/null; then
        log_success "SSH 서버가 시작되었습니다 (포트: 8022)"
    else
        log_error "SSH 서버 시작 실패"
    fi
}

# VNC 서버 설정 및 시작
setup_vnc_server() {
    log_info "VNC 서버 설정 및 시작 중..."
    
    # VNC 패키지 설치
    pkg update -y
    pkg install -y x11vnc tigervnc xorg-server xfce4 openbox twm xterm
    
    # VNC 디렉토리 생성
    mkdir -p ~/.vnc
    chmod 700 ~/.vnc
    
    # VNC 비밀번호 설정
    echo "mobile_ide_vnc" | vncpasswd -f > ~/.vnc/passwd
    chmod 600 ~/.vnc/passwd
    
    # xstartup 파일 생성
    cat > ~/.vnc/xstartup << 'EOF'
#!/bin/bash
xrdb $HOME/.Xresources
xsetroot -solid grey
openbox &
xterm -geometry 80x24+10+10 -ls -title "$VNCDESKTOP Desktop" &
xterm -geometry 80x24+10+100 -ls -title "Cursor AI Terminal" &
EOF
    
    chmod +x ~/.vnc/xstartup
    
    # VNC 서버 시작
    pkill vncserver 2>/dev/null || true
    vncserver :1 -geometry 1024x768 -depth 24 -localhost no -SecurityTypes VncAuth -dpi 96 &
    
    sleep 3
    if pgrep vncserver > /dev/null; then
        log_success "VNC 서버가 시작되었습니다 (포트: 5901)"
    else
        log_error "VNC 서버 시작 실패"
    fi
}

# 통합 원격 접속 설정
setup_integrated_remote() {
    log_info "통합 원격 접속 설정 중..."
    
    setup_ssh_server
    setup_vnc_server
    
    log_success "통합 원격 접속 설정 완료"
}

# 서버 상태 확인
check_server_status() {
    log_info "서버 상태 확인 중..."
    
    echo "=========================================="
    echo "  서버 상태"
    echo "=========================================="
    
    # SSH 서버 상태
    if pgrep sshd > /dev/null; then
        echo "SSH 서버: ✅ 실행 중 (포트: 8022)"
    else
        echo "SSH 서버: ❌ 중지됨"
    fi
    
    # VNC 서버 상태
    if pgrep vncserver > /dev/null; then
        echo "VNC 서버: ✅ 실행 중 (포트: 5901)"
    else
        echo "VNC 서버: ❌ 중지됨"
    fi
    
    # 포트 확인
    echo ""
    echo "열린 포트:"
    netstat -tlnp 2>/dev/null | grep -E ":(8022|5901)" || echo "열린 포트 없음"
    
    echo "=========================================="
}

# 서버 중지
stop_servers() {
    log_info "서버 중지 중..."
    
    pkill sshd 2>/dev/null || true
    pkill vncserver 2>/dev/null || true
    pkill x11vnc 2>/dev/null || true
    
    log_success "모든 서버가 중지되었습니다"
}

# 연결 정보 표시
show_connection_info() {
    log_info "연결 정보:"
    
    local ip_address=$(hostname -I | awk '{print $1}')
    
    echo "=========================================="
    echo "  연결 정보"
    echo "=========================================="
    echo "호스트 IP: $ip_address"
    echo ""
    echo "SSH 연결:"
    echo "  포트: 8022"
    echo "  명령어: ssh -p 8022 $(whoami)@$ip_address"
    echo ""
    echo "VNC 연결:"
    echo "  포트: 5901"
    echo "  주소: $ip_address:5901"
    echo "  비밀번호: mobile_ide_vnc"
    echo ""
    echo "클라이언트 프로그램:"
    echo "  SSH: PuTTY, OpenSSH, Termius"
    echo "  VNC: VNC Viewer, RealVNC Viewer"
    echo "=========================================="
}

# 원격 접속 테스트
test_remote_access() {
    log_info "원격 접속 테스트 중..."
    
    local ip_address=$(hostname -I | awk '{print $1}')
    
    echo "=========================================="
    echo "  원격 접속 테스트"
    echo "=========================================="
    
    # SSH 테스트
    echo "SSH 연결 테스트:"
    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -p 8022 localhost "echo 'SSH 연결 성공!'" 2>/dev/null; then
        echo "  ✅ SSH 연결 성공"
    else
        echo "  ❌ SSH 연결 실패"
    fi
    
    # VNC 포트 테스트
    echo "VNC 포트 테스트:"
    if netstat -tlnp 2>/dev/null | grep -q ":5901"; then
        echo "  ✅ VNC 포트 5901 열림"
    else
        echo "  ❌ VNC 포트 5901 닫힘"
    fi
    
    echo "=========================================="
}

# 자동 시작 스크립트 생성
create_autostart_script() {
    log_info "자동 시작 스크립트 생성 중..."
    
    cat > ~/start_remote_access.sh << 'EOF'
#!/bin/bash
# 원격 접속 자동 시작 스크립트

echo "🚀 원격 접속 서비스 시작..."

# SSH 서버 시작
sshd -p 8022 -D &

# VNC 서버 시작
vncserver :1 -geometry 1024x768 -depth 24 -localhost no -SecurityTypes VncAuth -dpi 96 &

echo "✅ 원격 접속 서비스가 시작되었습니다"
echo "📱 연결 정보:"
echo "SSH: ssh -p 8022 $(whoami)@$(hostname -I | awk '{print $1}')"
echo "VNC: $(hostname -I | awk '{print $1}'):5901 (비밀번호: mobile_ide_vnc)"
echo ""
echo "🔧 서비스 중지: pkill sshd && pkill vncserver"
EOF
    
    chmod +x ~/start_remote_access.sh
    log_success "자동 시작 스크립트 생성 완료: ~/start_remote_access.sh"
}

# 메인 함수
main() {
    while true; do
        show_menu
        read -p "선택하세요 (0-9): " choice
        
        case $choice in
            1)
                setup_ssh_server
                ;;
            2)
                setup_vnc_server
                ;;
            3)
                setup_integrated_remote
                ;;
            4)
                check_server_status
                ;;
            5)
                stop_servers
                ;;
            6)
                show_connection_info
                ;;
            7)
                test_remote_access
                ;;
            8)
                check_system_info
                ;;
            9)
                create_autostart_script
                ;;
            0)
                echo "프로그램을 종료합니다."
                exit 0
                ;;
            *)
                echo "잘못된 선택입니다. 다시 선택해주세요."
                ;;
        esac
        
        echo ""
        read -p "계속하려면 Enter를 누르세요..."
    done
}

# 스크립트 실행
main "$@" 