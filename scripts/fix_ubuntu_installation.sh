#!/bin/bash

# Ubuntu 환경 설치 실패 자동 해결 스크립트
# Author: Mobile IDE Team
# Version: 1.0.0
# Description: Ubuntu 환경 설치 실패 시 자동으로 문제를 해결합니다

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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
    local command="$1"
    local description="${2:-명령어}"
    
    log_info "$description 실행 중..."
    if eval "$command" 2>/dev/null; then
        log_success "$description 완료"
        return 0
    else
        log_warning "$description 실패 (계속 진행)"
        return 1
    fi
}

# 저장공간 긴급 정리
emergency_storage_cleanup() {
    log_info "저장공간 긴급 정리 중..."
    
    # 사용 가능한 공간 확인
    local available_space=$(df /data | awk 'NR==2{printf "%.0f", $4/1024/1024}')
    log_info "현재 사용 가능한 공간: ${available_space}GB"
    
    if [ "$available_space" -lt 5 ]; then
        log_warning "저장공간이 부족합니다. 긴급 정리 시작..."
        
        # 패키지 캐시 정리
        safe_run "pkg clean" "패키지 캐시 정리"
        safe_run "pkg autoclean" "패키지 자동 정리"
        
        # 사용자 캐시 정리
        safe_run "rm -rf ~/.cache/*" "사용자 캐시 정리"
        safe_run "rm -rf ~/.npm" "npm 캐시 정리"
        safe_run "rm -rf ~/.node-gyp" "node-gyp 캐시 정리"
        
        # 임시 파일 정리
        safe_run "rm -rf /tmp/*" "시스템 임시 파일 정리"
        safe_run "rm -rf ~/tmp/*" "사용자 임시 파일 정리"
        
        # 로그 파일 정리
        safe_run "find ~ -name '*.log' -type f -size +5M -delete" "대용량 로그 파일 정리"
        
        # 다운로드된 파일 정리
        safe_run "find ~ -name '*.AppImage' -type f -delete" "AppImage 파일 정리"
        safe_run "find ~ -name '*.tar.gz' -type f -delete" "압축 파일 정리"
        
        # 정리 후 다시 확인
        available_space=$(df /data | awk 'NR==2{printf "%.0f", $4/1024/1024}')
        log_info "정리 후 사용 가능한 공간: ${available_space}GB"
        
        if [ "$available_space" -lt 3 ]; then
            log_error "저장공간이 여전히 부족합니다 (${available_space}GB)."
            log_info "Android 설정 → 디바이스 케어 → 저장공간에서 시스템 캐시를 정리하세요."
            return 1
        fi
    fi
    
    log_success "저장공간 정리 완료"
    return 0
}

# 기존 Ubuntu 환경 완전 제거
remove_existing_ubuntu() {
    log_info "기존 Ubuntu 환경 제거 중..."
    
    # proot-distro로 설치된 Ubuntu 제거
    if proot-distro list | grep -q "ubuntu"; then
        log_info "proot-distro Ubuntu 제거 중..."
        safe_run "proot-distro remove ubuntu" "proot-distro Ubuntu 제거"
    fi
    
    # 수동으로 남은 Ubuntu 디렉토리 제거
    if [ -d "$HOME/ubuntu" ]; then
        log_info "Ubuntu 디렉토리 제거 중..."
        safe_run "rm -rf $HOME/ubuntu" "Ubuntu 디렉토리 제거"
    fi
    
    # Ubuntu 관련 캐시 정리
    safe_run "rm -rf $HOME/.local/share/proot-distro/installed-rootfs/ubuntu" "Ubuntu 캐시 정리"
    safe_run "rm -rf $HOME/.cache/proot-distro" "proot-distro 캐시 정리"
    
    log_success "기존 Ubuntu 환경 제거 완료"
}

# 네트워크 문제 해결
fix_network_issues() {
    log_info "네트워크 문제 해결 중..."
    
    # DNS 서버 설정
    safe_run "echo 'nameserver 8.8.8.8' > /etc/resolv.conf" "Google DNS 설정"
    safe_run "echo 'nameserver 8.8.4.4' >> /etc/resolv.conf" "Google DNS 백업 설정"
    safe_run "echo 'nameserver 1.1.1.1' >> /etc/resolv.conf" "Cloudflare DNS 설정"
    safe_run "echo 'nameserver 208.67.222.222' >> /etc/resolv.conf" "OpenDNS 설정"
    
    # 네트워크 연결 테스트
    if nslookup google.com >/dev/null 2>&1; then
        log_success "DNS 확인 성공"
    else
        log_warning "DNS 확인 실패 (계속 진행)"
    fi
    
    if curl -s --connect-timeout 10 https://www.google.com >/dev/null; then
        log_success "HTTP 연결 확인 성공"
    else
        log_warning "HTTP 연결 확인 실패 (계속 진행)"
    fi
}

# proot-distro 재설치
reinstall_proot_distro() {
    log_info "proot-distro 재설치 중..."
    
    # 기존 proot-distro 제거
    safe_run "pkg remove -y proot-distro" "기존 proot-distro 제거"
    
    # 패키지 업데이트
    safe_run "pkg update -y" "패키지 업데이트"
    
    # proot-distro 재설치
    safe_run "pkg install -y proot-distro" "proot-distro 재설치"
    
    # proot-distro 초기화
    safe_run "proot-distro reset" "proot-distro 초기화"
    
    log_success "proot-distro 재설치 완료"
}

