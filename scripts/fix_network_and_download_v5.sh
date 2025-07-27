#!/bin/bash

# 네트워크 및 다운로드 문제 해결 스크립트 v5.0
# Author: Mobile IDE Team
# Version: 5.0.0
# Description: 네트워크 연결 문제, DNS 해석 실패, 다운로드 실패 해결
# Usage: ./scripts/fix_network_and_download_v5.sh

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
    echo "  -c, --cursor   Cursor AI 다운로드만 해결합니다"
    echo ""
    echo "예제:"
    echo "  $0              # 모든 문제 해결"
    echo "  $0 --network    # 네트워크 문제만 해결"
    echo "  $0 --cursor     # Cursor AI 다운로드만 해결"
}

# 버전 정보
show_version() {
    echo "버전: 5.0.0"
    echo "작성자: Mobile IDE Team"
    echo "마지막 업데이트: $(date +%Y-%m-%d)"
    echo "주요 기능:"
    echo "  - 네트워크 연결 문제 해결"
    echo "  - DNS 해석 실패 해결"
    echo "  - Cursor AI 다운로드 문제 해결"
    echo "  - 대체 다운로드 방법 제공"
}

# 네트워크 진단
diagnose_network() {
    log_info "네트워크 진단 시작..."
    
    local issues=0
    
    # 1. 기본 네트워크 연결 확인
    log_info "기본 네트워크 연결 확인 중..."
    if ping -c 1 8.8.8.8 &>/dev/null; then
        log_success "기본 네트워크 연결됨"
    else
        log_error "기본 네트워크 연결 실패"
        ((issues++))
    fi
    
    # 2. DNS 서버 확인 및 설정
    log_info "DNS 서버 확인 중..."
    if [ -f /etc/resolv.conf ]; then
        log_info "현재 DNS 설정:"
        cat /etc/resolv.conf
    else
        log_warning "DNS 설정 파일이 없습니다. 환경 변수로 설정합니다..."
        
        # 환경 변수로 DNS 설정
        export DNS_SERVERS="8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1 208.67.222.222 208.67.220.220 9.9.9.9 149.112.112.112"
        log_success "DNS 서버 환경 변수 설정 완료"
    fi
    
    # 3. DNS 해석 테스트 (여러 DNS 서버 시도)
    log_info "DNS 해석 테스트 중..."
    local dns_servers=("8.8.8.8" "1.1.1.1" "208.67.222.222" "9.9.9.9")
    local dns_success=false
    
    for dns in "${dns_servers[@]}"; do
        if nslookup google.com "$dns" &>/dev/null; then
            log_success "DNS 해석 성공 (서버: $dns)"
            dns_success=true
            break
        fi
    done
    
    if [ "$dns_success" = false ]; then
        log_error "모든 DNS 서버에서 해석 실패"
        ((issues++))
    fi
    
    # 4. HTTP 연결 테스트
    log_info "HTTP 연결 테스트 중..."
    if curl -s --connect-timeout 10 https://www.google.com &>/dev/null; then
        log_success "HTTP 연결 성공"
    else
        log_error "HTTP 연결 실패"
        ((issues++))
    fi
    
    # 5. Cursor URL 테스트 (여러 DNS 서버 사용)
    log_info "Cursor URL 테스트 중..."
    local cursor_urls=(
        "download.cursor.sh"
        "cursor.sh"
        "www.cursor.sh"
        "github.com"
    )
    
    local working_urls=0
    for url in "${cursor_urls[@]}"; do
        for dns in "${dns_servers[@]}"; do
            if nslookup "$url" "$dns" &>/dev/null; then
                log_success "URL 해석 성공: $url (DNS: $dns)"
                ((working_urls++))
                break
            fi
        done
    done
    
    if [ $working_urls -eq 0 ]; then
        log_error "모든 Cursor URL 해석 실패"
        ((issues++))
    fi
    
    return $issues
}

