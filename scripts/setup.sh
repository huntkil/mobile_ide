#!/bin/bash

# Galaxy Android용 Cursor AI IDE 설치 스크립트
# Author: Mobile IDE Team
# Version: 1.0.0

set -e  # 에러 발생 시 스크립트 중단

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 시스템 정보 출력
print_system_info() {
    log_info "시스템 정보 확인 중..."
    echo "Android 버전: $(getprop ro.build.version.release)"
    echo "아키텍처: $(uname -m)"
    echo "사용 가능한 메모리: $(free -h | grep Mem | awk '{print $2}')"
    echo "사용 가능한 저장공간: $(df -h /data | tail -1 | awk '{print $4}')"
}

# 의존성 확인
check_dependencies() {
    log_info "필수 의존성 확인 중..."
    
    # Termux 필수 패키지 확인
    local required_packages=("curl" "wget" "proot" "tar" "unzip")
    
    for package in "${required_packages[@]}"; do
        if ! command -v "$package" &> /dev/null; then
            log_warning "$package이 설치되지 않았습니다. 설치를 진행합니다..."
            pkg install -y "$package"
        else
            log_success "$package 확인됨"
        fi
    done
}

# proot-distro 설치
install_proot_distro() {
    log_info "proot-distro 설치 중..."
    
    if ! command -v proot-distro &> /dev/null; then
        pkg install -y proot-distro
        log_success "proot-distro 설치 완료"
    else
        log_info "proot-distro가 이미 설치되어 있습니다."
    fi
}

# Ubuntu 22.04 설치
install_ubuntu() {
    log_info "Ubuntu 22.04 LTS 설치 중..."
    
    if [ ! -d "$HOME/ubuntu" ]; then
        proot-distro install ubuntu
        log_success "Ubuntu 22.04 LTS 설치 완료"
    else
        log_info "Ubuntu가 이미 설치되어 있습니다."
    fi
}

# Ubuntu 환경 설정
setup_ubuntu_environment() {
    log_info "Ubuntu 환경 설정 중..."
    
    # Ubuntu 환경에서 실행할 스크립트 생성
    cat > "$HOME/setup_ubuntu.sh" << 'EOF'
#!/bin/bash
set -e

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[INFO]${NC} Ubuntu 환경 설정 시작..."

# 패키지 목록 업데이트
apt update

# 필수 패키지 설치
echo -e "${BLUE}[INFO]${NC} 필수 패키지 설치 중..."
apt install -y \
    curl \
    wget \
    git \
    build-essential \
    python3 \
    python3-pip \
    vim \
    nano \
    htop \
    tree \
    unzip \
    zip \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common || {
    echo -e "${YELLOW}[WARNING]${NC} 일부 패키지 설치 실패, 계속 진행..."
}

# Node.js 최신 버전 설치
echo -e "${BLUE}[INFO]${NC} Node.js 최신 버전 설치 중..."
# 기존 Node.js 제거 (충돌 방지)
apt remove -y nodejs npm 2>/dev/null || true
apt autoremove -y

# Node.js 18 LTS 설치 (더 안정적)
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# npm 최신 버전으로 업데이트
npm install -g npm@latest

# 전역 패키지 설치
echo -e "${BLUE}[INFO]${NC} 전역 패키지 설치 중..."
npm install -g yarn typescript ts-node

# X11 관련 패키지 설치
echo -e "${BLUE}[INFO]${NC} X11 환경 설정 중..."
apt install -y \
    xvfb \
    x11-apps \
    x11-utils \
    x11-xserver-utils \
    dbus-x11 \
    libx11-6 \
    libxext6 \
    libxrender1 \
    libxtst6 \
    libxi6 \
    libxrandr2 \
    libxss1 \
    libxcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxfixes3 \
    libxinerama1 \
    libxrandr2 \
    libxtst6 \
    libnss3 \
    libcups2t64 \
    libdrm2 \
    libxkbcommon0 \
    libatspi2.0-0t64 \
    libgtk-3-0t64 \
    libgbm1 \
    libasound2t64 || {
    echo -e "${YELLOW}[WARNING]${NC} 일부 X11 패키지 설치 실패, 대체 패키지 시도..."
    # 대체 패키지 설치
    apt install -y libcups2 libatspi2.0-0 libgtk-3-0 libasound2 2>/dev/null || {
        echo -e "${YELLOW}[WARNING]${NC} X11 패키지 설치 실패, 기본 기능으로 진행..."
    }
}

# 작업 디렉토리 생성
mkdir -p /home/cursor-ide
cd /home/cursor-ide

echo -e "${GREEN}[SUCCESS]${NC} Ubuntu 환경 설정 완료!"
EOF

    # Ubuntu 환경에서 설정 스크립트 실행
    proot-distro login ubuntu -- bash "$HOME/setup_ubuntu.sh"
    
    # 임시 스크립트 삭제
    rm "$HOME/setup_ubuntu.sh"
}

