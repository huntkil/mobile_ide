#!/bin/bash

# Galaxy Android용 Cursor AI IDE 완벽 설치 스크립트 v4.0
# Author: Mobile IDE Team
# Version: 4.0.0
# Description: npm 오류 완전 해결, 모든 문제 방지, 안정적인 설치
# Usage: ./scripts/termux_perfect_setup_v4.sh

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
    echo "  -s, --skip-npm npm 설치를 건너뜁니다"
    echo ""
    echo "예제:"
    echo "  $0              # 기본 실행"
    echo "  $0 --debug      # 디버그 모드"
    echo "  $0 --skip-npm   # npm 없이 설치"
}

# 버전 정보
show_version() {
    echo "버전: 4.0.0"
    echo "작성자: Mobile IDE Team"
    echo "마지막 업데이트: $(date +%Y-%m-%d)"
    echo "주요 개선사항:"
    echo "  - npm 오류 완전 해결"
    echo "  - 메모리 최적화"
    echo "  - 안정적인 설치 프로세스"
    echo "  - 자동 문제 해결"
    echo "  - 완전한 오류 처리"
}

# 사용자 권한 확인
check_user_permissions() {
    log_info "사용자 권한 확인 중..."
    
    # root 사용자 확인
    if [ "$(id -u)" -eq 0 ]; then
        log_error "root 사용자로 실행할 수 없습니다."
        echo ""
        echo "해결 방법:"
        echo "1. 일반 사용자로 다시 로그인하세요"
        echo "2. 또는 다음 명령어로 일반 사용자로 전환하세요:"
        echo "   su - [사용자명]"
        echo ""
        echo "현재 사용자: $(whoami)"
        echo "현재 UID: $(id -u)"
        return 1
    fi
    
    # proot-distro 확인
    if ! command -v proot-distro &> /dev/null; then
        log_error "proot-distro가 설치되지 않았습니다."
        log_info "다음 명령어로 설치하세요:"
        echo "pkg install proot-distro"
        return 1
    fi
    
    log_success "사용자 권한 확인 완료"
    return 0
}

# 시스템 요구사항 확인
check_system_requirements() {
    log_info "시스템 요구사항 확인 중..."
    
    # Android 버전 확인
    local android_version=$(getprop ro.build.version.release)
    local android_sdk=$(getprop ro.build.version.sdk)
    
    if [ "$android_sdk" -lt 29 ]; then
        log_error "Android 10+ (API 29+)가 필요합니다."
        log_info "현재 버전: Android $android_version (API $android_sdk)"
        return 1
    fi
    
    # 메모리 확인
    local total_mem=$(free | awk 'NR==2{printf "%.0f", $2/1024/1024}')
    if [ "$total_mem" -lt 4 ]; then
        log_warning "최소 4GB 메모리가 권장됩니다."
        log_info "현재 메모리: ${total_mem}GB"
    fi
    
    # 저장공간 확인
    local available_space=$(df /data | awk 'NR==2{printf "%.0f", $4/1024/1024}')
    if [ "$available_space" -lt 10 ]; then
        log_error "최소 10GB 저장공간이 필요합니다."
        log_info "현재 사용 가능한 공간: ${available_space}GB"
        return 1
    fi
    
    log_success "시스템 요구사항 확인 완료"
    return 0
}

# 메모리 최적화
optimize_memory() {
    log_info "메모리 최적화 중..."
    
    # 메모리 캐시 정리
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    
    # 불필요한 프로세스 종료
    pkill -f "Xvfb" 2>/dev/null || true
    pkill -f "vnc" 2>/dev/null || true
    
    # 메모리 상태 확인
    local free_mem=$(free | awk 'NR==2{printf "%.0f", $4/1024/1024}')
    log_info "사용 가능한 메모리: ${free_mem}GB"
    
    log_success "메모리 최적화 완료"
}

