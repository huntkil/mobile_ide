#!/bin/bash

# Galaxy Android용 Cursor AI IDE 최소 설치 스크립트 (Termux 최적화)
# Author: Mobile IDE Team
# Version: 3.0.0 - 최소 패키지 설치 버전
# 패키지 충돌 문제를 피하고 필수적인 것만 설치

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# 전역 변수 (안전한 로그 파일 위치)
SCRIPT_DIR="$(pwd)"
LOG_FILE="$HOME/cursor_install_$(date +%Y%m%d_%H%M%S).log"
CURSOR_DIR="$HOME/cursor-ide"
UBUNTU_HOME="$HOME/ubuntu/home"
INSTALL_STEPS=0
TOTAL_STEPS=10

# 로그 함수 (권한 문제 해결)
log_info() {
    local message="$1"
    echo -e "${BLUE}[INFO]${NC} $message"
    echo "[INFO] $message" >> "$LOG_FILE" 2>/dev/null || true
}

log_success() {
    local message="$1"
    echo -e "${GREEN}[SUCCESS]${NC} $message"
    echo "[SUCCESS] $message" >> "$LOG_FILE" 2>/dev/null || true
}

log_warning() {
    local message="$1"
    echo -e "${YELLOW}[WARNING]${NC} $message"
    echo "[WARNING] $message" >> "$LOG_FILE" 2>/dev/null || true
}

log_error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} $message"
    echo "[ERROR] $message" >> "$LOG_FILE" 2>/dev/null || true
}

log_step() {
    INSTALL_STEPS=$((INSTALL_STEPS + 1))
    local message="$1"
    echo -e "${PURPLE}[STEP $INSTALL_STEPS/$TOTAL_STEPS]${NC} $message"
    echo "[STEP $INSTALL_STEPS/$TOTAL_STEPS] $message" >> "$LOG_FILE" 2>/dev/null || true
}

# 시스템 정보 확인
check_system_requirements() {
    log_step "시스템 요구사항 확인"
    
    # Android 버전 확인
    local android_version
    android_version=$(getprop ro.build.version.release 2>/dev/null || echo "unknown")
    log_info "Android 버전: $android_version"
    
    # 아키텍처 확인
    local arch
    arch=$(uname -m)
    log_info "아키텍처: $arch"
    
    # 메모리 확인
    local mem_total
    mem_total=$(free -h | grep Mem | awk '{print $2}')
    log_info "총 메모리: $mem_total"
    
    # 저장공간 확인
    local disk_free
    disk_free=$(df -h /data | tail -1 | awk '{print $4}')
    log_info "사용 가능한 저장공간: $disk_free"
    
    log_success "시스템 요구사항 확인 완료"
}

# 사용자 권한 확인
check_user_permissions() {
    log_step "사용자 권한 확인"
    
    # root 사용자 확인
    if [ "$(id -u)" -eq 0 ]; then
        log_error "root 사용자로 실행할 수 없습니다."
        exit 1
    fi
    
    # 홈 디렉토리 쓰기 권한 확인
    if [ ! -w "$HOME" ]; then
        log_error "홈 디렉토리에 쓰기 권한이 없습니다."
        exit 1
    fi
    
    log_success "사용자 권한 확인 완료"
}

# 네트워크 연결 확인
check_network_connection() {
    log_step "네트워크 연결 확인"
    
    # DNS 설정 확인 및 수정
    if ! ping -c 1 google.com &> /dev/null; then
        log_warning "네트워크 연결 문제 감지, DNS 설정 수정..."
        echo "nameserver 8.8.8.8" > /etc/resolv.conf 2>/dev/null || true
        echo "nameserver 8.8.4.4" >> /etc/resolv.conf 2>/dev/null || true
        
        if ! ping -c 1 google.com &> /dev/null; then
            log_error "네트워크 연결을 확인할 수 없습니다."
            exit 1
        fi
    fi
    
    log_success "네트워크 연결 확인 완료"
}

# 최소 의존성 패키지 설치
install_minimal_dependencies() {
    log_step "최소 의존성 패키지 설치"
    
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
        exit 1
    fi
    
    log_success "최소 의존성 패키지 설치 완료"
}

# Ubuntu 환경 설치
install_ubuntu_environment() {
    log_step "Ubuntu 환경 설치"
    
    # 기존 Ubuntu 환경 확인
    if [ -d "$HOME/ubuntu" ]; then
        log_info "기존 Ubuntu 환경 발견, 제거 중..."
        proot-distro remove ubuntu 2>/dev/null || true
        rm -rf "$HOME/ubuntu" 2>/dev/null || true
    fi
    
    # Ubuntu 설치
    log_info "Ubuntu 22.04 LTS 설치 중..."
    proot-distro install ubuntu || {
        log_error "Ubuntu 설치에 실패했습니다."
        exit 1
    }
    
    log_success "Ubuntu 환경 설치 완료"
}

