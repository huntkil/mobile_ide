#!/bin/bash

# Galaxy Android용 Cursor AI IDE 환경 복구 스크립트
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

# 백업 생성
create_backup() {
    log_info "현재 환경 백업 중..."
    
    local backup_dir="$HOME/cursor_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # 설정 파일 백업
    if [ -f "$HOME/cursor-config.json" ]; then
        cp "$HOME/cursor-config.json" "$backup_dir/"
        log_success "설정 파일 백업 완료"
    fi
    
    # 프로젝트 파일 백업 (있는 경우)
    if [ -d "$HOME/ubuntu/home/cursor-ide/projects" ]; then
        cp -r "$HOME/ubuntu/home/cursor-ide/projects" "$backup_dir/"
        log_success "프로젝트 파일 백업 완료"
    fi
    
    log_success "백업 완료: $backup_dir"
}

# Ubuntu 환경 제거
remove_ubuntu_environment() {
    log_info "기존 Ubuntu 환경 제거 중..."
    
    if [ -d "$HOME/ubuntu" ]; then
        rm -rf "$HOME/ubuntu"
        log_success "Ubuntu 환경 제거 완료"
    else
        log_info "Ubuntu 환경이 존재하지 않습니다."
    fi
}

# 캐시 정리
clean_cache() {
    log_info "캐시 정리 중..."
    
    # Termux 캐시 정리
    rm -rf "$HOME/.cache" 2>/dev/null || true
    
    # npm 캐시 정리
    npm cache clean --force 2>/dev/null || true
    
    # 시스템 캐시 정리
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    
    log_success "캐시 정리 완료"
}

# 의존성 재설치
reinstall_dependencies() {
    log_info "의존성 재설치 중..."
    
    # Termux 패키지 업데이트
    pkg update -y
    
    # 필수 패키지 재설치
    pkg install -y \
        curl \
        wget \
        proot \
        tar \
        unzip \
        proot-distro
    
    log_success "의존성 재설치 완료"
}

# Ubuntu 재설치
reinstall_ubuntu() {
    log_info "Ubuntu 22.04 LTS 재설치 중..."
    
    proot-distro install ubuntu
    
    log_success "Ubuntu 재설치 완료"
}

# 환경 재설정
reconfigure_environment() {
    log_info "환경 재설정 중..."
    
    # Ubuntu 환경 설정 스크립트 실행
    cat > "$HOME/reconfigure_ubuntu.sh" << 'EOF'
#!/bin/bash
set -e

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[INFO]${NC} Ubuntu 환경 재설정 시작..."

# 패키지 목록 업데이트
apt update

# 필수 패키지 재설치
echo -e "${BLUE}[INFO]${NC} 필수 패키지 재설치 중..."
apt install -y \
    curl \
    wget \
    git \
    build-essential \
    python3 \
    python3-pip \
    nodejs \
    npm \
    vim \
    nano \
    htop \
    tree \
    unzip \
    zip \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common

# Node.js 최신 버전 재설치
echo -e "${BLUE}[INFO]${NC} Node.js 최신 버전 재설치 중..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs

# npm 최신 버전으로 업데이트
npm install -g npm@latest

# 전역 패키지 재설치
echo -e "${BLUE}[INFO]${NC} 전역 패키지 재설치 중..."
npm install -g yarn typescript ts-node

# X11 관련 패키지 재설치
echo -e "${BLUE}[INFO]${NC} X11 환경 재설정 중..."
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
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libatspi2.0-0 \
    libgtk-3-0 \
    libgbm1 \
    libasound2

# 작업 디렉토리 재생성
mkdir -p /home/cursor-ide
cd /home/cursor-ide

echo -e "${GREEN}[SUCCESS]${NC} Ubuntu 환경 재설정 완료!"
EOF

    # Ubuntu 환경에서 재설정 스크립트 실행
    proot-distro login ubuntu -- bash "$HOME/reconfigure_ubuntu.sh"
    
    # 임시 스크립트 삭제
    rm "$HOME/reconfigure_ubuntu.sh"
}

