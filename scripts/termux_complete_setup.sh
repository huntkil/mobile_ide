#!/bin/bash

# Galaxy Android용 Cursor AI IDE 완전 설치 스크립트 (모든 가이드 반영)
# Author: Mobile IDE Team
# Version: 5.0.0 - 모든 가이드 완전 반영
# DEVELOPMENT_GUIDE.md, ERROR_DATABASE.md, TROUBLESHOOTING.md 완전 적용

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 전역 변수 (모든 가이드 반영)
SCRIPT_DIR="$(pwd)"
LOG_FILE="$HOME/cursor_install_$(date +%Y%m%d_%H%M%S).log"
LOG_LEVEL=${LOG_LEVEL:-INFO}
CURSOR_DIR="$HOME/cursor-ide"
UBUNTU_HOME="$HOME/ubuntu/home"
BACKUP_DIR="$HOME/cursor_backup_$(date +%Y%m%d_%H%M%S)"

# 오류 코드 정의 (ERROR_DATABASE.md 반영)
ERROR_CODES=(
    "INSTALL-001:Ubuntu 중복 설치"
    "INSTALL-002:패키지 설치 실패"
    "INSTALL-003:AppImage 다운로드 실패"
    "INSTALL-004:AppImage 추출 실패"
    "PERM-001:Root 사용자 실행"
    "PERM-002:파일 권한 문제"
    "PERM-003:디렉토리 접근 권한"
    "NET-001:DNS 해석 실패"
    "NET-002:다운로드 타임아웃"
    "NET-003:SSL 인증서 문제"
    "COMPAT-001:npm 버전 호환성"
    "COMPAT-002:ARM64 패키지 호환성"
    "COMPAT-003:Android 버전 호환성"
    "SCRIPT-001:문법 오류"
    "SCRIPT-002:변수 확장 오류"
    "SCRIPT-003:함수 호출 오류"
    "PERF-001:메모리 부족"
    "PERF-002:디스크 공간 부족"
    "PERF-003:CPU 과부하"
)

# 설치 단계 정의 (DEVELOPMENT_GUIDE.md 반영)
INSTALL_STEPS=(
    "시스템 검증"
    "사용자 권한 확인"
    "네트워크 연결 확인"
    "시스템 요구사항 확인"
    "최소 의존성 패키지 설치"
    "Ubuntu 환경 설치"
    "Ubuntu 환경 완전 설정"
    "Cursor AI 다운로드 및 설치"
    "설정 파일 생성"
    "최종 검증"
)