# Cursor AI 다운로드 및 설치
install_cursor_ai() {
    log_info "Cursor AI 다운로드 및 설치 중..."
    
    # Ubuntu 환경에서 Cursor AI 설치
    cat > "$HOME/install_cursor.sh" << 'EOF'
#!/bin/bash
set -e

cd /home/cursor-ide

# Cursor AI AppImage 다운로드 (ARM64 버전)
echo "Cursor AI ARM64 AppImage 다운로드 중..."
wget -O cursor.AppImage "https://download.cursor.sh/linux/appImage/arm64"

# 실행 권한 부여
chmod +x cursor.AppImage

# AppImage 실행을 위한 의존성 설치
apt install -y fuse

# AppImage 추출 (fuse가 작동하지 않을 경우)
./cursor.AppImage --appimage-extract

echo "Cursor AI 설치 완료!"
EOF

    proot-distro login ubuntu -- bash "$HOME/install_cursor.sh"
    rm "$HOME/install_cursor.sh"
}

# 모바일 최적화 설정
setup_mobile_optimization() {
    log_info "모바일 최적화 설정 중..."
    
    # Cursor AI 설정 파일 생성
    cat > "$HOME/cursor-config.json" << 'EOF'
{
    "window": {
        "width": 1200,
        "height": 800,
        "minWidth": 800,
        "minHeight": 600,
        "resizable": true,
        "maximizable": true,
        "fullscreenable": true
    },
    "editor": {
        "fontSize": 14,
        "fontFamily": "Monaco, 'Courier New', monospace",
        "lineHeight": 1.5,
        "wordWrap": "on",
        "minimap": {
            "enabled": false
        },
        "scrollBeyondLastLine": false,
        "smoothScrolling": true,
        "cursorBlinking": "smooth",
        "cursorSmoothCaretAnimation": "on"
    },
    "workbench": {
        "colorTheme": "Default Dark+",
        "iconTheme": "vs-seti",
        "sideBar": {
            "location": "left"
        },
        "panel": {
            "defaultLocation": "bottom"
        },
        "tree": {
            "indent": 20,
            "renderIndentGuides": "always"
        }
    },
    "terminal": {
        "integrated": {
            "fontSize": 12,
            "fontFamily": "Monaco, 'Courier New', monospace"
        }
    },
    "files": {
        "autoSave": "afterDelay",
        "autoSaveDelay": 1000,
        "exclude": {
            "**/node_modules": true,
            "**/dist": true,
            "**/build": true,
            "**/.git": true
        }
    },
    "telemetry": {
        "enableCrashReporter": false,
        "enableTelemetry": false
    }
}
EOF

    # Ubuntu 환경으로 설정 파일 복사
    cp "$HOME/cursor-config.json" "$HOME/ubuntu/home/cursor-ide/"
}

