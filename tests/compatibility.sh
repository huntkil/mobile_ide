#!/bin/bash

# Galaxy Android용 Cursor AI IDE 호환성 테스트 스크립트
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

# 테스트 결과 저장
TEST_RESULTS=()

# 테스트 함수
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    log_info "테스트 실행: $test_name"
    
    if eval "$test_command" >/dev/null 2>&1; then
        log_success "$test_name: 통과"
        TEST_RESULTS+=("$test_name: PASS")
        return 0
    else
        log_error "$test_name: 실패"
        TEST_RESULTS+=("$test_name: FAIL")
        return 1
    fi
}

# 시스템 정보 수집
collect_system_info() {
    log_info "시스템 정보 수집 중..."
    
    echo "=== 시스템 정보 ===" > compatibility_report.txt
    echo "테스트 날짜: $(date)" >> compatibility_report.txt
    echo "" >> compatibility_report.txt
    
    echo "Android 버전: $(getprop ro.build.version.release)" >> compatibility_report.txt
    echo "Android API 레벨: $(getprop ro.build.version.sdk)" >> compatibility_report.txt
    echo "기기 모델: $(getprop ro.product.model)" >> compatibility_report.txt
    echo "제조사: $(getprop ro.product.manufacturer)" >> compatibility_report.txt
    echo "아키텍처: $(uname -m)" >> compatibility_report.txt
    echo "CPU 코어 수: $(nproc)" >> compatibility_report.txt
    echo "총 메모리: $(free -h | grep Mem | awk '{print $2}')" >> compatibility_report.txt
    echo "사용 가능한 메모리: $(free -h | grep Mem | awk '{print $7}')" >> compatibility_report.txt
    echo "총 저장공간: $(df -h /data | tail -1 | awk '{print $2}')" >> compatibility_report.txt
    echo "사용 가능한 저장공간: $(df -h /data | tail -1 | awk '{print $4}')" >> compatibility_report.txt
    echo "" >> compatibility_report.txt
}

# Android 버전 호환성 테스트
test_android_version() {
    log_info "Android 버전 호환성 테스트..."
    
    local android_version=$(getprop ro.build.version.release)
    local api_level=$(getprop ro.build.version.sdk)
    
    echo "Android 버전: $android_version (API $api_level)" >> compatibility_report.txt
    
    if [ "$api_level" -ge 24 ]; then
        log_success "Android 버전 호환: API $api_level (Android $android_version)"
        TEST_RESULTS+=("Android 버전: PASS")
    else
        log_error "Android 버전 비호환: API $api_level (Android $android_version) - 최소 API 24 필요"
        TEST_RESULTS+=("Android 버전: FAIL")
        return 1
    fi
}

