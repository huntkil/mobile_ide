#!/bin/bash

# WSL용 Cursor AI IDE 설치 스크립트
# Author: Mobile IDE Team
# Version: 1.0.0 - WSL 환경 최적화

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 전역 변수
SCRIPT_DIR="$(pwd)"
LOG_FILE="$HOME/cursor_wsl_install_$(date +%Y%m%d_%H%M%S).log"
LOG_LEVEL=${LOG_LEVEL:-INFO}
CURSOR_DIR="$HOME/cursor-ide"
LOCAL_APPIMAGE="$HOME/Cursor-1.2.1-aarch64.AppImage"

# 설치 단계 정의
INSTALL_STEPS=(
    "WSL 환경 검증"
    "로컬 AppImage 파일 확인"
    "시스템 의존성 설치"
    "X11 환경 설정"
    "로컬 AppImage 설치"
    "설정 파일 생성"
    "최종 검증"
)

# 설치 진행 상황 추적
CURRENT_STEP=0
TOTAL_STEPS=${#INSTALL_STEPS[@]}

# 로그 함수
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

# 진행 상황 표시
show_progress() {
    local current=$1
    local total=$2
    local step_name=$3
    
    local percentage=$((current * 100 / total))
    local filled=$((percentage / 2))
    local empty=$((50 - filled))
    
    printf "\r["
    printf "%${filled}s" | tr ' ' '#'
    printf "%${empty}s" | tr ' ' ' '
    printf "] %d%% (%d/%d) - %s" "$percentage" "$current" "$total" "$step_name"
}

# 설치 단계 실행
run_install_step() {
    local step_name="$1"
    local step_function="$2"
    
    ((CURRENT_STEP++))
    show_progress "$CURRENT_STEP" "$TOTAL_STEPS" "$step_name"
    echo ""
    
    log_info "$step_name: [$(printf '%*s' $((CURRENT_STEP * 50 / TOTAL_STEPS)) | tr ' ' '#')$(printf '%*s' $((50 - CURRENT_STEP * 50 / TOTAL_STEPS)) | tr ' ' ' ')] $CURRENT_STEP/$TOTAL_STEPS"
    
    if $step_function; then
        log_success "$(date '+%Y-%m-%d %H:%M:%S') - $step_name 완료"
        return 0
    else
        log_error "$(date '+%Y-%m-%d %H:%M:%S') - $step_name 실패"
        return 1
    fi
}

# WSL 환경 검증
validate_wsl_environment() {
    log_info "WSL 환경 검증 시작..."
    
    # WSL 환경 확인
    if ! grep -q Microsoft /proc/version 2>/dev/null; then
        log_warning "WSL 환경이 아닙니다. 일부 기능이 제한될 수 있습니다."
    else
        log_success "WSL 환경 확인됨"
    fi
    
    # 아키텍처 확인
    local arch=$(uname -m)
    if [[ "$arch" == "x86_64" ]]; then
        log_success "x86_64 아키텍처 확인됨"
    elif [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
        log_success "ARM64 아키텍처 확인됨"
    else
        log_warning "알 수 없는 아키텍처: $arch"
    fi
    
    # 사용자 권한 확인
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
    
    log_success "WSL 환경 검증 완료"
    return 0
}

# 로컬 AppImage 파일 확인
check_local_appimage() {
    log_info "로컬 AppImage 파일 확인 중..."
    
    if [ ! -f "$LOCAL_APPIMAGE" ]; then
        log_error "로컬 AppImage 파일을 찾을 수 없습니다: $LOCAL_APPIMAGE"
        echo ""
        echo "해결 방법:"
        echo "1. Cursor AI AppImage 파일을 $LOCAL_APPIMAGE 위치에 다운로드하세요"
        echo "2. 또는 다음 명령어로 다운로드하세요:"
        echo "   wget -O $LOCAL_APPIMAGE 'https://download.cursor.sh/linux/appImage/x64'"
        echo ""
        return 1
    fi
    
    # 파일 유효성 확인
    if ! file "$LOCAL_APPIMAGE" | grep -q "ELF\|AppImage\|executable"; then
        log_error "유효하지 않은 AppImage 파일입니다."
        file "$LOCAL_APPIMAGE"
        return 1
    fi
    
    log_success "로컬 AppImage 파일 확인 완료: $LOCAL_APPIMAGE"
    return 0
}

# 시스템 의존성 설치
install_system_dependencies() {
    log_info "시스템 의존성 설치 중..."
    
    # 패키지 목록 업데이트
    log_info "패키지 목록 업데이트..."
    sudo apt update -y || {
        log_warning "패키지 업데이트 실패, 계속 진행..."
    }
    
    # 필수 패키지 설치
    local required_packages=(
        "curl" "wget" "git" "build-essential" "python3" "python3-pip"
        "xvfb" "x11-apps" "x11-utils" "x11-xserver-utils" "dbus-x11"
        "libx11-6" "libxext6" "libxrender1" "libxtst6" "libxi6"
        "libxrandr2" "libxss1" "libxcb1" "libxcomposite1"
        "libxcursor1" "libxdamage1" "libxfixes3" "libxinerama1"
        "libnss3" "libcups2" "libdrm2" "libxkbcommon0"
        "libatspi2.0-0" "libgtk-3-0" "libgbm1" "libasound2"
        "squashfs-tools" "p7zip-full"
    )
    
    for package in "${required_packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            log_info "$package 설치 중..."
            sudo apt install -y "$package" || {
                log_warning "$package 설치 실패, 계속 진행..."
            }
        else
            log_info "$package 이미 설치됨"
        fi
    done
    
    # Node.js 설치
    log_info "Node.js 설치 중..."
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt install -y nodejs
    else
        log_info "Node.js 이미 설치됨"
    fi
    
    # npm 업데이트
    log_info "npm 업데이트 중..."
    sudo npm install -g npm@latest
    
    # 전역 패키지 설치
    log_info "전역 패키지 설치 중..."
    sudo npm install -g yarn typescript ts-node || {
        log_warning "일부 전역 패키지 설치 실패, 계속 진행..."
    }
    
    log_success "시스템 의존성 설치 완료"
    return 0
}

# X11 환경 설정
setup_x11_environment() {
    log_info "X11 환경 설정 중..."
    
    # Xvfb 시작
    log_info "Xvfb 시작 중..."
    Xvfb :0 -screen 0 1200x800x24 -ac +extension GLX +render -noreset &
    XVFB_PID=$!
    sleep 3
    
    # DISPLAY 변수 설정
    export DISPLAY=:0
    
    # X11 권한 설정
    xhost +local: 2>/dev/null || {
        log_warning "X11 권한 설정 실패, 계속 진행..."
    }
    
    log_success "X11 환경 설정 완료"
    return 0
}

# 로컬 AppImage 설치
install_local_appimage() {
    log_info "로컬 AppImage 설치 중..."
    
    # 작업 디렉토리 생성
    mkdir -p "$CURSOR_DIR"
    cd "$CURSOR_DIR"
    
    # 로컬 AppImage 파일 복사
    log_info "로컬 AppImage 파일 복사 중..."
    cp "$LOCAL_APPIMAGE" ./cursor.AppImage
    
    # 실행 권한 부여
    chmod +x cursor.AppImage
    
    # AppImage 추출
    log_info "AppImage 추출 중..."
    if ./cursor.AppImage --appimage-extract 2>/dev/null; then
        log_success "기본 추출 성공"
    elif ./cursor.AppImage --appimage-extract-and-run 2>/dev/null; then
        log_success "추출 및 실행 방법 성공"
    else
        log_warning "자동 추출 실패, 수동 추출 시도..."
        # 수동 추출 방법들
        if command -v unsquashfs &> /dev/null; then
            unsquashfs -f -d squashfs-root cursor.AppImage 2>/dev/null || {
                log_warning "unsquashfs 추출 실패"
            }
        fi
        
        if command -v 7z &> /dev/null; then
            7z x cursor.AppImage -osquashfs-root 2>/dev/null || {
                log_warning "7z 추출 실패"
            }
        fi
    fi
    
    # 실행 스크립트 생성
    cat > launch_cursor.sh << 'EOF'
#!/bin/bash

# Cursor AI 실행 스크립트 (WSL 버전)
# Author: Mobile IDE Team

set -e

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}[INFO]${NC} Cursor AI 시작 중..."

# X11 환경 확인
if [ -z "$DISPLAY" ]; then
    echo -e "${YELLOW}[WARNING]${NC} DISPLAY 변수가 설정되지 않았습니다."
    echo -e "${BLUE}[INFO]${NC} Xvfb 시작 중..."
    Xvfb :0 -screen 0 1200x800x24 -ac +extension GLX +render -noreset &
    XVFB_PID=$!
    sleep 3
    export DISPLAY=:0
fi

# X11 권한 설정
xhost +local: 2>/dev/null || true

# Cursor AI 실행
cd "$(dirname "$0")"
if [ -f "./squashfs-root/cursor" ]; then
    echo -e "${BLUE}[INFO]${NC} 추출된 Cursor AI 실행..."
    ./squashfs-root/cursor "$@"
elif [ -f "./cursor.AppImage" ]; then
    echo -e "${BLUE}[INFO]${NC} AppImage 직접 실행..."
    ./cursor.AppImage "$@"
else
    echo -e "${RED}[ERROR]${NC} Cursor AI 실행 파일을 찾을 수 없습니다."
    exit 1
fi

# Xvfb 정리
if [ ! -z "$XVFB_PID" ]; then
    kill $XVFB_PID 2>/dev/null || true
fi

echo -e "${GREEN}[SUCCESS]${NC} Cursor AI 종료"
EOF
    
    chmod +x launch_cursor.sh
    
    log_success "로컬 AppImage 설치 완료"
    return 0
}

# 설정 파일 생성
create_configuration() {
    log_info "설정 파일 생성 중..."
    
    # 실행 스크립트 생성
    cat > "$CURSOR_DIR/launch.sh" << 'EOF'
#!/bin/bash

# Cursor AI 실행 스크립트 (WSL 버전)
# Author: Mobile IDE Team

set -e

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}[INFO]${NC} Cursor AI 시작 중..."

# Cursor AI 실행
cd "$HOME/cursor-ide"
./launch_cursor.sh "$@"

echo -e "${GREEN}[SUCCESS]${NC} Cursor AI 종료"
EOF
    
    chmod +x "$CURSOR_DIR/launch.sh"
    
    # 최적화 스크립트 생성
    cat > "$CURSOR_DIR/optimize.sh" << 'EOF'
#!/bin/bash

# 성능 최적화 스크립트 (WSL 버전)
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

# 불필요한 패키지 정리
sudo apt autoremove -y 2>/dev/null || true
sudo apt clean 2>/dev/null || true

echo -e "${GREEN}[SUCCESS]${NC} 성능 최적화 완료"
EOF
    
    chmod +x "$CURSOR_DIR/optimize.sh"
    
    # 디버깅 스크립트 생성
    cat > "$CURSOR_DIR/debug.sh" << 'EOF'
#!/bin/bash

# 디버깅 스크립트 (WSL 버전)
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
echo "WSL 버전: $(grep -o Microsoft /proc/version 2>/dev/null || echo 'unknown')"

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
ps aux | grep -E "(cursor|Xvfb)" | head -10

# X11 환경 확인
echo -e "${YELLOW}[X11]${NC} X11 환경:"
echo "DISPLAY: $DISPLAY"
xhost 2>/dev/null || echo "X11 서버: 연결되지 않음"

# Cursor AI 확인
echo -e "${YELLOW}[CURSOR]${NC} Cursor AI:"
if [ -f "$HOME/cursor-ide/launch_cursor.sh" ]; then
    echo "Cursor AI: 설치됨"
    ls -la "$HOME/cursor-ide/"
else
    echo "Cursor AI: 설치되지 않음"
fi

# 로컬 AppImage 파일 확인
echo -e "${YELLOW}[LOCAL_APPIMAGE]${NC} 로컬 AppImage:"
if [ -f "$HOME/Cursor-1.2.1-aarch64.AppImage" ]; then
    echo "로컬 AppImage: 발견됨"
    ls -la "$HOME/Cursor-1.2.1-aarch64.AppImage"
else
    echo "로컬 AppImage: 발견되지 않음"
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
    
    # Cursor AI 확인
    if [ ! -f "$CURSOR_DIR/launch_cursor.sh" ]; then
        log_error "Cursor AI가 설치되지 않았습니다."
        return 1
    fi
    
    # 실행 권한 확인
    if [ ! -x "$CURSOR_DIR/launch_cursor.sh" ]; then
        log_warning "실행 권한 수정 중..."
        chmod +x "$CURSOR_DIR/launch_cursor.sh"
    fi
    
    # X11 환경 확인
    if [ -z "$DISPLAY" ]; then
        log_warning "DISPLAY 변수가 설정되지 않았습니다."
    fi
    
    log_success "최종 검증 완료"
    return 0
}