# Ubuntu 환경 최소 설정
setup_minimal_ubuntu_environment() {
    log_step "Ubuntu 환경 최소 설정"
    
    # Ubuntu 환경에서 실행할 스크립트 생성
    cat > "$HOME/setup_minimal_ubuntu.sh" << 'EOF'
#!/bin/bash
set -e

echo "Ubuntu 환경 최소 설정 시작..."

# 패키지 목록 업데이트 (재시도 로직)
for i in {1..3}; do
    if apt update; then
        break
    else
        echo "패키지 업데이트 실패, 재시도 $i/3..."
        sleep 2
    fi
done

# 최소한의 필수 패키지만 설치
echo "최소 필수 패키지 설치 중..."

# 기본 도구들
apt install -y curl wget git

# X11 최소 패키지 (충돌 가능성 낮은 것들만)
apt install -y xvfb || echo "xvfb 설치 실패, 계속 진행..."

# 기본 라이브러리들 (안전한 것들만)
apt install -y libx11-6 libxext6 libxrender1 || echo "일부 X11 라이브러리 설치 실패, 계속 진행..."

# Node.js 18 LTS 설치
echo "Node.js 18 LTS 설치 중..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# npm 업데이트
npm install -g npm@latest

# 작업 디렉토리 생성
mkdir -p /home/cursor-ide
cd /home/cursor-ide

echo "Ubuntu 환경 최소 설정 완료"
EOF
    
    # Ubuntu 환경에서 스크립트 실행
    log_info "Ubuntu 환경에서 최소 설정 스크립트 실행..."
    proot-distro login ubuntu -- bash "$HOME/setup_minimal_ubuntu.sh" || {
        log_error "Ubuntu 환경 최소 설정에 실패했습니다."
        exit 1
    }
    
    # 임시 스크립트 정리
    rm -f "$HOME/setup_minimal_ubuntu.sh"
    
    log_success "Ubuntu 환경 최소 설정 완료"
}

# Cursor AI 다운로드
download_cursor_ai() {
    log_step "Cursor AI 다운로드"
    
    # 다운로드 URL 목록
    local download_urls=(
        "https://download.cursor.sh/linux/appImage/arm64"
        "https://cursor.sh/download/linux/arm64"
        "https://github.com/getcursor/cursor/releases/latest/download/cursor-linux-arm64.AppImage"
    )
    
    local download_success=false
    
    # 여러 URL에서 다운로드 시도
    for url in "${download_urls[@]}"; do
        log_info "다운로드 시도: $url"
        
        if wget --timeout=60 --tries=3 -O "$HOME/cursor.AppImage" "$url" 2>/dev/null; then
            download_success=true
            break
        fi
        
        if curl --connect-timeout 60 --retry 3 -L -o "$HOME/cursor.AppImage" "$url" 2>/dev/null; then
            download_success=true
            break
        fi
        
        log_warning "다운로드 실패: $url"
    done
    
    if [ "$download_success" = false ]; then
        log_error "모든 다운로드 URL에서 실패했습니다."
        echo ""
        echo "수동 다운로드 방법:"
        echo "1. 브라우저에서 https://cursor.sh/download 접속"
        echo "2. Linux ARM64 버전 다운로드"
        echo "3. 다운로드한 파일을 $HOME/cursor.AppImage로 복사"
        echo ""
        read -p "수동 다운로드 완료 후 Enter를 누르세요..."
        
        if [ ! -f "$HOME/cursor.AppImage" ]; then
            log_error "수동 다운로드 파일을 찾을 수 없습니다"
            exit 1
        fi
    fi
    
    log_success "Cursor AI 다운로드 완료"
}

