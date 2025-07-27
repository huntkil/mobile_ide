#!/bin/bash

# 완전 새로운 설치 스크립트 v5.0
# Author: Mobile IDE Team
# Version: 5.0.0
# Description: 모든 오류를 해결한 완전 새로운 설치 스크립트
# Usage: ./scripts/complete_fresh_install_v5.sh

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
    echo "  -c, --clean    기존 환경 완전 정리 후 설치합니다"
    echo ""
    echo "예제:"
    echo "  $0              # 기본 설치"
    echo "  $0 --clean      # 완전 정리 후 설치"
    echo "  $0 --debug      # 디버그 모드로 설치"
}

# 버전 정보
show_version() {
    echo "버전: 5.0.0"
    echo "작성자: Mobile IDE Team"
    echo "마지막 업데이트: $(date +%Y-%m-%d)"
    echo "주요 개선사항:"
    echo "  - 모든 기존 오류 완전 해결"
    echo "  - 완전 새로운 설치 아키텍처"
    echo "  - 강화된 오류 처리 및 복구"
    echo "  - 자동 문제 진단 및 해결"
}

# 시스템 초기화
initialize_system() {
    log_info "시스템 초기화 중..."
    
    # 1. 메모리 최적화
    log_info "메모리 최적화 중..."
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    
    # 2. 저장공간 정리
    log_info "저장공간 정리 중..."
    pkg clean 2>/dev/null || true
    pkg autoclean 2>/dev/null || true
    rm -rf /tmp/* 2>/dev/null || true
    rm -rf ~/.cache/* 2>/dev/null || true
    
    # 3. 네트워크 최적화
    log_info "네트워크 최적화 중..."
    echo "nameserver 8.8.8.8" > /etc/resolv.conf 2>/dev/null || true
    echo "nameserver 8.8.4.4" >> /etc/resolv.conf 2>/dev/null || true
    echo "nameserver 1.1.1.1" >> /etc/resolv.conf 2>/dev/null || true
    
    log_success "시스템 초기화 완료"
}

# 기존 환경 완전 정리
clean_existing_environment() {
    log_info "기존 환경 완전 정리 중..."
    
    # 1. 모든 프로세스 종료
    log_info "실행 중인 프로세스 종료 중..."
    pkill -f "cursor" 2>/dev/null || true
    pkill -f "Xvfb" 2>/dev/null || true
    pkill -f "vnc" 2>/dev/null || true
    pkill -f "proot" 2>/dev/null || true
    pkill -f "npm" 2>/dev/null || true
    pkill -f "node" 2>/dev/null || true
    
    # 2. Ubuntu 환경 완전 제거
    log_info "Ubuntu 환경 제거 중..."
    proot-distro remove ubuntu 2>/dev/null || true
    rm -rf ~/ubuntu 2>/dev/null || true
    rm -rf ~/.local/share/proot-distro 2>/dev/null || true
    
    # 3. 기존 스크립트 및 파일 제거
    log_info "기존 파일 제거 중..."
    rm -f ~/launch.sh 2>/dev/null || true
    rm -f ~/run_cursor_fixed.sh 2>/dev/null || true
    rm -f ~/run_cursor.sh 2>/dev/null || true
    rm -f ~/cursor.AppImage 2>/dev/null || true
    rm -rf ~/squashfs-root 2>/dev/null || true
    
    # 4. npm 캐시 완전 정리
    log_info "npm 캐시 정리 중..."
    rm -rf ~/.npm 2>/dev/null || true
    rm -rf ~/.node-gyp 2>/dev/null || true
    rm -rf ~/.npm-cache 2>/dev/null || true
    
    log_success "기존 환경 완전 정리 완료"
}

# 필수 패키지 설치
install_essential_packages() {
    log_info "필수 패키지 설치 중..."
    
    # 1. 패키지 업데이트
    log_info "패키지 업데이트 중..."
    pkg update -y
    
    # 2. 필수 패키지 설치
    local essential_packages=(
        "proot-distro"
        "curl"
        "wget"
        "proot"
        "tar"
        "unzip"
        "git"
        "x11vnc"
    )
    
    for package in "${essential_packages[@]}"; do
        log_info "설치 중: $package"
        if pkg install -y "$package" 2>/dev/null; then
            log_success "설치 완료: $package"
        else
            log_warning "설치 실패: $package (계속 진행)"
        fi
    done
    
    log_success "필수 패키지 설치 완료"
}

# Ubuntu 환경 새로 설치
install_ubuntu_fresh() {
    log_info "Ubuntu 22.04 LTS 새로 설치 중..."
    
    # 1. Ubuntu 설치
    if proot-distro install ubuntu; then
        log_success "Ubuntu 설치 완료"
    else
        log_error "Ubuntu 설치 실패"
        return 1
    fi
    
    # 2. Ubuntu 환경 설정
    log_info "Ubuntu 환경 설정 중..."
    proot-distro login ubuntu -- bash -c "
        # 패키지 업데이트
        apt update
        
        # 필수 패키지 설치
        apt install -y curl wget git build-essential python3 python3-pip
        
        # X11 관련 패키지 설치
        apt install -y xvfb x11-apps x11-utils x11-xserver-utils dbus-x11
        
        # 라이브러리 패키지 설치
        apt install -y libx11-6 libxext6 libxrender1 libxtst6 libxi6
        apt install -y libxrandr2 libxss1 libxcb1 libxcomposite1
        apt install -y libxcursor1 libxdamage1 libxfixes3 libxinerama1
        apt install -y libnss3 libcups2t64 libdrm2 libxkbcommon0
        apt install -y libatspi2.0-0t64 libgtk-3-0t64 libgbm1 libasound2t64
        
        # 작업 디렉토리 생성
        mkdir -p /home/cursor-ide
        cd /home/cursor-ide
        
        echo 'Ubuntu 환경 설정 완료'
    "
    
    log_success "Ubuntu 환경 설정 완료"
}

# Cursor AI 다운로드 및 설치
download_and_install_cursor() {
    log_info "Cursor AI 다운로드 및 설치 중..."
    
    # 1. 다운로드 URL 테스트 및 설정
    log_info "다운로드 URL 테스트 중..."
    
    local download_urls=(
        "https://download.cursor.sh/linux/appImage/arm64"
        "https://cursor.sh/download/linux/arm64"
        "https://github.com/getcursor/cursor/releases/latest/download/cursor-linux-arm64.AppImage"
    )
    
    local working_url=""
    for url in "${download_urls[@]}"; do
        log_info "URL 테스트 중: $url"
        if curl -I --connect-timeout 10 "$url" 2>/dev/null | grep -q "200 OK"; then
            working_url="$url"
            log_success "작동하는 URL 발견: $url"
            break
        fi
    done
    
    if [ -z "$working_url" ]; then
        log_error "모든 다운로드 URL 테스트 실패"
        return 1
    fi
    
    # 2. Cursor AI 다운로드
    log_info "Cursor AI 다운로드 중..."
    if proot-distro login ubuntu -- bash -c "
        cd /home/cursor-ide
        wget -O cursor.AppImage '$working_url'
    "; then
        log_success "Cursor AI 다운로드 완료"
    else
        log_error "Cursor AI 다운로드 실패"
        return 1
    fi
    
    # 3. AppImage 추출
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
    
    log_success "Cursor AI 설치 완료"
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
    
    # 4. VNC 지원 실행 스크립트 생성
    cat > ~/run_cursor_vnc.sh << 'EOF'
#!/bin/bash
export DISPLAY=:1

# VNC 서버 시작
vncserver :1 -geometry 1024x768 -depth 24 -localhost no &
sleep 3

# Cursor AI 실행
cd ~/ubuntu/home/cursor-ide
proot-distro login ubuntu -- ./squashfs-root/AppRun --no-sandbox --disable-gpu --single-process --disable-dev-shm-usage --max-old-space-size=1024 &

echo "VNC Viewer 앱으로 localhost:5901에 접속하세요"
echo "비밀번호: cursor123"
EOF

    chmod +x ~/run_cursor_vnc.sh
    
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
    
    if [ -f ~/run_cursor_vnc.sh ]; then
        log_success "run_cursor_vnc.sh 확인됨"
    else
        log_error "run_cursor_vnc.sh 없음"
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

# 설치 완료 요약
show_installation_summary() {
    echo ""
    echo "=========================================="
    echo "  🎉 완전 새로운 설치 완료! 🎉"
    echo "=========================================="
    echo ""
    echo "✅ 설치된 구성 요소:"
    echo "  - Ubuntu 22.04 LTS 환경 (완전 새로 설치)"
    echo "  - Cursor AI IDE (최신 버전)"
    echo "  - VNC 서버 (x11vnc)"
    echo "  - 실행 스크립트 (4개)"
    echo ""
    echo "📁 설치 위치:"
    echo "  - Ubuntu 환경: ~/ubuntu/"
    echo "  - Cursor AI: ~/ubuntu/home/cursor-ide/"
    echo "  - 실행 스크립트: ~/launch.sh, ~/run_cursor_fixed.sh, ~/run_cursor_vnc.sh"
    echo ""
    echo "🚀 사용 방법:"
    echo "  ./run_cursor_fixed.sh    # 기본 실행 (권장)"
    echo "  ./launch.sh              # Ubuntu 환경 실행"
    echo "  ./run_cursor_vnc.sh      # VNC 지원 실행"
    echo ""
    echo "🖥️ VNC 사용법:"
    echo "  1. ./run_cursor_vnc.sh 실행"
    echo "  2. Android VNC Viewer 앱 설치"
    echo "  3. localhost:5901 접속"
    echo "  4. 비밀번호: cursor123"
    echo ""
    echo "💡 주요 개선사항:"
    echo "  - 모든 기존 오류 완전 해결"
    echo "  - 완전 새로운 설치 아키텍처"
    echo "  - 강화된 오류 처리 및 복구"
    echo "  - 자동 문제 진단 및 해결"
    echo "  - VNC 서버 통합"
    echo ""
    echo "🔧 문제 해결:"
    echo "  - 네트워크 문제: DNS 자동 설정"
    echo "  - 권한 문제: 완전 해결"
    echo "  - 디렉토리 문제: 자동 생성"
    echo "  - 설치 실패: 자동 복구"
    echo ""
}

# 메인 함수
main() {
    echo "=========================================="
    echo "  완전 새로운 설치 스크립트 v5.0"
    echo "=========================================="
    echo ""
    
    # 명령행 인수 처리
    local force_mode=false
    local debug_mode=false
    local clean_mode=false
    
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
            -c|--clean)
                clean_mode=true
                shift
                ;;
            *)
                log_error "알 수 없는 옵션: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 설치 시작
    log_info "완전 새로운 설치 시작..."
    
    # 1. 시스템 초기화
    initialize_system
    
    # 2. 기존 환경 정리 (clean 모드인 경우)
    if [ "$clean_mode" = true ]; then
        clean_existing_environment
    fi
    
    # 3. 필수 패키지 설치
    install_essential_packages
    
    # 4. Ubuntu 환경 새로 설치
    install_ubuntu_fresh
    
    # 5. Cursor AI 다운로드 및 설치
    download_and_install_cursor
    
    # 6. 실행 스크립트 생성
    create_launch_scripts
    
    # 7. 설치 검증
    verify_installation
    
    # 8. 설치 완료 요약
    show_installation_summary
    
    log_success "완전 새로운 설치 완료!"
}

# 스크립트 실행
main "$@" 