# 아키텍처 호환성 테스트
test_architecture() {
    log_info "아키텍처 호환성 테스트..."
    
    local arch=$(uname -m)
    echo "아키텍처: $arch" >> compatibility_report.txt
    
    if [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
        log_success "아키텍처 호환: $arch"
        TEST_RESULTS+=("아키텍처: PASS")
    else
        log_error "아키텍처 비호환: $arch - ARM64 필요"
        TEST_RESULTS+=("아키텍처: FAIL")
        return 1
    fi
}

# 메모리 호환성 테스트
test_memory() {
    log_info "메모리 호환성 테스트..."
    
    local total_memory=$(free -m | grep Mem | awk '{print $2}')
    local available_memory=$(free -m | grep Mem | awk '{print $7}')
    
    echo "총 메모리: ${total_memory}MB" >> compatibility_report.txt
    echo "사용 가능한 메모리: ${available_memory}MB" >> compatibility_report.txt
    
    if [ "$total_memory" -ge 4096 ]; then
        log_success "메모리 호환: ${total_memory}MB (최소 4GB)"
        TEST_RESULTS+=("메모리: PASS")
    else
        log_warning "메모리 부족: ${total_memory}MB (최소 4GB 권장)"
        TEST_RESULTS+=("메모리: WARNING")
    fi
    
    if [ "$available_memory" -ge 2048 ]; then
        log_success "사용 가능한 메모리 충분: ${available_memory}MB"
        TEST_RESULTS+=("사용 가능한 메모리: PASS")
    else
        log_warning "사용 가능한 메모리 부족: ${available_memory}MB"
        TEST_RESULTS+=("사용 가능한 메모리: WARNING")
    fi
}

# 저장공간 호환성 테스트
test_storage() {
    log_info "저장공간 호환성 테스트..."
    
    local available_space=$(df -m /data | tail -1 | awk '{print $4}')
    
    echo "사용 가능한 저장공간: ${available_space}MB" >> compatibility_report.txt
    
    if [ "$available_space" -ge 10240 ]; then
        log_success "저장공간 호환: ${available_space}MB (최소 10GB)"
        TEST_RESULTS+=("저장공간: PASS")
    else
        log_error "저장공간 부족: ${available_space}MB (최소 10GB 필요)"
        TEST_RESULTS+=("저장공간: FAIL")
        return 1
    fi
}

# Termux 환경 테스트
test_termux_environment() {
    log_info "Termux 환경 테스트..."
    
    echo "=== Termux 환경 테스트 ===" >> compatibility_report.txt
    
    # Termux 설치 확인
    if command -v pkg >/dev/null 2>&1; then
        log_success "Termux 패키지 매니저 확인"
        TEST_RESULTS+=("Termux 패키지 매니저: PASS")
    else
        log_error "Termux 패키지 매니저 없음"
        TEST_RESULTS+=("Termux 패키지 매니저: FAIL")
        return 1
    fi
    
    # 필수 패키지 테스트
    local required_packages=("curl" "wget" "proot" "tar" "unzip")
    
    for package in "${required_packages[@]}"; do
        if command -v "$package" >/dev/null 2>&1; then
            log_success "$package 확인됨"
            TEST_RESULTS+=("$package: PASS")
        else
            log_warning "$package 없음"
            TEST_RESULTS+=("$package: WARNING")
        fi
    done
    
    # proot-distro 테스트
    if command -v proot-distro >/dev/null 2>&1; then
        log_success "proot-distro 확인됨"
        TEST_RESULTS+=("proot-distro: PASS")
    else
        log_warning "proot-distro 없음"
        TEST_RESULTS+=("proot-distro: WARNING")
    fi
}

# 네트워크 연결 테스트
test_network_connectivity() {
    log_info "네트워크 연결 테스트..."
    
    echo "=== 네트워크 연결 테스트 ===" >> compatibility_report.txt
    
    # 인터넷 연결 테스트
    if ping -c 1 google.com >/dev/null 2>&1; then
        log_success "인터넷 연결 확인"
        TEST_RESULTS+=("인터넷 연결: PASS")
    else
        log_error "인터넷 연결 실패"
        TEST_RESULTS+=("인터넷 연결: FAIL")
        return 1
    fi
    
    # DNS 해석 테스트
    if nslookup google.com >/dev/null 2>&1; then
        log_success "DNS 해석 확인"
        TEST_RESULTS+=("DNS 해석: PASS")
    else
        log_warning "DNS 해석 실패"
        TEST_RESULTS+=("DNS 해석: WARNING")
    fi
    
    # Cursor AI API 연결 테스트
    if curl -I https://api.cursor.sh >/dev/null 2>&1; then
        log_success "Cursor AI API 연결 확인"
        TEST_RESULTS+=("Cursor AI API: PASS")
    else
        log_warning "Cursor AI API 연결 실패"
        TEST_RESULTS+=("Cursor AI API: WARNING")
    fi
}

# Ubuntu 환경 테스트
test_ubuntu_environment() {
    log_info "Ubuntu 환경 테스트..."
    
    echo "=== Ubuntu 환경 테스트 ===" >> compatibility_report.txt
    
    if [ ! -d "$HOME/ubuntu" ]; then
        log_warning "Ubuntu 환경이 설치되지 않음"
        TEST_RESULTS+=("Ubuntu 환경: NOT_INSTALLED")
        return 0
    fi
    
    # Ubuntu 환경 진입 테스트
    if proot-distro login ubuntu -- echo "test" >/dev/null 2>&1; then
        log_success "Ubuntu 환경 진입 확인"
        TEST_RESULTS+=("Ubuntu 환경 진입: PASS")
    else
        log_error "Ubuntu 환경 진입 실패"
        TEST_RESULTS+=("Ubuntu 환경 진입: FAIL")
        return 1
    fi
    
    # Ubuntu 내부 패키지 테스트
    local ubuntu_packages=("apt" "curl" "wget" "git" "node" "npm")
    
    for package in "${ubuntu_packages[@]}"; do
        if proot-distro login ubuntu -- command -v "$package" >/dev/null 2>&1; then
            log_success "Ubuntu $package 확인됨"
            TEST_RESULTS+=("Ubuntu $package: PASS")
        else
            log_warning "Ubuntu $package 없음"
            TEST_RESULTS+=("Ubuntu $package: WARNING")
        fi
    done
}

# X11 환경 테스트
test_x11_environment() {
    log_info "X11 환경 테스트..."
    
    echo "=== X11 환경 테스트 ===" >> compatibility_report.txt
    
    # Xvfb 프로세스 확인
    if pgrep -x "Xvfb" >/dev/null; then
        log_success "Xvfb 프로세스 실행 중"
        TEST_RESULTS+=("Xvfb 프로세스: PASS")
    else
        log_warning "Xvfb 프로세스 없음"
        TEST_RESULTS+=("Xvfb 프로세스: WARNING")
    fi
    
    # DISPLAY 변수 확인
    if [ -n "$DISPLAY" ]; then
        log_success "DISPLAY 변수 설정됨: $DISPLAY"
        TEST_RESULTS+=("DISPLAY 변수: PASS")
    else
        log_warning "DISPLAY 변수 설정되지 않음"
        TEST_RESULTS+=("DISPLAY 변수: WARNING")
    fi
    
    # X11 권한 테스트
    if xhost >/dev/null 2>&1; then
        log_success "X11 권한 확인"
        TEST_RESULTS+=("X11 권한: PASS")
    else
        log_warning "X11 권한 확인 실패"
        TEST_RESULTS+=("X11 권한: WARNING")
    fi
}

# Cursor AI 설치 테스트
test_cursor_installation() {
    log_info "Cursor AI 설치 테스트..."
    
    echo "=== Cursor AI 설치 테스트 ===" >> compatibility_report.txt
    
    if [ ! -d "$HOME/ubuntu/home/cursor-ide" ]; then
        log_warning "Cursor AI 디렉토리 없음"
        TEST_RESULTS+=("Cursor AI 디렉토리: NOT_INSTALLED")
        return 0
    fi
    
    # AppImage 파일 확인
    if [ -f "$HOME/ubuntu/home/cursor-ide/cursor.AppImage" ]; then
        log_success "Cursor AI AppImage 확인됨"
        TEST_RESULTS+=("Cursor AI AppImage: PASS")
    else
        log_warning "Cursor AI AppImage 없음"
        TEST_RESULTS+=("Cursor AI AppImage: WARNING")
    fi
    
    # 추출된 버전 확인
    if [ -d "$HOME/ubuntu/home/cursor-ide/squashfs-root" ]; then
        log_success "Cursor AI 추출된 버전 확인됨"
        TEST_RESULTS+=("Cursor AI 추출된 버전: PASS")
    else
        log_warning "Cursor AI 추출된 버전 없음"
        TEST_RESULTS+=("Cursor AI 추출된 버전: WARNING")
    fi
    
    # 실행 권한 확인
    if [ -x "$HOME/ubuntu/home/cursor-ide/cursor.AppImage" ]; then
        log_success "Cursor AI 실행 권한 확인"
        TEST_RESULTS+=("Cursor AI 실행 권한: PASS")
    else
        log_warning "Cursor AI 실행 권한 없음"
        TEST_RESULTS+=("Cursor AI 실행 권한: WARNING")
    fi
}

# 성능 테스트
test_performance() {
    log_info "성능 테스트..."
    
    echo "=== 성능 테스트 ===" >> compatibility_report.txt
    
    # CPU 성능 테스트
    local cpu_cores=$(nproc)
    echo "CPU 코어 수: $cpu_cores" >> compatibility_report.txt
    
    if [ "$cpu_cores" -ge 4 ]; then
        log_success "CPU 코어 수 충분: $cpu_cores"
        TEST_RESULTS+=("CPU 코어 수: PASS")
    else
        log_warning "CPU 코어 수 부족: $cpu_cores (4개 이상 권장)"
        TEST_RESULTS+=("CPU 코어 수: WARNING")
    fi
    
    # 메모리 성능 테스트
    local total_memory=$(free -m | grep Mem | awk '{print $2}')
    echo "총 메모리: ${total_memory}MB" >> compatibility_report.txt
    
    if [ "$total_memory" -ge 8192 ]; then
        log_success "메모리 성능 우수: ${total_memory}MB"
        TEST_RESULTS+=("메모리 성능: EXCELLENT")
    elif [ "$total_memory" -ge 4096 ]; then
        log_success "메모리 성능 양호: ${total_memory}MB"
        TEST_RESULTS+=("메모리 성능: GOOD")
    else
        log_warning "메모리 성능 부족: ${total_memory}MB"
        TEST_RESULTS+=("메모리 성능: POOR")
    fi
    
    # 저장공간 성능 테스트
    local available_space=$(df -m /data | tail -1 | awk '{print $4}')
    echo "사용 가능한 저장공간: ${available_space}MB" >> compatibility_report.txt
    
    if [ "$available_space" -ge 20480 ]; then
        log_success "저장공간 성능 우수: ${available_space}MB"
        TEST_RESULTS+=("저장공간 성능: EXCELLENT")
    elif [ "$available_space" -ge 10240 ]; then
        log_success "저장공간 성능 양호: ${available_space}MB"
        TEST_RESULTS+=("저장공간 성능: GOOD")
    else
        log_warning "저장공간 성능 부족: ${available_space}MB"
        TEST_RESULTS+=("저장공간 성능: POOR")
    fi
}

# 결과 요약 생성
generate_summary() {
    log_info "테스트 결과 요약 생성 중..."
    
    echo "" >> compatibility_report.txt
    echo "=== 테스트 결과 요약 ===" >> compatibility_report.txt
    echo "" >> compatibility_report.txt
    
    local pass_count=0
    local fail_count=0
    local warning_count=0
    
    for result in "${TEST_RESULTS[@]}"; do
        echo "$result" >> compatibility_report.txt
        
        if [[ "$result" == *": PASS" || "$result" == *": EXCELLENT" || "$result" == *": GOOD" ]]; then
            ((pass_count++))
        elif [[ "$result" == *": FAIL" ]]; then
            ((fail_count++))
        elif [[ "$result" == *": WARNING" || "$result" == *": POOR" ]]; then
            ((warning_count++))
        fi
    done
    
    echo "" >> compatibility_report.txt
    echo "총 테스트: ${#TEST_RESULTS[@]}" >> compatibility_report.txt
    echo "통과: $pass_count" >> compatibility_report.txt
    echo "실패: $fail_count" >> compatibility_report.txt
    echo "경고: $warning_count" >> compatibility_report.txt
    
    # 호환성 등급 결정
    local compatibility_grade=""
    if [ "$fail_count" -eq 0 ] && [ "$warning_count" -eq 0 ]; then
        compatibility_grade="A+ (완벽 호환)"
    elif [ "$fail_count" -eq 0 ] && [ "$warning_count" -le 2 ]; then
        compatibility_grade="A (우수 호환)"
    elif [ "$fail_count" -eq 0 ] && [ "$warning_count" -le 5 ]; then
        compatibility_grade="B (양호 호환)"
    elif [ "$fail_count" -le 2 ]; then
        compatibility_grade="C (보통 호환)"
    else
        compatibility_grade="D (호환성 문제)"
    fi
    
    echo "호환성 등급: $compatibility_grade" >> compatibility_report.txt
    
    # 결과 출력
    echo ""
    echo "=========================================="
    echo "  호환성 테스트 결과"
    echo "=========================================="
    echo ""
    echo "총 테스트: ${#TEST_RESULTS[@]}"
    echo "통과: $pass_count"
    echo "실패: $fail_count"
    echo "경고: $warning_count"
    echo ""
    echo "호환성 등급: $compatibility_grade"
    echo ""
    echo "상세 결과는 compatibility_report.txt 파일을 확인하세요."
}

# 메인 테스트 함수
main() {
    echo "=========================================="
    echo "  Galaxy Android 호환성 테스트"
    echo "=========================================="
    echo ""
    
    # 시스템 정보 수집
    collect_system_info
    
    # 기본 호환성 테스트
    test_android_version
    test_architecture
    test_memory
    test_storage
    
    # 환경 테스트
    test_termux_environment
    test_network_connectivity
    
    # 설치된 환경 테스트
    test_ubuntu_environment
    test_x11_environment
    test_cursor_installation
    
    # 성능 테스트
    test_performance
    
    # 결과 요약 생성
    generate_summary
    
    echo ""
    log_success "호환성 테스트가 완료되었습니다!"
}

# 스크립트 실행
main "$@" 