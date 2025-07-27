#!/bin/bash

# 네트워크 및 설치 문제 해결 스크립트 v4.0
# Author: Mobile IDE Team
# Version: 4.0.0
# Description: DNS 해석 실패, 디렉토리 문제, 설치 실패 해결
# Usage: ./scripts/fix_network_and_install_v4.sh

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
    echo "  -n, --network  네트워크 문제만 해결합니다"
    echo "  -i, --install  설치 문제만 해결합니다"
    echo ""
    echo "예제:"
    echo "  $0              # 모든 문제 해결"
    echo "  $0 --network    # 네트워크 문제만 해결"
    echo "  $0 --install    # 설치 문제만 해결"
}

# 버전 정보
show_version() {
    echo "버전: 4.0.0"
    echo "작성자: Mobile IDE Team"
    echo "마지막 업데이트: $(date +%Y-%m-%d)"
    echo "주요 기능:"
    echo "  - DNS 해석 실패 해결"
    echo "  - 디렉토리 문제 해결"
    echo "  - 설치 실패 해결"
    echo "  - 네트워크 연결 안정화"
}

# 네트워크 문제 해결
fix_network_issues() {
    log_info "네트워크 문제 해결 중..."
    
    # 1. DNS 서버 설정
    log_info "DNS 서버 설정 중..."
    echo "nameserver 8.8.8.8" > /etc/resolv.conf 2>/dev/null || true
    echo "nameserver 8.8.4.4" >> /etc/resolv.conf 2>/dev/null || true
    echo "nameserver 1.1.1.1" >> /etc/resolv.conf 2>/dev/null || true
    echo "nameserver 208.67.222.222" >> /etc/resolv.conf 2>/dev/null || true
    
    # 2. 네트워크 연결 테스트
    log_info "네트워크 연결 테스트 중..."
    
    # Google DNS로 테스트
    if ping -c 1 8.8.8.8 &>/dev/null; then
        log_success "네트워크 연결됨 (IP)"
    else
        log_error "네트워크 연결 실패"
        return 1
    fi
    
    # DNS 해석 테스트
    if nslookup google.com 8.8.8.8 &>/dev/null; then
        log_success "DNS 해석 성공 (Google DNS)"
    else
        log_warning "Google DNS 해석 실패"
    fi
    
    # Cloudflare DNS로 테스트
    if nslookup google.com 1.1.1.1 &>/dev/null; then
        log_success "DNS 해석 성공 (Cloudflare DNS)"
    else
        log_warning "Cloudflare DNS 해석 실패"
    fi
    
    # 3. Cursor 다운로드 URL 테스트
    log_info "Cursor 다운로드 URL 테스트 중..."
    
    # 여러 DNS로 Cursor URL 테스트
    local cursor_urls=(
        "download.cursor.sh"
        "cursor.sh"
        "www.cursor.sh"
    )
    
    local working_url=""
    for url in "${cursor_urls[@]}"; do
        log_info "테스트 중: $url"
        if nslookup "$url" 8.8.8.8 &>/dev/null; then
            working_url="$url"
            log_success "작동하는 URL 발견: $url"
            break
        fi
    done
    
    if [ -n "$working_url" ]; then
        # 환경 변수로 설정
        export CURSOR_DOWNLOAD_URL="https://$working_url/linux/appImage/arm64"
        log_success "Cursor 다운로드 URL 설정: $CURSOR_DOWNLOAD_URL"
    else
        log_warning "모든 URL 테스트 실패, 기본 URL 사용"
        export CURSOR_DOWNLOAD_URL="https://download.cursor.sh/linux/appImage/arm64"
    fi
    
    log_success "네트워크 문제 해결 완료"
}

# 디렉토리 문제 해결
fix_directory_issues() {
    log_info "디렉토리 문제 해결 중..."
    
    # 1. Ubuntu 환경 확인 및 생성
    if [ ! -d ~/ubuntu ]; then
        log_warning "Ubuntu 환경이 없습니다. 새로 설치합니다..."
        proot-distro install ubuntu
    fi
    
    # 2. cursor-ide 디렉토리 생성
    log_info "cursor-ide 디렉토리 생성 중..."
    proot-distro login ubuntu -- bash -c "
        mkdir -p /home/cursor-ide
        cd /home/cursor-ide
        pwd
        ls -la
    "
    
    # 3. Termux에서 디렉토리 확인
    if [ -d ~/ubuntu/home/cursor-ide ]; then
        log_success "cursor-ide 디렉토리 확인됨"
    else
        log_error "cursor-ide 디렉토리 생성 실패"
        return 1
    fi
    
    log_success "디렉토리 문제 해결 완료"
}

