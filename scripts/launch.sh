#!/bin/bash

# Galaxy Android용 Cursor AI IDE 실행 스크립트
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

# 시스템 상태 확인
check_system_status() {
    log_info "시스템 상태 확인 중..."
    
    # 메모리 확인
    local available_memory=$(free -m | grep Mem | awk '{print $7}')
    if [ "$available_memory" -lt 2048 ]; then
        log_warning "사용 가능한 메모리가 부족합니다. (${available_memory}MB)"
        log_info "다른 앱을 종료하고 다시 시도하세요."
    fi
    
    # 저장공간 확인
    local available_space=$(df -m /data | tail -1 | awk '{print $4}')
    if [ "$available_space" -lt 5120 ]; then
        log_warning "사용 가능한 저장공간이 부족합니다. (${available_space}MB)"
        log_info "불필요한 파일을 삭제하고 다시 시도하세요."
    fi
}

# X11 환경 설정
setup_x11_environment() {
    log_info "X11 환경 설정 중..."
    
    # DISPLAY 변수 설정
    export DISPLAY=:0
    
    # Xvfb 프로세스 확인 및 시작
    if ! pgrep -x "Xvfb" > /dev/null; then
        log_info "X11 가상 디스플레이 시작 중..."
        Xvfb :0 -screen 0 1200x800x24 -ac +extension GLX +render -noreset &
        sleep 3
        
        if ! pgrep -x "Xvfb" > /dev/null; then
            log_error "Xvfb 시작에 실패했습니다."
            exit 1
        fi
        log_success "Xvfb 시작 완료"
    else
        log_info "Xvfb가 이미 실행 중입니다."
    fi
}

# Ubuntu 환경 확인
check_ubuntu_environment() {
    log_info "Ubuntu 환경 확인 중..."
    
    if [ ! -d "$HOME/ubuntu" ]; then
        log_error "Ubuntu 환경이 설치되지 않았습니다."
        log_info "다음 명령어로 설치를 진행하세요:"
        echo "  bash setup.sh"
        exit 1
    fi
    
    log_success "Ubuntu 환경 확인 완료"
}

# Cursor AI 실행
launch_cursor_ai() {
    log_info "Cursor AI 실행 중..."
    
    # Ubuntu 환경으로 이동
    cd "$HOME/ubuntu/home/cursor-ide"
    
    # Cursor AI 실행 방법 결정
    if [ -f "cursor.AppImage" ]; then
        log_info "Cursor AI AppImage 실행 중..."
        proot-distro login ubuntu -- ./cursor.AppImage
    elif [ -d "squashfs-root" ]; then
        log_info "Cursor AI 추출된 버전 실행 중..."
        proot-distro login ubuntu -- ./squashfs-root/cursor
    else
        log_error "Cursor AI를 찾을 수 없습니다."
        log_info "설치를 다시 진행하세요:"
        echo "  bash setup.sh"
        exit 1
    fi
}

# 성능 최적화
optimize_performance() {
    log_info "성능 최적화 적용 중..."
    
    # 메모리 캐시 정리
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    
    # CPU 성능 모드 설정
    echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || true
    
    # 배터리 최적화 비활성화 (성능 우선)
    log_info "배터리 최적화 비활성화..."
    
    log_success "성능 최적화 완료"
}

# 정리 함수
cleanup() {
    log_info "정리 작업 중..."
    
    # Xvfb 프로세스 종료 (선택적)
    # pkill Xvfb 2>/dev/null || true
    
    log_success "정리 완료"
}

# 시그널 핸들러
trap cleanup EXIT

# 메인 함수
main() {
    echo "=========================================="
    echo "  Cursor AI IDE 실행"
    echo "=========================================="
    echo ""
    
    # 시스템 상태 확인
    check_system_status
    echo ""
    
    # Ubuntu 환경 확인
    check_ubuntu_environment
    echo ""
    
    # X11 환경 설정
    setup_x11_environment
    echo ""
    
    # 성능 최적화
    optimize_performance
    echo ""
    
    # Cursor AI 실행
    log_success "Cursor AI를 시작합니다..."
    echo ""
    launch_cursor_ai
}

# 스크립트 실행
main "$@" 