# Cursor AI 재설치
reinstall_cursor_ai() {
    log_info "Cursor AI 재설치 중..."
    
    # Ubuntu 환경에서 Cursor AI 재설치
    cat > "$HOME/reinstall_cursor.sh" << 'EOF'
#!/bin/bash
set -e

cd /home/cursor-ide

# 기존 Cursor AI 제거
rm -rf cursor.AppImage squashfs-root 2>/dev/null || true

# Cursor AI AppImage 재다운로드 (ARM64 버전)
echo "Cursor AI ARM64 AppImage 재다운로드 중..."
wget -O cursor.AppImage "https://download.cursor.sh/linux/appImage/arm64"

# 실행 권한 부여
chmod +x cursor.AppImage

# AppImage 추출 (fuse가 작동하지 않을 경우)
./cursor.AppImage --appimage-extract

echo "Cursor AI 재설치 완료!"
EOF

    proot-distro login ubuntu -- bash "$HOME/reinstall_cursor.sh"
    rm "$HOME/reinstall_cursor.sh"
}

# 설정 복원
restore_configuration() {
    log_info "설정 복원 중..."
    
    # 백업된 설정 파일 복원
    local backup_files=($(find "$HOME" -name "cursor_backup_*" -type d | sort -r))
    
    if [ ${#backup_files[@]} -gt 0 ]; then
        local latest_backup="${backup_files[0]}"
        
        if [ -f "$latest_backup/cursor-config.json" ]; then
            cp "$latest_backup/cursor-config.json" "$HOME/ubuntu/home/cursor-ide/"
            log_success "설정 파일 복원 완료"
        fi
        
        if [ -d "$latest_backup/projects" ]; then
            cp -r "$latest_backup/projects" "$HOME/ubuntu/home/cursor-ide/"
            log_success "프로젝트 파일 복원 완료"
        fi
    else
        log_warning "복원할 백업을 찾을 수 없습니다."
    fi
}

# 실행 스크립트 재생성
recreate_scripts() {
    log_info "실행 스크립트 재생성 중..."
    
    # launch.sh 재생성
    if [ -f "scripts/launch.sh" ]; then
        cp "scripts/launch.sh" "$HOME/"
        chmod +x "$HOME/launch.sh"
    fi
    
    # optimize.sh 재생성
    if [ -f "scripts/optimize.sh" ]; then
        cp "scripts/optimize.sh" "$HOME/"
        chmod +x "$HOME/optimize.sh"
    fi
    
    log_success "실행 스크립트 재생성 완료"
}

# 메인 복구 함수
main() {
    echo "=========================================="
    echo "  Cursor AI IDE 환경 복구"
    echo "=========================================="
    echo ""
    
    # 사용자 확인
    echo "이 작업은 기존 환경을 완전히 제거하고 재설치합니다."
    echo "중요한 프로젝트 파일은 백업됩니다."
    echo ""
    read -p "계속하시겠습니까? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "복구 작업이 취소되었습니다."
        exit 0
    fi
    
    # 백업 생성
    create_backup
    echo ""
    
    # 캐시 정리
    clean_cache
    echo ""
    
    # Ubuntu 환경 제거
    remove_ubuntu_environment
    echo ""
    
    # 의존성 재설치
    reinstall_dependencies
    echo ""
    
    # Ubuntu 재설치
    reinstall_ubuntu
    echo ""
    
    # 환경 재설정
    reconfigure_environment
    echo ""
    
    # Cursor AI 재설치
    reinstall_cursor_ai
    echo ""
    
    # 설정 복원
    restore_configuration
    echo ""
    
    # 실행 스크립트 재생성
    recreate_scripts
    echo ""
    
    log_success "환경 복구가 완료되었습니다!"
    echo ""
    echo "사용 방법:"
    echo "  실행: ./launch.sh"
    echo "  최적화: ./optimize.sh"
    echo ""
    echo "주의사항:"
    echo "  - 첫 실행 시 시간이 오래 걸릴 수 있습니다."
    echo "  - 백업된 파일은 $HOME/cursor_backup_* 디렉토리에 있습니다."
}

# 스크립트 실행
main "$@" 