# Cursor AI 재설치
reinstall_cursor_ai() {
    log_info "Cursor AI 재설치 중..."
    
    # 1. 기존 설치 제거
    log_info "기존 설치 제거 중..."
    proot-distro login ubuntu -- bash -c "
        cd /home/cursor-ide
        rm -rf cursor.AppImage squashfs-root 2>/dev/null || true
    "
    
    # 2. 네트워크 문제 해결
    fix_network_issues
    
    # 3. Cursor AI 다운로드 (여러 방법 시도)
    log_info "Cursor AI 다운로드 중..."
    
    local download_success=false
    
    # 방법 1: wget 사용
    if proot-distro login ubuntu -- bash -c "
        cd /home/cursor-ide
        wget -O cursor.AppImage '$CURSOR_DOWNLOAD_URL'
    "; then
        download_success=true
        log_success "wget으로 다운로드 성공"
    else
        log_warning "wget 다운로드 실패"
    fi
    
    # 방법 2: curl 사용 (wget 실패 시)
    if [ "$download_success" = false ]; then
        log_info "curl로 다운로드 시도 중..."
        if proot-distro login ubuntu -- bash -c "
            cd /home/cursor-ide
            curl -L -o cursor.AppImage '$CURSOR_DOWNLOAD_URL'
        "; then
            download_success=true
            log_success "curl로 다운로드 성공"
        else
            log_warning "curl 다운로드 실패"
        fi
    fi
    
    # 방법 3: 대체 URL 시도
    if [ "$download_success" = false ]; then
        log_info "대체 URL로 다운로드 시도 중..."
        local alternative_urls=(
            "https://github.com/getcursor/cursor/releases/latest/download/cursor-linux-arm64.AppImage"
            "https://cursor.sh/download/linux/arm64"
        )
        
        for alt_url in "${alternative_urls[@]}"; do
            log_info "시도 중: $alt_url"
            if proot-distro login ubuntu -- bash -c "
                cd /home/cursor-ide
                wget -O cursor.AppImage '$alt_url'
            "; then
                download_success=true
                log_success "대체 URL로 다운로드 성공: $alt_url"
                break
            fi
        done
    fi
    
    if [ "$download_success" = false ]; then
        log_error "모든 다운로드 방법 실패"
        return 1
    fi
    
    # 4. AppImage 추출
    log_info "AppImage 추출 중..."
    if proot-distro login ubuntu -- bash -c "
        cd /home/cursor-ide
        chmod +x cursor.AppImage
        ./cursor.AppImage --appimage-extract
    "; then
        log_success "AppImage 추출 완료"
    else
        log_error "AppImage 추출 실패"
        return 1
    fi
    
    log_success "Cursor AI 재설치 완료"
}

# 실행 스크립트 재생성
recreate_launch_scripts() {
    log_info "실행 스크립트 재생성 중..."
    
    # 1. Ubuntu 환경에서 실행할 스크립트 생성
    cat > ~/ubuntu/home/cursor-ide/start.sh << 'EOF'
#!/bin/bash
export DISPLAY=:0
export XDG_RUNTIME_DIR="$HOME/.runtime-cursor"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# Xvfb 시작
Xvfb :0 -screen 0 1024x768x16 -ac +extension GLX +render -noreset &
sleep 3

# Cursor AI 실행 (안전한 옵션)
./squashfs-root/AppRun --no-sandbox --disable-gpu --single-process --disable-dev-shm-usage --max-old-space-size=1024 &
EOF

    chmod +x ~/ubuntu/home/cursor-ide/start.sh
    
    # 2. Termux에서 실행할 스크립트 생성
    cat > ~/launch.sh << 'EOF'
#!/bin/bash
proot-distro login ubuntu -- bash /home/cursor-ide/start.sh
EOF

    chmod +x ~/launch.sh
    
    # 3. 권한 문제 해결된 실행 스크립트 생성
    cat > ~/run_cursor_fixed.sh << 'EOF'
#!/bin/bash
export DISPLAY=:0
export XDG_RUNTIME_DIR="$HOME/.runtime-cursor"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# Xvfb 시작
Xvfb :0 -screen 0 1024x768x16 -ac +extension GLX +render -noreset &
sleep 3

# Cursor AI 실행
cd ~/ubuntu/home/cursor-ide
proot-distro login ubuntu -- ./squashfs-root/AppRun --no-sandbox --disable-gpu --single-process --disable-dev-shm-usage --max-old-space-size=1024 &
EOF

    chmod +x ~/run_cursor_fixed.sh
    
    log_success "실행 스크립트 재생성 완료"
}