# 설치 진행 상황 추적
CURRENT_STEP=0
TOTAL_STEPS=${#INSTALL_STEPS[@]}

# 로그 함수 (모든 가이드 반영)
log_debug() {
    if [[ "$LOG_LEVEL" == "DEBUG" ]]; then
        echo -e "${PURPLE}[DEBUG]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE" 2>/dev/null || true
    fi
}

log_info() {
    if [[ "$LOG_LEVEL" == "DEBUG" || "$LOG_LEVEL" == "INFO" ]]; then
        echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE" 2>/dev/null || true
    fi
}

log_success() {
    if [[ "$LOG_LEVEL" == "DEBUG" || "$LOG_LEVEL" == "INFO" ]]; then
        echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE" 2>/dev/null || true
    fi
}

log_warning() {
    if [[ "$LOG_LEVEL" == "DEBUG" || "$LOG_LEVEL" == "INFO" || "$LOG_LEVEL" == "WARNING" ]]; then
        echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE" 2>/dev/null || true
    fi
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE" 2>/dev/null || true
}

# 진행 상황 표시 (DEVELOPMENT_GUIDE.md 반영)
show_progress() {
    local current=$1
    local total=$2
    local description="${3:-진행 중}"
    
    local percentage=$((current * 100 / total))
    local filled=$((percentage / 2))
    local empty=$((50 - filled))
    
    printf "\r${BLUE}[INFO]${NC} %s: [%s%s] %d%% (%d/%d)" \
        "$description" \
        "$(printf '#%.0s' $(seq 1 $filled))" \
        "$(printf ' %.0s' $(seq 1 $empty))" \
        "$percentage" \
        "$current" \
        "$total"
    
    if [ "$current" -eq "$total" ]; then
        echo
    fi
}

# 설치 단계 실행 (DEVELOPMENT_GUIDE.md 반영)
run_install_step() {
    local step_name="$1"
    local step_function="$2"
    
    ((CURRENT_STEP++))
    show_progress "$CURRENT_STEP" "$TOTAL_STEPS" "$step_name"
    
    if "$step_function"; then
        log_success "$step_name 완료"
        return 0
    else
        log_error "$step_name 실패"
        return 1
    fi
}

# 에러 핸들러 (ERROR_DATABASE.md 반영)
error_handler() {
    local exit_code=$1
    local line_no=$2
    local last_command="$3"
    
    log_error "스크립트 실행 중 오류 발생!"
    log_error "Exit Code: $exit_code"
    log_error "Line Number: $line_no"
    log_error "Command: $last_command"
    
    echo ""
    echo "🔧 자동 복구를 시도합니다..."
    auto_recovery
    
    echo ""
    echo "📋 문제 해결 방법:"
    echo "1. 로그 파일 확인: $LOG_FILE"
    echo "2. 수동 복구 실행: ./termux_complete_restore.sh"
    echo "3. 네트워크 연결 확인"
    echo "4. 저장공간 확인: df -h"
    echo "5. 메모리 확인: free -h"
    
    exit "$exit_code"
}

# 자동 복구 함수 (ERROR_DATABASE.md 반영)
auto_recovery() {
    log_info "자동 복구 시작..."
    
    # 네트워크 복구 (NET-001, NET-002, NET-003)
    if ! ping -c 1 google.com &> /dev/null; then
        log_warning "네트워크 연결 문제 감지, DNS 설정 수정..."
        echo "nameserver 8.8.8.8" > /etc/resolv.conf 2>/dev/null || true
        echo "nameserver 8.8.4.4" >> /etc/resolv.conf 2>/dev/null || true
        echo "nameserver 1.1.1.1" >> /etc/resolv.conf 2>/dev/null || true
    fi
    
    # 권한 복구 (PERM-002, PERM-003)
    if [ -d "$CURSOR_DIR" ]; then
        log_warning "Cursor 디렉토리 권한 수정..."
        chmod -R 755 "$CURSOR_DIR" 2>/dev/null || true
    fi
    
    # 임시 파일 정리 (PERF-002)
    log_warning "임시 파일 정리..."
    rm -f "$HOME/cursor*.AppImage" 2>/dev/null || true
    rm -f "$HOME/cursor*.deb" 2>/dev/null || true
    
    # 메모리 정리 (PERF-001)
    log_warning "메모리 캐시 정리..."
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
}

# 검증 함수들 (DEVELOPMENT_GUIDE.md 반영)

# 사용자 권한 확인 (PERM-001)
check_user_permissions() {
    log_info "사용자 권한 확인 중..."
    
    # root 사용자 확인
    if [ "$(id -u)" -eq 0 ]; then
        log_error "root 사용자로 실행할 수 없습니다. (PERM-001)"
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
    
    # Termux 환경 확인
    if [ -z "${TERMUX_VERSION:-}" ]; then
        log_warning "Termux 환경이 아닙니다. 일부 기능이 제한될 수 있습니다."
    fi
    
    # 홈 디렉토리 쓰기 권한 확인
    if [ ! -w "$HOME" ]; then
        log_error "홈 디렉토리에 쓰기 권한이 없습니다. (PERM-002)"
        return 1
    fi
    
    # 로그 파일 디렉토리 권한 확인
    local log_dir
    log_dir=$(dirname "$LOG_FILE")
    if [ ! -w "$log_dir" ]; then
        log_warning "로그 디렉토리에 쓰기 권한이 없습니다. 홈 디렉토리로 변경합니다."
        LOG_FILE="$HOME/cursor_install_$(date +%Y%m%d_%H%M%S).log"
    fi
    
    log_success "사용자 권한 확인 완료"
    return 0
}

# 시스템 요구사항 확인 (COMPAT-003, PERF-001, PERF-002)
check_system_requirements() {
    log_info "시스템 요구사항 확인 중..."
    
    # Android 버전 확인
    local android_version
    android_version=$(getprop ro.build.version.release 2>/dev/null || echo "unknown")
    local android_sdk
    android_sdk=$(getprop ro.build.version.sdk 2>/dev/null || echo "0")
    
    log_info "Android 버전: $android_version (API $android_sdk)"
    
    if [ "$android_sdk" -lt 29 ]; then
        log_warning "Android 10+ (API 29+)가 권장됩니다. (COMPAT-003)"
        log_info "현재 버전: Android $android_version (API $android_sdk)"
    fi
    
    # 아키텍처 확인
    local arch
    arch=$(uname -m)
    log_info "아키텍처: $arch"
    
    if [[ "$arch" != "aarch64" && "$arch" != "arm64" ]]; then
        log_warning "ARM64 아키텍처가 아닙니다. 호환성 문제가 있을 수 있습니다."
    fi
    
    # 메모리 확인 (PERF-001)
    local mem_total
    mem_total=$(free -h | grep Mem | awk '{print $2}')
    local mem_gb
    mem_gb=$(free -g | grep Mem | awk '{print $2}')
    log_info "총 메모리: $mem_total"
    
    if [ "$mem_gb" -lt 4 ]; then
        log_warning "메모리가 4GB 미만입니다. 성능이 저하될 수 있습니다. (PERF-001)"
    fi
    
    # 저장공간 확인 (PERF-002)
    local disk_free
    disk_free=$(df -h /data | tail -1 | awk '{print $4}')
    local disk_free_gb
    disk_free_gb=$(df -g /data | tail -1 | awk '{print $4}')
    log_info "사용 가능한 저장공간: $disk_free"
    
    if [ "$disk_free_gb" -lt 10 ]; then
        log_warning "저장공간이 10GB 미만입니다. 설치에 문제가 있을 수 있습니다. (PERF-002)"
    fi
    
    log_success "시스템 요구사항 확인 완료"
    return 0
}

# 네트워크 연결 확인 (NET-001, NET-002, NET-003)
check_network_connection() {
    log_info "네트워크 연결 확인 중..."
    
    # DNS 확인 (NET-001)
    if ! nslookup google.com >/dev/null 2>&1; then
        log_warning "DNS 확인 실패, DNS 설정 수정... (NET-001)"
        echo "nameserver 8.8.8.8" > /etc/resolv.conf 2>/dev/null || true
        echo "nameserver 8.8.4.4" >> /etc/resolv.conf 2>/dev/null || true
        echo "nameserver 1.1.1.1" >> /etc/resolv.conf 2>/dev/null || true
    fi
    
    # HTTP 연결 확인 (NET-002, NET-003)
    if ! curl -s --connect-timeout 10 https://www.google.com >/dev/null; then
        log_warning "HTTP 연결 실패 (NET-002, NET-003)"
        return 1
    fi
    
    log_success "네트워크 연결 확인 완료"
    return 0
}

# 전체 시스템 검증
validate_system() {
    log_info "시스템 검증 시작..."
    
    local errors=0
    
    # 사용자 권한 확인
    if ! check_user_permissions; then
        ((errors++))
    fi
    
    # 시스템 요구사항 확인
    if ! check_system_requirements; then
        ((errors++))
    fi
    
    # 네트워크 연결 확인
    if ! check_network_connection; then
        ((errors++))
    fi
    
    if [ $errors -eq 0 ]; then
        log_success "시스템 검증 완료 - 모든 검사 통과"
        return 0
    else
        log_error "시스템 검증 실패 - $errors개 오류 발견"
        return 1
    fi
}

# 설치 함수들 (DEVELOPMENT_GUIDE.md 완전 반영)

# 최소 의존성 패키지 설치
install_minimal_dependencies() {
    log_info "최소 의존성 패키지 설치 중..."
    
    # Termux 패키지 업데이트
    log_info "패키지 목록 업데이트..."
    pkg update -y || {
        log_warning "패키지 업데이트 실패, 계속 진행..."
    }
    
    # 필수 패키지만 설치 (최소화)
    local minimal_packages=(
        "curl" "wget" "proot" "proot-distro"
    )
    
    for package in "${minimal_packages[@]}"; do
        if ! command -v "$package" &> /dev/null; then
            log_info "$package 설치 중..."
            pkg install -y "$package" || {
                log_warning "$package 설치 실패, 계속 진행..."
            }
        else
            log_info "$package 이미 설치됨"
        fi
    done
    
    # proot-distro 특별 확인
    if ! command -v proot-distro &> /dev/null; then
        log_error "proot-distro 설치에 실패했습니다."
        return 1
    fi
    
    log_success "최소 의존성 패키지 설치 완료"
    return 0
}

# Ubuntu 환경 설치 (INSTALL-001)
install_ubuntu_environment() {
    log_info "Ubuntu 환경 설치 중..."
    
    # 기존 Ubuntu 환경 확인 (INSTALL-001)
    if [ -d "$HOME/ubuntu" ]; then
        log_info "기존 Ubuntu 환경 발견, 백업 생성..."
        mkdir -p "$BACKUP_DIR"
        cp -r "$HOME/ubuntu" "$BACKUP_DIR/" 2>/dev/null || true
        
        log_info "기존 환경 제거..."
        proot-distro remove ubuntu 2>/dev/null || true
        rm -rf "$HOME/ubuntu" 2>/dev/null || true
    fi
    
    # Ubuntu 설치
    log_info "Ubuntu 22.04 LTS 설치 중..."
    proot-distro install ubuntu || {
        log_error "Ubuntu 설치에 실패했습니다. (INSTALL-001)"
        return 1
    }
    
    log_success "Ubuntu 환경 설치 완료"
    return 0
}

# Ubuntu 환경 완전 설정 (DEVELOPMENT_GUIDE.md 완전 반영)
setup_complete_ubuntu_environment() {
    log_info "Ubuntu 환경 완전 설정 중..."
    
    # Ubuntu 환경에서 실행할 스크립트 생성
    cat > "$HOME/setup_complete_ubuntu.sh" << 'EOF'
#!/bin/bash
set -e

echo "Ubuntu 환경 완전 설정 시작..."

# 패키지 목록 업데이트 (재시도 로직)
for i in {1..3}; do
    if apt update; then
        break
    else
        echo "패키지 업데이트 실패, 재시도 $i/3..."
        sleep 2
    fi
done

# 기본 패키지 설치
echo "기본 패키지 설치 중..."
apt install -y curl wget git build-essential python3 python3-pip

# X11 관련 패키지
echo "X11 패키지 설치 중..."
apt install -y xvfb x11-apps x11-utils x11-xserver-utils dbus-x11

# 기본 X11 라이브러리
echo "X11 라이브러리 설치 중..."
apt install -y libx11-6 libxext6 libxrender1 libxtst6 libxi6
apt install -y libxrandr2 libxss1 libxcb1 libxcomposite1
apt install -y libxcursor1 libxdamage1 libxfixes3 libxinerama1
apt install -y libnss3 libdrm2 libxkbcommon0

# ARM64 특정 패키지 (COMPAT-002 완전 반영)
echo "ARM64 특정 패키지 설치 중..."
apt install -y libcups2t64 || {
    echo "libcups2t64 설치 실패, 기본 버전 시도..."
    apt install -y libcups2 || echo "libcups2도 설치 실패, 건너뜀..."
}

apt install -y libatspi2.0-0t64 || {
    echo "libatspi2.0-0t64 설치 실패, 기본 버전 시도..."
    apt install -y libatspi2.0-0 || echo "libatspi2.0-0도 설치 실패, 건너뜀..."
}

apt install -y libgtk-3-0t64 || {
    echo "libgtk-3-0t64 설치 실패, 기본 버전 시도..."
    apt install -y libgtk-3-0 || echo "libgtk-3-0도 설치 실패, 건너뜀..."
}

apt install -y libasound2t64 || {
    echo "libasound2t64 설치 실패, 기본 버전 시도..."
    apt install -y libasound2 || echo "libasound2도 설치 실패, 건너뜀..."
}

apt install -y libgbm1 || echo "libgbm1 설치 실패, 건너뜀..."

# 추가 의존성 패키지들
echo "추가 의존성 패키지 설치 중..."
apt install -y libglib2.0-0 libpango-1.0-0 libcairo2 libgdk-pixbuf2.0-0 || {
    echo "일부 GTK 의존성 설치 실패, 계속 진행..."
}

# Node.js 완전 설치 (COMPAT-001 완전 반영)
echo "Node.js 완전 설치 중..."
# 기존 Node.js 제거 (충돌 방지)
apt remove -y nodejs npm 2>/dev/null || true
apt autoremove -y

# Node.js 18 LTS 설치
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# npm 호환성 문제 해결 (COMPAT-001)
echo "npm 호환성 문제 해결 중..."
npm install -g npm@10.8.2 || {
    echo "npm 버전 변경 실패, 기본 버전 사용..."
    npm cache clean --force 2>/dev/null || true
}

# npm 캐시 정리
npm cache clean --force 2>/dev/null || true

# 호환되는 전역 패키지 설치
echo "전역 패키지 설치 중..."
npm install -g yarn@1.22.19 typescript@5.3.3 ts-node@10.9.2 || {
    echo "일부 전역 패키지 설치 실패, 계속 진행..."
}

# 작업 디렉토리 생성
mkdir -p /home/cursor-ide
cd /home/cursor-ide

echo "Ubuntu 환경 완전 설정 완료"
EOF
    
    # Ubuntu 환경에서 스크립트 실행
    log_info "Ubuntu 환경에서 완전 설정 스크립트 실행..."
    proot-distro login ubuntu -- bash "$HOME/setup_complete_ubuntu.sh" || {
        log_error "Ubuntu 환경 완전 설정에 실패했습니다."
        return 1
    }
    
    # 임시 스크립트 정리
    rm -f "$HOME/setup_complete_ubuntu.sh"
    
    log_success "Ubuntu 환경 완전 설정 완료"
    return 0
}

# Cursor AI 다운로드 및 설치 (INSTALL-003, INSTALL-004)
download_and_install_cursor_ai() {
    log_info "Cursor AI 다운로드 및 설치 중..."
    
    # Ubuntu 환경에서 직접 다운로드 및 설치
    cat > "$HOME/download_install_cursor.sh" << 'EOF'
#!/bin/bash
set -e

cd /home/cursor-ide

# 다운로드 URL 목록 (올바른 URL들로 수정)
download_urls=(
    "https://github.com/getcursor/cursor/releases/latest/download/cursor-linux-arm64.AppImage"
    "https://download.cursor.sh/linux/appImage/arm64"
    "https://cursor.sh/download/linux/arm64"
)

download_success=false

# 여러 URL에서 다운로드 시도
for url in "${download_urls[@]}"; do
    echo "다운로드 시도: $url"
    
    # 기존 파일 제거
    rm -f cursor.AppImage
    
    if wget --timeout=60 --tries=3 -O cursor.AppImage "$url" 2>/dev/null; then
        # 파일 유효성 검사 (HTML이 아닌 실제 AppImage인지 확인)
        if file cursor.AppImage | grep -q "ELF\|AppImage\|executable"; then
            download_success=true
            echo "유효한 AppImage 파일 다운로드 완료"
            break
        else
            echo "HTML 페이지가 다운로드됨, 다른 URL 시도..."
            rm -f cursor.AppImage
        fi
    fi
    
    if curl --connect-timeout 60 --retry 3 -L -o cursor.AppImage "$url" 2>/dev/null; then
        # 파일 유효성 검사
        if file cursor.AppImage | grep -q "ELF\|AppImage\|executable"; then
            download_success=true
            echo "유효한 AppImage 파일 다운로드 완료"
            break
        else
            echo "HTML 페이지가 다운로드됨, 다른 URL 시도..."
            rm -f cursor.AppImage
        fi
    fi
    
    echo "다운로드 실패: $url"
done

if [ "$download_success" = false ]; then
    echo "모든 다운로드 URL에서 실패했습니다."
    echo ""
    echo "수동 다운로드 방법:"
    echo "1. 브라우저에서 https://github.com/getcursor/cursor/releases 접속"
    echo "2. 최신 릴리즈에서 'cursor-linux-arm64.AppImage' 다운로드"
    echo "3. 다운로드한 파일을 현재 디렉토리로 복사"
    echo ""
    read -p "수동 다운로드 완료 후 Enter를 누르세요..."
    
    if [ ! -f "cursor.AppImage" ]; then
        echo "수동 다운로드 파일을 찾을 수 없습니다"
        exit 1
    fi
    
    # 수동 다운로드 파일도 유효성 검사
    if ! file cursor.AppImage | grep -q "ELF\|AppImage\|executable"; then
        echo "수동 다운로드 파일이 유효하지 않습니다"
        exit 1
    fi
fi

# 실행 권한 부여
chmod +x cursor.AppImage

# AppImage 추출 (INSTALL-004)
echo "AppImage 추출 중..."
./cursor.AppImage --appimage-extract || {
    echo "AppImage 추출 실패, 대체 방법 시도..."
    ./cursor.AppImage --appimage-extract-and-run || {
        echo "모든 추출 방법 실패"
        exit 1
    }
}

# 완전한 실행 스크립트 생성 (TROUBLESHOOTING.md 반영)
cat > launch_cursor.sh << 'LAUNCH_EOF'
#!/bin/bash
cd /home/cursor-ide
export DISPLAY=:0
export XDG_RUNTIME_DIR=/tmp/runtime-cursor
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

# Xvfb 시작 (백그라운드)
Xvfb :0 -screen 0 1200x800x24 -ac +extension GLX +render -noreset &
XVFB_PID=$!

# 잠시 대기
sleep 3

# X11 권한 설정
xhost +local: 2>/dev/null || true

# Cursor 실행
./squashfs-root/cursor "$@"

# Xvfb 종료
kill $XVFB_PID 2>/dev/null || true
LAUNCH_EOF

chmod +x launch_cursor.sh

echo "Cursor AI 다운로드 및 설치 완료"
EOF
    
    # Ubuntu 환경에서 다운로드 및 설치 스크립트 실행
    log_info "Ubuntu 환경에서 Cursor AI 다운로드 및 설치..."
    proot-distro login ubuntu -- bash "$HOME/download_install_cursor.sh" || {
        log_error "Cursor AI 다운로드 및 설치에 실패했습니다. (INSTALL-003, INSTALL-004)"
        return 1
    }
    
    # 임시 스크립트 정리
    rm -f "$HOME/download_install_cursor.sh"
    
    log_success "Cursor AI 다운로드 및 설치 완료"
    return 0
}

# 설정 파일 생성
create_configuration() {
    log_info "설정 파일 생성 중..."
    
    # Cursor 설정 디렉토리 생성
    mkdir -p "$CURSOR_DIR"
    
    # 실행 스크립트 생성 (TROUBLESHOOTING.md 반영)
    cat > "$CURSOR_DIR/launch.sh" << 'EOF'
#!/bin/bash

# Cursor AI 실행 스크립트
# Author: Mobile IDE Team

set -e

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}[INFO]${NC} Cursor AI 시작 중..."

# Ubuntu 환경에서 Cursor 실행
proot-distro login ubuntu -- bash /home/cursor-ide/launch_cursor.sh "$@"

echo -e "${GREEN}[SUCCESS]${NC} Cursor AI 종료"
EOF
    
    chmod +x "$CURSOR_DIR/launch.sh"
    
    # 최적화 스크립트 생성 (TROUBLESHOOTING.md 반영)
    cat > "$CURSOR_DIR/optimize.sh" << 'EOF'
#!/bin/bash

# 성능 최적화 스크립트
# Author: Mobile IDE Team

set -e

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}[INFO]${NC} 성능 최적화 시작..."

