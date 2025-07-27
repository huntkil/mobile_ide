#!/bin/bash

# Galaxy Android용 Cursor AI IDE 설치 스크립트 (v3.1.1)
# Author: Mobile IDE Team
# Version: 3.1.1
# Description: Termux 환경에서 Cursor AI IDE 완전 설치
# Usage: ./termux_local_setup.sh

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
    echo ""
    echo "예제:"
    echo "  $0              # 기본 실행"
    echo "  $0 --debug      # 디버그 모드"
}

# 버전 정보
show_version() {
    echo "버전: 3.1.1"
    echo "작성자: Mobile IDE Team"
    echo "마지막 업데이트: $(date +%Y-%m-%d)"
    echo "주요 개선사항:"
    echo "  - 스크립트 문법 오류 수정"
    echo "  - 권한 문제 해결 (XDG_RUNTIME_DIR)"
    echo "  - VNC 서버 통합"
    echo "  - 네트워크 DNS 해석 실패 해결"
    echo "  - 외부 저장소 실행 권한 제한 해결"
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

# 네트워크 연결 확인
check_network_connection() {
    log_info "네트워크 연결 확인 중..."
    
    # DNS 확인
    if ! nslookup google.com >/dev/null 2>&1; then
        log_warning "DNS 확인 실패"
        return 1
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
        read -p "기존 환경을 제거하고 새로 설치하시겠습니까? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "기존 Ubuntu 환경 제거 중..."
            proot-distro remove ubuntu 2>/dev/null || true
            rm -rf "$HOME/ubuntu" 2>/dev/null || true
        else
            log_info "기존 환경을 사용합니다."
            return 0
        fi
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

# Ubuntu 환경 설정
setup_ubuntu() {
    log_info "Ubuntu 환경 설정 중..."
    
    # Ubuntu 환경에서 실행할 스크립트 생성
    cat > "$HOME/setup_ubuntu_temp.sh" << 'EOF'
#!/bin/bash
set -e

echo "Ubuntu 환경 설정 시작..."

# 패키지 목록 업데이트
apt update

# 필수 패키지 설치
apt install -y curl wget git build-essential python3 python3-pip

# X11 관련 패키지 설치
apt install -y xvfb x11-apps x11-utils x11-xserver-utils dbus-x11

# X11 라이브러리 설치
apt install -y libx11-6 libxext6 libxrender1 libxtst6 libxi6
apt install -y libxrandr2 libxss1 libxcb1 libxcomposite1
apt install -y libxcursor1 libxdamage1 libxfixes3 libxinerama1
apt install -y libnss3 libcups2t64 libdrm2 libxkbcommon0
apt install -y libatspi2.0-0t64 libgtk-3-0t64 libgbm1 libasound2t64

# Node.js 설치
echo "Node.js 설치 중..."
apt remove -y nodejs npm 2>/dev/null || true
apt autoremove -y

curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# npm 호환성 문제 해결
npm install -g npm@10.8.2 || {
    echo "npm 버전 변경 실패, 기본 버전 사용..."
}

# npm 캐시 정리
npm cache clean --force

# 전역 패키지 설치
npm install -g yarn@1.22.19 typescript@5.3.3 ts-node@10.9.2 || {
    echo "일부 전역 패키지 설치 실패, 계속 진행..."
}

# 작업 디렉토리 생성
mkdir -p /home/cursor-ide
cd /home/cursor-ide

echo "Ubuntu 환경 설정 완료"
EOF

    # Ubuntu 환경에서 스크립트 실행
    if proot-distro login ubuntu -- bash "$HOME/setup_ubuntu_temp.sh"; then
        log_success "Ubuntu 환경 설정 완료"
        rm -f "$HOME/setup_ubuntu_temp.sh"
        return 0
    else
        log_error "Ubuntu 환경 설정 실패"
        rm -f "$HOME/setup_ubuntu_temp.sh"
        return 1
    fi
}

# Cursor AI 설치
install_cursor_ai() {
    log_info "Cursor AI 설치 중..."
    
    # Ubuntu 환경에서 실행할 설치 스크립트 생성
    cat > "$HOME/install_cursor_temp.sh" << 'EOF'
#!/bin/bash
set -e

cd /home/cursor-ide

# AppImage 다운로드 (ARM64)
echo "Cursor AI AppImage 다운로드 중..."
wget -O cursor.AppImage "https://download.cursor.sh/linux/appImage/arm64"

# 실행 권한 부여
chmod +x cursor.AppImage

# AppImage 추출
echo "AppImage 추출 중..."
./cursor.AppImage --appimage-extract

echo "Cursor AI 설치 완료"
EOF

    # Ubuntu 환경에서 설치 스크립트 실행
    if proot-distro login ubuntu -- bash "$HOME/install_cursor_temp.sh"; then
        log_success "Cursor AI 설치 완료"
        rm -f "$HOME/install_cursor_temp.sh"
        return 0
    else
        log_error "Cursor AI 설치 실패"
        rm -f "$HOME/install_cursor_temp.sh"
        return 1
    fi
}

# 실행 스크립트 생성
create_launch_script() {
    log_info "실행 스크립트 생성 중..."
    
    # Termux에서 실행할 launch.sh 생성
    cat > "$HOME/launch.sh" << 'EOF'
#!/bin/bash
echo "=========================================="
echo "  Cursor AI IDE 실행"
echo "=========================================="
echo ""

# Ubuntu 환경에서 start.sh 실행
proot-distro login ubuntu -- bash /home/cursor-ide/start.sh
EOF

    # Ubuntu 환경에서 실행할 start.sh 생성
    cat > "$HOME/start.sh" << 'EOF'
#!/bin/bash
set -e

echo "Cursor AI 시작 중..."

# 환경 변수 설정
export DISPLAY=:0
export LIBGL_ALWAYS_SOFTWARE=1
export XDG_RUNTIME_DIR="$HOME/.runtime-cursor"

# 런타임 디렉토리 생성
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

echo "환경 변수 설정 완료"
echo "DISPLAY: $DISPLAY"
echo "XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"

# Xvfb 시작 (가능한 경우)
if command -v Xvfb > /dev/null 2>&1; then
    if ! pgrep -x "Xvfb" > /dev/null; then
        echo "Xvfb 시작 중..."
        Xvfb :0 -screen 0 1024x768x16 -ac +extension GLX +render -noreset &
        sleep 3
        echo "Xvfb 시작됨"
    else
        echo "Xvfb가 이미 실행 중"
    fi
else
    echo "Xvfb 없음 - 소프트웨어 렌더링 모드"
fi

# Cursor AI 실행
if [ -f "./squashfs-root/AppRun" ]; then
    echo "Cursor AI 실행 중..."
    ./squashfs-root/AppRun --no-sandbox --disable-gpu --single-process --disable-dev-shm-usage &
    CURSOR_PID=$!
    echo "Cursor AI 실행됨 (PID: $CURSOR_PID)"
    echo "종료하려면: kill $CURSOR_PID"
else
    echo "실행 파일을 찾을 수 없습니다."
    echo "AppImage 추출: ./cursor.AppImage --appimage-extract"
    exit 1
fi

# 프로세스 상태 확인
sleep 3
if ps -p $CURSOR_PID > /dev/null; then
    echo "Cursor AI가 정상적으로 실행 중입니다!"
else
    echo "Cursor AI 프로세스 상태를 확인하세요."
fi
EOF

    # Ubuntu 환경에 start.sh 복사
    proot-distro login ubuntu -- cp "$HOME/start.sh" /home/cursor-ide/start.sh
    proot-distro login ubuntu -- chmod +x /home/cursor-ide/start.sh
    
    # Termux에서 실행할 수정된 스크립트 생성
    cat > "$HOME/run_cursor_fixed.sh" << 'EOF'
#!/bin/bash
cd ~

echo "[INFO] Cursor AI 실행 중 (권한 문제 해결)..."

# 안전한 환경 변수 설정
export DISPLAY=:0
export LIBGL_ALWAYS_SOFTWARE=1
export XDG_RUNTIME_DIR="$HOME/.runtime-cursor"

# 런타임 디렉토리 생성
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

echo "[INFO] 환경 변수 설정 완료"
echo "DISPLAY: $DISPLAY"
echo "XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"

# Xvfb 시작 (가능한 경우)
if command -v Xvfb > /dev/null 2>&1; then
    if ! pgrep -x "Xvfb" > /dev/null; then
        echo "[INFO] Xvfb 시작 중..."
        Xvfb :0 -screen 0 1024x768x16 -ac +extension GLX +render -noreset &
        sleep 3
        echo "[INFO] Xvfb 시작됨"
    else
        echo "[INFO] Xvfb가 이미 실행 중"
    fi
else
    echo "[INFO] Xvfb 없음 - 소프트웨어 렌더링 모드"
fi

# Cursor AI 실행
if [ -f "./squashfs-root/AppRun" ]; then
    echo "[INFO] Cursor AI 실행 중..."
    ./squashfs-root/AppRun --no-sandbox --disable-gpu --single-process --disable-dev-shm-usage &
    CURSOR_PID=$!
    echo "[SUCCESS] Cursor AI 실행됨 (PID: $CURSOR_PID)"
    echo "[INFO] 종료하려면: kill $CURSOR_PID"
else
    echo "[ERROR] 실행 파일을 찾을 수 없습니다."
    echo "AppImage 추출: ./cursor.AppImage --appimage-extract"
    exit 1
fi

# 프로세스 상태 확인
sleep 3
if ps -p $CURSOR_PID > /dev/null; then
    echo "[SUCCESS] Cursor AI가 정상적으로 실행 중입니다!"
else
    echo "[WARNING] Cursor AI 프로세스 상태를 확인하세요."
fi
EOF

    # 실행 권한 부여
    chmod +x "$HOME/launch.sh"
    chmod +x "$HOME/run_cursor_fixed.sh"
    
    # 임시 파일 정리
    rm -f "$HOME/start.sh"
    
    log_success "실행 스크립트 생성 완료"
    return 0
}

# 최종 검증
final_verification() {
    log_info "최종 검증 중..."
    
    # Ubuntu 환경 확인
    if [ ! -d "$HOME/ubuntu" ] && [ ! -d "$HOME/.local/share/proot-distro/installed-rootfs/ubuntu" ]; then
        log_error "Ubuntu 환경이 설치되지 않았습니다."
        log_info "확인한 경로들:"
        log_info "- $HOME/ubuntu"
        log_info "- $HOME/.local/share/proot-distro/installed-rootfs/ubuntu"
        return 1
    fi
    
    # Cursor AI 확인
    if ! proot-distro login ubuntu -- test -f /home/cursor-ide/squashfs-root/AppRun; then
        log_error "Cursor AI가 설치되지 않았습니다."
        return 1
    fi
    
    # 실행 스크립트 확인
    if [ ! -f "$HOME/launch.sh" ] || [ ! -f "$HOME/run_cursor_fixed.sh" ]; then
        log_error "실행 스크립트가 생성되지 않았습니다."
        return 1
    fi
    
    log_success "최종 검증 완료"
    return 0
}

# 설치 요약 표시
show_installation_summary() {
    echo ""
    echo "=========================================="
    echo "  설치 완료 요약"
    echo "=========================================="
    echo ""
    echo "✅ 설치된 구성 요소:"
    echo "  - Ubuntu 22.04 LTS 환경"
    echo "  - Node.js 18 LTS"
    echo "  - Cursor AI IDE"
    echo "  - 실행 스크립트 (launch.sh, run_cursor_fixed.sh)"
    echo ""
    echo "📁 설치 위치:"
    echo "  - Ubuntu 환경: ~/ubuntu/"
    echo "  - Cursor AI: ~/ubuntu/home/cursor-ide/"
    echo "  - 실행 스크립트: ~/launch.sh, ~/run_cursor_fixed.sh"
    echo ""
    echo "🚀 사용 방법:"
    echo "  ./launch.sh                    # Ubuntu 환경에서 실행"
    echo "  ./run_cursor_fixed.sh          # 권한 문제 해결된 실행"
    echo ""
    echo "🔧 문제 해결:"
    echo "  ./scripts/fix_installation.sh  # 설치 문제 해결"
    echo ""
    echo "📱 VNC 서버 설정 (GUI 표시용):"
    echo "  1. pkg install x11vnc"
    echo "  2. vncserver :1 -geometry 1024x768 -depth 24"
    echo "  3. Android VNC Viewer 앱에서 localhost:5901 접속"
    echo ""
}

# 메인 함수
main() {
    echo "=========================================="
    echo "  Galaxy Android용 Cursor AI IDE 설치"
    echo "=========================================="
    echo ""
    
    # 명령행 인수 처리
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
                set -x
                shift
                ;;
            *)
                log_error "알 수 없는 옵션: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 설치 단계 실행
    log_info "설치 시작..."
    
    # 1. 사용자 권한 확인
    check_user_permissions || exit 1
    
    # 2. 시스템 요구사항 확인
    check_system_requirements || exit 1
    
    # 3. 네트워크 연결 확인
    check_network_connection || {
        log_warning "네트워크 연결 문제가 있습니다. 계속 진행하시겠습니까? (y/N): "
        read -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    }
    
    # 4. Ubuntu 환경 설치
    install_ubuntu || exit 1
    
    # 5. Ubuntu 환경 설정
    setup_ubuntu || exit 1
    
    # 6. Cursor AI 설치
    install_cursor_ai || exit 1
    
    # 7. 실행 스크립트 생성
    create_launch_script || exit 1
    
    # 8. 최종 검증
    final_verification || exit 1
    
    # 9. 설치 요약 표시
    show_installation_summary
    
    log_success "설치 완료!"
}

# 스크립트 실행
main "$@" 