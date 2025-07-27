#!/bin/bash

# Ubuntu 환경 완전 삭제 후 재설치 스크립트
# Author: Mobile IDE Team
# Version: 1.0.0
# Description: Ubuntu 환경을 완전히 지우고 새로 설치합니다

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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
    local command="$1"
    local description="${2:-명령어}"
    
    log_info "$description 실행 중..."
    if eval "$command" 2>/dev/null; then
        log_success "$description 완료"
        return 0
    else
        log_warning "$description 실패 (계속 진행)"
        return 1
    fi
}

# 저장공간 확인 및 정리
check_and_cleanup_storage() {
    log_info "저장공간 확인 및 정리 중..."
    
    # 사용 가능한 공간 확인
    local available_space=$(df /data | awk 'NR==2{printf "%.0f", $4/1024/1024}')
    log_info "현재 사용 가능한 공간: ${available_space}GB"
    
    if [ "$available_space" -lt 8 ]; then
        log_warning "저장공간이 부족합니다 (${available_space}GB). 정리 중..."
        
        # 긴급 정리
        safe_run "pkg clean" "패키지 캐시 정리"
        safe_run "pkg autoclean" "패키지 자동 정리"
        safe_run "rm -rf ~/.cache/*" "사용자 캐시 정리"
        safe_run "rm -rf /tmp/*" "임시 파일 정리"
        safe_run "find ~ -name '*.log' -type f -size +10M -delete" "대용량 로그 파일 정리"
        
        # 정리 후 다시 확인
        available_space=$(df /data | awk 'NR==2{printf "%.0f", $4/1024/1024}')
        log_info "정리 후 사용 가능한 공간: ${available_space}GB"
    fi
    
    if [ "$available_space" -lt 5 ]; then
        log_error "저장공간이 너무 부족합니다 (${available_space}GB). 최소 5GB 필요."
        log_info "Android 설정 → 디바이스 케어 → 저장공간에서 시스템 캐시를 정리하세요."
        return 1
    fi
    
    log_success "저장공간 확인 완료 (${available_space}GB 사용 가능)"
    return 0
}

# Ubuntu 환경 완전 삭제
completely_remove_ubuntu() {
    log_info "Ubuntu 환경 완전 삭제 중..."
    
    # 1. proot-distro로 설치된 Ubuntu 제거
    if proot-distro list | grep -q "ubuntu"; then
        log_info "proot-distro Ubuntu 제거 중..."
        safe_run "proot-distro remove ubuntu" "proot-distro Ubuntu 제거"
    fi
    
    # 2. Ubuntu 디렉토리 완전 삭제
    if [ -d "$HOME/ubuntu" ]; then
        log_info "Ubuntu 디렉토리 삭제 중..."
        safe_run "rm -rf $HOME/ubuntu" "Ubuntu 디렉토리 삭제"
    fi
    
    # 3. Ubuntu 관련 모든 캐시 및 설정 파일 삭제
    log_info "Ubuntu 관련 캐시 및 설정 파일 삭제 중..."
    safe_run "rm -rf $HOME/.local/share/proot-distro/installed-rootfs/ubuntu" "Ubuntu 루트파일시스템 캐시 삭제"
    safe_run "rm -rf $HOME/.cache/proot-distro" "proot-distro 캐시 삭제"
    safe_run "rm -rf $HOME/.config/proot-distro" "proot-distro 설정 삭제"
    safe_run "rm -rf $HOME/.proot-distro" "proot-distro 홈 디렉토리 삭제"
    
    # 4. Ubuntu 관련 임시 파일 삭제
    safe_run "find $HOME -name '*ubuntu*' -type d -exec rm -rf {} +" "Ubuntu 관련 디렉토리 삭제"
    safe_run "find $HOME -name '*ubuntu*' -type f -delete" "Ubuntu 관련 파일 삭제"
    
    # 5. Cursor AI 관련 파일 삭제
    safe_run "rm -rf $HOME/cursor-ide" "Cursor AI 디렉토리 삭제"
    safe_run "find $HOME -name 'cursor.AppImage' -type f -delete" "Cursor AI AppImage 파일 삭제"
    safe_run "find $HOME -name 'squashfs-root' -type d -exec rm -rf {} +" "AppImage 추출 디렉토리 삭제"
    
    # 6. 실행 스크립트 삭제
    safe_run "rm -f $HOME/launch_cursor.sh" "실행 스크립트 삭제"
    safe_run "rm -f $HOME/launch_cursor_with_vnc.sh" "VNC 실행 스크립트 삭제"
    safe_run "rm -f $HOME/start_vnc.sh" "VNC 시작 스크립트 삭제"
    safe_run "rm -f $HOME/check_cursor_status.sh" "상태 확인 스크립트 삭제"
    
    # 7. VNC 관련 파일 삭제
    safe_run "rm -rf $HOME/.vnc" "VNC 설정 디렉토리 삭제"
    safe_run "pkill vncserver" "VNC 서버 프로세스 종료"
    
    log_success "Ubuntu 환경 완전 삭제 완료"
}

# proot-distro 완전 재설치
reinstall_proot_distro() {
    log_info "proot-distro 완전 재설치 중..."
    
    # 1. 기존 proot-distro 제거
    safe_run "pkg remove -y proot-distro" "기존 proot-distro 제거"
    
    # 2. proot-distro 관련 파일 삭제
    safe_run "rm -rf $HOME/.local/share/proot-distro" "proot-distro 공유 데이터 삭제"
    safe_run "rm -rf $HOME/.cache/proot-distro" "proot-distro 캐시 삭제"
    safe_run "rm -rf $HOME/.config/proot-distro" "proot-distro 설정 삭제"
    
    # 3. 패키지 업데이트
    safe_run "pkg update -y" "패키지 업데이트"
    safe_run "pkg upgrade -y" "패키지 업그레이드"
    
    # 4. proot-distro 재설치
    safe_run "pkg install -y proot-distro" "proot-distro 재설치"
    
    # 5. proot-distro 초기화
    safe_run "proot-distro reset" "proot-distro 초기화"
    
    log_success "proot-distro 완전 재설치 완료"
}