# 메모리 캐시 정리
echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true

# CPU 성능 모드 설정
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || true

# Ubuntu 환경에서 추가 최적화
proot-distro login ubuntu -- bash -c "
# 불필요한 패키지 정리
apt autoremove -y 2>/dev/null || true
apt clean 2>/dev/null || true

# 메모리 최적화
echo 'vm.swappiness=10' >> /etc/sysctl.conf 2>/dev/null || true
"

echo -e "${GREEN}[SUCCESS]${NC} 성능 최적화 완료"
EOF
    
    chmod +x "$CURSOR_DIR/optimize.sh"
    
    # 디버깅 스크립트 생성 (TROUBLESHOOTING.md 반영)
    cat > "$CURSOR_DIR/debug.sh" << 'EOF'
#!/bin/bash

# 디버깅 스크립트
# Author: Mobile IDE Team

set -e

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}[INFO]${NC} 시스템 진단 시작..."

# 시스템 정보
echo -e "${YELLOW}[SYSTEM]${NC} 시스템 정보:"
uname -a
echo "Android 버전: $(getprop ro.build.version.release 2>/dev/null || echo 'unknown')"
echo "아키텍처: $(uname -m)"

# 메모리 정보
echo -e "${YELLOW}[MEMORY]${NC} 메모리 정보:"
free -h