# 설치 요약 표시
show_installation_summary() {
    echo ""
    echo "=========================================="
    echo "  WSL용 Cursor AI IDE 설치 완료 요약"
    echo "=========================================="
    echo ""
    echo "✅ 설치된 구성 요소:"
    echo "  - 시스템 의존성 패키지"
    echo "  - Node.js 18 LTS"
    echo "  - Cursor AI IDE (로컬 AppImage)"
    echo "  - X11 환경 설정"
    echo "  - 실행 스크립트 (launch.sh)"
    echo "  - 최적화 스크립트 (optimize.sh)"
    echo "  - 디버깅 스크립트 (debug.sh)"
    echo ""
    echo "📁 설치 위치:"
    echo "  - Cursor AI: $CURSOR_DIR/"
    echo "  - 실행 스크립트: $CURSOR_DIR/launch.sh"
    echo "  - 로그 파일: $LOG_FILE"
    echo "  - 로컬 AppImage: $LOCAL_APPIMAGE"
    echo ""
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
    echo "  로컬 AppImage 확인: $LOCAL_APPIMAGE"
    echo "  GitHub 이슈: https://github.com/huntkil/mobile_ide/issues"
    echo ""
    echo "📱 WSL 사용 팁:"
    echo "  - Windows Terminal 사용 권장"
    echo "  - GPU 가속 활성화 (WSLg)"
    echo "  - 메모리 제한 조정"
    echo ""
    echo "⚠️  주의사항:"
    echo "  - 첫 실행 시 시간이 걸릴 수 있습니다"
    echo "  - X11 서버가 필요합니다"
    echo "  - WSLg 또는 VcXsrv 사용 권장"
    echo ""
}

