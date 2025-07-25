#!/bin/bash

# 사용자 권한 문제 해결 스크립트
# Author: Mobile IDE Team
# Version: 1.0.0

set -e

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

# 현재 사용자 정보 확인
check_current_user() {
    log_info "현재 사용자 정보 확인 중..."
    
    echo "현재 사용자: $(whoami)"
    echo "현재 UID: $(id -u)"
    echo "현재 GID: $(id -g)"
    echo "홈 디렉토리: $HOME"
    echo "TERMUX_VERSION: $TERMUX_VERSION"
    echo ""
    
    if [ "$(id -u)" -eq 0 ]; then
        log_error "root 사용자로 실행 중입니다!"
        return 1
    else
        log_success "일반 사용자로 실행 중입니다."
        return 0
    fi
}

# 일반 사용자로 전환 가이드
switch_to_normal_user() {
    log_info "일반 사용자로 전환 가이드..."
    
    echo ""
    echo "=========================================="
    echo "  일반 사용자로 전환 방법"
    echo "=========================================="
    echo ""
    
    # 현재 사용자 목록 확인
    echo "시스템의 사용자 목록:"
    if command -v getent &> /dev/null; then
        getent passwd | grep -E ":[0-9]{4}:" | cut -d: -f1 | sort
    else
        cat /etc/passwd | grep -E ":[0-9]{4}:" | cut -d: -f1 | sort
    fi
    echo ""
    
    echo "일반 사용자로 전환하는 방법:"
    echo ""
    echo "1. 특정 사용자로 전환:"
    echo "   su - [사용자명]"
    echo "   예: su - huntkil"
    echo ""
    echo "2. 또는 새 터미널 세션 시작:"
    echo "   - Termux를 완전히 종료하고 다시 시작"
    echo "   - 또는 새 터미널 탭/창 열기"
    echo ""
    echo "3. 현재 세션에서 사용자 변경:"
    echo "   exit  # root 세션 종료"
    echo "   # 그 후 일반 사용자로 다시 로그인"
    echo ""
}

# Termux 환경 확인 및 설정
check_termux_environment() {
    log_info "Termux 환경 확인 중..."
    
    if [ -n "$TERMUX_VERSION" ]; then
        log_success "Termux 환경이 감지되었습니다."
        echo "Termux 버전: $TERMUX_VERSION"
        
        # Termux 권한 확인
        if [ -d "$HOME/.termux" ]; then
            log_success "Termux 설정 디렉토리 존재"
        else
            log_warning "Termux 설정 디렉토리가 없습니다."
        fi
        
        return 0
    else
        log_warning "Termux 환경이 아닙니다."
        echo "현재 환경: $SHELL"
        echo "PATH: $PATH"
        
        # WSL 환경 확인
        if grep -q Microsoft /proc/version 2>/dev/null; then
            log_info "WSL 환경이 감지되었습니다."
            echo "WSL에서는 Termux 대신 다른 방법을 사용해야 할 수 있습니다."
        fi
        
        return 1
    fi
}

# proot-distro 설치 확인
check_proot_distro() {
    log_info "proot-distro 설치 확인 중..."
    
    if command -v proot-distro &> /dev/null; then
        log_success "proot-distro가 설치되어 있습니다."
        proot-distro --version
        return 0
    else
        log_error "proot-distro가 설치되지 않았습니다."
        
        if [ -n "$TERMUX_VERSION" ]; then
            echo ""
            echo "Termux에서 proot-distro 설치:"
            echo "pkg update"
            echo "pkg install proot-distro"
        else
            echo ""
            echo "현재 환경에서는 proot-distro를 설치할 수 없습니다."
            echo "Termux 환경에서 실행해주세요."
        fi
        
        return 1
    fi
}

# 권한 문제 해결
fix_permissions() {
    log_info "권한 문제 해결 중..."
    
    # 홈 디렉토리 권한 확인
    if [ -w "$HOME" ]; then
        log_success "홈 디렉토리 쓰기 권한 확인"
    else
        log_error "홈 디렉토리 쓰기 권한이 없습니다."
        return 1
    fi
    
    # 실행 권한 확인
    if [ -x "$(dirname "$0")" ]; then
        log_success "스크립트 디렉토리 실행 권한 확인"
    else
        log_warning "스크립트 디렉토리 실행 권한이 제한적입니다."
    fi
    
    return 0
}

# 메인 함수
main() {
    echo "=========================================="
    echo "  사용자 권한 문제 해결 스크립트"
    echo "=========================================="
    echo ""
    
    # 현재 사용자 정보 확인
    if ! check_current_user; then
        echo ""
        log_error "root 사용자로 실행 중입니다!"
        echo ""
        switch_to_normal_user
        exit 1
    fi
    
    # Termux 환경 확인
    check_termux_environment
    
    # proot-distro 확인
    if ! check_proot_distro; then
        echo ""
        log_error "proot-distro 설치가 필요합니다."
        exit 1
    fi
    
    # 권한 문제 해결
    if ! fix_permissions; then
        echo ""
        log_error "권한 문제가 있습니다."
        exit 1
    fi
    
    log_success "모든 권한 문제가 해결되었습니다!"
    echo ""
    echo "이제 Cursor AI 설치를 진행할 수 있습니다:"
    echo "  curl -sSL https://raw.githubusercontent.com/huntkil/mobile_ide/main/scripts/install_from_local.sh | bash"
    echo ""
}

# 스크립트 실행
main "$@" 