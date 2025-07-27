#!/bin/bash

# ==========================================
# Cursor AI 완전 설치 및 실행 스크립트 v6.0
# ==========================================
# 로컬 AppImage 파일을 사용한 오류 없는 설치
# Author: Mobile IDE Team
# Version: 6.0.0

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

# 시스템 최적화
optimize_system() {
    log_info "시스템 최적화 중..."
    
    # 메모리 캐시 정리 (권한 문제 무시)
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || log_warning "메모리 캐시 정리 권한 없음 (무시됨)"
    
    # 불필요한 프로세스 종료 (권한 문제 무시)
    pkill -f "Xvfb" 2>/dev/null || log_warning "Xvfb 프로세스 종료 실패 (무시됨)"
    pkill -f "cursor" 2>/dev/null || log_warning "cursor 프로세스 종료 실패 (무시됨)"
    
    # 저장공간 정리 (권한 문제 무시)
    pkg clean 2>/dev/null || log_warning "패키지 캐시 정리 실패 (무시됨)"
    pkg autoclean 2>/dev/null || log_warning "패키지 자동 정리 실패 (무시됨)"
    rm -rf /tmp/* 2>/dev/null || log_warning "임시 파일 정리 실패 (무시됨)"
    rm -rf ~/.cache/* 2>/dev/null || log_warning "사용자 캐시 정리 실패 (무시됨)"
    
    log_success "시스템 최적화 완료"
}

# 필수 패키지 설치
install_required_packages() {
    log_info "필수 패키지 설치 중..."
    
    # Termux 패키지 업데이트
    pkg update -y
    
    # 필수 패키지 설치
    pkg install -y proot-distro curl wget proot tar unzip git
    
    # Ubuntu 설치 확인
    if ! proot-distro list | grep -q "ubuntu"; then
        log_info "Ubuntu 환경 설치 중..."
        proot-distro install ubuntu
    else
        log_success "Ubuntu 환경 이미 설치됨"
    fi
    
    log_success "필수 패키지 설치 완료"
}

# Ubuntu 환경 설정
setup_ubuntu_environment() {
    log_info "Ubuntu 환경 설정 중..."
    
    # Ubuntu 환경에서 실행
    proot-distro login ubuntu -- bash -c "
        # 패키지 업데이트
        apt update -y
        
        # 필수 패키지 설치
        apt install -y curl wget git build-essential python3 python3-pip
        
        # X11 관련 패키지 설치
        apt install -y xvfb x11-apps x11-utils x11-xserver-utils dbus-x11
        
        # Node.js 설치 (기존 제거 후 재설치)
        apt remove -y nodejs npm 2>/dev/null || true
        apt autoremove -y
        
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt install -y nodejs
        
        # npm 호환성 문제 해결
        npm install -g npm@10.8.2
        npm cache clean --force
        
        # 작업 디렉토리 생성
        mkdir -p /home/cursor-ide
        cd /home/cursor-ide
        
        echo 'Ubuntu 환경 설정 완료'
    "
    
    log_success "Ubuntu 환경 설정 완료"
}

# 로컬 AppImage 파일 확인 및 복사
setup_cursor_appimage() {
    log_info "로컬 AppImage 파일 설정 중..."
    
    # 현재 디렉토리에서 AppImage 파일 확인
    local appimage_files=(
        "Cursor-1.2.1-aarch64.AppImage"
        "cursor.AppImage"
        "cursor-linux-arm64.AppImage"
    )
    
    local found_file=""
    for file in "${appimage_files[@]}"; do
        if [ -f "$file" ]; then
            found_file="$file"
            log_success "AppImage 파일 발견: $file"
            break
        fi
    done
    
    if [ -z "$found_file" ]; then
        log_error "AppImage 파일을 찾을 수 없습니다."
        log_info "다음 파일 중 하나가 필요합니다:"
        for file in "${appimage_files[@]}"; do
            echo "  - $file"
        done
        return 1
    fi
    
    # Ubuntu 환경으로 파일 복사
    log_info "Ubuntu 환경으로 파일 복사 중..."
    proot-distro login ubuntu -- bash -c "
        cd /home/cursor-ide
        cp '$PWD/$found_file' cursor.AppImage
        chmod +x cursor.AppImage
        ls -la cursor.AppImage
    "
    
    log_success "AppImage 파일 설정 완료"
}

# AppImage 추출
extract_appimage() {
    log_info "AppImage 추출 중..."
    
    proot-distro login ubuntu -- bash -c "
        cd /home/cursor-ide
        
        # 기존 추출 파일 정리
        rm -rf squashfs-root 2>/dev/null || true
        
        # AppImage 추출
        ./cursor.AppImage --appimage-extract
        
        # 추출 결과 확인
        if [ -d 'squashfs-root' ]; then
            echo 'AppImage 추출 완료'
            ls -la squashfs-root/
        else
            echo 'AppImage 추출 실패'
            exit 1
        fi
    "
    
    log_success "AppImage 추출 완료"
}

# 실행 스크립트 생성
create_launch_scripts() {
    log_info "실행 스크립트 생성 중..."
    
    # Ubuntu 환경에서 실행할 스크립트 생성
    proot-distro login ubuntu -- bash -c "
        cd /home/cursor-ide
        
        cat > start.sh << 'EOF'
#!/bin/bash
export DISPLAY=:0
export XDG_RUNTIME_DIR=\"\$HOME/.runtime-cursor\"
mkdir -p \"\$XDG_RUNTIME_DIR\"
chmod 700 \"\$XDG_RUNTIME_DIR\"

# Xvfb 시작
Xvfb :0 -screen 0 1024x768x16 -ac +extension GLX +render -noreset &
sleep 3

# Cursor AI 실행
./squashfs-root/AppRun --no-sandbox --disable-gpu --single-process --disable-dev-shm-usage --max-old-space-size=1024 &
EOF
        
        chmod +x start.sh
        echo 'Ubuntu 실행 스크립트 생성 완료'
    "
    
    # Termux에서 실행할 스크립트 생성
    cat > ~/launch_cursor.sh << 'EOF'
#!/bin/bash
echo "=========================================="
echo "  Cursor AI 실행 중..."
echo "=========================================="

# Ubuntu 환경에서 Cursor AI 실행
proot-distro login ubuntu -- bash /home/cursor-ide/start.sh

echo "Cursor AI가 실행되었습니다."
echo "VNC 서버를 사용하여 GUI 화면을 볼 수 있습니다."
echo ""
echo "VNC 서버 시작: vncserver :1 -geometry 1024x768 -depth 24"
echo "VNC Viewer 앱에서 localhost:5901 접속"
EOF
    
    chmod +x ~/launch_cursor.sh
    
    # VNC 지원 실행 스크립트 생성
    cat > ~/launch_cursor_vnc.sh << 'EOF'
#!/bin/bash
echo "=========================================="
echo "  Cursor AI VNC 실행 중..."
echo "=========================================="

# VNC 서버 시작
vncserver :1 -geometry 1024x768 -depth 24 -localhost no &
sleep 3

# Ubuntu 환경에서 Cursor AI 실행
proot-distro login ubuntu -- bash -c "
cd /home/cursor-ide
export DISPLAY=:1
./squashfs-root/AppRun --no-sandbox --disable-gpu --single-process --disable-dev-shm-usage --max-old-space-size=1024 &
"

echo "Cursor AI가 VNC 서버와 함께 실행되었습니다."
echo "Android VNC Viewer 앱에서 localhost:5901에 접속하세요."
echo "비밀번호: cursor123"
EOF
    
    chmod +x ~/launch_cursor_vnc.sh
    
    log_success "실행 스크립트 생성 완료"
}

# 설치 검증
verify_installation() {
    log_info "설치 검증 중..."
    
    local errors=0
    
    # Ubuntu 환경 내부에서 검증
    if proot-distro login ubuntu -- bash -c "test -d /home/cursor-ide"; then
        log_success "Ubuntu 내부에서 cursor-ide 디렉토리 확인됨"
    else
        log_error "Ubuntu 내부에서 cursor-ide 디렉토리 없음"
        ((errors++))
    fi
    
    if proot-distro login ubuntu -- bash -c "test -f /home/cursor-ide/cursor.AppImage"; then
        log_success "Ubuntu 내부에서 cursor.AppImage 확인됨"
    else
        log_error "Ubuntu 내부에서 cursor.AppImage 없음"
        ((errors++))
    fi
    
    if proot-distro login ubuntu -- bash -c "test -d /home/cursor-ide/squashfs-root"; then
        log_success "Ubuntu 내부에서 squashfs-root 디렉토리 확인됨"
    else
        log_error "Ubuntu 내부에서 squashfs-root 디렉토리 없음"
        ((errors++))
    fi
    
    # Termux에서 실행 스크립트 확인
    if [ -f ~/launch_cursor.sh ]; then
        log_success "launch_cursor.sh 확인됨"
    else
        log_error "launch_cursor.sh 없음"
        ((errors++))
    fi
    
    if [ -f ~/launch_cursor_vnc.sh ]; then
        log_success "launch_cursor_vnc.sh 확인됨"
    else
        log_error "launch_cursor_vnc.sh 없음"
        ((errors++))
    fi
    
    if [ $errors -eq 0 ]; then
        log_success "설치 검증 완료 - 모든 구성 요소 정상"
        return 0
    else
        log_error "설치 검증 실패 - $errors 개 오류 발견"
        return 1
    fi
}

# 메인 함수
main() {
    echo "=========================================="
    echo "  Cursor AI 완전 설치 및 실행 스크립트 v6.0"
    echo "=========================================="
    echo ""
    
    log_info "설치 시작..."
    
    # 1. 시스템 최적화
    optimize_system
    
    # 2. 필수 패키지 설치
    install_required_packages
    
    # 3. Ubuntu 환경 설정
    setup_ubuntu_environment
    
    # 4. 로컬 AppImage 파일 설정
    setup_cursor_appimage
    
    # 5. AppImage 추출
    extract_appimage
    
    # 6. 실행 스크립트 생성
    create_launch_scripts
    
    # 7. 설치 검증
    verify_installation
    
    echo ""
    echo "=========================================="
    echo "  설치 완료!"
    echo "=========================================="
    echo ""
    echo "사용 가능한 실행 명령어:"
    echo ""
    echo "1. 기본 실행:"
    echo "   ./launch_cursor.sh"
    echo ""
    echo "2. VNC 서버와 함께 실행 (GUI 화면 표시):"
    echo "   ./launch_cursor_vnc.sh"
    echo ""
    echo "3. VNC 서버만 시작:"
    echo "   vncserver :1 -geometry 1024x768 -depth 24"
    echo ""
    echo "4. Android VNC Viewer 앱에서 localhost:5901 접속"
    echo "   비밀번호: cursor123"
    echo ""
    echo "5. 프로세스 확인:"
    echo "   ps aux | grep -E '(cursor|AppRun)' | grep -v grep"
    echo ""
    echo "6. 프로세스 종료:"
    echo "   pkill -f 'cursor'"
    echo ""
    
    log_success "Cursor AI 설치 및 설정 완료!"
}

# 스크립트 실행
main "$@" 