#!/bin/bash

# ==========================================
# Cursor AI 실행 스크립트 경로 수정기
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

# 메인 함수
main() {
    echo "=========================================="
    echo "  Cursor AI 실행 스크립트 경로 수정기"
    echo "=========================================="
    echo ""
    
    log_info "실행 스크립트 경로 수정 시작..."
    
    # 현재 디렉토리 확인
    current_dir=$(pwd)
    log_info "현재 디렉토리: $current_dir"
    
    # 1. 홈 디렉토리에 있는 스크립트들을 현재 디렉토리로 복사
    log_info "홈 디렉토리에서 실행 스크립트 복사 중..."
    
    if [ -f ~/launch_cursor.sh ]; then
        cp ~/launch_cursor.sh ./launch_cursor.sh
        chmod +x ./launch_cursor.sh
        log_success "launch_cursor.sh 복사 완료"
    else
        log_warning "~/launch_cursor.sh 파일이 없습니다"
    fi
    
    if [ -f ~/launch_cursor_vnc.sh ]; then
        cp ~/launch_cursor_vnc.sh ./launch_cursor_vnc.sh
        chmod +x ./launch_cursor_vnc.sh
        log_success "launch_cursor_vnc.sh 복사 완료"
    else
        log_warning "~/launch_cursor_vnc.sh 파일이 없습니다"
    fi
    
    if [ -f ~/start_vnc.sh ]; then
        cp ~/start_vnc.sh ./start_vnc.sh
        chmod +x ./start_vnc.sh
        log_success "start_vnc.sh 복사 완료"
    else
        log_warning "~/start_vnc.sh 파일이 없습니다"
    fi
    
    if [ -f ~/cursor_control.sh ]; then
        cp ~/cursor_control.sh ./cursor_control.sh
        chmod +x ./cursor_control.sh
        log_success "cursor_control.sh 복사 완료"
    else
        log_warning "~/cursor_control.sh 파일이 없습니다"
    fi
    
    # 2. 현재 디렉토리에 직접 스크립트 생성 (백업)
    log_info "현재 디렉토리에 실행 스크립트 직접 생성 중..."
    
    # 기본 실행 스크립트
    cat > ./launch_cursor.sh << 'EOF'
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
    
    chmod +x ./launch_cursor.sh
    log_success "launch_cursor.sh 생성 완료"
    
    # VNC 지원 실행 스크립트
    cat > ./launch_cursor_vnc.sh << 'EOF'
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
    
    chmod +x ./launch_cursor_vnc.sh
    log_success "launch_cursor_vnc.sh 생성 완료"
    
    # VNC 서버만 시작하는 스크립트
    cat > ./start_vnc.sh << 'EOF'
#!/bin/bash
echo "=========================================="
echo "  VNC 서버 시작 중..."
echo "=========================================="

# 기존 VNC 서버 종료
vncserver -kill :1 2>/dev/null || true

# VNC 서버 시작
vncserver :1 -geometry 1024x768 -depth 24 -localhost no

echo "VNC 서버가 시작되었습니다."
echo "Android VNC Viewer 앱에서 localhost:5901에 접속하세요."
echo "비밀번호: cursor123"
EOF
    
    chmod +x ./start_vnc.sh
    log_success "start_vnc.sh 생성 완료"
    
    # 프로세스 관리 스크립트
    cat > ./cursor_control.sh << 'EOF'
#!/bin/bash
echo "=========================================="
echo "  Cursor AI 프로세스 관리"
echo "=========================================="

case "$1" in
    "status")
        echo "Cursor AI 프로세스 상태:"
        ps aux | grep -E '(cursor|AppRun)' | grep -v grep || echo "실행 중인 프로세스 없음"
        ;;
    "stop")
        echo "Cursor AI 프로세스 종료 중..."
        pkill -f 'cursor' || echo "종료할 프로세스 없음"
        pkill -f 'AppRun' || echo "종료할 프로세스 없음"
        echo "프로세스 종료 완료"
        ;;
    "restart")
        echo "Cursor AI 재시작 중..."
        pkill -f 'cursor' 2>/dev/null || true
        pkill -f 'AppRun' 2>/dev/null || true
        sleep 2
        proot-distro login ubuntu -- bash /home/cursor-ide/start.sh
        echo "재시작 완료"
        ;;
    *)
        echo "사용법: $0 {status|stop|restart}"
        echo ""
        echo "명령어:"
        echo "  status  - 프로세스 상태 확인"
        echo "  stop    - 프로세스 종료"
        echo "  restart - 프로세스 재시작"
        ;;
esac
EOF
    
    chmod +x ./cursor_control.sh
    log_success "cursor_control.sh 생성 완료"
    
    # 3. 생성된 파일들 확인
    log_info "생성된 파일들 확인 중..."
    ls -la ./launch_cursor.sh
    ls -la ./launch_cursor_vnc.sh
    ls -la ./start_vnc.sh
    ls -la ./cursor_control.sh
    
    # 4. 설치 완료 메시지
    echo ""
    echo "=========================================="
    echo "  실행 스크립트 경로 수정 완료!"
    echo "=========================================="
    echo ""
    echo "현재 디렉토리에 생성된 스크립트:"
    echo ""
    echo "1. 기본 실행:"
    echo "   ./launch_cursor.sh"
    echo ""
    echo "2. VNC 서버와 함께 실행 (GUI 화면 표시):"
    echo "   ./launch_cursor_vnc.sh"
    echo ""
    echo "3. VNC 서버만 시작:"
    echo "   ./start_vnc.sh"
    echo ""
    echo "4. 프로세스 관리:"
    echo "   ./cursor_control.sh status    # 상태 확인"
    echo "   ./cursor_control.sh stop      # 프로세스 종료"
    echo "   ./cursor_control.sh restart   # 재시작"
    echo ""
    echo "5. Android VNC Viewer 앱에서 localhost:5901 접속"
    echo "   비밀번호: cursor123"
    echo ""
    
    log_success "모든 실행 스크립트 경로 수정 완료!"
}

# 스크립트 실행
main "$@" 