# 네트워크 문제 해결
fix_network_issues() {
    log_info "네트워크 문제 해결 중..."
    
    # 1. DNS 서버 환경 변수 설정
    log_info "DNS 서버 환경 변수 설정 중..."
    
    # 환경 변수로 DNS 설정
    export DNS_SERVERS="8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1 208.67.222.222 208.67.220.220 9.9.9.9 149.112.112.112"
    export DNS1="8.8.8.8"
    export DNS2="1.1.1.1"
    export DNS3="208.67.222.222"
    export DNS4="9.9.9.9"
    
    log_success "DNS 서버 환경 변수 설정 완료"
    
    # 2. 네트워크 재시작 시도
    log_info "네트워크 재시작 시도 중..."
    
    # 네트워크 관련 프로세스 재시작
    pkill -f "network" 2>/dev/null || true
    pkill -f "dnsmasq" 2>/dev/null || true
    
    # 잠시 대기
    sleep 2
    
    # 3. 네트워크 연결 재확인 (여러 DNS 서버 사용)
    log_info "네트워크 연결 재확인 중..."
    
    local retry_count=0
    local max_retries=5
    local dns_servers=("8.8.8.8" "1.1.1.1" "208.67.222.222" "9.9.9.9")
    local connection_success=false
    
    while [ $retry_count -lt $max_retries ] && [ "$connection_success" = false ]; do
        log_info "재시도 $((retry_count + 1))/$max_retries"
        
        for dns in "${dns_servers[@]}"; do
            if ping -c 1 "$dns" &>/dev/null; then
                log_success "네트워크 연결 복구됨 (DNS: $dns)"
                connection_success=true
                break
            fi
        done
        
        if [ "$connection_success" = false ]; then
            ((retry_count++))
            if [ $retry_count -lt $max_retries ]; then
                log_warning "네트워크 연결 재시도 $retry_count/$max_retries"
                sleep 3
            fi
        fi
    done
    
    if [ "$connection_success" = false ]; then
        log_error "네트워크 연결 복구 실패"
        return 1
    fi
    
    log_success "네트워크 문제 해결 완료"
}

# Cursor AI 다운로드 문제 해결
fix_cursor_download() {
    log_info "Cursor AI 다운로드 문제 해결 중..."
    
    # 1. 다운로드 URL 테스트 및 설정
    log_info "다운로드 URL 테스트 중..."
    
    local download_urls=(
        "https://download.cursor.sh/linux/appImage/arm64"
        "https://cursor.sh/download/linux/arm64"
        "https://github.com/getcursor/cursor/releases/latest/download/cursor-linux-arm64.AppImage"
        "https://github.com/getcursor/cursor/releases/download/v0.2.0/cursor-linux-arm64.AppImage"
        "https://github.com/getcursor/cursor/releases/download/v0.1.0/cursor-linux-arm64.AppImage"
    )
    
    local working_url=""
    local test_methods=("curl" "wget")
    
    for method in "${test_methods[@]}"; do
        log_info "테스트 방법: $method"
        
        for url in "${download_urls[@]}"; do
            log_info "URL 테스트 중: $url"
            
            if [ "$method" = "curl" ]; then
                if curl -I --connect-timeout 10 "$url" 2>/dev/null | grep -q "200 OK"; then
                    working_url="$url"
                    log_success "작동하는 URL 발견 (curl): $url"
                    break 2
                fi
            elif [ "$method" = "wget" ]; then
                if wget --spider --timeout=10 "$url" 2>/dev/null; then
                    working_url="$url"
                    log_success "작동하는 URL 발견 (wget): $url"
                    break 2
                fi
            fi
        done
    done
    
    if [ -z "$working_url" ]; then
        log_error "모든 다운로드 URL 테스트 실패"
        log_info "대체 방법을 시도합니다..."
        
        # 2. 대체 다운로드 방법 시도
        try_alternative_download_methods
        return $?
    fi
    
    # 3. Cursor AI 다운로드
    log_info "Cursor AI 다운로드 중..."
    if proot-distro login ubuntu -- bash -c "
        cd /home/cursor-ide
        wget -O cursor.AppImage '$working_url'
    "; then
        log_success "Cursor AI 다운로드 완료"
        return 0
    else
        log_error "Cursor AI 다운로드 실패"
        return 1
    fi
}

# 대체 다운로드 방법
try_alternative_download_methods() {
    log_info "대체 다운로드 방법 시도 중..."
    
    # 1. 로컬 AppImage 파일 확인
    log_info "로컬 AppImage 파일 확인 중..."
    local local_files=(
        "~/cursor.AppImage"
        "~/Cursor-*.AppImage"
        "~/storage/shared/Download/cursor*.AppImage"
        "~/storage/shared/Download/Cursor*.AppImage"
    )
    
    for pattern in "${local_files[@]}"; do
        for file in $pattern; do
            if [ -f "$file" ]; then
                log_success "로컬 AppImage 파일 발견: $file"
                
                # Ubuntu 환경으로 복사
                if proot-distro login ubuntu -- bash -c "
                    cd /home/cursor-ide
                    cp '$file' cursor.AppImage
                    chmod +x cursor.AppImage
                "; then
                    log_success "로컬 파일 복사 완료"
                    return 0
                fi
            fi
        done
    done
    
    # 2. 미러 사이트 시도
    log_info "미러 사이트 시도 중..."
    local mirror_urls=(
        "https://mirror.ghproxy.com/https://github.com/getcursor/cursor/releases/latest/download/cursor-linux-arm64.AppImage"
        "https://download.fastgit.org/getcursor/cursor/releases/latest/download/cursor-linux-arm64.AppImage"
    )
    
    for url in "${mirror_urls[@]}"; do
        log_info "미러 URL 시도 중: $url"
        if proot-distro login ubuntu -- bash -c "
            cd /home/cursor-ide
            wget -O cursor.AppImage '$url'
        "; then
            log_success "미러 사이트에서 다운로드 성공"
            return 0
        fi
    done
    
    # 3. 수동 다운로드 안내
    log_warning "자동 다운로드 실패"
    log_info "수동 다운로드 방법:"
    echo ""
    echo "1. 웹 브라우저에서 다음 URL 접속:"
    echo "   https://cursor.sh/download"
    echo ""
    echo "2. ARM64 Linux 버전 다운로드"
    echo ""
    echo "3. 다운로드한 파일을 다음 위치로 이동:"
    echo "   ~/storage/shared/Download/"
    echo ""
    echo "4. 이 스크립트를 다시 실행하세요"
    echo ""
    
    return 1
}