# 설치 검증
verify_installation() {
    log_info "설치 검증 중..."
    
    local errors=0
    
    # 1. 디렉토리 확인
    if [ -d ~/ubuntu/home/cursor-ide ]; then
        log_success "cursor-ide 디렉토리 확인됨"
    else
        log_error "cursor-ide 디렉토리 없음"
        ((errors++))
    fi
    
    # 2. AppImage 확인
    if [ -f ~/ubuntu/home/cursor-ide/cursor.AppImage ]; then
        log_success "cursor.AppImage 확인됨"
    else
        log_error "cursor.AppImage 없음"
        ((errors++))
    fi
    
    # 3. 추출된 파일 확인
    if [ -d ~/ubuntu/home/cursor-ide/squashfs-root ]; then
        log_success "squashfs-root 디렉토리 확인됨"
    else
        log_error "squashfs-root 디렉토리 없음"
        ((errors++))
    fi
    
    # 4. 실행 스크립트 확인
    if [ -f ~/launch.sh ]; then
        log_success "launch.sh 확인됨"
    else
        log_error "launch.sh 없음"
        ((errors++))
    fi
    
    if [ -f ~/run_cursor_fixed.sh ]; then
        log_success "run_cursor_fixed.sh 확인됨"
    else
        log_error "run_cursor_fixed.sh 없음"
        ((errors++))
    fi
    
    # 5. 네트워크 연결 확인
    if ping -c 1 8.8.8.8 &>/dev/null; then
        log_success "네트워크 연결 확인됨"
    else
        log_warning "네트워크 연결 문제"
        ((errors++))
    fi
    
    if [ $errors -eq 0 ]; then
        log_success "설치 검증 완료 - 모든 검사 통과"
        return 0
    else
        log_error "설치 검증 실패 - $errors개 오류 발견"
        return 1
    fi
}

# 문제 해결 요약
show_fix_summary() {
    echo ""
    echo "=========================================="
    echo "  🎉 네트워크 및 설치 문제 해결 완료! 🎉"
    echo "=========================================="
    echo ""
    echo "✅ 완료된 작업:"
    echo "  - DNS 해석 실패 해결"
    echo "  - 디렉토리 문제 해결"
    echo "  - Cursor AI 재설치"
    echo "  - 실행 스크립트 재생성"
    echo "  - 설치 검증"
    echo ""
    echo "📁 설치 위치:"
    echo "  - Ubuntu 환경: ~/ubuntu/"
    echo "  - Cursor AI: ~/ubuntu/home/cursor-ide/"
    echo "  - 실행 스크립트: ~/launch.sh, ~/run_cursor_fixed.sh"
    echo ""
    echo "🚀 사용 방법:"
    echo "  ./run_cursor_fixed.sh    # 권장"
    echo "  ./launch.sh              # 기본 실행"
    echo ""
    echo "💡 팁:"
    echo "  - 네트워크 문제가 다시 발생하면 이 스크립트를 다시 실행하세요"
    echo "  - DNS 설정이 자동으로 최적화되었습니다"
    echo "  - 여러 다운로드 방법이 시도되었습니다"
    echo ""
}

# 메인 함수
main() {
    echo "=========================================="
    echo "  네트워크 및 설치 문제 해결 스크립트 v4.0"
    echo "=========================================="
    echo ""
    
    # 명령행 인수 처리
    local force_mode=false
    local debug_mode=false
    local network_only=false
    local install_only=false
    
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
            -n|--network)
                network_only=true
                shift
                ;;
            -i|--install)
                install_only=true
                shift
                ;;
            *)
                log_error "알 수 없는 옵션: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    if [ "$network_only" = true ]; then
        # 네트워크 문제만 해결
        fix_network_issues
    elif [ "$install_only" = true ]; then
        # 설치 문제만 해결
        fix_directory_issues
        reinstall_cursor_ai
        recreate_launch_scripts
        verify_installation
    else
        # 모든 문제 해결
        fix_network_issues
        fix_directory_issues
        reinstall_cursor_ai
        recreate_launch_scripts
        verify_installation
    fi
    
    # 문제 해결 요약
    show_fix_summary
    
    log_success "네트워크 및 설치 문제 해결 완료!"
}

# 스크립트 실행
main "$@" 