# 메인 설치 함수
main_install() {
    echo ""
    echo "🚀 WSL용 Cursor AI IDE 설치 스크립트"
    echo "===================================="
    echo ""
    
    # 로그 파일 초기화
    echo "WSL 설치 시작: $(date)" > "$LOG_FILE" 2>/dev/null || {
        echo "로그 파일 생성 실패, 로그 없이 진행합니다."
        LOG_FILE="/dev/null"
    }
    
    # 각 설치 단계 실행
    run_install_step "WSL 환경 검증" validate_wsl_environment || exit 1
    run_install_step "로컬 AppImage 파일 확인" check_local_appimage || exit 1
    run_install_step "시스템 의존성 설치" install_system_dependencies || exit 1
    run_install_step "X11 환경 설정" setup_x11_environment || exit 1
    run_install_step "로컬 AppImage 설치" install_local_appimage || exit 1
    run_install_step "설정 파일 생성" create_configuration || exit 1
    run_install_step "최종 검증" final_verification || exit 1
    
    # 설치 요약 표시
    show_installation_summary
    
    # 로그 파일 정리
    echo "WSL 설치 완료: $(date)" >> "$LOG_FILE" 2>/dev/null || true
    
    log_success "모든 설치 단계 완료!"
}

# 스크립트 실행
main_install "$@" 