# 저장공간 정보
echo -e "${YELLOW}[STORAGE]${NC} 저장공간 정보:"
df -h

# 네트워크 정보
echo -e "${YELLOW}[NETWORK]${NC} 네트워크 정보:"
ping -c 1 google.com 2>/dev/null && echo "네트워크 연결: 정상" || echo "네트워크 연결: 실패"

# 프로세스 정보
echo -e "${YELLOW}[PROCESSES]${NC} 관련 프로세스:"
ps aux | grep -E "(cursor|Xvfb|proot)" | head -10

# Ubuntu 환경 확인
echo -e "${YELLOW}[UBUNTU]${NC} Ubuntu 환경:"
if [ -d "$HOME/ubuntu" ]; then
    echo "Ubuntu 환경: 설치됨"
    ls -la "$HOME/ubuntu/home/cursor-ide/" 2>/dev/null || echo "Cursor AI: 설치되지 않음"
else
    echo "Ubuntu 환경: 설치되지 않음"
fi

echo -e "${GREEN}[SUCCESS]${NC} 시스템 진단 완료"
EOF
    
    chmod +x "$CURSOR_DIR/debug.sh"
    
    log_success "설정 파일 생성 완료"
    return 0
}

# 최종 검증
final_verification() {
    log_info "최종 검증 중..."
    
    # Ubuntu 환경 확인
    if [ ! -d "$HOME/ubuntu" ]; then
        log_error "Ubuntu 환경이 설치되지 않았습니다."
        return 1
    fi
    
    # Cursor AI 확인
    if [ ! -f "$UBUNTU_HOME/cursor-ide/launch_cursor.sh" ]; then
        log_error "Cursor AI가 설치되지 않았습니다."
        return 1
    fi
    
    # 실행 권한 확인
    if [ ! -x "$UBUNTU_HOME/cursor-ide/launch_cursor.sh" ]; then
        log_warning "실행 권한 수정 중..."
        chmod +x "$UBUNTU_HOME/cursor-ide/launch_cursor.sh"
    fi
    
    log_success "최종 검증 완료"
    return 0
}

