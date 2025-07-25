#!/bin/bash

# Galaxy Android용 Cursor AI IDE 안전 복구 스크립트 (Termux 최적화)
# Author: Mobile IDE Team
# Version: 2.2.0 - 권한 문제 완전 해결 버전
# 모든 문제 상황을 해결하고 환경을 완전히 복구

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
LOG_FILE="$HOME/cursor_restore_$(date +%Y%m%d_%H%M%S).log"
CURSOR_DIR="$HOME/cursor-ide"
UBUNTU_HOME="$HOME/ubuntu/home"
BACKUP_DIR="$HOME/cursor_backup_$(date +%Y%m%d_%H%M%S)"

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

# 시스템 상태 진단
diagnose_system() {
    log_info "시스템 상태 진단 시작..."
    
    echo ""
    echo "🔍 시스템 정보:"
    echo "  Android 버전: $(getprop ro.build.version.release 2>/dev/null || echo 'unknown')"
    echo "  아키텍처: $(uname -m)"
    echo "  메모리: $(free -h | grep Mem | awk '{print $2}')"
    echo "  저장공간: $(df -h /data | tail -1 | awk '{print $4}')"
    echo "  사용자: $(whoami) (UID: $(id -u))"
    
    echo ""
    echo "🔍 설치 상태 확인:"
    
    # Ubuntu 환경 확인
    if [ -d "$HOME/ubuntu" ]; then
        echo "  ✅ Ubuntu 환경: 설치됨"
    else
        echo "  ❌ Ubuntu 환경: 설치되지 않음"
    fi
    
    # Cursor AI 확인
    if [ -f "$UBUNTU_HOME/cursor-ide/launch_cursor.sh" ]; then
        echo "  ✅ Cursor AI: 설치됨"
    else
        echo "  ❌ Cursor AI: 설치되지 않음"
    fi
    
    # proot-distro 확인
    if command -v proot-distro &> /dev/null; then
        echo "  ✅ proot-distro: 설치됨"
    else
        echo "  ❌ proot-distro: 설치되지 않음"
    fi
    
    # 네트워크 연결 확인
    if ping -c 1 google.com &> /dev/null; then
        echo "  ✅ 네트워크: 연결됨"
    else
        echo "  ❌ 네트워크: 연결 안됨"
    fi
    
    echo ""
}

# 네트워크 문제 해결
fix_network_issues() {
    log_info "네트워크 문제 해결 중..."
    
    # DNS 설정 수정
    log_info "DNS 설정 수정..."
    echo "nameserver 8.8.8.8" > /etc/resolv.conf 2>/dev/null || true
    echo "nameserver 8.8.4.4" >> /etc/resolv.conf 2>/dev/null || true
    echo "nameserver 1.1.1.1" >> /etc/resolv.conf 2>/dev/null || true
    
    # 네트워크 재시작 (가능한 경우)
    if command -v systemctl &> /dev/null; then
        systemctl restart systemd-resolved 2>/dev/null || true
    fi
    
    # 연결 테스트
    if ping -c 1 google.com &> /dev/null; then
        log_success "네트워크 연결 복구됨"
    else
        log_warning "네트워크 연결 문제가 지속됩니다"
    fi
}

# 권한 문제 해결
fix_permission_issues() {
    log_info "권한 문제 해결 중..."
    
    # 홈 디렉토리 권한 수정
    if [ -d "$HOME" ]; then
        chmod 755 "$HOME" 2>/dev/null || true
    fi
    
    # Cursor 디렉토리 권한 수정
    if [ -d "$CURSOR_DIR" ]; then
        chmod -R 755 "$CURSOR_DIR" 2>/dev/null || true
    fi
    
    # Ubuntu 환경 권한 수정
    if [ -d "$HOME/ubuntu" ]; then
        chmod -R 755 "$HOME/ubuntu" 2>/dev/null || true
    fi
    
    # 임시 파일 권한 수정 (안전한 위치)
    chmod 755 "$HOME" 2>/dev/null || true
    
    log_success "권한 문제 해결 완료"
}

# 패키지 문제 해결
fix_package_issues() {
    log_info "패키지 문제 해결 중..."
    
    # Termux 패키지 업데이트
    log_info "패키지 목록 업데이트..."
    pkg update -y || {
        log_warning "패키지 업데이트 실패"
    }
    
    # 필수 패키지 재설치
    local required_packages=(
        "curl" "wget" "proot" "tar" "unzip" "proot-distro"
        "git" "build-essential" "python3" "python3-pip"
    )
    
    for package in "${required_packages[@]}"; do
        log_info "$package 재설치 중..."
        pkg install -y "$package" || {
            log_warning "$package 재설치 실패"
        }
    done
    
    log_success "패키지 문제 해결 완료"
}

