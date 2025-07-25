#!/bin/bash

# Galaxy Android용 Cursor AI IDE 설치 문제 해결 스크립트
# Author: Mobile IDE Team
# Version: 1.0.0

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

# 문제 해결 함수들
fix_nodejs_issues() {
    log_info "Node.js 문제 해결 중..."
    
    # Ubuntu 환경에서 실행
    cat > "$HOME/fix_nodejs.sh" << 'EOF'
#!/bin/bash
set -e

echo "Node.js 문제 해결 시작..."

# 기존 Node.js 완전 제거
apt remove -y nodejs npm 2>/dev/null || true
apt autoremove -y
apt clean

# Node.js 저장소 제거
rm -f /etc/apt/sources.list.d/nodesource.list*

# 패키지 목록 업데이트
apt update

# Node.js 18 LTS 재설치
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# npm 업데이트
npm install -g npm@latest

echo "Node.js 문제 해결 완료!"
EOF

    proot-distro login ubuntu -- bash "$HOME/fix_nodejs.sh"
    rm "$HOME/fix_nodejs.sh"
}

fix_x11_packages() {
    log_info "X11 패키지 문제 해결 중..."
    
    # Ubuntu 환경에서 실행
    cat > "$HOME/fix_x11.sh" << 'EOF'
#!/bin/bash
set -e

echo "X11 패키지 문제 해결 시작..."

# 기존 X11 패키지 제거
apt remove -y xvfb x11-apps x11-utils x11-xserver-utils dbus-x11 2>/dev/null || true
apt autoremove -y

# 패키지 목록 업데이트
apt update

# ARM64 호환 패키지 설치
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
    libdrm2 \
    libxkbcommon0 \
    libgbm1

# ARM64 특화 패키지 시도
apt install -y libcups2t64 libatspi2.0-0t64 libgtk-3-0t64 libasound2t64 2>/dev/null || {
    echo "ARM64 특화 패키지 설치 실패, 일반 패키지 시도..."
    apt install -y libcups2 libatspi2.0-0 libgtk-3-0 libasound2 2>/dev/null || {
        echo "일반 패키지도 설치 실패, 기본 기능으로 진행..."
    }
}

echo "X11 패키지 문제 해결 완료!"
EOF

    proot-distro login ubuntu -- bash "$HOME/fix_x11.sh"
    rm "$HOME/fix_x11.sh"
}

fix_cursor_installation() {
    log_info "Cursor AI 설치 문제 해결 중..."
    
    # Ubuntu 환경에서 실행
    cat > "$HOME/fix_cursor.sh" << 'EOF'
#!/bin/bash
set -e

cd /home/cursor-ide

echo "Cursor AI 설치 문제 해결 시작..."

# 기존 Cursor AI 제거
rm -rf cursor.AppImage squashfs-root 2>/dev/null || true

# Cursor AI 재다운로드
echo "Cursor AI ARM64 AppImage 재다운로드 중..."
wget -O cursor.AppImage "https://download.cursor.sh/linux/appImage/arm64"

# 실행 권한 부여
chmod +x cursor.AppImage

# AppImage 추출
./cursor.AppImage --appimage-extract

echo "Cursor AI 설치 문제 해결 완료!"
EOF

    proot-distro login ubuntu -- bash "$HOME/fix_cursor.sh"
    rm "$HOME/fix_cursor.sh"
}

# 메인 해결 함수
main() {
    echo "=========================================="
    echo "  설치 문제 해결 도구"
    echo "=========================================="
    echo ""
    
    echo "해결할 문제를 선택하세요:"
    echo "1. Node.js 문제 해결"
    echo "2. X11 패키지 문제 해결"
    echo "3. Cursor AI 설치 문제 해결"
    echo "4. 모든 문제 해결"
    echo "5. 종료"
    echo ""
    
    read -p "선택 (1-5): " choice
    
    case $choice in
        1)
            fix_nodejs_issues
            ;;
        2)
            fix_x11_packages
            ;;
        3)
            fix_cursor_installation
            ;;
        4)
            log_info "모든 문제 해결 시작..."
            fix_nodejs_issues
            echo ""
            fix_x11_packages
            echo ""
            fix_cursor_installation
            echo ""
            log_success "모든 문제 해결 완료!"
            ;;
        5)
            log_info "종료합니다."
            exit 0
            ;;
        *)
            log_error "잘못된 선택입니다."
            exit 1
            ;;
    esac
    
    echo ""
    log_success "문제 해결이 완료되었습니다!"
    echo ""
    echo "다음 단계:"
    echo "  ./launch.sh  # Cursor AI 실행"
    echo "  ./optimize.sh  # 성능 최적화"
}

# 스크립트 실행
main "$@" 