# Cursor AI 설치
install_cursor_ai() {
    log_step "Cursor AI 설치"
    
    # Ubuntu 환경에서 설치
    cat > "$HOME/install_cursor_minimal.sh" << 'EOF'
#!/bin/bash
set -e

cd /home/cursor-ide

# AppImage 파일 복사
cp /home/cursor.AppImage ./cursor.AppImage

# 실행 권한 부여
chmod +x cursor.AppImage

# AppImage 추출
echo "AppImage 추출 중..."
./cursor.AppImage --appimage-extract || {
    echo "AppImage 추출 실패, 대체 방법 시도..."
    ./cursor.AppImage --appimage-extract-and-run || {
        echo "모든 추출 방법 실패"
        exit 1
    }
}

# 간단한 실행 스크립트 생성
cat > launch_cursor.sh << 'LAUNCH_EOF'
#!/bin/bash
cd /home/cursor-ide
export DISPLAY=:0

# Xvfb 시작 (백그라운드)
Xvfb :0 -screen 0 1200x800x24 &
XVFB_PID=$!

# 잠시 대기
sleep 2

# Cursor 실행
./squashfs-root/cursor "$@"

# Xvfb 종료
kill $XVFB_PID 2>/dev/null || true
LAUNCH_EOF

chmod +x launch_cursor.sh

echo "Cursor AI 설치 완료"
EOF
    
    # Ubuntu 환경에서 설치 스크립트 실행
    log_info "Ubuntu 환경에서 Cursor AI 설치..."
    proot-distro login ubuntu -- bash "$HOME/install_cursor_minimal.sh" || {
        log_error "Cursor AI 설치에 실패했습니다."
        exit 1
    }
    
    # 임시 스크립트 정리
    rm -f "$HOME/install_cursor_minimal.sh"
    
    log_success "Cursor AI 설치 완료"
}

# 설정 파일 생성
create_configuration() {
    log_step "설정 파일 생성"
    
    # Cursor 설정 디렉토리 생성
    mkdir -p "$CURSOR_DIR"
    
    # 실행 스크립트 생성
    cat > "$CURSOR_DIR/launch.sh" << 'EOF'
#!/bin/bash

# Cursor AI 실행 스크립트
# Author: Mobile IDE Team

set -e

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[INFO]${NC} Cursor AI 시작 중..."

# Ubuntu 환경에서 Cursor 실행
proot-distro login ubuntu -- bash /home/cursor-ide/launch_cursor.sh "$@"

echo -e "${GREEN}[SUCCESS]${NC} Cursor AI 종료"
EOF
    
    chmod +x "$CURSOR_DIR/launch.sh"
    
    log_success "설정 파일 생성 완료"
}

# 최종 검증
final_verification() {
    log_step "최종 검증"
    
    # Ubuntu 환경 확인
    if [ ! -d "$HOME/ubuntu" ]; then
        log_error "Ubuntu 환경이 설치되지 않았습니다."
        exit 1
    fi
    
    # Cursor AI 확인
    if [ ! -f "$UBUNTU_HOME/cursor-ide/launch_cursor.sh" ]; then
        log_error "Cursor AI가 설치되지 않았습니다."
        exit 1
    fi
    
    # 실행 권한 확인
    if [ ! -x "$UBUNTU_HOME/cursor-ide/launch_cursor.sh" ]; then
        log_warning "실행 권한 수정 중..."
        chmod +x "$UBUNTU_HOME/cursor-ide/launch_cursor.sh"
    fi
    
    log_success "최종 검증 완료"
}

# 설치 완료 메시지
show_completion_message() {
    log_step "설치 완료"
    
    echo ""
    echo "🎉 Cursor AI IDE 최소 설치가 완료되었습니다!"
    echo ""
    echo "📁 설치 위치: $CURSOR_DIR"
    echo "📁 Ubuntu 환경: $HOME/ubuntu"
    echo "📄 로그 파일: $LOG_FILE"
    echo ""
    echo "🚀 실행 방법:"
    echo "  cd $CURSOR_DIR"
    echo "  ./launch.sh"
    echo ""
    echo "⚠️  주의사항:"
    echo "  - 최소 설치로 일부 기능이 제한될 수 있습니다"
    echo "  - 첫 실행 시 시간이 걸릴 수 있습니다"
    echo "  - 문제 발생 시 완전 설치 스크립트를 사용하세요"
    echo ""
    
    log_success "최소 설치 프로세스 완료!"
}

# 메인 실행 함수
main() {
    echo ""
    echo "🚀 Galaxy Android용 Cursor AI IDE 최소 설치 스크립트 (Termux 최적화)"
    echo "=================================================================="
    echo ""
    
    # 로그 파일 초기화 (권한 안전)
    echo "최소 설치 시작: $(date)" > "$LOG_FILE" 2>/dev/null || {
        echo "로그 파일 생성 실패, 로그 없이 진행합니다."
        LOG_FILE="/dev/null"
    }
    
    # 각 단계 실행
    check_system_requirements
    check_user_permissions
    check_network_connection
    install_minimal_dependencies
    install_ubuntu_environment
    setup_minimal_ubuntu_environment
    download_cursor_ai
    install_cursor_ai
    create_configuration
    final_verification
    show_completion_message
    
    # 로그 파일 정리
    echo "최소 설치 완료: $(date)" >> "$LOG_FILE" 2>/dev/null || true
}

# 스크립트 실행
main "$@" 