# Ubuntu 환경 복구
restore_ubuntu_environment() {
    log_info "Ubuntu 환경 복구 중..."
    
    # 기존 환경 백업
    if [ -d "$HOME/ubuntu" ]; then
        log_info "기존 Ubuntu 환경 백업 중..."
        mkdir -p "$BACKUP_DIR"
        cp -r "$HOME/ubuntu" "$BACKUP_DIR/" 2>/dev/null || true
        log_info "백업 완료: $BACKUP_DIR"
    fi
    
    # 기존 환경 제거
    log_info "기존 Ubuntu 환경 제거 중..."
    proot-distro remove ubuntu 2>/dev/null || true
    rm -rf "$HOME/ubuntu" 2>/dev/null || true
    
    # 새 Ubuntu 환경 설치
    log_info "새 Ubuntu 환경 설치 중..."
    proot-distro install ubuntu || {
        log_error "Ubuntu 환경 설치 실패"
        return 1
    }
    
    # Ubuntu 환경 설정
    log_info "Ubuntu 환경 설정 중..."
    cat > "$HOME/restore_ubuntu_internal.sh" << 'EOF'
#!/bin/bash
set -e

echo "Ubuntu 환경 설정 시작..."

# 패키지 목록 업데이트 (재시도 로직)
for i in {1..3}; do
    if apt update; then
        break
    else
        echo "패키지 업데이트 실패, 재시도 $i/3..."
        sleep 2
    fi
done

# 필수 패키지 설치
apt install -y curl wget git build-essential python3 python3-pip
apt install -y xvfb x11-apps x11-utils x11-xserver-utils dbus-x11

# 추가 라이브러리 (Termux Ubuntu 환경에 맞게 수정)
echo "X11 라이브러리 설치 중..."

# 기본 X11 라이브러리
apt install -y libx11-6 libxext6 libxrender1 libxtst6 libxi6
apt install -y libxrandr2 libxss1 libxcb1 libxcomposite1
apt install -y libxcursor1 libxdamage1 libxfixes3 libxinerama1
apt install -y libnss3 libcups2 libdrm2 libxkbcommon0

# Termux Ubuntu 환경용 패키지 (t64 접미사 포함)
echo "Termux 전용 라이브러리 설치 중..."

# libatspi2.0-0 대신 libatspi2.0-0t64 사용
apt install -y libatspi2.0-0t64 || {
    echo "libatspi2.0-0t64 설치 실패, 기본 버전 시도..."
    apt install -y libatspi2.0-0 || true
}

# libgtk-3-0 대신 libgtk-3-0t64 사용
apt install -y libgtk-3-0t64 || {
    echo "libgtk-3-0t64 설치 실패, 기본 버전 시도..."
    apt install -y libgtk-3-0 || true
}

# libgbm1 설치
apt install -y libgbm1 || {
    echo "libgbm1 설치 실패, 건너뜀..."
}

# libasound2 대신 libasound2t64 사용
apt install -y libasound2t64 || {
    echo "libasound2t64 설치 실패, 기본 버전 시도..."
    apt install -y libasound2 || {
        echo "libasound2도 설치 실패, 건너뜀..."
    }
}

# 추가 의존성 패키지들
echo "추가 의존성 패키지 설치 중..."

# 일반적인 개발 라이브러리들
apt install -y libglib2.0-0 libpango-1.0-0 libcairo2 libgdk-pixbuf2.0-0 || {
    echo "일부 GTK 의존성 설치 실패, 계속 진행..."
}

# Node.js 18 LTS 설치
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# npm 업데이트
npm install -g npm@latest

# 추가 개발 도구
npm install -g yarn typescript ts-node

# 작업 디렉토리 생성
mkdir -p /home/cursor-ide
cd /home/cursor-ide

echo "Ubuntu 환경 설정 완료"
EOF
    
    proot-distro login ubuntu -- bash "$HOME/restore_ubuntu_internal.sh" || {
        log_error "Ubuntu 환경 설정 실패"
        return 1
    }
    
    rm -f "$HOME/restore_ubuntu_internal.sh"
    
    log_success "Ubuntu 환경 복구 완료"
}

# Cursor AI 재설치
reinstall_cursor_ai() {
    log_info "Cursor AI 재설치 중..."
    
    # 임시 파일 정리 (안전한 위치)
    rm -f "$HOME/cursor*.AppImage" 2>/dev/null || true
    rm -f "$HOME/cursor*.deb" 2>/dev/null || true
    
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
        log_error "다운로드 실패"
        echo ""
        echo "수동 다운로드 방법:"
        echo "1. 브라우저에서 https://cursor.sh/download 접속"
        echo "2. Linux ARM64 버전 다운로드"
        echo "3. 다운로드한 파일을 $HOME/cursor.AppImage로 복사"
        echo ""
        read -p "수동 다운로드 완료 후 Enter를 누르세요..."
        
        if [ ! -f "$HOME/cursor.AppImage" ]; then
            log_error "수동 다운로드 파일을 찾을 수 없습니다"
            return 1
        fi
    fi
    
    # Ubuntu 환경에서 설치
    cat > "$HOME/reinstall_cursor_internal.sh" << 'EOF'
#!/bin/bash
set -e

cd /home/cursor-ide

# 기존 설치 제거
rm -rf squashfs-root 2>/dev/null || true
rm -f cursor.AppImage 2>/dev/null || true
rm -f launch_cursor.sh 2>/dev/null || true

# AppImage 파일 복사 (안전한 위치에서)
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

# 실행 스크립트 생성
cat > launch_cursor.sh << 'LAUNCH_EOF'
#!/bin/bash
cd /home/cursor-ide
export DISPLAY=:0
export XDG_RUNTIME_DIR=/tmp/runtime-cursor
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

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

echo "Cursor AI 재설치 완료"
EOF
    
    proot-distro login ubuntu -- bash "$HOME/reinstall_cursor_internal.sh" || {
        log_error "Cursor AI 재설치 실패"
        return 1
    }
    
    rm -f "$HOME/reinstall_cursor_internal.sh"
    
    log_success "Cursor AI 재설치 완료"
}

