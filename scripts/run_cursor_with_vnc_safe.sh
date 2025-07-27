#!/bin/bash

# ==========================================
# Cursor AI + VNC 서버 통합 실행 스크립트 (안전 버전)
# ==========================================
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

# 메인 함수
main() {
    echo "=========================================="
    echo "  Cursor AI + VNC 서버 통합 실행 (안전 버전)"
    echo "=========================================="
    echo ""
    
    log_info "통합 실행 시작..."
    
    # 1. 기존 프로세스 정리 (안전하게)
    log_info "기존 프로세스 정리 중..."
    safe_run "pkill -f 'cursor'" "Cursor 프로세스 종료"
    safe_run "pkill -f 'AppRun'" "AppRun 프로세스 종료"
    safe_run "vncserver -kill :1" "VNC 서버 종료"
    sleep 3
    
    # 2. VNC 서버 시작 (안전하게)
    log_info "VNC 서버 시작 중..."
    if command -v vncserver &>/dev/null; then
        log_info "TigerVNC 서버 시작 중..."
        vncserver :1 -geometry 1024x768 -depth 24 -localhost no -SecurityTypes VncAuth &
        sleep 5
        
        # VNC 서버 상태 확인
        if ps aux | grep -E "(Xvnc|vncserver)" | grep -v grep &>/dev/null; then
            log_success "VNC 서버 시작 완료"
        else
            log_warning "VNC 서버 시작 실패 (무시됨)"
        fi
    else
        log_error "VNC 서버를 찾을 수 없습니다."
        log_info "VNC 서버를 먼저 설치하세요: ./scripts/install_vnc_server.sh"
        return 1
    fi
    
    # 3. Cursor AI 실행 (안전하게)
    log_info "Cursor AI 실행 중..."
    proot-distro login ubuntu -- bash -c "
        cd /home/cursor-ide
        export DISPLAY=:1
        export XDG_RUNTIME_DIR=\"\$HOME/.runtime-cursor\"
        mkdir -p \"\$XDG_RUNTIME_DIR\"
        chmod 700 \"\$XDG_RUNTIME_DIR\"
        
        # Cursor AI 실행
        ./squashfs-root/AppRun --no-sandbox --disable-gpu --single-process --disable-dev-shm-usage --max-old-space-size=1024 &
        
        echo 'Cursor AI 실행 완료'
    " || log_warning "Cursor AI 실행 중 오류 발생 (무시됨)"
    
    # 4. 프로세스 확인 (안전하게)
    log_info "실행된 프로세스 확인 중..."
    sleep 3
    
    echo ""
    echo "실행된 프로세스:"
    ps aux | grep -E "(cursor|AppRun|Xvnc)" | grep -v grep || echo "실행 중인 프로세스 없음"
    
    # 5. 연결 정보 표시
    echo ""
    echo "=========================================="
    echo "  연결 정보"
    echo "=========================================="
    echo ""
    echo "VNC 서버 정보:"
    echo "  서버 주소: localhost:5901"
    echo "  비밀번호: cursor123"
    echo "  해상도: 1024x768"
    echo ""
    echo "Android VNC Viewer 앱에서 위 정보로 접속하세요."
    echo ""
    echo "관리 명령어:"
    echo "  프로세스 확인: ps aux | grep -E '(cursor|AppRun|Xvnc)' | grep -v grep"
    echo "  프로세스 종료: pkill -f 'cursor' && vncserver -kill :1"
    echo "  재시작: ./run_cursor_with_vnc_safe.sh"
    echo ""
    
    log_success "Cursor AI + VNC 서버 통합 실행 완료!"
    log_info "이제 VNC Viewer에서 localhost:5901에 접속하면 Cursor AI 화면을 볼 수 있습니다."
}

# 스크립트 실행
main "$@" 