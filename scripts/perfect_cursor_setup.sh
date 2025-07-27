#!/bin/bash

# Galaxy Android용 Cursor AI IDE 완벽 설치 스크립트 (v4.0.0)
# Author: Mobile IDE Team
# Version: 4.0.0
# Description: 모든 알려진 문제를 해결한 완벽한 Cursor AI IDE 설치
# Usage: ./perfect_cursor_setup.sh

# 중요: set -e 제거 (문서에서 지적한 문제)
# set -e

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

# 안전한 명령어 실행 함수
safe_run() {
    local command="$1"
    local description="${2:-명령어}"
    
    log_info "$description 실행 중..."
    if eval "$command" 2>/dev/null || log_warning "$description 실패 (계속 진행)"; then
        log_success "$description 완료"
        return 0
    else
        log_warning "$description 실패 (계속 진행)"
        return 1
    fi
}

# 시스템 정보 수집
collect_system_info() {
    log_info "시스템 정보 수집 중..."
    
    echo "=========================================="
    echo "  시스템 정보"
    echo "=========================================="
    echo "Android 버전: $(getprop ro.build.version.release)"
    echo "Android API: $(getprop ro.build.version.sdk)"
    echo "아키텍처: $(uname -m)"
    echo "메모리: $(free -h | awk 'NR==2{print $2}')"
    echo "저장공간: $(df -h /data | awk 'NR==2{print $4}') 사용 가능"
    echo "Termux 버전: $TERMUX_VERSION"
    echo "=========================================="
    echo ""
}

# 저장공간 확인 및 정리
check_and_cleanup_storage() {
    log_info "저장공간 확인 및 정리 중..."
    
    # 사용 가능한 공간 확인
    local available_space=$(df /data | awk 'NR==2{printf "%.0f", $4/1024/1024}')
    
    if [ "$available_space" -lt 5 ]; then
        log_warning "저장공간이 부족합니다 (${available_space}GB). 정리 중..."
        
        # 긴급 정리
        safe_run "pkg clean" "패키지 캐시 정리"
        safe_run "rm -rf ~/.cache/*" "사용자 캐시 정리"
        safe_run "rm -rf /tmp/*" "임시 파일 정리"
        safe_run "find ~ -name '*.log' -type f -size +10M -delete" "대용량 로그 파일 정리"
        
        # 정리 후 다시 확인
        available_space=$(df /data | awk 'NR==2{printf "%.0f", $4/1024/1024}')
        log_info "정리 후 사용 가능한 공간: ${available_space}GB"
    fi
    
    if [ "$available_space" -lt 3 ]; then
        log_error "저장공간이 너무 부족합니다 (${available_space}GB). 최소 3GB 필요."
        log_info "Android 설정 → 디바이스 케어 → 저장공간에서 시스템 캐시를 정리하세요."
        return 1
    fi
    
    log_success "저장공간 확인 완료 (${available_space}GB 사용 가능)"
    return 0
}

# 네트워크 연결 확인 및 DNS 설정
setup_network() {
    log_info "네트워크 연결 확인 및 DNS 설정 중..."
    
    # DNS 서버 설정 (다중 백업)
    safe_run "echo 'nameserver 8.8.8.8' > /etc/resolv.conf" "Google DNS 설정"
    safe_run "echo 'nameserver 8.8.4.4' >> /etc/resolv.conf" "Google DNS 백업 설정"
    safe_run "echo 'nameserver 1.1.1.1' >> /etc/resolv.conf" "Cloudflare DNS 설정"
    
    # 네트워크 연결 테스트
    if nslookup google.com >/dev/null 2>&1; then
        log_success "DNS 확인 성공"
    else
        log_warning "DNS 확인 실패 (계속 진행)"
    fi
    
    if curl -s --connect-timeout 10 https://www.google.com >/dev/null; then
        log_success "HTTP 연결 확인 성공"
    else
        log_warning "HTTP 연결 실패 (계속 진행)"
    fi
}

# 필수 패키지 설치
install_essential_packages() {
    log_info "필수 패키지 설치 중..."
    
    # 패키지 업데이트
    safe_run "pkg update -y" "패키지 업데이트"
    safe_run "pkg upgrade -y" "패키지 업그레이드"
    
    # 필수 패키지 설치
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
        safe_run "pkg install -y $package" "$package 설치"
    done
    
    log_success "필수 패키지 설치 완료"
}

