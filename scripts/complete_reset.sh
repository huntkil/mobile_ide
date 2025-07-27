#!/bin/bash

# Galaxy Android용 Cursor AI IDE 완전 초기화 스크립트 (v3.1.1)
# Author: Mobile IDE Team
# Version: 3.1.1
# Description: 모든 환경을 완전히 초기화하고 새로 시작
# Usage: ./scripts/complete_reset.sh

set -e

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

# 헬프 함수
show_help() {
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  -h, --help     이 도움말을 표시합니다"
    echo "  -v, --version  버전 정보를 표시합니다"
    echo "  -d, --debug    디버그 모드로 실행합니다"
    echo "  -f, --force    확인 없이 강제 실행합니다"
    echo ""
    echo "⚠️  주의: 이 스크립트는 모든 데이터를 삭제합니다!"
    echo ""
    echo "예제:"
    echo "  $0              # 기본 실행 (확인 요청)"
    echo "  $0 --force      # 강제 실행 (확인 없음)"
    echo "  $0 --debug      # 디버그 모드"
}

# 버전 정보
show_version() {
    echo "버전: 3.1.1"
    echo "작성자: Mobile IDE Team"
    echo "마지막 업데이트: $(date +%Y-%m-%d)"
    echo "설명: 완전한 환경 초기화 및 재설치"
}

# 사용자 확인
confirm_reset() {
    echo ""
    echo "=========================================="
    echo "  ⚠️  완전 초기화 경고 ⚠️"
    echo "=========================================="
    echo ""
    echo "이 스크립트는 다음을 수행합니다:"
    echo "  ❌ 모든 홈 디렉토리 파일 삭제"
    echo "  ❌ 모든 설정 파일 삭제"
    echo "  ❌ Ubuntu 환경 완전 제거"
    echo "  ❌ Cursor AI 완전 제거"
    echo "  ❌ 모든 스크립트 삭제"
    echo ""
    echo "⚠️  모든 데이터가 영구적으로 삭제됩니다!"
    echo ""
    
    read -p "정말로 계속하시겠습니까? (yes/no): " -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_info "사용자가 취소했습니다."
        exit 0
    fi
    
    echo ""
    echo "마지막 확인:"
    echo "  - 백업이 필요한 파일이 있나요?"
    echo "  - 중요한 프로젝트가 있나요?"
    echo ""
    
    read -p "모든 데이터를 삭제하고 새로 시작하시겠습니까? (YES): " -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_info "사용자가 취소했습니다."
        exit 0
    fi
}

# 백업 생성
create_backup() {
    log_info "백업 생성 중..."
    
    # 백업 디렉토리 생성
    mkdir -p ~/storage/shared/TermuxBackup/$(date +%Y%m%d_%H%M%S)
    local backup_dir="~/storage/shared/TermuxBackup/$(date +%Y%m%d_%H%M%S)"
    
    # 중요 파일 백업
    if [ -d ~/projects ]; then
        log_info "프로젝트 폴더 백업 중..."
        cp -r ~/projects "$backup_dir/" 2>/dev/null || log_warning "프로젝트 백업 실패"
    fi
    
    if [ -f ~/.bashrc ]; then
        log_info "설정 파일 백업 중..."
        cp ~/.bashrc "$backup_dir/" 2>/dev/null || log_warning "설정 파일 백업 실패"
    fi
    
    if [ -f ~/.profile ]; then
        cp ~/.profile "$backup_dir/" 2>/dev/null || log_warning "프로필 백업 실패"
    fi
    
    log_success "백업 완료: $backup_dir"
}