# 설치 요약 표시 (모든 가이드 반영)
show_installation_summary() {
    echo ""
    echo "=========================================="
    echo "  설치 완료 요약"
    echo "=========================================="
    echo ""
    echo "✅ 설치된 구성 요소:"
    echo "  - Ubuntu 22.04 LTS 환경"
    echo "  - Node.js 18 LTS (npm@10.8.2)"
    echo "  - Cursor AI IDE"
    echo "  - 실행 스크립트 (launch.sh)"
    echo "  - 최적화 스크립트 (optimize.sh)"
    echo "  - 디버깅 스크립트 (debug.sh)"
    echo ""
    echo "📁 설치 위치:"
    echo "  - Ubuntu 환경: ~/ubuntu/"
    echo "  - Cursor AI: ~/ubuntu/home/cursor-ide/"
    echo "  - 실행 스크립트: ~/cursor-ide/launch.sh"
    echo "  - 로그 파일: $LOG_FILE"
    echo ""
    if [ -d "$BACKUP_DIR" ]; then
        echo "📁 백업 위치: $BACKUP_DIR"
        echo ""
    fi
    echo "🚀 사용 방법:"
    echo "  cd $CURSOR_DIR"
    echo "  ./launch.sh"
    echo ""
    echo "⚡ 성능 최적화:"
    echo "  ./optimize.sh"
    echo ""
    echo "🔍 디버깅:"
    echo "  ./debug.sh"
    echo ""
    echo "🔧 문제 해결:"
    echo "  로그 파일 확인: $LOG_FILE"
    echo "  복구 스크립트: ./termux_complete_restore.sh"
    echo "  GitHub 이슈: https://github.com/huntkil/mobile_ide/issues"
    echo ""
    echo "📱 모바일 사용 팁:"
    echo "  - 터치 제스처로 확대/축소"
    echo "  - 가상 키보드 사용"
    echo "  - 정기적인 메모리 정리"
    echo ""
    echo "⚠️  주의사항:"
    echo "  - 첫 실행 시 시간이 걸릴 수 있습니다"
    echo "  - 메모리 사용량이 높을 수 있습니다"
    echo "  - 배터리 소모가 있을 수 있습니다"
    echo ""
}