# 네트워크 설정 최적화
optimize_network() {
    log_info "네트워크 설정 최적화 중..."
    
    # DNS 서버 설정
    safe_run "echo 'nameserver 8.8.8.8' > /etc/resolv.conf" "Google DNS 설정"
    safe_run "echo 'nameserver 8.8.4.4' >> /etc/resolv.conf" "Google DNS 백업 설정"
    safe_run "echo 'nameserver 1.1.1.1' >> /etc/resolv.conf" "Cloudflare DNS 설정"
    safe_run "echo 'nameserver 208.67.222.222' >> /etc/resolv.conf" "OpenDNS 설정"
    
    # 네트워크 연결 테스트
    if nslookup google.com >/dev/null 2>&1; then
        log_success "DNS 확인 성공"
    else
        log_warning "DNS 확인 실패 (계속 진행)"
    fi
    
    if curl -s --connect-timeout 10 https://www.google.com >/dev/null; then
        log_success "HTTP 연결 확인 성공"
    else
        log_warning "HTTP 연결 확인 실패 (계속 진행)"
    fi
}

# Ubuntu 환경 새로 설치
install_fresh_ubuntu() {
    log_info "Ubuntu 환경 새로 설치 중..."
    
    # Ubuntu 설치
    if proot-distro install ubuntu; then
        log_success "Ubuntu 환경 새로 설치 성공!"
        return 0
    else
        log_error "Ubuntu 환경 새로 설치 실패"
        return 1
    fi
}

# 설치 확인
verify_installation() {
    log_info "Ubuntu 환경 설치 확인 중..."
    
    # Ubuntu 환경 확인
    if [ -d "$HOME/ubuntu" ]; then
        log_success "Ubuntu 디렉토리 확인됨"
    else
        log_error "Ubuntu 디렉토리가 없습니다"
        return 1
    fi
    
    # proot-distro 확인
    if proot-distro list | grep -q "ubuntu"; then
        log_success "proot-distro Ubuntu 확인됨"
    else
        log_error "proot-distro Ubuntu가 없습니다"
        return 1
    fi
    
    # Ubuntu 환경 테스트
    if proot-distro login ubuntu -- echo "Ubuntu 환경 테스트 성공"; then
        log_success "Ubuntu 환경 테스트 성공"
    else
        log_error "Ubuntu 환경 테스트 실패"
        return 1
    fi
    
    log_success "Ubuntu 환경 설치 확인 완료"
    return 0
}

# 메인 함수
main() {
    echo "=========================================="
    echo "  Ubuntu 환경 완전 삭제 후 재설치"
    echo "=========================================="
    echo "버전: 1.0.0"
    echo "작성자: Mobile IDE Team"
    echo "날짜: $(date)"
    echo "=========================================="
    echo ""
    
    log_warning "⚠️  주의: 이 스크립트는 모든 Ubuntu 환경과 관련 파일을 완전히 삭제합니다!"
    log_warning "⚠️  Cursor AI, VNC 설정, 모든 프로젝트 파일이 삭제됩니다!"
    echo ""
    
    read -p "정말로 계속하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "작업이 취소되었습니다."
        exit 0
    fi
    
    log_info "Ubuntu 환경 완전 삭제 후 재설치 시작..."
    
    # 1. 저장공간 확인 및 정리
    if ! check_and_cleanup_storage; then
        log_error "저장공간 부족으로 작업을 중단합니다."
        exit 1
    fi
    
    # 2. Ubuntu 환경 완전 삭제
    completely_remove_ubuntu
    
    # 3. proot-distro 완전 재설치
    reinstall_proot_distro
    
    # 4. 네트워크 설정 최적화
    optimize_network
    
    # 5. Ubuntu 환경 새로 설치
    if ! install_fresh_ubuntu; then
        log_error "Ubuntu 환경 새로 설치 실패"
        echo ""
        echo "=========================================="
        echo "  해결 방법"
        echo "=========================================="
        echo "1. Android 설정 → 디바이스 케어 → 저장공간"
        echo "   - 시스템 캐시 정리"
        echo "   - 앱 데이터 정리"
        echo ""
        echo "2. Termux 재설치"
        echo "   - Google Play Store에서 Termux 재설치"
        echo ""
        echo "3. 수동 설치"
        echo "   - https://f-droid.org/en/packages/com.termux/"
        echo ""
        exit 1
    fi
    
    # 6. 설치 확인
    if ! verify_installation; then
        log_error "Ubuntu 환경 설치 확인 실패"
        exit 1
    fi
    
    echo ""
    echo "=========================================="
    echo "  완전 삭제 후 재설치 완료!"
    echo "=========================================="
    echo ""
    echo "✅ Ubuntu 환경이 완전히 새로 설치되었습니다!"
    echo ""
    echo "다음 단계:"
    echo "1. ./scripts/perfect_cursor_setup.sh 실행"
    echo "2. 또는 ./launch_cursor.sh 실행"
    echo ""
    echo "📝 참고:"
    echo "- 모든 기존 데이터가 삭제되었습니다"
    echo "- Cursor AI를 다시 설치해야 합니다"
    echo "- VNC 설정을 다시 해야 합니다"
    echo ""
    
    log_success "Ubuntu 환경 완전 삭제 후 재설치 완료!"
}

# 스크립트 실행
main "$@" 