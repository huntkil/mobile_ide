#!/bin/bash

# Galaxy Android용 Cursor AI IDE 설치 스크립트 (기존 환경 처리)
# Author: Mobile IDE Team
# Version: 1.0.0

set -e  # 에러 발생 시 스크립트 중단

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# 기존 Ubuntu 환경 확인 및 처리
check_and_handle_existing_ubuntu() {
    log_info "기존 Ubuntu 환경 확인 중..."
    
    if [ -d "$HOME/ubuntu" ]; then
        log_warning "기존 Ubuntu 환경이 발견되었습니다."
        echo ""
        echo "다음 중 하나를 선택하세요:"
        echo "1. 기존 환경 재설정 (권장 - 데이터 유지)"
        echo "2. 완전 제거 후 재설치"
        echo "3. 기존 환경에서 직접 설정"
        echo "4. 종료"
        echo ""
        
        read -p "선택 (1-4): " choice
        
        case $choice in
            1)
                log_info "기존 Ubuntu 환경 재설정 중..."
                proot-distro reset ubuntu
                log_success "Ubuntu 환경 재설정 완료"
                return 0
                ;;
            2)
                log_info "기존 Ubuntu 환경 완전 제거 중..."
                proot-distro remove ubuntu
                log_success "Ubuntu 환경 제거 완료"
                return 0
                ;;
            3)
                log_info "기존 환경에서 직접 설정을 진행합니다..."
                return 1  # 기존 환경 사용
                ;;
            4)
                log_info "설치를 취소합니다."
                exit 0
                ;;
            *)
                log_error "잘못된 선택입니다."
                exit 1
                ;;
        esac
    else
        log_info "기존 Ubuntu 환경이 없습니다. 새로 설치합니다."
        return 0
    fi
}

# Ubuntu 환경 설정 (기존 환경용)
setup_existing_ubuntu() {
    log_info "기존 Ubuntu 환경 설정 중..."
    
    # Ubuntu 환경에서 실행할 스크립트 생성
    cat > "$HOME/setup_existing_ubuntu.sh" << 'EOF'
#!/bin/bash
set -e

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}[INFO]${NC} 기존 Ubuntu 환경 설정 시작..."

# 패키지 목록 업데이트
apt update

# 필수 패키지 설치 (기존 패키지와 충돌 방지)
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

# Node.js 상태 확인 및 업데이트
echo -e "${BLUE}[INFO]${NC} Node.js 상태 확인 중..."
if ! command -v node &> /dev/null; then
    echo -e "${BLUE}[INFO]${NC} Node.js 설치 중..."
    # 기존 Node.js 제거 (충돌 방지)
    apt remove -y nodejs npm 2>/dev/null || true
    apt autoremove -y
    
    # Node.js 18 LTS 설치
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs
else
    echo -e "${GREEN}[SUCCESS]${NC} Node.js가 이미 설치되어 있습니다."
    node --version
fi

# npm 업데이트
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

echo -e "${GREEN}[SUCCESS]${NC} 기존 Ubuntu 환경 설정 완료!"
EOF

    # Ubuntu 환경에서 설정 스크립트 실행
    proot-distro login ubuntu -- bash "$HOME/setup_existing_ubuntu.sh"
    
    # 임시 스크립트 삭제
    rm "$HOME/setup_existing_ubuntu.sh"
}

# Cursor AI 설치 (기존 환경용)
install_cursor_ai_existing() {
    log_info "Cursor AI 설치 중..."
    
    # Ubuntu 환경에서 Cursor AI 설치
    cat > "$HOME/install_cursor_existing.sh" << 'EOF'
#!/bin/bash
set -e

cd /home/cursor-ide

echo "Cursor AI 설치 시작..."

# 기존 Cursor AI 제거 (있는 경우)
rm -rf cursor.AppImage squashfs-root 2>/dev/null || true

# Cursor AI AppImage 다운로드 (ARM64 버전)
echo "Cursor AI ARM64 AppImage 다운로드 중..."
wget -O cursor.AppImage "https://download.cursor.sh/linux/appImage/arm64"

# 실행 권한 부여
chmod +x cursor.AppImage

# AppImage 추출
./cursor.AppImage --appimage-extract

echo "Cursor AI 설치 완료!"
EOF

    proot-distro login ubuntu -- bash "$HOME/install_cursor_existing.sh"
    rm "$HOME/install_cursor_existing.sh"
}

# 메인 설치 함수
main() {
    echo "=========================================="
    echo "  Galaxy Android용 Cursor AI IDE 설치"
    echo "  (기존 환경 처리 버전)"
    echo "=========================================="
    echo ""
    
    # 기존 Ubuntu 환경 확인 및 처리
    if check_and_handle_existing_ubuntu; then
        # 새로운 설치 또는 재설정된 환경
        log_info "새로운 Ubuntu 환경 설치 중..."
        proot-distro install ubuntu
        setup_existing_ubuntu
    else
        # 기존 환경 사용
        log_info "기존 Ubuntu 환경을 사용합니다."
    fi
    
    # Cursor AI 설치
    install_cursor_ai_existing
    
    # 실행 스크립트 생성
    log_info "실행 스크립트 생성 중..."
    
    # launch.sh 생성
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
    Xvfb :0 -screen 0 1200x800x24 -ac +extension GLX +render -noreset &
    sleep 3
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
    echo -e "${RED}[ERROR]${NC} Cursor AI를 찾을 수 없습니다."
    exit 1
fi
EOF

    chmod +x "$HOME/launch.sh"
    
    log_success "설치가 완료되었습니다!"
    echo ""
    echo "사용 방법:"
    echo "  실행: ./launch.sh"
    echo ""
    echo "주의사항:"
    echo "  - 첫 실행 시 시간이 오래 걸릴 수 있습니다."
    echo "  - 충분한 저장공간과 메모리가 필요합니다."
}

# 스크립트 실행
main "$@" 