# Ubuntu 환경 재설치
reinstall_ubuntu() {
    log_info "Ubuntu 환경 재설치 중..."
    
    # Ubuntu 설치 시도 (여러 번 시도)
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log_info "Ubuntu 설치 시도 $attempt/$max_attempts"
        
        if proot-distro install ubuntu; then
            log_success "Ubuntu 환경 설치 성공!"
            return 0
        else
            log_warning "Ubuntu 설치 시도 $attempt 실패"
            
            if [ $attempt -lt $max_attempts ]; then
                log_info "5초 후 재시도..."
                sleep 5
                
                # 네트워크 재설정
                fix_network_issues
            fi
        fi
        
        attempt=$((attempt + 1))
    done
    
    log_error "Ubuntu 환경 설치 실패 (최대 시도 횟수 초과)"
    return 1
}

# 대체 설치 방법 (수동 다운로드)
manual_ubuntu_install() {
    log_info "대체 설치 방법 시도 중..."
    
    # Ubuntu 루트파일시스템 수동 다운로드
    local ubuntu_url="https://github.com/termux/proot-distro/releases/download/v3.18.0/ubuntu-22.04.3-arm64-pd-v3.18.0.tar.xz"
    local download_path="$HOME/ubuntu.tar.xz"
    
    log_info "Ubuntu 루트파일시스템 다운로드 중..."
    
    if curl -L -o "$download_path" "$ubuntu_url"; then
        log_success "Ubuntu 루트파일시스템 다운로드 완료"
        
        # 압축 해제
        log_info "압축 해제 중..."
        if tar -xf "$download_path" -C "$HOME"; then
            log_success "압축 해제 완료"
            
            # 임시 파일 정리
            rm -f "$download_path"
            
            # Ubuntu 환경 설정
            setup_manual_ubuntu
            return 0
        else
            log_error "압축 해제 실패"
            rm -f "$download_path"
            return 1
        fi
    else
        log_error "Ubuntu 루트파일시스템 다운로드 실패"
        return 1
    fi
}

# 수동 설치된 Ubuntu 환경 설정
setup_manual_ubuntu() {
    log_info "수동 설치된 Ubuntu 환경 설정 중..."
    
    # Ubuntu 디렉토리 생성
    mkdir -p "$HOME/ubuntu"
    
    # 기본 환경 설정
    cat > "$HOME/ubuntu/etc/resolv.conf" << 'EOF'
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
EOF
    
    # 기본 사용자 설정
    echo "root:x:0:0:root:/root:/bin/bash" > "$HOME/ubuntu/etc/passwd"
    echo "root::0:0:99999:7:::" > "$HOME/ubuntu/etc/shadow"
    
    log_success "수동 Ubuntu 환경 설정 완료"
}

# 메인 해결 함수
main() {
    echo "=========================================="
    echo "  Ubuntu 환경 설치 실패 자동 해결"
    echo "=========================================="
    echo "버전: 1.0.0"
    echo "작성자: Mobile IDE Team"
    echo "날짜: $(date)"
    echo "=========================================="
    echo ""
    
    log_info "Ubuntu 환경 설치 실패 문제 해결 시작..."
    
    # 1. 저장공간 긴급 정리
    if ! emergency_storage_cleanup; then
        log_error "저장공간 부족으로 해결을 중단합니다."
        exit 1
    fi
    
    # 2. 기존 Ubuntu 환경 완전 제거
    remove_existing_ubuntu
    
    # 3. 네트워크 문제 해결
    fix_network_issues
    
    # 4. proot-distro 재설치
    reinstall_proot_distro
    
    # 5. Ubuntu 환경 재설치 시도
    if reinstall_ubuntu; then
        log_success "Ubuntu 환경 설치 성공!"
    else
        log_warning "표준 설치 방법 실패. 대체 방법 시도..."
        
        # 6. 대체 설치 방법 시도
        if manual_ubuntu_install; then
            log_success "대체 방법으로 Ubuntu 환경 설치 성공!"
        else
            log_error "모든 설치 방법 실패"
            echo ""
            echo "=========================================="
            echo "  해결 방법"
            echo "=========================================="
            echo "1. Android 설정 → 디바이스 케어 → 저장공간"
            echo "   - 시스템 캐시 정리"
            echo "   - 앱 데이터 정리"
            echo ""
            echo "2. Termux 재설치"
            echo "   - Google Play Store에서 Termux 재설치"
            echo ""
            echo "3. 수동 설치"
            echo "   - https://f-droid.org/en/packages/com.termux/"
            echo ""
            exit 1
        fi
    fi
    
    echo ""
    echo "=========================================="
    echo "  해결 완료!"
    echo "=========================================="
    echo ""
    echo "✅ Ubuntu 환경이 성공적으로 설치되었습니다!"
    echo ""
    echo "다음 단계:"
    echo "1. ./scripts/perfect_cursor_setup.sh 실행"
    echo "2. 또는 ./launch_cursor.sh 실행"
    echo ""
    
    log_success "Ubuntu 환경 설치 실패 문제 해결 완료!"
}

# 스크립트 실행
main "$@" 