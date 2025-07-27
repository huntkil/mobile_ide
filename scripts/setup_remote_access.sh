#!/bin/bash

# Android Termux용 원격 접속 설정 스크립트
# Author: Mobile IDE Team
# Version: 1.0.0
# Description: SSH 서버를 구축하여 원격 접속을 가능하게 합니다

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

# SSH 서버 설치 및 설정
setup_ssh_server() {
    log_info "SSH 서버 설치 및 설정 중..."
    
    # 1. OpenSSH 설치
    log_info "OpenSSH 설치 중..."
    pkg update -y
    pkg install openssh -y
    
    # 2. SSH 설정 파일 생성
    log_info "SSH 설정 파일 생성 중..."
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    # SSH 서버 설정
    cat > ~/.ssh/sshd_config << 'EOF'
Port 8022
Protocol 2
HostKey /data/data/com.termux/files/home/.ssh/ssh_host_rsa_key
HostKey /data/data/com.termux/files/home/.ssh/ssh_host_dsa_key
HostKey /data/data/com.termux/files/home/.ssh/ssh_host_ecdsa_key
HostKey /data/data/com.termux/files/home/.ssh/ssh_host_ed25519_key
UsePrivilegeSeparation no
KeyRegenerationInterval 3600
ServerKeyBits 1024
SyslogFacility AUTH
LogLevel INFO
LoginGraceTime 120
PermitRootLogin yes
StrictModes no
RSAAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
IgnoreRhosts yes
RhostsRSAAuthentication no
HostbasedAuthentication no
PermitEmptyPasswords yes
ChallengeResponseAuthentication no
PasswordAuthentication yes
X11Forwarding yes
X11DisplayOffset 10
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
AcceptEnv LANG LC_*
Subsystem sftp /data/data/com.termux/files/usr/libexec/sftp-server
UsePAM no
EOF
    
    # 3. SSH 키 생성
    log_info "SSH 키 생성 중..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/ssh_host_rsa_key -N ""
    ssh-keygen -t dsa -b 1024 -f ~/.ssh/ssh_host_dsa_key -N ""
    ssh-keygen -t ecdsa -b 521 -f ~/.ssh/ssh_host_ecdsa_key -N ""
    ssh-keygen -t ed25519 -f ~/.ssh/ssh_host_ed25519_key -N ""
    
    # 4. 사용자 키 생성
    log_info "사용자 SSH 키 생성 중..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
    
    # 5. authorized_keys 설정
    log_info "authorized_keys 설정 중..."
    cat ~/.ssh/id_rsa.pub > ~/.ssh/authorized_keys
    cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    
    log_success "SSH 서버 설정 완료"
}

# SSH 서버 시작
start_ssh_server() {
    log_info "SSH 서버 시작 중..."
    
    # 기존 SSH 프로세스 종료
    pkill sshd 2>/dev/null || true
    
    # SSH 서버 시작
    sshd -f ~/.ssh/sshd_config -D &
    
    # 프로세스 확인
    sleep 2
    if pgrep sshd > /dev/null; then
        log_success "SSH 서버가 성공적으로 시작되었습니다"
    else
        log_error "SSH 서버 시작 실패"
        return 1
    fi
}

# 방화벽 설정 (선택사항)
setup_firewall() {
    log_info "방화벽 설정 중..."
    
    # iptables 규칙 추가 (선택사항)
    log_warning "방화벽 설정은 선택사항입니다. 필요시 수동으로 설정하세요."
    log_info "SSH 포트 8022를 열어야 합니다."
}

# 연결 정보 표시
show_connection_info() {
    log_info "연결 정보:"
    echo "=========================================="
    echo "  SSH 연결 정보"
    echo "=========================================="
    echo "호스트: $(hostname -I | awk '{print $1}')"
    echo "포트: 8022"
    echo "사용자: $(whoami)"
    echo "연결 명령어: ssh -p 8022 $(whoami)@$(hostname -I | awk '{print $1}')"
    echo ""
    echo "  SSH 키 정보"
    echo "=========================================="
    echo "공개키 (클라이언트에 복사):"
    cat ~/.ssh/id_rsa.pub
    echo ""
    echo "개인키 (안전하게 보관):"
    cat ~/.ssh/id_rsa
    echo "=========================================="
}

# 원격 접속 테스트
test_remote_access() {
    log_info "원격 접속 테스트 중..."
    
    # 로컬에서 SSH 연결 테스트
    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -p 8022 localhost "echo 'SSH 연결 성공!'"; then
        log_success "로컬 SSH 연결 테스트 성공"
    else
        log_warning "로컬 SSH 연결 테스트 실패"
    fi
}

# 메인 실행 함수
main() {
    echo "🚀 Android Termux 원격 접속 설정 시작..."
    echo ""
    
    # 시스템 정보 수집
    collect_system_info
    
    # 저장공간 확인
    local available_space=$(df /data | awk 'NR==2{printf "%.0f", $4/1024/1024}')
    if [ "$available_space" -lt 1 ]; then
        log_error "저장공간이 부족합니다 (${available_space}GB). 최소 1GB 필요."
        return 1
    fi
    
    # SSH 서버 설치 및 설정
    setup_ssh_server
    
    # SSH 서버 시작
    start_ssh_server
    
    # 방화벽 설정
    setup_firewall
    
    # 연결 정보 표시
    show_connection_info
    
    # 원격 접속 테스트
    test_remote_access
    
    echo ""
    log_success "원격 접속 설정이 완료되었습니다!"
    echo ""
    echo "📱 다음 단계:"
    echo "1. PC에서 SSH 클라이언트로 연결"
    echo "2. 연결 명령어: ssh -p 8022 $(whoami)@$(hostname -I | awk '{print $1}')"
    echo "3. 비밀번호 없이 키 기반 인증으로 연결됩니다"
    echo ""
    echo "🔧 SSH 서버 관리:"
    echo "- 시작: sshd -f ~/.ssh/sshd_config -D &"
    echo "- 중지: pkill sshd"
    echo "- 상태 확인: pgrep sshd"
}

# 스크립트 실행
main "$@" 