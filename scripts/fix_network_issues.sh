#!/bin/bash

# 네트워크 연결 문제 해결 스크립트
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

# 네트워크 연결 테스트
test_network_connection() {
    log_info "네트워크 연결 테스트 중..."
    
    # DNS 확인 테스트
    if nslookup google.com >/dev/null 2>&1; then
        log_success "DNS 확인: 정상"
    else
        log_warning "DNS 확인: 실패"
        return 1
    fi
    
    # HTTP 연결 테스트
    if curl -s --connect-timeout 10 https://www.google.com >/dev/null; then
        log_success "HTTP 연결: 정상"
    else
        log_warning "HTTP 연결: 실패"
        return 1
    fi
    
    return 0
}

# DNS 설정 수정
fix_dns_settings() {
    log_info "DNS 설정 수정 중..."
    
    # Ubuntu 환경에서 DNS 설정 수정
    cat > "$HOME/fix_dns_ubuntu.sh" << 'EOF'
#!/bin/bash
set -e

echo "DNS 설정 수정 중..."

# DNS 서버 설정 (Google DNS, Cloudflare DNS)
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf

# resolv.conf 보호 해제
chattr -i /etc/resolv.conf 2>/dev/null || true

# 네트워크 재시작
systemctl restart systemd-resolved 2>/dev/null || true

echo "DNS 설정 완료!"
EOF

    proot-distro login ubuntu -- bash "$HOME/fix_dns_ubuntu.sh"
    rm "$HOME/fix_dns_ubuntu.sh"
}

# 대체 다운로드 방법
download_cursor_alternative() {
    log_info "대체 다운로드 방법 시도 중..."
    
    # Ubuntu 환경에서 대체 다운로드
    cat > "$HOME/download_cursor_alt.sh" << 'EOF'
#!/bin/bash
set -e

cd /home/cursor-ide

echo "대체 다운로드 방법 시도 중..."

# 방법 1: curl 사용
echo "방법 1: curl로 다운로드 시도..."
if curl -L -o cursor.AppImage "https://download.cursor.sh/linux/appImage/arm64" --connect-timeout 30; then
    echo "curl 다운로드 성공!"
    chmod +x cursor.AppImage
    ./cursor.AppImage --appimage-extract
    exit 0
fi

# 방법 2: 다른 URL 시도
echo "방법 2: 대체 URL 시도..."
if curl -L -o cursor.AppImage "https://cursor.sh/download/linux/arm64" --connect-timeout 30; then
    echo "대체 URL 다운로드 성공!"
    chmod +x cursor.AppImage
    ./cursor.AppImage --appimage-extract
    exit 0
fi

# 방법 3: GitHub 릴리즈에서 다운로드
echo "방법 3: GitHub 릴리즈에서 다운로드 시도..."
if curl -L -o cursor.AppImage "https://github.com/getcursor/cursor/releases/latest/download/cursor-linux-arm64.AppImage" --connect-timeout 30; then
    echo "GitHub 릴리즈 다운로드 성공!"
    chmod +x cursor.AppImage
    ./cursor.AppImage --appimage-extract
    exit 0
fi

echo "모든 다운로드 방법 실패"
exit 1
EOF

    proot-distro login ubuntu -- bash "$HOME/download_cursor_alt.sh"
    local result=$?
    rm "$HOME/download_cursor_alt.sh"
    return $result
}

# 수동 다운로드 가이드
manual_download_guide() {
    log_info "수동 다운로드 가이드 제공..."
    
    echo ""
    echo "=========================================="
    echo "  수동 다운로드 가이드"
    echo "=========================================="
    echo ""
    echo "네트워크 문제로 자동 다운로드가 실패했습니다."
    echo "다음 방법 중 하나를 시도해보세요:"
    echo ""
    echo "1. 브라우저에서 다운로드:"
    echo "   - https://cursor.sh 에서 ARM64 버전 다운로드"
    echo "   - 다운로드한 파일을 ~/ubuntu/home/cursor-ide/ 폴더로 이동"
    echo "   - 파일명을 'cursor.AppImage'로 변경"
    echo ""
    echo "2. 터미널에서 직접 다운로드:"
    echo "   proot-distro login ubuntu"
    echo "   cd /home/cursor-ide"
    echo "   wget -O cursor.AppImage 'https://download.cursor.sh/linux/appImage/arm64'"
    echo "   chmod +x cursor.AppImage"
    echo "   ./cursor.AppImage --appimage-extract"
    echo ""
    echo "3. 네트워크 설정 확인:"
    echo "   - VPN 사용 중인지 확인"
    echo "   - 방화벽 설정 확인"
    echo "   - DNS 설정 확인"
    echo ""
}

# 메인 함수
main() {
    echo "=========================================="
    echo "  네트워크 연결 문제 해결 스크립트"
    echo "=========================================="
    echo ""
    
    # 네트워크 연결 테스트
    if test_network_connection; then
        log_success "네트워크 연결이 정상입니다."
        echo ""
        echo "Cursor AI 다운로드를 다시 시도합니다..."
        
        if download_cursor_alternative; then
            log_success "Cursor AI 다운로드 성공!"
            echo ""
            echo "이제 Cursor AI를 실행할 수 있습니다:"
            echo "  ./launch.sh"
        else
            log_error "다운로드 실패"
            manual_download_guide
        fi
    else
        log_warning "네트워크 연결에 문제가 있습니다."
        echo ""
        echo "DNS 설정을 수정합니다..."
        fix_dns_settings
        
        echo ""
        echo "네트워크 연결을 다시 테스트합니다..."
        if test_network_connection; then
            log_success "네트워크 연결이 복구되었습니다."
            
            if download_cursor_alternative; then
                log_success "Cursor AI 다운로드 성공!"
                echo ""
                echo "이제 Cursor AI를 실행할 수 있습니다:"
                echo "  ./launch.sh"
            else
                log_error "다운로드 실패"
                manual_download_guide
            fi
        else
            log_error "네트워크 연결을 복구할 수 없습니다."
            manual_download_guide
        fi
    fi
}

# 스크립트 실행
main "$@" 