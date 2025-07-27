#!/bin/bash

# 저장공간 정리 스크립트
# Author: Mobile IDE Team
# Version: 1.0.0
# Description: Termux 환경에서 저장공간을 정리합니다

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

# 정리 전 저장공간 확인
show_storage_before() {
    log_info "정리 전 저장공간 확인..."
    echo "=========================================="
    echo "  정리 전 저장공간"
    echo "=========================================="
    df -h /data
    echo "=========================================="
    echo ""
}

# 정리 후 저장공간 확인
show_storage_after() {
    log_info "정리 후 저장공간 확인..."
    echo "=========================================="
    echo "  정리 후 저장공간"
    echo "=========================================="
    df -h /data
    echo "=========================================="
    echo ""
}

# 패키지 캐시 정리
cleanup_package_cache() {
    log_info "패키지 캐시 정리 중..."
    
    # pkg 캐시 정리
    pkg clean 2>/dev/null || log_warning "pkg 캐시 정리 실패"
    
    # apt 캐시 정리 (Ubuntu 환경이 있는 경우)
    if [ -d "$HOME/ubuntu" ]; then
        proot-distro login ubuntu -- apt clean 2>/dev/null || log_warning "apt 캐시 정리 실패"
        proot-distro login ubuntu -- apt autoclean 2>/dev/null || log_warning "apt autoclean 실패"
    fi
    
    log_success "패키지 캐시 정리 완료"
}

# 사용자 캐시 정리
cleanup_user_cache() {
    log_info "사용자 캐시 정리 중..."
    
    # Termux 캐시
    rm -rf ~/.cache/* 2>/dev/null || log_warning "Termux 캐시 정리 실패"
    
    # Ubuntu 캐시 (Ubuntu 환경이 있는 경우)
    if [ -d "$HOME/ubuntu" ]; then
        rm -rf ~/ubuntu/home/.cache/* 2>/dev/null || log_warning "Ubuntu 캐시 정리 실패"
    fi
    
    # npm 캐시 (Ubuntu 환경이 있는 경우)
    if [ -d "$HOME/ubuntu" ]; then
        proot-distro login ubuntu -- npm cache clean --force 2>/dev/null || log_warning "npm 캐시 정리 실패"
    fi
    
    log_success "사용자 캐시 정리 완료"
}

# 임시 파일 정리
cleanup_temp_files() {
    log_info "임시 파일 정리 중..."
    
    # 시스템 임시 파일
    rm -rf /tmp/* 2>/dev/null || log_warning "시스템 임시 파일 정리 실패"
    
    # 사용자 임시 파일
    rm -rf ~/tmp/* 2>/dev/null || log_warning "사용자 임시 파일 정리 실패"
    
    # 다운로드된 임시 파일
    find ~ -name "*.tmp" -type f -delete 2>/dev/null || log_warning "임시 파일 정리 실패"
    find ~ -name "*.temp" -type f -delete 2>/dev/null || log_warning "임시 파일 정리 실패"
    
    log_success "임시 파일 정리 완료"
}

# 로그 파일 정리
cleanup_log_files() {
    log_info "로그 파일 정리 중..."
    
    # 대용량 로그 파일 삭제 (10MB 이상)
    find ~ -name "*.log" -type f -size +10M -delete 2>/dev/null || log_warning "대용량 로그 파일 정리 실패"
    
    # 오래된 로그 파일 삭제 (7일 이상)
    find ~ -name "*.log" -type f -mtime +7 -delete 2>/dev/null || log_warning "오래된 로그 파일 정리 실패"
    
    log_success "로그 파일 정리 완료"
}

# 불필요한 파일 정리
cleanup_unnecessary_files() {
    log_info "불필요한 파일 정리 중..."
    
    # 다운로드된 AppImage 파일 (이미 추출된 경우)
    if [ -d "$HOME/ubuntu/home/cursor-ide/squashfs-root" ]; then
        rm -f ~/ubuntu/home/cursor-ide/cursor.AppImage 2>/dev/null || log_warning "AppImage 파일 정리 실패"
    fi
    
    # 중복된 설치 스크립트
    find ~/mobile_ide/scripts -name "*_v*.sh" -type f -delete 2>/dev/null || log_warning "중복 스크립트 정리 실패"
    
    log_success "불필요한 파일 정리 완료"
}

# 메인 정리 함수
main() {
    echo "=========================================="
    echo "  저장공간 정리"
    echo "=========================================="
    echo "버전: 1.0.0"
    echo "작성자: Mobile IDE Team"
    echo "날짜: $(date)"
    echo "=========================================="
    echo ""
    
    # 정리 전 저장공간 확인
    show_storage_before
    
    # 각종 정리 작업 수행
    cleanup_package_cache
    cleanup_user_cache
    cleanup_temp_files
    cleanup_log_files
    cleanup_unnecessary_files
    
    # 정리 후 저장공간 확인
    show_storage_after
    
    # 정리 결과 요약
    echo ""
    echo "=========================================="
    echo "  정리 완료!"
    echo "=========================================="
    echo ""
    echo "✅ 정리된 항목:"
    echo "  - 패키지 캐시"
    echo "  - 사용자 캐시"
    echo "  - 임시 파일"
    echo "  - 로그 파일"
    echo "  - 불필요한 파일"
    echo ""
    echo "💡 추가 정리 팁:"
    echo "  - Android 설정 → 디바이스 케어 → 저장공간"
    echo "  - 시스템 캐시 정리"
    echo "  - 앱 데이터 정리"
    echo ""
    
    log_success "저장공간 정리가 완료되었습니다!"
}

# 스크립트 실행
main "$@" 