#!/bin/bash

# 중단된 설치 완료 스크립트
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

# 설치 상태 확인
check_installation_status() {
    log_info "설치 상태 확인 중..."
    
    local status=0
    
    # Ubuntu 환경 확인
    if [ -d "$HOME/ubuntu" ]; then
        log_success "Ubuntu 환경: 설치됨"
    else
        log_warning "Ubuntu 환경: 없음"
        status=1
    fi
    
    # launch.sh 확인
    if [ -f "$HOME/launch.sh" ]; then
        log_success "launch.sh: 존재함"
    else
        log_warning "launch.sh: 없음"
        status=1
    fi
    
    # Cursor AI 확인
    if [ -f "$HOME/ubuntu/home/cursor-ide/cursor.AppImage" ] || [ -d "$HOME/ubuntu/home/cursor-ide/squashfs-root" ]; then
        log_success "Cursor AI: 설치됨"
    else
        log_warning "Cursor AI: 없음"
        status=1
    fi
    
    return $status
}

# Ubuntu 환경 설치
install_ubuntu() {
    log_info "Ubuntu 22.04 LTS 설치 중..."
    
    # proot-distro 확인
    if ! command -v proot-distro &> /dev/null; then
        log_error "proot-distro가 설치되지 않았습니다."
        log_info "다음 명령어로 설치하세요:"
        echo "pkg install proot-distro"
        exit 1
    fi
    
    # Ubuntu 설치
    proot-distro install ubuntu
    
    log_success "Ubuntu 환경 설치 완료"
}

# Ubuntu 환경 설정
setup_ubuntu() {
    log_info "Ubuntu 환경 설정 중..."
    
    # Ubuntu 환경에서 실행할 스크립트 생성
    cat > "$HOME/setup_ubuntu_complete.sh" << 'EOF'
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
    proot-distro login ubuntu -- bash "$HOME/setup_ubuntu_complete.sh"
    
    # 임시 스크립트 삭제
    rm "$HOME/setup_ubuntu_complete.sh"
}

# Cursor AI 설치
install_cursor_ai() {
    log_info "Cursor AI 설치 중..."
    
    # Ubuntu 환경에서 Cursor AI 설치
    cat > "$HOME/install_cursor_complete.sh" << 'EOF'
#!/bin/bash
set -e

cd /home/cursor-ide

echo "Cursor AI 설치 시작..."

# 기존 Cursor AI 제거 (있는 경우)
rm -rf cursor.AppImage squashfs-root 2>/dev/null || true

# 네트워크 연결 테스트
echo "네트워크 연결 테스트 중..."
if ! nslookup download.cursor.sh >/dev/null 2>&1; then
    echo "DNS 문제 감지, DNS 설정 수정 중..."
    echo "nameserver 8.8.8.8" > /etc/resolv.conf
    echo "nameserver 8.8.4.4" >> /etc/resolv.conf
    echo "nameserver 1.1.1.1" >> /etc/resolv.conf
fi

# Cursor AI AppImage 다운로드 (여러 방법 시도)
echo "Cursor AI ARM64 AppImage 다운로드 중..."

# 방법 1: 기본 URL
if wget -O cursor.AppImage "https://download.cursor.sh/linux/appImage/arm64" --timeout=30; then
    echo "기본 URL 다운로드 성공!"
elif curl -L -o cursor.AppImage "https://download.cursor.sh/linux/appImage/arm64" --connect-timeout 30; then
    echo "curl로 다운로드 성공!"
elif wget -O cursor.AppImage "https://cursor.sh/download/linux/arm64" --timeout=30; then
    echo "대체 URL 다운로드 성공!"
elif curl -L -o cursor.AppImage "https://cursor.sh/download/linux/arm64" --connect-timeout 30; then
    echo "curl 대체 URL 다운로드 성공!"
elif wget -O cursor.AppImage "https://github.com/getcursor/cursor/releases/latest/download/cursor-linux-arm64.AppImage" --timeout=30; then
    echo "GitHub 릴리즈 다운로드 성공!"
elif curl -L -o cursor.AppImage "https://github.com/getcursor/cursor/releases/latest/download/cursor-linux-arm64.AppImage" --connect-timeout 30; then
    echo "curl GitHub 릴리즈 다운로드 성공!"
else
    echo "모든 다운로드 방법 실패"
    echo "수동 다운로드가 필요합니다:"
    echo "1. 브라우저에서 https://cursor.sh 방문"
    echo "2. ARM64 버전 다운로드"
    echo "3. 파일을 /home/cursor-ide/ 폴더로 이동"
    echo "4. 파일명을 'cursor.AppImage'로 변경"
    exit 1
fi

# 실행 권한 부여
chmod +x cursor.AppImage

# AppImage 추출
echo "AppImage 추출 중..."
./cursor.AppImage --appimage-extract

echo "Cursor AI 설치 완료!"
EOF

    proot-distro login ubuntu -- bash "$HOME/install_cursor_complete.sh"
    local result=$?
    rm "$HOME/install_cursor_complete.sh"
    return $result
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
    echo "  중단된 설치 완료 스크립트"
    echo "=========================================="
    echo ""
    
    # 현재 상태 확인
    if check_installation_status; then
        log_success "설치가 완료되어 있습니다!"
        echo ""
        echo "사용 방법:"
        echo "  ./launch.sh"
        return 0
    fi
    
    echo ""
    echo "누락된 부분을 설치합니다..."
    echo ""
    
    # Ubuntu 환경 설치 (필요한 경우)
    if [ ! -d "$HOME/ubuntu" ]; then
        install_ubuntu
        setup_ubuntu
    else
        log_info "Ubuntu 환경이 이미 존재합니다."
    fi
    
    # Cursor AI 설치 (필요한 경우)
    if [ ! -f "$HOME/ubuntu/home/cursor-ide/cursor.AppImage" ] && [ ! -d "$HOME/ubuntu/home/cursor-ide/squashfs-root" ]; then
        install_cursor_ai
    else
        log_info "Cursor AI가 이미 설치되어 있습니다."
    fi
    
    # launch.sh 생성 (필요한 경우)
    if [ ! -f "$HOME/launch.sh" ]; then
        create_launch_script
    else
        log_info "launch.sh가 이미 존재합니다."
    fi
    
    log_success "설치 완료!"
    echo ""
    echo "사용 방법:"
    echo "  ./launch.sh"
    echo ""
    echo "주의사항:"
    echo "  - 첫 실행 시 시간이 오래 걸릴 수 있습니다."
    echo "  - 충분한 저장공간과 메모리가 필요합니다."
}

# 스크립트 실행
main "$@" 