# 완전 초기화
complete_reset() {
    log_info "완전 초기화 시작..."
    
    # 1. 모든 프로세스 종료
    log_info "실행 중인 프로세스 종료 중..."
    pkill -f "cursor" 2>/dev/null || true
    pkill -f "Xvfb" 2>/dev/null || true
    pkill -f "vnc" 2>/dev/null || true
    pkill -f "proot" 2>/dev/null || true
    
    # 2. 모든 파일 삭제
    log_info "홈 디렉토리 완전 정리 중..."
    rm -rf ~/* 2>/dev/null || true
    rm -rf ~/.* 2>/dev/null || true
    rm -rf ~/.cache 2>/dev/null || true
    rm -rf ~/.config 2>/dev/null || true
    rm -rf ~/.local 2>/dev/null || true
    
    # 3. Ubuntu 환경 완전 제거
    log_info "Ubuntu 환경 제거 중..."
    proot-distro remove ubuntu 2>/dev/null || true
    rm -rf ~/.local/share/proot-distro 2>/dev/null || true
    
    # 4. 패키지 캐시 정리
    log_info "패키지 캐시 정리 중..."
    pkg clean 2>/dev/null || true
    pkg autoclean 2>/dev/null || true
    
    # 5. 임시 파일 정리
    log_info "임시 파일 정리 중..."
    rm -rf /tmp/* 2>/dev/null || true
    rm -rf /var/tmp/* 2>/dev/null || true
    
    log_success "완전 초기화 완료"
}

# 패키지 재설치
reinstall_packages() {
    log_info "패키지 재설치 중..."
    
    # 1. 패키지 목록 업데이트
    log_info "패키지 목록 업데이트 중..."
    pkg update -y
    
    # 2. 패키지 업그레이드
    log_info "패키지 업그레이드 중..."
    pkg upgrade -y
    
    # 3. 필수 패키지 설치
    log_info "필수 패키지 설치 중..."
    pkg install -y proot-distro curl wget proot tar unzip git
    
    # 4. 설치 확인
    log_info "패키지 설치 확인 중..."
    if command -v proot-distro &> /dev/null; then
        log_success "proot-distro 설치 완료"
    else
        log_error "proot-distro 설치 실패"
        return 1
    fi
    
    if command -v curl &> /dev/null; then
        log_success "curl 설치 완료"
    else
        log_error "curl 설치 실패"
        return 1
    fi
    
    log_success "패키지 재설치 완료"
}

# 프로젝트 재다운로드
redownload_project() {
    log_info "프로젝트 재다운로드 중..."
    
    # 1. 프로젝트 디렉토리 생성
    mkdir -p ~/mobile_ide
    cd ~/mobile_ide
    
    # 2. Git 클론
    log_info "Git 저장소 클론 중..."
    if git clone https://github.com/huntkil/mobile_ide.git .; then
        log_success "프로젝트 다운로드 완료"
    else
        log_error "프로젝트 다운로드 실패"
        return 1
    fi
    
    # 3. 최신 버전 확인
    log_info "최신 버전 확인 중..."
    git status
    git log --oneline -3
    
    log_success "프로젝트 재다운로드 완료"
}

# 자동 설치 실행
run_auto_install() {
    log_info "자동 설치 실행 중..."
    
    # 1. 스크립트 실행 권한 부여
    chmod +x scripts/termux_local_setup.sh
    
    # 2. 자동 설치 실행
    log_info "termux_local_setup.sh 실행 중..."
    if ./scripts/termux_local_setup.sh; then
        log_success "자동 설치 완료"
    else
        log_error "자동 설치 실패"
        return 1
    fi
    
    # 3. 설치 확인
    log_info "설치 결과 확인 중..."
    if [ -f ~/launch.sh ] && [ -f ~/run_cursor_fixed.sh ]; then
        log_success "실행 스크립트 생성 완료"
    else
        log_warning "실행 스크립트가 생성되지 않았습니다"
    fi
    
    log_success "자동 설치 실행 완료"
}

# 시스템 정보 표시
show_system_info() {
    log_info "시스템 정보 확인 중..."
    
    echo ""
    echo "=========================================="
    echo "  시스템 정보"
    echo "=========================================="
    echo ""
    
    # Android 정보
    echo "Android 버전: $(getprop ro.build.version.release 2>/dev/null || echo 'Unknown')"
    echo "Android API: $(getprop ro.build.version.sdk 2>/dev/null || echo 'Unknown')"
    echo "기기 모델: $(getprop ro.product.model 2>/dev/null || echo 'Unknown')"
    echo ""
    
    # 시스템 정보
    echo "아키텍처: $(uname -m)"
    echo "커널: $(uname -r)"
    echo ""
    
    # 메모리 정보
    echo "메모리 정보:"
    free -h
    echo ""
    
    # 저장공간 정보
    echo "저장공간 정보:"
    df -h
    echo ""
    
    # 네트워크 정보
    echo "네트워크 연결:"
    if ping -c 1 google.com &>/dev/null; then
        echo "✅ 인터넷 연결됨"
    else
        echo "❌ 인터넷 연결 안됨"
    fi
    echo ""
}

# 최종 검증
final_verification() {
    log_info "최종 검증 중..."
    
    local errors=0
    
    # 1. 필수 패키지 확인
    local required_packages=("proot-distro" "curl" "wget" "git")
    for package in "${required_packages[@]}"; do
        if command -v "$package" &> /dev/null; then
            log_success "$package 확인됨"
        else
            log_error "$package 없음"
            ((errors++))
        fi
    done
    
    # 2. 프로젝트 확인
    if [ -d ~/mobile_ide ]; then
        log_success "프로젝트 디렉토리 확인됨"
    else
        log_error "프로젝트 디렉토리 없음"
        ((errors++))
    fi
    
    # 3. 실행 스크립트 확인
    if [ -f ~/launch.sh ]; then
        log_success "launch.sh 확인됨"
    else
        log_warning "launch.sh 없음"
    fi
    
    if [ -f ~/run_cursor_fixed.sh ]; then
        log_success "run_cursor_fixed.sh 확인됨"
    else
        log_warning "run_cursor_fixed.sh 없음"
    fi
    
    # 4. 저장공간 확인
    local available_space=$(df / | awk 'NR==2{printf "%.0f", $4/1024/1024}')
    if [ "$available_space" -gt 5 ]; then
        log_success "저장공간 충분: ${available_space}GB"
    else
        log_warning "저장공간 부족: ${available_space}GB"
        ((errors++))
    fi
    
    if [ $errors -eq 0 ]; then
        log_success "최종 검증 완료 - 모든 검사 통과"
        return 0
    else
        log_error "최종 검증 실패 - $errors개 오류 발견"
        return 1
    fi
}

# 설치 완료 요약
show_completion_summary() {
    echo ""
    echo "=========================================="
    echo "  🎉 완전 초기화 완료! 🎉"
    echo "=========================================="
    echo ""
    echo "✅ 완료된 작업:"
    echo "  - 모든 환경 완전 초기화"
    echo "  - 패키지 재설치"
    echo "  - 프로젝트 재다운로드"
    echo "  - 자동 설치 실행"
    echo ""
    echo "📁 현재 상태:"
    echo "  - 프로젝트 위치: ~/mobile_ide/"
    echo "  - 실행 스크립트: ~/launch.sh, ~/run_cursor_fixed.sh"
    echo ""
    echo "🚀 다음 단계:"
    echo "  1. Cursor AI 실행: ./run_cursor_fixed.sh"
    echo "  2. VNC 서버 설정: pkg install x11vnc"
    echo "  3. GUI 화면 보기: Android VNC Viewer 앱"
    echo ""
    echo "📚 문서:"
    echo "  - 완전 설치 가이드: docs/COMPLETE_SETUP_GUIDE.md"
    echo "  - 문제 해결: docs/troubleshooting.md"
    echo ""
    echo "💡 팁:"
    echo "  - 문제가 발생하면 이 스크립트를 다시 실행하세요"
    echo "  - 정기적으로 cleanup.sh로 저장공간을 정리하세요"
    echo ""
}

# 메인 함수
main() {
    echo "=========================================="
    echo "  Galaxy Android용 Cursor AI IDE 완전 초기화"
    echo "=========================================="
    echo ""
    
    # 명령행 인수 처리
    local force_mode=false
    local debug_mode=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -d|--debug)
                debug_mode=true
                set -x
                shift
                ;;
            -f|--force)
                force_mode=true
                shift
                ;;
            *)
                log_error "알 수 없는 옵션: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 사용자 확인 (강제 모드가 아닌 경우)
    if [ "$force_mode" = false ]; then
        confirm_reset
    fi
    
    # 시스템 정보 표시
    show_system_info
    
    # 백업 생성
    create_backup
    
    # 완전 초기화
    complete_reset
    
    # 패키지 재설치
    reinstall_packages || {
        log_error "패키지 재설치 실패"
        exit 1
    }
    
    # 프로젝트 재다운로드
    redownload_project || {
        log_error "프로젝트 재다운로드 실패"
        exit 1
    }
    
    # 자동 설치 실행
    run_auto_install || {
        log_error "자동 설치 실패"
        exit 1
    }
    
    # 최종 검증
    final_verification || {
        log_warning "일부 검증 실패, 수동 확인 필요"
    }
    
    # 설치 완료 요약
    show_completion_summary
    
    log_success "완전 초기화 완료!"
}

# 스크립트 실행
main "$@" 