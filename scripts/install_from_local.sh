#!/bin/bash

# 로컬 AppImage 파일로 Cursor AI 설치 스크립트
# Author: Mobile IDE Team
# Version: 1.0.0

set -e

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

# 로컬 AppImage 파일 확인
check_local_appimage() {
    log_info "로컬 AppImage 파일 확인 중..."
    
    # 여러 가능한 위치 확인
    local possible_paths=(
        "$HOME/cursor_ide/Cursor-1.2.1-aarch64.AppImage"
        "$HOME/cursor_ide/cursor.AppImage"
        "$HOME/cursor_ide/Cursor*.AppImage"
        "$HOME/Downloads/Cursor-1.2.1-aarch64.AppImage"
        "$HOME/Downloads/cursor.AppImage"
        "$HOME/Downloads/Cursor*.AppImage"
        "./Cursor-1.2.1-aarch64.AppImage"
        "./cursor.AppImage"
        "./Cursor*.AppImage"
    )
    
    for path in "${possible_paths[@]}"; do
        if ls $path >/dev/null 2>&1; then
            local found_file=$(ls $path | head -1)
            if [ -f "$found_file" ]; then
                log_success "AppImage 파일 발견: $found_file"
                echo "$found_file"
                return 0
            fi
        fi
    done
    
    log_error "AppImage 파일을 찾을 수 없습니다."
    echo ""
    echo "다음 위치에서 AppImage 파일을 확인해주세요:"
    echo "  - $HOME/cursor_ide/"
    echo "  - $HOME/Downloads/"
    echo "  - 현재 디렉토리"
    echo ""
    echo "또는 파일 경로를 직접 입력해주세요:"
    read -p "AppImage 파일 경로: " custom_path
    
    if [ -f "$custom_path" ]; then
        log_success "사용자 지정 파일 확인: $custom_path"
        echo "$custom_path"
        return 0
    else
        log_error "파일을 찾을 수 없습니다: $custom_path"
        return 1
    fi
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
        exit 1
    fi
    
    # proot-distro 확인
    if ! command -v proot-distro &> /dev/null; then
        log_error "proot-distro가 설치되지 않았습니다."
        log_info "다음 명령어로 설치하세요:"
        echo "pkg install proot-distro"
        exit 1
    fi
    
    # Termux 환경 확인
    if [ -z "$TERMUX_VERSION" ]; then
        log_warning "Termux 환경이 아닙니다. 일부 기능이 제한될 수 있습니다."
    fi
    
    log_success "사용자 권한 확인 완료"
}

# Ubuntu 환경 확인 및 설치
check_ubuntu_environment() {
    log_info "Ubuntu 환경 확인 중..."
    
    if [ ! -d "$HOME/ubuntu" ]; then
        log_warning "Ubuntu 환경이 없습니다. 설치를 진행합니다."
        
        # Ubuntu 설치
        log_info "Ubuntu 22.04 LTS 설치 중..."
        proot-distro install ubuntu
        
        # Ubuntu 환경 설정
        setup_ubuntu_environment
    else
        log_success "Ubuntu 환경이 이미 존재합니다."
    fi
}

# Ubuntu 환경 설정
setup_ubuntu_environment() {
    log_info "Ubuntu 환경 설정 중..."
    
    # Ubuntu 환경에서 실행할 스크립트 생성
    cat > "$HOME/setup_ubuntu_local.sh" << 'EOF'
#!/bin/bash
set -e

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

# Node.js 설치
echo -e "${BLUE}[INFO]${NC} Node.js 설치 중..."
# 기존 Node.js 제거 (충돌 방지)
apt remove -y nodejs npm 2>/dev/null || true
apt autoremove -y

# Node.js 18 LTS 설치
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# npm 호환성 문제 해결
echo -e "${BLUE}[INFO]${NC} npm 호환성 문제 해결 중..."
npm install -g npm@10.8.2 || {
    echo -e "${YELLOW}[WARNING]${NC} npm 버전 변경 실패, 기본 버전 사용..."
}

# npm 캐시 정리
npm cache clean --force

# 전역 패키지 설치
echo -e "${BLUE}[INFO]${NC} 전역 패키지 설치 중..."
npm install -g yarn@1.22.19 typescript@5.3.3 ts-node@10.9.2 || {
    echo -e "${YELLOW}[WARNING]${NC} 일부 전역 패키지 설치 실패, 계속 진행..."
}

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
    proot-distro login ubuntu -- bash "$HOME/setup_ubuntu_local.sh"
    
    # 임시 스크립트 삭제
    rm "$HOME/setup_ubuntu_local.sh"
}

# 로컬 AppImage 파일 복사 및 설치
install_local_appimage() {
    local appimage_path="$1"
    log_info "로컬 AppImage 파일 설치 중..."
    
    # Ubuntu 환경에서 설치 스크립트 생성
    cat > "$HOME/install_local_cursor.sh" << EOF
#!/bin/bash
set -e

cd /home/cursor-ide

echo "로컬 AppImage 파일 설치 시작..."

# 기존 Cursor AI 제거 (있는 경우)
rm -rf cursor.AppImage squashfs-root 2>/dev/null || true

# 로컬 AppImage 파일 복사
echo "AppImage 파일 복사 중..."
cp "$appimage_path" ./cursor.AppImage

# 파일 크기 확인
if [ ! -s cursor.AppImage ]; then
    echo "오류: AppImage 파일이 비어있거나 복사에 실패했습니다."
    exit 1
fi

echo "AppImage 파일 크기: \$(ls -lh cursor.AppImage | awk '{print \$5}')"

# 실행 권한 부여
chmod +x cursor.AppImage

# AppImage 추출
echo "AppImage 추출 중..."
./cursor.AppImage --appimage-extract

echo "로컬 AppImage 설치 완료!"
EOF

    # Ubuntu 환경에서 설치 스크립트 실행
    proot-distro login ubuntu -- bash "$HOME/install_local_cursor.sh"
    
    # 임시 스크립트 삭제
    rm "$HOME/install_local_cursor.sh"
}

# launch.sh 생성
create_launch_script() {
    log_info "실행 스크립트 생성 중..."
    
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
    log_success "launch.sh 생성 완료"
}

# 메인 함수
main() {
    echo "=========================================="
    echo "  로컬 AppImage 파일로 Cursor AI 설치"
    echo "=========================================="
    echo ""
    
    # 사용자 권한 확인
    check_user_permissions

    # 로컬 AppImage 파일 확인
    local appimage_path=$(check_local_appimage)
    if [ $? -ne 0 ]; then
        exit 1
    fi
    
    echo ""
    log_info "설치를 시작합니다..."
    echo ""
    
    # Ubuntu 환경 확인 및 설치
    check_ubuntu_environment
    
    # 로컬 AppImage 파일 설치
    install_local_appimage "$appimage_path"
    
    # launch.sh 생성
    create_launch_script
    
    log_success "설치가 완료되었습니다!"
    echo ""
    echo "사용 방법:"
    echo "  ./launch.sh"
    echo ""
    echo "설치된 파일 정보:"
    echo "  - 원본 파일: $appimage_path"
    echo "  - 설치 위치: ~/ubuntu/home/cursor-ide/"
    echo "  - 실행 스크립트: ~/launch.sh"
    echo ""
    echo "주의사항:"
    echo "  - 첫 실행 시 시간이 오래 걸릴 수 있습니다."
    echo "  - 충분한 저장공간과 메모리가 필요합니다."
}

# 스크립트 실행
main "$@" 