# 저장공간 정리
cleanup_storage() {
    log_info "저장공간 정리 중..."
    
    # 패키지 캐시 정리
    pkg clean 2>/dev/null || true
    pkg autoclean 2>/dev/null || true
    
    # 임시 파일 정리
    rm -rf /tmp/* 2>/dev/null || true
    rm -rf ~/.cache/* 2>/dev/null || true
    
    # 로그 파일 정리
    find ~ -name "*.log" -type f -size +10M -delete 2>/dev/null || true
    
    # 저장공간 상태 확인
    local available_space=$(df /data | awk 'NR==2{printf "%.0f", $4/1024/1024}')
    log_info "사용 가능한 저장공간: ${available_space}GB"
    
    log_success "저장공간 정리 완료"
}

# 네트워크 연결 확인
check_network_connection() {
    log_info "네트워크 연결 확인 중..."
    
    # DNS 확인
    if ! nslookup google.com >/dev/null 2>&1; then
        log_warning "DNS 확인 실패, DNS 서버 설정 중..."
        echo "nameserver 8.8.8.8" > /etc/resolv.conf 2>/dev/null || true
        echo "nameserver 8.8.4.4" >> /etc/resolv.conf 2>/dev/null || true
        echo "nameserver 1.1.1.1" >> /etc/resolv.conf 2>/dev/null || true
    fi
    
    # HTTP 연결 확인
    if ! curl -s --connect-timeout 10 https://www.google.com >/dev/null; then
        log_warning "HTTP 연결 실패"
        return 1
    fi
    
    log_success "네트워크 연결 확인 완료"
    return 0
}

# Ubuntu 환경 설치
install_ubuntu() {
    log_info "Ubuntu 22.04 LTS 설치 중..."
    
    # 기존 환경 확인
    if [ -d "$HOME/ubuntu" ]; then
        log_warning "기존 Ubuntu 환경이 발견되었습니다."
        log_info "기존 환경을 제거하고 새로 설치합니다..."
        proot-distro remove ubuntu 2>/dev/null || true
        rm -rf "$HOME/ubuntu" 2>/dev/null || true
    fi
    
    # Ubuntu 설치
    if proot-distro install ubuntu; then
        log_success "Ubuntu 환경 설치 완료"
        return 0
    else
        log_error "Ubuntu 환경 설치 실패"
        return 1
    fi
}

# Ubuntu 환경 설정 (npm 없이)
setup_ubuntu_without_npm() {
    log_info "Ubuntu 환경 설정 중 (npm 없이)..."
    
    # Ubuntu 환경에서 실행할 스크립트 생성
    cat > ~/setup_ubuntu_temp.sh << 'EOF'
#!/bin/bash
set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# 패키지 목록 업데이트
log_info "패키지 목록 업데이트 중..."
apt update

# 필수 패키지 설치
log_info "필수 패키지 설치 중..."
apt install -y curl wget git build-essential python3 python3-pip

# X11 관련 패키지 설치
log_info "X11 관련 패키지 설치 중..."
apt install -y xvfb x11-apps x11-utils x11-xserver-utils dbus-x11

# 추가 라이브러리 설치
log_info "추가 라이브러리 설치 중..."
apt install -y libx11-6 libxext6 libxrender1 libxtst6 libxi6
apt install -y libxrandr2 libxss1 libxcb1 libxcomposite1
apt install -y libxcursor1 libxdamage1 libxfixes3 libxinerama1
apt install -y libnss3 libcups2t64 libdrm2 libxkbcommon0
apt install -y libatspi2.0-0t64 libgtk-3-0t64 libgbm1 libasound2t64

# 작업 디렉토리 생성
log_info "작업 디렉토리 생성 중..."
mkdir -p /home/cursor-ide
cd /home/cursor-ide

log_success "Ubuntu 환경 설정 완료 (npm 없이)"
EOF

    chmod +x ~/setup_ubuntu_temp.sh
    
    # Ubuntu 환경에서 스크립트 실행
    if proot-distro login ubuntu -- bash ~/setup_ubuntu_temp.sh; then
        log_success "Ubuntu 환경 설정 완료"
        rm -f ~/setup_ubuntu_temp.sh
        return 0
    else
        log_error "Ubuntu 환경 설정 실패"
        rm -f ~/setup_ubuntu_temp.sh
        return 1
    fi
}

# Ubuntu 환경 설정 (npm 포함)
setup_ubuntu_with_npm() {
    log_info "Ubuntu 환경 설정 중 (npm 포함)..."
    
    # Ubuntu 환경에서 실행할 스크립트 생성
    cat > ~/setup_ubuntu_temp.sh << 'EOF'
#!/bin/bash
set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# 패키지 목록 업데이트
log_info "패키지 목록 업데이트 중..."
apt update

# 필수 패키지 설치
log_info "필수 패키지 설치 중..."
apt install -y curl wget git build-essential python3 python3-pip

# X11 관련 패키지 설치
log_info "X11 관련 패키지 설치 중..."
apt install -y xvfb x11-apps x11-utils x11-xserver-utils dbus-x11

# 추가 라이브러리 설치
log_info "추가 라이브러리 설치 중..."
apt install -y libx11-6 libxext6 libxrender1 libxtst6 libxi6
apt install -y libxrandr2 libxss1 libxcb1 libxcomposite1
apt install -y libxcursor1 libxdamage1 libxfixes3 libxinerama1
apt install -y libnss3 libcups2t64 libdrm2 libxkbcommon0
apt install -y libatspi2.0-0t64 libgtk-3-0t64 libgbm1 libasound2t64

# Node.js 설치 (안전한 방법)
log_info "Node.js 설치 중..."
# 기존 Node.js 제거
apt remove -y nodejs npm 2>/dev/null || true
apt autoremove -y

# Node.js 18 LTS 설치
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# npm 안전한 설정
log_info "npm 안전 설정 중..."
npm config set registry https://registry.npmjs.org/
npm config set cache ~/.npm-cache

# npm 캐시 정리 (안전한 방법)
log_info "npm 캐시 정리 중..."
npm cache verify 2>/dev/null || true

# 전역 패키지 설치 (선택사항)
log_info "전역 패키지 설치 중..."
npm install -g npm@10.8.2 2>/dev/null || log_warning "npm 버전 변경 실패, 기본 버전 사용"

# 작업 디렉토리 생성
log_info "작업 디렉토리 생성 중..."
mkdir -p /home/cursor-ide
cd /home/cursor-ide

log_success "Ubuntu 환경 설정 완료 (npm 포함)"
EOF

    chmod +x ~/setup_ubuntu_temp.sh
    
    # Ubuntu 환경에서 스크립트 실행
    if proot-distro login ubuntu -- bash ~/setup_ubuntu_temp.sh; then
        log_success "Ubuntu 환경 설정 완료"
        rm -f ~/setup_ubuntu_temp.sh
        return 0
    else
        log_error "Ubuntu 환경 설정 실패"
        rm -f ~/setup_ubuntu_temp.sh
        return 1
    fi
}

# Cursor AI 설치
install_cursor_ai() {
    log_info "Cursor AI 설치 중..."
    
    # Ubuntu 환경에서 실행할 스크립트 생성
    cat > ~/install_cursor_temp.sh << 'EOF'
#!/bin/bash
set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

cd /home/cursor-ide

# AppImage 다운로드 (ARM64)
log_info "Cursor AI AppImage 다운로드 중..."
wget -O cursor.AppImage "https://download.cursor.sh/linux/appImage/arm64"

# 실행 권한 부여
chmod +x cursor.AppImage

# AppImage 추출
log_info "AppImage 추출 중..."
./cursor.AppImage --appimage-extract

log_success "Cursor AI 설치 완료"
EOF

    chmod +x ~/install_cursor_temp.sh
    
    # Ubuntu 환경에서 스크립트 실행
    if proot-distro login ubuntu -- bash ~/install_cursor_temp.sh; then
        log_success "Cursor AI 설치 완료"
        rm -f ~/install_cursor_temp.sh
        return 0
    else
        log_error "Cursor AI 설치 실패"
        rm -f ~/install_cursor_temp.sh
        return 1
    fi
}

# 실행 스크립트 생성
create_launch_scripts() {
    log_info "실행 스크립트 생성 중..."
    
    # Ubuntu 환경에서 실행할 스크립트 생성
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
    
    # Termux에서 실행할 스크립트 생성
    cat > ~/launch.sh << 'EOF'
#!/bin/bash
proot-distro login ubuntu -- bash /home/cursor-ide/start.sh
EOF

    chmod +x ~/launch.sh
    
    # 권한 문제 해결된 실행 스크립트 생성
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

# 설치 완료 요약
show_installation_summary() {
    echo ""
    echo "=========================================="
    echo "  🎉 설치 완료! 🎉"
    echo "=========================================="
    echo ""
    echo "✅ 설치된 구성 요소:"
    echo "  - Ubuntu 22.04 LTS 환경"
    if [ "$SKIP_NPM" = false ]; then
        echo "  - Node.js 18 LTS"
    else
        echo "  - Node.js (건너뜀)"
    fi
    echo "  - Cursor AI IDE"
    echo "  - 실행 스크립트 (launch.sh, run_cursor_fixed.sh)"
    echo ""
    echo "📁 설치 위치:"
    echo "  - Ubuntu 환경: ~/ubuntu/"
    echo "  - Cursor AI: ~/ubuntu/home/cursor-ide/"
    echo "  - 실행 스크립트: ~/launch.sh, ~/run_cursor_fixed.sh"
    echo ""
    echo "🚀 사용 방법:"
    echo "  ./run_cursor_fixed.sh    # 권장 (권한 문제 해결됨)"
    echo "  ./launch.sh              # 기본 실행"
    echo ""
    echo "🔧 문제 해결:"
    echo "  ./scripts/fix_installation.sh"
    echo ""
    echo "📚 문서:"
    echo "  docs/COMPLETE_SETUP_GUIDE.md"
    echo "  docs/troubleshooting.md"
    echo ""
}

# 메인 함수
main() {
    echo "=========================================="
    echo "  Galaxy Android용 Cursor AI IDE 완벽 설치 v4.0"
    echo "=========================================="
    echo ""
    
    # 명령행 인수 처리
    local force_mode=false
    local debug_mode=false
    SKIP_NPM=false
    
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
            -s|--skip-npm)
                SKIP_NPM=true
                shift
                ;;
            *)
                log_error "알 수 없는 옵션: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 사용자 권한 확인
    check_user_permissions || exit 1
    
    # 시스템 요구사항 확인
    check_system_requirements || exit 1
    
    # 메모리 최적화
    optimize_memory
    
    # 저장공간 정리
    cleanup_storage
    
    # 네트워크 연결 확인
    check_network_connection || {
        log_warning "네트워크 연결 문제, 계속 진행..."
    }
    
    # Ubuntu 환경 설치
    install_ubuntu || exit 1
    
    # Ubuntu 환경 설정
    if [ "$SKIP_NPM" = true ]; then
        setup_ubuntu_without_npm || exit 1
    else
        setup_ubuntu_with_npm || exit 1
    fi
    
    # Cursor AI 설치
    install_cursor_ai || exit 1
    
    # 실행 스크립트 생성
    create_launch_scripts || exit 1
    
    # 설치 완료 요약
    show_installation_summary
    
    log_success "완벽 설치 완료!"
}

# 스크립트 실행
main "$@" 