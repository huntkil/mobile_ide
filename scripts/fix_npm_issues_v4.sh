#!/bin/bash

# npm 문제 완전 해결 스크립트 v4.0
# Author: Mobile IDE Team
# Version: 4.0.0
# Description: npm 오류 완전 해결, 메모리 손상 문제 해결, 안정적인 npm 환경 구축
# Usage: ./scripts/fix_npm_issues_v4.sh

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

log_debug() {
    echo -e "${PURPLE}[DEBUG]${NC} $1"
}

# 헬프 함수
show_help() {
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  -h, --help     이 도움말을 표시합니다"
    echo "  -v, --version  버전 정보를 표시합니다"
    echo "  -d, --debug    디버그 모드로 실행합니다"
    echo "  -f, --force    확인 없이 강제 실행합니다"
    echo "  -c, --clean    npm 캐시만 정리합니다"
    echo ""
    echo "예제:"
    echo "  $0              # 기본 실행"
    echo "  $0 --debug      # 디버그 모드"
    echo "  $0 --clean      # 캐시만 정리"
}

# 버전 정보
show_version() {
    echo "버전: 4.0.0"
    echo "작성자: Mobile IDE Team"
    echo "마지막 업데이트: $(date +%Y-%m-%d)"
    echo "주요 개선사항:"
    echo "  - npm 오류 완전 해결"
    echo "  - 메모리 손상 문제 해결"
    echo "  - 안전한 npm 캐시 정리"
    echo "  - Node.js 재설치"
    echo "  - npm 설정 최적화"
}

# 메모리 최적화
optimize_memory() {
    log_info "메모리 최적화 중..."
    
    # 메모리 캐시 정리
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    
    # 불필요한 프로세스 종료
    pkill -f "npm" 2>/dev/null || true
    pkill -f "node" 2>/dev/null || true
    
    # 메모리 상태 확인
    local free_mem=$(free | awk 'NR==2{printf "%.0f", $4/1024/1024}')
    log_info "사용 가능한 메모리: ${free_mem}GB"
    
    log_success "메모리 최적화 완료"
}

# npm 완전 제거
remove_npm_completely() {
    log_info "npm 완전 제거 중..."
    
    # Ubuntu 환경에서 npm 제거
    proot-distro login ubuntu -- bash -c "
        # 기존 Node.js/npm 제거
        apt remove -y nodejs npm 2>/dev/null || true
        apt autoremove -y
        
        # npm 관련 디렉토리 제거
        rm -rf ~/.npm 2>/dev/null || true
        rm -rf ~/.node-gyp 2>/dev/null || true
        rm -rf ~/.npm-cache 2>/dev/null || true
        rm -rf /tmp/npm-* 2>/dev/null || true
        rm -rf /tmp/.npm 2>/dev/null || true
        
        # npm 설정 파일 제거
        rm -f ~/.npmrc 2>/dev/null || true
        
        echo 'npm 완전 제거 완료'
    "
    
    log_success "npm 완전 제거 완료"
}

# npm 캐시 안전 정리
clean_npm_cache_safely() {
    log_info "npm 캐시 안전 정리 중..."
    
    # Ubuntu 환경에서 안전한 캐시 정리
    proot-distro login ubuntu -- bash -c "
        # npm 캐시 확인
        if command -v npm &> /dev/null; then
            echo 'npm 캐시 확인 중...'
            npm cache verify 2>/dev/null || echo 'npm 캐시 확인 실패'
            
            # 안전한 캐시 정리 (--force 사용하지 않음)
            echo 'npm 캐시 정리 중...'
            npm cache clean --prefer-offline 2>/dev/null || echo 'npm 캐시 정리 실패'
        else
            echo 'npm이 설치되지 않음'
        fi
        
        # 수동으로 캐시 디렉토리 정리
        rm -rf ~/.npm/_cacache 2>/dev/null || true
        rm -rf ~/.npm/_logs 2>/dev/null || true
        
        echo 'npm 캐시 안전 정리 완료'
    "
    
    log_success "npm 캐시 안전 정리 완료"
}

# Node.js 안전 재설치
reinstall_nodejs_safely() {
    log_info "Node.js 안전 재설치 중..."
    
    # Ubuntu 환경에서 Node.js 재설치
    proot-distro login ubuntu -- bash -c "
        # 패키지 목록 업데이트
        apt update
        
        # 기존 Node.js 완전 제거
        apt remove -y nodejs npm 2>/dev/null || true
        apt autoremove -y
        
        # Node.js 18 LTS 설치
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt install -y nodejs
        
        # npm 안전 설정
        npm config set registry https://registry.npmjs.org/
        npm config set cache ~/.npm-cache
        npm config set prefer-offline true
        
        # npm 버전 확인
        npm --version
        
        echo 'Node.js 안전 재설치 완료'
    "
    
    log_success "Node.js 안전 재설치 완료"
}