# 메인 설치 함수
main_install() {
    echo ""
    echo "🚀 Galaxy Android용 Cursor AI IDE 완전 설치 스크립트 (모든 가이드 반영)"
    echo "=================================================================="
    echo ""
    
    # 로그 파일 초기화 (권한 안전)
    echo "설치 시작: $(date)" > "$LOG_FILE" 2>/dev/null || {
        echo "로그 파일 생성 실패, 로그 없이 진행합니다."
        LOG_FILE="/dev/null"
    }
    
    # 각 설치 단계 실행
    run_install_step "시스템 검증" validate_system || exit 1
    run_install_step "사용자 권한 확인" check_user_permissions || exit 1
    run_install_step "네트워크 연결 확인" check_network_connection || exit 1
    run_install_step "시스템 요구사항 확인" check_system_requirements || exit 1
    run_install_step "최소 의존성 패키지 설치" install_minimal_dependencies || exit 1
    run_install_step "Ubuntu 환경 설치" install_ubuntu_environment || exit 1
    run_install_step "Ubuntu 환경 완전 설정" setup_complete_ubuntu_environment || exit 1
    run_install_step "Cursor AI 다운로드 및 설치" download_and_install_cursor_ai || exit 1
    run_install_step "설정 파일 생성" create_configuration || exit 1
    run_install_step "최종 검증" final_verification || exit 1
    
    # 설치 요약 표시
    show_installation_summary
    
    # 로그 파일 정리
    echo "설치 완료: $(date)" >> "$LOG_FILE" 2>/dev/null || true
    
    log_success "모든 설치 단계 완료!"
}

# 스크립트 실행
main_install "$@" 