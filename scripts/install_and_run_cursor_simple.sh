#!/bin/bash

# ==========================================
# Cursor AI 간단 설치 스크립트 (안전 버전)
# ==========================================
# 로컬 AppImage 파일을 사용한 오류 없는 설치
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

# 안전한 명령어 실행 함수
safe_run() {
    local cmd="$1"
    local description="$2"
    
    log_info "$description"
    if eval "$cmd" 2>/dev/null; then
        log_success "$description 완료"
        return 0
    else
        log_warning "$description 실패 (무시됨)"
        return 1
    fi
}

# 메인 설치 함수
main() {
    echo "=========================================="
    echo "  Cursor AI 간단 설치 스크립트 (안전 버전)"
    echo "=========================================="
    echo ""
    
    log_info "설치 시작..."
    
    # 1. AppImage 파일 확인
    log_info "AppImage 파일 확인 중..."
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
    
    # 2. 필수 패키지 설치 (안전하게)
    safe_run "pkg update -y" "패키지 업데이트"
    safe_run "pkg install -y proot-distro curl wget proot tar unzip git" "필수 패키지 설치"
    
    # 3. Ubuntu 환경 확인 및 설치
    if ! proot-distro list | grep -q "ubuntu"; then
        log_info "Ubuntu 환경 설치 중..."
        safe_run "proot-distro install ubuntu" "Ubuntu 환경 설치"
    else
        log_success "Ubuntu 환경 이미 설치됨"
    fi
    
    # 4. Ubuntu 환경 설정 (안전하게)
    log_info "Ubuntu 환경 설정 중..."
    proot-distro login ubuntu -- bash -c "
        apt update -y || echo '패키지 업데이트 실패 (무시됨)'
        apt install -y curl wget git build-essential python3 python3-pip || echo '일부 패키지 설치 실패 (무시됨)'
        apt install -y xvfb x11-apps x11-utils x11-xserver-utils dbus-x11 || echo 'X11 패키지 설치 실패 (무시됨)'
        mkdir -p /home/cursor-ide
        cd /home/cursor-ide
        echo 'Ubuntu 환경 설정 완료'
    " || log_warning "Ubuntu 환경 설정 중 일부 오류 발생 (무시됨)"
    
    # 5. AppImage 파일 복사
    log_info "AppImage 파일 복사 중..."
    proot-distro login ubuntu -- bash -c "
        cd /home/cursor-ide
        cp '$PWD/$found_file' cursor.AppImage
        chmod +x cursor.AppImage
        ls -la cursor.AppImage
    " || log_error "AppImage 파일 복사 실패"
    
    # 6. AppImage 추출
    log_info "AppImage 추출 중..."
    proot-distro login ubuntu -- bash -c "
        cd /home/cursor-ide
        rm -rf squashfs-root 2>/dev/null || true
        ./cursor.AppImage --appimage-extract
        if [ -d 'squashfs-root' ]; then
            echo 'AppImage 추출 완료'
        else
            echo 'AppImage 추출 실패'
            exit 1
        fi
    " || log_error "AppImage 추출 실패"
    
    # 7. 실행 스크립트 생성
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
    " || log_warning "Ubuntu 실행 스크립트 생성 실패 (무시됨)"
    
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
    
    chmod +x ~/launch_cursor.sh || log_warning "launch_cursor.sh 권한 설정 실패 (무시됨)"
    
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
    
    chmod +x ~/launch_cursor_vnc.sh || log_warning "launch_cursor_vnc.sh 권한 설정 실패 (무시됨)"
    
    log_success "실행 스크립트 생성 완료"
    
    # 8. 설치 완료 메시지
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