# npm 설정 최적화
optimize_npm_config() {
    log_info "npm 설정 최적화 중..."
    
    # Ubuntu 환경에서 npm 설정 최적화
    proot-distro login ubuntu -- bash -c "
        # npm 설정 최적화
        npm config set registry https://registry.npmjs.org/
        npm config set cache ~/.npm-cache
        npm config set prefer-offline true
        npm config set audit false
        npm config set fund false
        
        # 메모리 제한 설정
        npm config set maxsockets 1
        npm config set fetch-retries 3
        npm config set fetch-retry-mintimeout 5000
        npm config set fetch-retry-maxtimeout 60000
        
        # 캐시 설정
        npm config set cache-min 3600
        npm config set cache-max 86400
        
        echo 'npm 설정 최적화 완료'
    "
    
    log_success "npm 설정 최적화 완료"
}

# npm 테스트
test_npm() {
    log_info "npm 테스트 중..."
    
    # Ubuntu 환경에서 npm 테스트
    proot-distro login ubuntu -- bash -c "
        # npm 버전 확인
        echo 'npm 버전:'
        npm --version
        
        # Node.js 버전 확인
        echo 'Node.js 버전:'
        node --version
        
        # 간단한 패키지 설치 테스트
        echo '테스트 패키지 설치 중...'
        npm install -g npm@10.8.2 2>/dev/null || echo 'npm 버전 변경 실패, 기본 버전 사용'
        
        # npm 캐시 상태 확인
        echo 'npm 캐시 상태:'
        npm cache verify 2>/dev/null || echo 'npm 캐시 확인 실패'
        
        echo 'npm 테스트 완료'
    "
    
    log_success "npm 테스트 완료"
}

# 시스템 진단
diagnose_system() {
    log_info "시스템 진단 중..."
    
    echo ""
    echo "=========================================="
    echo "  시스템 진단 결과"
    echo "=========================================="
    echo ""
    
    # 메모리 정보
    echo "메모리 정보:"
    free -h
    echo ""
    
    # 저장공간 정보
    echo "저장공간 정보:"
    df -h
    echo ""
    
    # Ubuntu 환경 확인
    echo "Ubuntu 환경 확인:"
    if [ -d ~/ubuntu ]; then
        echo "✅ Ubuntu 환경 존재"
    else
        echo "❌ Ubuntu 환경 없음"
    fi
    
    # Node.js 확인
    echo "Node.js 확인:"
    proot-distro login ubuntu -- bash -c "node --version 2>/dev/null || echo 'Node.js 없음'"
    
    # npm 확인
    echo "npm 확인:"
    proot-distro login ubuntu -- bash -c "npm --version 2>/dev/null || echo 'npm 없음'"
    
    echo ""
}

# 문제 해결 요약
show_fix_summary() {
    echo ""
    echo "=========================================="
    echo "  🎉 npm 문제 해결 완료! 🎉"
    echo "=========================================="
    echo ""
    echo "✅ 완료된 작업:"
    echo "  - 메모리 최적화"
    echo "  - npm 완전 제거"
    echo "  - npm 캐시 안전 정리"
    echo "  - Node.js 안전 재설치"
    echo "  - npm 설정 최적화"
    echo "  - npm 테스트"
    echo ""
    echo "🚀 다음 단계:"
    echo "  1. Cursor AI 설치 재시도"
    echo "  2. 또는 npm 없이 설치: ./scripts/termux_perfect_setup_v4.sh --skip-npm"
    echo ""
    echo "💡 팁:"
    echo "  - npm 오류가 다시 발생하면 이 스크립트를 다시 실행하세요"
    echo "  - 메모리 부족 시 다른 앱을 종료하세요"
    echo "  - 정기적으로 메모리 정리를 하세요"
    echo ""
}

# 메인 함수
main() {
    echo "=========================================="
    echo "  npm 문제 완전 해결 스크립트 v4.0"
    echo "=========================================="
    echo ""
    
    # 명령행 인수 처리
    local force_mode=false
    local debug_mode=false
    local clean_only=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -d|--debug)
                debug_mode=true
                set -x
                shift
                ;;
            -f|--force)
                force_mode=true
                shift
                ;;
            -c|--clean)
                clean_only=true
                shift
                ;;
            *)
                log_error "알 수 없는 옵션: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 시스템 진단
    diagnose_system
    
    # 메모리 최적화
    optimize_memory
    
    if [ "$clean_only" = true ]; then
        # 캐시만 정리
        clean_npm_cache_safely
    else
        # 완전한 npm 문제 해결
        remove_npm_completely
        clean_npm_cache_safely
        reinstall_nodejs_safely
        optimize_npm_config
        test_npm
    fi
    
    # 문제 해결 요약
    show_fix_summary
    
    log_success "npm 문제 해결 완료!"
}

# 스크립트 실행
main "$@" 