# 실행 스크립트 생성
create_launch_scripts() {
    log_info "실행 스크립트 생성 중..."
    
    # 메인 실행 스크립트
    cat > "$HOME/launch.sh" << 'EOF'
#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}[INFO]${NC} Cursor AI IDE 시작 중..."

# X11 디스플레이 설정
export DISPLAY=:0

# Xvfb 시작 (백그라운드)
if ! pgrep -x "Xvfb" > /dev/null; then
    echo -e "${BLUE}[INFO]${NC} X11 가상 디스플레이 시작 중..."
    Xvfb :0 -screen 0 1200x800x24 &
    sleep 2
fi

# Ubuntu 환경에서 Cursor AI 실행
cd "$HOME/ubuntu/home/cursor-ide"

if [ -f "cursor.AppImage" ]; then
    echo -e "${BLUE}[INFO]${NC} Cursor AI AppImage 실행 중..."
    proot-distro login ubuntu -- ./cursor.AppImage
elif [ -d "squashfs-root" ]; then
    echo -e "${BLUE}[INFO]${NC} Cursor AI 추출된 버전 실행 중..."
    proot-distro login ubuntu -- ./squashfs-root/cursor
else
    echo -e "${RED}[ERROR]${NC} Cursor AI를 찾을 수 없습니다. 설치를 다시 진행하세요."
    exit 1
fi
EOF

    # 성능 최적화 스크립트
    cat > "$HOME/optimize.sh" << 'EOF'
#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[INFO]${NC} 성능 최적화 중..."

# 메모리 최적화
echo -e "${BLUE}[INFO]${NC} 메모리 최적화..."
echo 3 > /proc/sys/vm/drop_caches

# CPU 성능 모드 설정
echo -e "${BLUE}[INFO]${NC} CPU 성능 모드 설정..."
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# 배터리 최적화 비활성화 (성능 우선)
echo -e "${BLUE}[INFO]${NC} 배터리 최적화 비활성화..."

echo -e "${GREEN}[SUCCESS]${NC} 성능 최적화 완료!"
EOF

    # 환경 복구 스크립트
    cat > "$HOME/restore.sh" << 'EOF'
#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[INFO]${NC} 환경 복구 중..."

# Ubuntu 환경 재설치
echo -e "${BLUE}[INFO]${NC} Ubuntu 환경 재설치..."
rm -rf "$HOME/ubuntu"
proot-distro install ubuntu

# 설정 재적용
echo -e "${BLUE}[INFO]${NC} 설정 재적용..."
bash "$HOME/setup.sh"

echo -e "${GREEN}[SUCCESS]${NC} 환경 복구 완료!"
EOF

    # 실행 권한 부여
    chmod +x "$HOME/launch.sh"
    chmod +x "$HOME/optimize.sh"
    chmod +x "$HOME/restore.sh"
}

# 메인 설치 함수
main() {
    echo "=========================================="
    echo "  Galaxy Android용 Cursor AI IDE 설치"
    echo "=========================================="
    echo ""
    
    # 시스템 정보 출력
    print_system_info
    echo ""
    
    # 의존성 확인
    check_dependencies
    echo ""
    
    # proot-distro 설치
    install_proot_distro
    echo ""
    
    # Ubuntu 설치
    install_ubuntu
    echo ""
    
    # Ubuntu 환경 설정
    setup_ubuntu_environment
    echo ""
    
    # Cursor AI 설치
    install_cursor_ai
    echo ""
    
    # 모바일 최적화
    setup_mobile_optimization
    echo ""
    
    # 실행 스크립트 생성
    create_launch_scripts
    echo ""
    
    log_success "설치가 완료되었습니다!"
    echo ""
    echo "사용 방법:"
    echo "  실행: ./launch.sh"
    echo "  최적화: ./optimize.sh"
    echo "  복구: ./restore.sh"
    echo ""
    echo "주의사항:"
    echo "  - 첫 실행 시 시간이 오래 걸릴 수 있습니다."
    echo "  - 충분한 저장공간과 메모리가 필요합니다."
    echo "  - 배터리 사용량이 증가할 수 있습니다."
}

# 스크립트 실행
main "$@" 