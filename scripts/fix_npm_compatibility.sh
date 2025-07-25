#!/bin/bash

# npm 호환성 문제 해결 스크립트
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

# Ubuntu 환경에서 npm 호환성 문제 해결
fix_npm_compatibility() {
    log_info "npm 호환성 문제 해결 시작..."
    
    # Ubuntu 환경에서 실행할 스크립트 생성
    cat > "$HOME/fix_npm_ubuntu.sh" << 'EOF'
#!/bin/bash
set -e

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}[INFO]${NC} Ubuntu 환경에서 npm 호환성 문제 해결 중..."

# 현재 Node.js 및 npm 버전 확인
echo -e "${BLUE}[INFO]${NC} 현재 버전 확인:"
node --version
npm --version

# npm 캐시 완전 정리
echo -e "${BLUE}[INFO]${NC} npm 캐시 정리 중..."
npm cache clean --force
rm -rf ~/.npm 2>/dev/null || true

# Node.js 18과 호환되는 npm 버전으로 다운그레이드
echo -e "${BLUE}[INFO]${NC} npm 버전 다운그레이드 중..."
npm install -g npm@10.8.2

# npm 캐시 다시 정리
npm cache clean --force

# 호환되는 전역 패키지 설치
echo -e "${BLUE}[INFO]${NC} 호환되는 전역 패키지 설치 중..."
npm install -g yarn@1.22.19 typescript@5.3.3 ts-node@10.9.2

# 최종 버전 확인
echo -e "${GREEN}[SUCCESS]${NC} 최종 버전 확인:"
node --version
npm --version
yarn --version

echo -e "${GREEN}[SUCCESS]${NC} npm 호환성 문제 해결 완료!"
EOF

    # Ubuntu 환경에서 스크립트 실행
    proot-distro login ubuntu -- bash "$HOME/fix_npm_ubuntu.sh"
    
    # 임시 스크립트 삭제
    rm "$HOME/fix_npm_ubuntu.sh"
}

# Node.js 버전 업그레이드 (선택사항)
upgrade_nodejs() {
    log_info "Node.js 버전 업그레이드 옵션 제공..."
    echo ""
    echo "Node.js 18에서 20으로 업그레이드하시겠습니까?"
    echo "1. Node.js 20 LTS로 업그레이드 (권장)"
    echo "2. 현재 Node.js 18 유지"
    echo ""
    
    read -p "선택 (1-2): " choice
    
    case $choice in
        1)
            log_info "Node.js 20 LTS로 업그레이드 중..."
            
            # Ubuntu 환경에서 Node.js 업그레이드 스크립트 생성
            cat > "$HOME/upgrade_nodejs_ubuntu.sh" << 'EOF'
#!/bin/bash
set -e

echo "Node.js 20 LTS로 업그레이드 중..."

# 기존 Node.js 제거
apt remove -y nodejs npm 2>/dev/null || true
apt autoremove -y

# Node.js 20 LTS 설치
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# npm 최신 버전 설치
npm install -g npm@latest

# 전역 패키지 재설치
npm install -g yarn typescript ts-node

echo "Node.js 20 LTS 업그레이드 완료!"
node --version
npm --version
EOF

            proot-distro login ubuntu -- bash "$HOME/upgrade_nodejs_ubuntu.sh"
            rm "$HOME/upgrade_nodejs_ubuntu.sh"
            ;;
        2)
            log_info "현재 Node.js 18 유지"
            ;;
        *)
            log_error "잘못된 선택입니다."
            exit 1
            ;;
    esac
}

# 메인 함수
main() {
    echo "=========================================="
    echo "  npm 호환성 문제 해결 스크립트"
    echo "=========================================="
    echo ""
    
    # npm 호환성 문제 해결
    fix_npm_compatibility
    
    # Node.js 업그레이드 옵션 제공
    upgrade_nodejs
    
    log_success "모든 npm 호환성 문제가 해결되었습니다!"
    echo ""
    echo "이제 Cursor AI IDE를 실행할 수 있습니다:"
    echo "  ./launch.sh"
}

# 스크립트 실행
main "$@" 