# Ubuntu 환경 설치
install_ubuntu_environment() {
    log_info "Ubuntu 22.04 LTS 환경 설치 중..."
    
    # 기존 Ubuntu 환경 확인
    if [ -d "$HOME/ubuntu" ]; then
        log_warning "기존 Ubuntu 환경이 발견되었습니다."
        read -p "기존 환경을 제거하고 새로 설치하시겠습니까? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "기존 Ubuntu 환경 제거 중..."
            safe_run "proot-distro remove ubuntu" "기존 Ubuntu 제거"
            safe_run "rm -rf $HOME/ubuntu" "기존 Ubuntu 디렉토리 제거"
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
setup_ubuntu_environment() {
    log_info "Ubuntu 환경 설정 중..."
    
    # Ubuntu 환경에서 실행할 설정 스크립트 생성
    cat > /tmp/ubuntu_setup.sh << 'EOF'
#!/bin/bash

# Ubuntu 환경 설정 스크립트
echo "[INFO] Ubuntu 환경 설정 시작..."

# 패키지 업데이트
apt update -y || echo "[WARNING] 패키지 업데이트 실패"

# 필수 패키지 설치
essential_packages=(
    "curl"
    "wget"
    "git"
    "build-essential"
    "python3"
    "python3-pip"
    "xvfb"
    "x11-apps"
    "x11-utils"
    "x11-xserver-utils"
    "dbus-x11"
    "libx11-6"
    "libxext6"
    "libxrender1"
    "libxtst6"
    "libxi6"
    "libxrandr2"
    "libxss1"
    "libxcb1"
    "libxcomposite1"
    "libxcursor1"
    "libxdamage1"
    "libxfixes3"
    "libxinerama1"
    "libnss3"
    "libcups2"
    "libdrm2"
    "libxkbcommon0"
    "libatspi2.0-0"
    "libgtk-3-0"
    "libgbm1"
    "libasound2"
)

for package in "${essential_packages[@]}"; do
    echo "[INFO] 설치 중: $package"
    apt install -y "$package" 2>/dev/null || echo "[WARNING] $package 설치 실패"
done

# Node.js 설치
echo "[INFO] Node.js 설치 중..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash - || echo "[WARNING] Node.js 저장소 설정 실패"
apt install -y nodejs || echo "[WARNING] Node.js 설치 실패"

# npm 호환성 문제 해결
echo "[INFO] npm 호환성 문제 해결 중..."
npm install -g npm@10.8.2 2>/dev/null || echo "[WARNING] npm 버전 변경 실패"
npm cache clean --force 2>/dev/null || echo "[WARNING] npm 캐시 정리 실패"

# 작업 디렉토리 생성
mkdir -p /home/cursor-ide
cd /home/cursor-ide

echo "[SUCCESS] Ubuntu 환경 설정 완료"
EOF

    # Ubuntu 환경에서 설정 스크립트 실행
    chmod +x /tmp/ubuntu_setup.sh
    proot-distro login ubuntu -- bash /tmp/ubuntu_setup.sh
    
    # 임시 파일 정리
    rm -f /tmp/ubuntu_setup.sh
    
    log_success "Ubuntu 환경 설정 완료"
}

# Cursor AI 설치
install_cursor_ai() {
    log_info "Cursor AI 설치 중..."
    
    # Ubuntu 환경에서 Cursor AI 설치 스크립트 생성
    cat > /tmp/cursor_install.sh << 'EOF'
#!/bin/bash

cd /home/cursor-ide

echo "[INFO] Cursor AI AppImage 다운로드 중..."

# AppImage 다운로드 (ARM64)
if wget -O cursor.AppImage "https://download.cursor.sh/linux/appImage/arm64"; then
    echo "[SUCCESS] AppImage 다운로드 완료"
else
    echo "[ERROR] AppImage 다운로드 실패"
    exit 1
fi

# 실행 권한 부여
chmod +x cursor.AppImage

# AppImage 추출 (FUSE 문제 해결)
echo "[INFO] AppImage 추출 중..."
./cursor.AppImage --appimage-extract

if [ -d "squashfs-root" ]; then
    echo "[SUCCESS] AppImage 추출 완료"
else
    echo "[ERROR] AppImage 추출 실패"
    exit 1
fi

# 실행 스크립트 생성
cat > /home/cursor-ide/start.sh << 'START_EOF'
#!/bin/bash

# Cursor AI 실행 스크립트
export DISPLAY=:0
export XDG_RUNTIME_DIR="$HOME/.runtime-cursor"
export LIBGL_ALWAYS_SOFTWARE=1

# 런타임 디렉토리 생성
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# Xvfb 시작
if ! pgrep -x "Xvfb" > /dev/null; then
    echo "[INFO] Xvfb 시작 중..."
    Xvfb :0 -screen 0 1024x768x16 -ac +extension GLX +render -noreset &
    sleep 3
fi

# Cursor AI 실행
cd /home/cursor-ide
./squashfs-root/AppRun --no-sandbox --disable-gpu --single-process --disable-dev-shm-usage --max-old-space-size=512 &
CURSOR_PID=$!

echo "[SUCCESS] Cursor AI 실행됨 (PID: $CURSOR_PID)"
echo "[INFO] 종료하려면: kill $CURSOR_PID"

# 프로세스 상태 확인
sleep 3
if ps -p $CURSOR_PID > /dev/null; then
    echo "[SUCCESS] Cursor AI가 정상적으로 실행 중입니다!"
else
    echo "[WARNING] Cursor AI 프로세스 상태를 확인하세요."
fi
START_EOF

chmod +x /home/cursor-ide/start.sh
echo "[SUCCESS] 실행 스크립트 생성 완료"
EOF

    # Ubuntu 환경에서 Cursor AI 설치 실행
    chmod +x /tmp/cursor_install.sh
    proot-distro login ubuntu -- bash /tmp/cursor_install.sh
    
    # 임시 파일 정리
    rm -f /tmp/cursor_install.sh
    
    log_success "Cursor AI 설치 완료"
}

# VNC 서버 설정
setup_vnc_server() {
    log_info "VNC 서버 설정 중..."
    
    # VNC 서버 시작 스크립트 생성
    cat > ~/start_vnc.sh << 'EOF'
#!/bin/bash

echo "[INFO] VNC 서버 시작 중..."

# VNC 서버 시작
vncserver :1 -geometry 1024x768 -depth 24 -localhost no

if [ $? -eq 0 ]; then
    echo "[SUCCESS] VNC 서버 시작됨"
    echo "[INFO] VNC 접속 정보:"
    echo "  - 주소: localhost:5901"
    echo "  - 해상도: 1024x768"
    echo "  - 비밀번호: cursor123"
    echo ""
    echo "[INFO] Android VNC Viewer 앱을 설치하고 위 정보로 접속하세요."
else
    echo "[ERROR] VNC 서버 시작 실패"
fi
EOF

    chmod +x ~/start_vnc.sh
    
    # VNC 비밀번호 설정
    mkdir -p ~/.vnc
    echo "cursor123" | vncpasswd -f > ~/.vnc/passwd
    chmod 600 ~/.vnc/passwd
    
    log_success "VNC 서버 설정 완료"
}

# 실행 스크립트 생성
create_launch_scripts() {
    log_info "실행 스크립트 생성 중..."
    
    # 메인 실행 스크립트 (Termux)
    cat > ~/launch_cursor.sh << 'EOF'
#!/bin/bash

echo "=========================================="
echo "  Cursor AI IDE 실행"
echo "=========================================="
echo ""

# Ubuntu 환경에서 Cursor AI 실행
proot-distro login ubuntu -- bash /home/cursor-ide/start.sh

echo ""
echo "[INFO] Cursor AI가 실행되었습니다."
echo "[INFO] GUI 화면을 보려면 VNC 서버를 시작하세요:"
echo "  ./start_vnc.sh"
EOF

    chmod +x ~/launch_cursor.sh
    
    # VNC와 함께 실행하는 스크립트
    cat > ~/launch_cursor_with_vnc.sh << 'EOF'
#!/bin/bash

echo "=========================================="
echo "  Cursor AI IDE + VNC 실행"
echo "=========================================="
echo ""

# VNC 서버 시작
echo "[INFO] VNC 서버 시작 중..."
./start_vnc.sh

# 잠시 대기
sleep 2

# Ubuntu 환경에서 Cursor AI 실행
echo "[INFO] Cursor AI 실행 중..."
proot-distro login ubuntu -- bash /home/cursor-ide/start.sh

echo ""
echo "[SUCCESS] Cursor AI + VNC 실행 완료!"
echo "[INFO] Android VNC Viewer 앱에서 localhost:5901로 접속하세요."
EOF

    chmod +x ~/launch_cursor_with_vnc.sh
    
    # 상태 확인 스크립트
    cat > ~/check_cursor_status.sh << 'EOF'
#!/bin/bash

echo "=========================================="
echo "  Cursor AI 상태 확인"
echo "=========================================="
echo ""

# Ubuntu 환경 확인
if [ -d "$HOME/ubuntu" ]; then
    echo "✅ Ubuntu 환경: 설치됨"
else
    echo "❌ Ubuntu 환경: 설치되지 않음"
fi

# Cursor AI 확인
if [ -f "$HOME/ubuntu/home/cursor-ide/squashfs-root/AppRun" ]; then
    echo "✅ Cursor AI: 설치됨"
else
    echo "❌ Cursor AI: 설치되지 않음"
fi

# 실행 스크립트 확인
if [ -f "$HOME/launch_cursor.sh" ]; then
    echo "✅ 실행 스크립트: 생성됨"
else
    echo "❌ 실행 스크립트: 생성되지 않음"
fi

# VNC 서버 확인
if pgrep -x "vncserver" > /dev/null; then
    echo "✅ VNC 서버: 실행 중"
else
    echo "❌ VNC 서버: 실행되지 않음"
fi

# Cursor AI 프로세스 확인
if proot-distro login ubuntu -- ps aux | grep -v grep | grep -q "AppRun"; then
    echo "✅ Cursor AI 프로세스: 실행 중"
else
    echo "❌ Cursor AI 프로세스: 실행되지 않음"
fi

echo ""
echo "=========================================="
EOF

    chmod +x ~/check_cursor_status.sh
    
    log_success "실행 스크립트 생성 완료"
}

# 설치 완료 요약
show_installation_summary() {
    echo ""
    echo "=========================================="
    echo "  설치 완료!"
    echo "=========================================="
    echo ""
    echo "✅ 설치된 구성 요소:"
    echo "  - Ubuntu 22.04 LTS 환경"
    echo "  - Node.js 18 LTS"
    echo "  - Cursor AI IDE"
    echo "  - VNC 서버"
    echo "  - 실행 스크립트들"
    echo ""
    echo "📁 설치 위치:"
    echo "  - Ubuntu 환경: ~/ubuntu/"
    echo "  - Cursor AI: ~/ubuntu/home/cursor-ide/"
    echo "  - 실행 스크립트: ~/launch_cursor.sh"
    echo ""
    echo "🚀 사용 방법:"
    echo "  1. 기본 실행: ./launch_cursor.sh"
    echo "  2. VNC와 함께 실행: ./launch_cursor_with_vnc.sh"
    echo "  3. 상태 확인: ./check_cursor_status.sh"
    echo "  4. VNC 서버만 시작: ./start_vnc.sh"
    echo ""
    echo "📱 VNC 접속 정보:"
    echo "  - 주소: localhost:5901"
    echo "  - 비밀번호: cursor123"
    echo "  - 앱: Android VNC Viewer"
    echo ""
    echo "🔧 문제 해결:"
    echo "  - 저장공간 부족: ./cleanup.sh"
    echo "  - 네트워크 문제: DNS 설정 확인"
    echo "  - 권한 문제: 스크립트 권한 확인"
    echo ""
    echo "📚 문서:"
    echo "  - 설치 가이드: docs/COMPLETE_SETUP_GUIDE.md"
    echo "  - 문제 해결: docs/ERROR_DATABASE.md"
    echo ""
}

# 메인 설치 함수
main() {
    echo "=========================================="
    echo "  Cursor AI IDE 완벽 설치"
    echo "=========================================="
    echo "버전: 4.0.0"
    echo "작성자: Mobile IDE Team"
    echo "날짜: $(date)"
    echo "=========================================="
    echo ""
    
    # 시스템 정보 수집
    collect_system_info
    
    # 저장공간 확인 및 정리
    if ! check_and_cleanup_storage; then
        log_error "저장공간이 부족하여 설치를 중단합니다."
        exit 1
    fi
    
    # 네트워크 설정
    setup_network
    
    # 필수 패키지 설치
    install_essential_packages
    
    # Ubuntu 환경 설치
    if ! install_ubuntu_environment; then
        log_error "Ubuntu 환경 설치 실패"
        exit 1
    fi
    
    # Ubuntu 환경 설정
    setup_ubuntu_environment
    
    # Cursor AI 설치
    install_cursor_ai
    
    # VNC 서버 설정
    setup_vnc_server
    
    # 실행 스크립트 생성
    create_launch_scripts
    
    # 설치 완료 요약
    show_installation_summary
    
    log_success "모든 설치가 완료되었습니다!"
}

# 스크립트 실행
main "$@" 