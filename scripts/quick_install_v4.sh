#!/bin/bash

# Galaxy Android용 Cursor AI IDE 빠른 설치 스크립트 v4.0
# Author: Mobile IDE Team
# Version: 4.0.0
# Description: npm 오류 방지, 빠른 설치, 간단한 사용법
# Usage: ./scripts/quick_install_v4.sh

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

# 헬프 함수
show_help() {
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  -h, --help     이 도움말을 표시합니다"
    echo "  -v, --version  버전 정보를 표시합니다"
    echo "  -s, --skip-npm npm 설치를 건너뜁니다 (권장)"
    echo ""
    echo "예제:"
    echo "  $0              # 기본 실행"
    echo "  $0 --skip-npm   # npm 없이 설치 (권장)"
}

# 버전 정보
show_version() {
    echo "버전: 4.0.0"
    echo "작성자: Mobile IDE Team"
    echo "마지막 업데이트: $(date +%Y-%m-%d)"
    echo "설명: npm 오류 방지, 빠른 설치"
}

# 빠른 설치
quick_install() {
    local skip_npm=false
    
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
            -s|--skip-npm)
                skip_npm=true
                shift
                ;;
            *)
                log_error "알 수 없는 옵션: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    echo "=========================================="
    echo "  Galaxy Android용 Cursor AI IDE 빠른 설치 v4.0"
    echo "=========================================="
    echo ""
    
    # 1. 기본 패키지 설치
    log_info "기본 패키지 설치 중..."
    pkg update -y
    pkg install -y proot-distro curl wget proot tar unzip git
    
    # 2. Ubuntu 환경 설치
    log_info "Ubuntu 환경 설치 중..."
    proot-distro install ubuntu
    
    # 3. Ubuntu 환경 설정 (npm 없이)
    log_info "Ubuntu 환경 설정 중..."
    proot-distro login ubuntu -- bash -c "
        apt update
        apt install -y curl wget git build-essential python3 python3-pip
        apt install -y xvfb x11-apps x11-utils x11-xserver-utils dbus-x11
        apt install -y libx11-6 libxext6 libxrender1 libxtst6 libxi6
        apt install -y libxrandr2 libxss1 libxcb1 libxcomposite1
        apt install -y libxcursor1 libxdamage1 libxfixes3 libxinerama1
        apt install -y libnss3 libcups2t64 libdrm2 libxkbcommon0
        apt install -y libatspi2.0-0t64 libgtk-3-0t64 libgbm1 libasound2t64
        mkdir -p /home/cursor-ide
        cd /home/cursor-ide
    "
    
    # 4. Cursor AI 설치
    log_info "Cursor AI 설치 중..."
    proot-distro login ubuntu -- bash -c "
        cd /home/cursor-ide
        wget -O cursor.AppImage 'https://download.cursor.sh/linux/appImage/arm64'
        chmod +x cursor.AppImage
        ./cursor.AppImage --appimage-extract
    "
    
    # 5. 실행 스크립트 생성
    log_info "실행 스크립트 생성 중..."
    
    # Ubuntu 환경에서 실행할 스크립트
    cat > ~/ubuntu/home/cursor-ide/start.sh << 'EOF'
#!/bin/bash
export DISPLAY=:0
export XDG_RUNTIME_DIR="$HOME/.runtime-cursor"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

Xvfb :0 -screen 0 1024x768x16 -ac +extension GLX +render -noreset &
sleep 3

./squashfs-root/AppRun --no-sandbox --disable-gpu --single-process --disable-dev-shm-usage --max-old-space-size=1024 &
EOF

    chmod +x ~/ubuntu/home/cursor-ide/start.sh
    
    # Termux에서 실행할 스크립트
    cat > ~/launch.sh << 'EOF'
#!/bin/bash
proot-distro login ubuntu -- bash /home/cursor-ide/start.sh
EOF

    chmod +x ~/launch.sh
    
    # 권한 문제 해결된 실행 스크립트
    cat > ~/run_cursor_fixed.sh << 'EOF'
#!/bin/bash
export DISPLAY=:0
export XDG_RUNTIME_DIR="$HOME/.runtime-cursor"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

Xvfb :0 -screen 0 1024x768x16 -ac +extension GLX +render -noreset &
sleep 3

cd ~/ubuntu/home/cursor-ide
proot-distro login ubuntu -- ./squashfs-root/AppRun --no-sandbox --disable-gpu --single-process --disable-dev-shm-usage --max-old-space-size=1024 &
EOF

    chmod +x ~/run_cursor_fixed.sh
    
    # 6. 설치 완료 메시지
    echo ""
    echo "=========================================="
    echo "  🎉 빠른 설치 완료! 🎉"
    echo "=========================================="
    echo ""
    echo "✅ 설치된 구성 요소:"
    echo "  - Ubuntu 22.04 LTS 환경"
    echo "  - Cursor AI IDE"
    echo "  - 실행 스크립트 (launch.sh, run_cursor_fixed.sh)"
    echo ""
    echo "🚀 사용 방법:"
    echo "  ./run_cursor_fixed.sh    # 권장"
    echo "  ./launch.sh              # 기본 실행"
    echo ""
    echo "💡 팁:"
    echo "  - npm 오류가 발생하면 npm 없이 설치된 버전입니다"
    echo "  - 문제가 있으면 ./scripts/complete_reset_v4.sh를 실행하세요"
    echo ""
    
    log_success "빠른 설치 완료!"
}

# 스크립트 실행
quick_install "$@" 