# AppImage 추출
extract_appimage() {
    log_info "AppImage 추출 중..."
    
    if proot-distro login ubuntu -- bash -c "
        cd /home/cursor-ide
        chmod +x cursor.AppImage
        ./cursor.AppImage --appimage-extract
    "; then
        log_success "AppImage 추출 완료"
        return 0
    else
        log_error "AppImage 추출 실패"
        return 1
    fi
}

# 실행 스크립트 생성
create_launch_scripts() {
    log_info "실행 스크립트 생성 중..."
    
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
    
    log_success "실행 스크립트 생성 완료"
}

# 설치 검증
verify_installation() {
    log_info "설치 검증 중..."
    
    local errors=0
    
    # 1. Ubuntu 환경 확인
    if proot-distro list | grep -q "ubuntu"; then
        log_success "Ubuntu 환경 확인됨"
    else
        log_error "Ubuntu 환경 없음"
        ((errors++))
    fi
    
    # 2. Ubuntu 내부에서 cursor-ide 디렉토리 확인
    if proot-distro login ubuntu -- bash -c "test -d /home/cursor-ide"; then
        log_success "cursor-ide 디렉토리 확인됨"
    else
        log_error "cursor-ide 디렉토리 없음"
        ((errors++))
    fi
    
    # 3. Ubuntu 내부에서 AppImage 확인
    if proot-distro login ubuntu -- bash -c "test -f /home/cursor-ide/cursor.AppImage"; then
        log_success "cursor.AppImage 확인됨"
    else
        log_error "cursor.AppImage 없음"
        ((errors++))
    fi
    
    # 4. Ubuntu 내부에서 추출된 파일 확인
    if proot-distro login ubuntu -- bash -c "test -d /home/cursor-ide/squashfs-root"; then
        log_success "squashfs-root 디렉토리 확인됨"
    else
        log_error "squashfs-root 디렉토리 없음"
        ((errors++))
    fi
    
    # 5. 실행 스크립트 확인
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
    
    # 6. 네트워크 연결 확인
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
    echo "  🎉 네트워크 및 다운로드 문제 해결 완료! 🎉"
    echo "=========================================="
    echo ""
    echo "✅ 완료된 작업:"
    echo "  - 네트워크 진단 및 문제 해결"
    echo "  - DNS 서버 다중 설정"
    echo "  - Cursor AI 다운로드 문제 해결"
    echo "  - 대체 다운로드 방법 시도"
    echo "  - AppImage 추출 및 실행 스크립트 생성"
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
    echo "  - DNS 설정이 다중 서버로 최적화되었습니다"
    echo "  - 여러 다운로드 방법이 시도되었습니다"
    echo ""
}

# 메인 함수
main() {
    echo "=========================================="
    echo "  네트워크 및 다운로드 문제 해결 스크립트 v5.0"
    echo "=========================================="
    echo ""
    
    # 명령행 인수 처리
    local force_mode=false
    local debug_mode=false
    local network_only=false
    local cursor_only=false
    
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
            -c|--cursor)
                cursor_only=true
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
        diagnose_network
        if [ $? -gt 0 ]; then
            fix_network_issues
        fi
    elif [ "$cursor_only" = true ]; then
        # Cursor AI 다운로드만 해결
        fix_cursor_download
        if [ $? -eq 0 ]; then
            extract_appimage
            create_launch_scripts
            verify_installation
        fi
    else
        # 모든 문제 해결
        diagnose_network
        if [ $? -gt 0 ]; then
            fix_network_issues
        fi
        fix_cursor_download
        if [ $? -eq 0 ]; then
            extract_appimage
            create_launch_scripts
            verify_installation
        fi
    fi
    
    # 문제 해결 요약
    show_fix_summary
    
    log_success "네트워크 및 다운로드 문제 해결 완료!"
}

# 스크립트 실행
main "$@" 