# 설정 파일 복구
restore_configuration() {
    log_info "설정 파일 복구 중..."
    
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
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}[INFO]${NC} Cursor AI 시작 중..."

# Ubuntu 환경에서 Cursor 실행
proot-distro login ubuntu -- bash /home/cursor-ide/launch_cursor.sh "$@"

echo -e "${GREEN}[SUCCESS]${NC} Cursor AI 종료"
EOF
    
    chmod +x "$CURSOR_DIR/launch.sh"
    
    # 최적화 스크립트 생성
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
    
    # 설정 파일 복사
    if [ -f "config/cursor-config.json" ]; then
        cp "config/cursor-config.json" "$CURSOR_DIR/"
        log_info "기본 설정 파일 복사됨"
    fi
    
    log_success "설정 파일 복구 완료"
}

# 최종 검증
final_verification() {
    log_info "최종 검증 중..."
    
    local all_good=true
    
    # Ubuntu 환경 확인
    if [ ! -d "$HOME/ubuntu" ]; then
        log_error "Ubuntu 환경이 없습니다"
        all_good=false
    fi
    
    # Cursor AI 확인
    if [ ! -f "$UBUNTU_HOME/cursor-ide/launch_cursor.sh" ]; then
        log_error "Cursor AI가 설치되지 않았습니다"
        all_good=false
    fi
    
    # 실행 권한 확인
    if [ ! -x "$UBUNTU_HOME/cursor-ide/launch_cursor.sh" ]; then
        log_warning "실행 권한 수정 중..."
        chmod +x "$UBUNTU_HOME/cursor-ide/launch_cursor.sh"
    fi
    
    # 네트워크 연결 확인
    if ! ping -c 1 google.com &> /dev/null; then
        log_warning "네트워크 연결이 불안정합니다"
    fi
    
    if [ "$all_good" = true ]; then
        log_success "모든 검증 통과"
        return 0
    else
        log_error "일부 검증 실패"
        return 1
    fi
}

# 복구 완료 메시지
show_completion_message() {
    echo ""
    echo "🎉 Cursor AI IDE 복구가 완료되었습니다!"
    echo ""
    echo "📁 설치 위치: $CURSOR_DIR"
    echo "📁 Ubuntu 환경: $HOME/ubuntu"
    echo "📄 로그 파일: $LOG_FILE"
    
    if [ -d "$BACKUP_DIR" ]; then
        echo "📁 백업 위치: $BACKUP_DIR"
    fi
    
    echo ""
    echo "🚀 실행 방법:"
    echo "  cd $CURSOR_DIR"
    echo "  ./launch.sh"
    echo ""
    echo "⚡ 성능 최적화:"
    echo "  ./optimize.sh"
    echo ""
    echo "🔧 추가 문제 해결:"
    echo "  로그 파일 확인: $LOG_FILE"
    echo "  완전 재설치: ./termux_safe_setup.sh"
    echo ""
    
    log_success "복구 프로세스 완료!"
}

# 메인 복구 함수
main() {
    echo ""
    echo "🔧 Galaxy Android용 Cursor AI IDE 안전 복구 스크립트 (Termux 최적화)"
    echo "=================================================================="
    echo ""
    
    # 로그 파일 초기화 (권한 안전)
    echo "복구 시작: $(date)" > "$LOG_FILE" 2>/dev/null || {
        echo "로그 파일 생성 실패, 로그 없이 진행합니다."
        LOG_FILE="/dev/null"
    }
    
    # 시스템 진단
    diagnose_system
    
    echo ""
    echo "🔧 복구 작업을 시작합니다..."
    echo ""
    
    # 각 복구 단계 실행
    fix_network_issues
    fix_permission_issues
    fix_package_issues
    restore_ubuntu_environment
    reinstall_cursor_ai
    restore_configuration
    final_verification
    show_completion_message
    
    # 로그 파일 정리
    echo "복구 완료: $(date)" >> "$LOG_FILE" 2>/dev/null || true
}

# 스크립트 실행
main "$@" 