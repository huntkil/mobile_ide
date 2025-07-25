# 스크립트 개발 템플릿 및 베스트 프랙티스

## 📋 목차
1. [기본 스크립트 템플릿](#기본-스크립트-템플릿)
2. [함수 템플릿](#함수-템플릿)
3. [에러 처리 패턴](#에러-처리-패턴)
4. [로깅 시스템](#로깅-시스템)
5. [검증 함수](#검증-함수)
6. [설치 스크립트 템플릿](#설치-스크립트-템플릿)
7. [트러블슈팅 스크립트 템플릿](#트러블슈팅-스크립트-템플릿)

## 🏗️ 기본 스크립트 템플릿

### 표준 스크립트 구조
```bash
#!/bin/bash

# 스크립트 정보
# Author: Mobile IDE Team
# Version: 1.0.0
# Description: 스크립트 설명
# Usage: ./script_name.sh [options]

set -e  # 에러 발생 시 스크립트 중단

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
    echo ""
    echo "예제:"
    echo "  $0              # 기본 실행"
    echo "  $0 --debug      # 디버그 모드"
}

# 버전 정보
show_version() {
    echo "버전: 1.0.0"
    echo "작성자: Mobile IDE Team"
    echo "마지막 업데이트: $(date +%Y-%m-%d)"
}

# 메인 함수
main() {
    echo "=========================================="
    echo "  스크립트 제목"
    echo "=========================================="
    echo ""
    
    # 주요 로직
    log_info "작업 시작..."
    
    # 에러 처리
    if [ $? -ne 0 ]; then
        log_error "작업 실패"
        exit 1
    fi
    
    log_success "작업 완료!"
}

# 스크립트 실행
main "$@"
```

## 🔧 함수 템플릿

### 검증 함수
```bash
# 사용자 권한 확인
check_user_permissions() {
    log_info "사용자 권한 확인 중..."
    
    # root 사용자 확인
    if [ "$(id -u)" -eq 0 ]; then
        log_error "root 사용자로 실행할 수 없습니다."
        echo ""
        echo "해결 방법:"
        echo "1. 일반 사용자로 다시 로그인하세요"
        echo "2. 또는 다음 명령어로 일반 사용자로 전환하세요:"
        echo "   su - [사용자명]"
        echo ""
        echo "현재 사용자: $(whoami)"
        echo "현재 UID: $(id -u)"
        return 1
    fi
    
    # proot-distro 확인
    if ! command -v proot-distro &> /dev/null; then
        log_error "proot-distro가 설치되지 않았습니다."
        log_info "다음 명령어로 설치하세요:"
        echo "pkg install proot-distro"
        return 1
    fi
    
    log_success "사용자 권한 확인 완료"
    return 0
}

# 시스템 요구사항 확인
check_system_requirements() {
    log_info "시스템 요구사항 확인 중..."
    
    # Android 버전 확인
    local android_version=$(getprop ro.build.version.release)
    local android_sdk=$(getprop ro.build.version.sdk)
    
    if [ "$android_sdk" -lt 29 ]; then
        log_error "Android 10+ (API 29+)가 필요합니다."
        log_info "현재 버전: Android $android_version (API $android_sdk)"
        return 1
    fi
    
    # 메모리 확인
    local total_mem=$(free | awk 'NR==2{printf "%.0f", $2/1024/1024}')
    if [ "$total_mem" -lt 4 ]; then
        log_warning "최소 4GB 메모리가 권장됩니다."
        log_info "현재 메모리: ${total_mem}GB"
    fi
    
    # 저장공간 확인
    local available_space=$(df /data | awk 'NR==2{printf "%.0f", $4/1024/1024}')
    if [ "$available_space" -lt 10 ]; then
        log_error "최소 10GB 저장공간이 필요합니다."
        log_info "현재 사용 가능한 공간: ${available_space}GB"
        return 1
    fi
    
    log_success "시스템 요구사항 확인 완료"
    return 0
}

# 네트워크 연결 확인
check_network_connection() {
    log_info "네트워크 연결 확인 중..."
    
    # DNS 확인
    if ! nslookup google.com >/dev/null 2>&1; then
        log_warning "DNS 확인 실패"
        return 1
    fi
    
    # HTTP 연결 확인
    if ! curl -s --connect-timeout 10 https://www.google.com >/dev/null; then
        log_warning "HTTP 연결 실패"
        return 1
    fi
    
    log_success "네트워크 연결 확인 완료"
    return 0
}

# 파일 존재 확인
check_file_exists() {
    local file_path="$1"
    local description="${2:-파일}"
    
    if [ ! -f "$file_path" ]; then
        log_error "$description을 찾을 수 없습니다: $file_path"
        return 1
    fi
    
    log_success "$description 확인됨: $file_path"
    return 0
}

# 디렉토리 존재 확인
check_directory_exists() {
    local dir_path="$1"
    local description="${2:-디렉토리}"
    
    if [ ! -d "$dir_path" ]; then
        log_error "$description을 찾을 수 없습니다: $dir_path"
        return 1
    fi
    
    log_success "$description 확인됨: $dir_path"
    return 0
}
```

### 설치 함수
```bash
# Ubuntu 환경 설치
install_ubuntu() {
    log_info "Ubuntu 22.04 LTS 설치 중..."
    
    # 기존 환경 확인
    if [ -d "$HOME/ubuntu" ]; then
        log_warning "기존 Ubuntu 환경이 발견되었습니다."
        read -p "기존 환경을 제거하고 새로 설치하시겠습니까? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "기존 Ubuntu 환경 제거 중..."
            proot-distro remove ubuntu 2>/dev/null || true
            rm -rf "$HOME/ubuntu" 2>/dev/null || true
        else
            log_info "기존 환경을 사용합니다."
            return 0
        fi
    fi
    
    # Ubuntu 설치
    if proot-distro install ubuntu; then
        log_success "Ubuntu 환경 설치 완료"
        return 0
    else
        log_error "Ubuntu 환경 설치 실패"
        return 1
    fi
}

# 패키지 설치
install_packages() {
    local packages=("$@")
    log_info "패키지 설치 중: ${packages[*]}"
    
    for package in "${packages[@]}"; do
        log_info "설치 중: $package"
        if apt install -y "$package"; then
            log_success "설치 완료: $package"
        else
            log_warning "설치 실패: $package"
            # 대체 패키지 시도
            case "$package" in
                "libasound2")
                    apt install -y libasound2t64 2>/dev/null || log_error "대체 패키지도 설치 실패: libasound2t64"
                    ;;
                "libgtk-3-0")
                    apt install -y libgtk-3-0t64 2>/dev/null || log_error "대체 패키지도 설치 실패: libgtk-3-0t64"
                    ;;
                *)
                    log_error "대체 패키지가 없습니다: $package"
                    ;;
            esac
        fi
    done
}

# Node.js 설치
install_nodejs() {
    log_info "Node.js 설치 중..."
    
    # 기존 Node.js 제거
    apt remove -y nodejs npm 2>/dev/null || true
    apt autoremove -y
    
    # Node.js 18 LTS 설치
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs
    
    # npm 호환성 문제 해결
    log_info "npm 호환성 문제 해결 중..."
    npm install -g npm@10.8.2 || {
        log_warning "npm 버전 변경 실패, 기본 버전 사용..."
    }
    
    # npm 캐시 정리
    npm cache clean --force
    
    # 전역 패키지 설치
    log_info "전역 패키지 설치 중..."
    npm install -g yarn@1.22.19 typescript@5.3.3 ts-node@10.9.2 || {
        log_warning "일부 전역 패키지 설치 실패, 계속 진행..."
    }
    
    log_success "Node.js 설치 완료"
}
```

## 🚨 에러 처리 패턴

### 기본 에러 처리
```bash
# 에러 발생 시 스크립트 중단
set -e

# 에러 발생 시 함수 호출
trap 'error_handler $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]:-})' ERR

# 에러 핸들러
error_handler() {
    local exit_code=$1
    local line_no=$2
    local bash_lineno=$3
    local last_command="$4"
    local func_stack="$5"
    
    log_error "오류가 발생했습니다!"
    log_error "종료 코드: $exit_code"
    log_error "라인 번호: $line_no"
    log_error "마지막 명령: $last_command"
    log_error "함수 스택: $func_stack"
    
    # 정리 작업
    cleanup_temp_files
    
    exit "$exit_code"
}

# 임시 파일 정리
cleanup_temp_files() {
    log_info "임시 파일 정리 중..."
    local temp_files=(
        "$HOME/setup_ubuntu_temp.sh"
        "$HOME/install_temp.sh"
        "$HOME/fix_temp.sh"
    )
    
    for file in "${temp_files[@]}"; do
        if [ -f "$file" ]; then
            rm -f "$file"
            log_info "삭제됨: $file"
        fi
    done
}
```

### 조건부 에러 처리
```bash
# 명령어 실행 및 에러 처리
run_command() {
    local command="$1"
    local description="${2:-명령어}"
    
    log_info "$description 실행 중..."
    if eval "$command"; then
        log_success "$description 완료"
        return 0
    else
        log_error "$description 실패"
        return 1
    fi
}

# 재시도 로직
retry_command() {
    local command="$1"
    local max_attempts="${2:-3}"
    local delay="${3:-5}"
    local description="${4:-명령어}"
    
    log_info "$description 실행 중 (최대 $max_attempts회 시도)..."
    
    for ((i=1; i<=max_attempts; i++)); do
        log_info "시도 $i/$max_attempts"
        
        if eval "$command"; then
            log_success "$description 완료 (시도 $i)"
            return 0
        else
            log_warning "$description 실패 (시도 $i)"
            
            if [ $i -lt $max_attempts ]; then
                log_info "$delay초 후 재시도..."
                sleep "$delay"
            fi
        fi
    done
    
    log_error "$description 최종 실패 ($max_attempts회 시도)"
    return 1
}
```

## 📝 로깅 시스템

### 고급 로깅
```bash
# 로그 레벨 설정
LOG_LEVEL=${LOG_LEVEL:-INFO}  # DEBUG, INFO, WARNING, ERROR

# 로그 파일 설정
LOG_FILE="${LOG_FILE:-/tmp/mobile_ide.log}"

# 로그 함수
log_debug() {
    if [[ "$LOG_LEVEL" == "DEBUG" ]]; then
        echo -e "${PURPLE}[DEBUG]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
    fi
}

log_info() {
    if [[ "$LOG_LEVEL" == "DEBUG" || "$LOG_LEVEL" == "INFO" ]]; then
        echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
    fi
}

log_warning() {
    if [[ "$LOG_LEVEL" == "DEBUG" || "$LOG_LEVEL" == "INFO" || "$LOG_LEVEL" == "WARNING" ]]; then
        echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
    fi
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# 진행 상황 표시
show_progress() {
    local current=$1
    local total=$2
    local description="${3:-진행 중}"
    
    local percentage=$((current * 100 / total))
    local filled=$((percentage / 2))
    local empty=$((50 - filled))
    
    printf "\r${BLUE}[INFO]${NC} %s: [%s%s] %d%% (%d/%d)" \
        "$description" \
        "$(printf '#%.0s' $(seq 1 $filled))" \
        "$(printf ' %.0s' $(seq 1 $empty))" \
        "$percentage" \
        "$current" \
        "$total"
    
    if [ "$current" -eq "$total" ]; then
        echo
    fi
}
```

## 🔍 검증 함수

### 시스템 검증
```bash
# 전체 시스템 검증
validate_system() {
    log_info "시스템 검증 시작..."
    
    local errors=0
    
    # 사용자 권한 확인
    if ! check_user_permissions; then
        ((errors++))
    fi
    
    # 시스템 요구사항 확인
    if ! check_system_requirements; then
        ((errors++))
    fi
    
    # 네트워크 연결 확인
    if ! check_network_connection; then
        ((errors++))
    fi
    
    # Termux 환경 확인
    if ! check_termux_environment; then
        ((errors++))
    fi
    
    if [ $errors -eq 0 ]; then
        log_success "시스템 검증 완료 - 모든 검사 통과"
        return 0
    else
        log_error "시스템 검증 실패 - $errors개 오류 발견"
        return 1
    fi
}

# Termux 환경 확인
check_termux_environment() {
    log_info "Termux 환경 확인 중..."
    
    # TERMUX_VERSION 확인
    if [ -z "$TERMUX_VERSION" ]; then
        log_warning "Termux 환경이 아닙니다. 일부 기능이 제한될 수 있습니다."
        return 0
    fi
    
    # 필수 패키지 확인
    local required_packages=("proot-distro" "curl" "wget" "proot" "tar" "unzip")
    local missing_packages=()
    
    for package in "${required_packages[@]}"; do
        if ! command -v "$package" &> /dev/null; then
            missing_packages+=("$package")
        fi
    done
    
    if [ ${#missing_packages[@]} -gt 0 ]; then
        log_error "필수 패키지가 누락되었습니다: ${missing_packages[*]}"
        log_info "다음 명령어로 설치하세요:"
        echo "pkg install ${missing_packages[*]}"
        return 1
    fi
    
    log_success "Termux 환경 확인 완료"
    return 0
}
```

## 📦 설치 스크립트 템플릿

### 완전한 설치 스크립트
```bash
#!/bin/bash

# 완전한 설치 스크립트 템플릿
# Author: Mobile IDE Team
# Version: 1.0.0

set -e

# 색상 및 로깅 함수 (위의 템플릿 사용)

# 설치 단계 정의
INSTALL_STEPS=(
    "시스템 검증"
    "Ubuntu 환경 설치"
    "Ubuntu 환경 설정"
    "Node.js 설치"
    "Cursor AI 설치"
    "실행 스크립트 생성"
)

# 설치 진행 상황 추적
CURRENT_STEP=0
TOTAL_STEPS=${#INSTALL_STEPS[@]}

# 설치 단계 실행
run_install_step() {
    local step_name="$1"
    local step_function="$2"
    
    ((CURRENT_STEP++))
    show_progress "$CURRENT_STEP" "$TOTAL_STEPS" "$step_name"
    
    if "$step_function"; then
        log_success "$step_name 완료"
        return 0
    else
        log_error "$step_name 실패"
        return 1
    fi
}

# 메인 설치 함수
main_install() {
    echo "=========================================="
    echo "  완전한 설치 시작"
    echo "=========================================="
    echo ""
    
    # 시스템 검증
    run_install_step "시스템 검증" validate_system || exit 1
    
    # Ubuntu 환경 설치
    run_install_step "Ubuntu 환경 설치" install_ubuntu || exit 1
    
    # Ubuntu 환경 설정
    run_install_step "Ubuntu 환경 설정" setup_ubuntu || exit 1
    
    # Node.js 설치
    run_install_step "Node.js 설치" install_nodejs || exit 1
    
    # Cursor AI 설치
    run_install_step "Cursor AI 설치" install_cursor_ai || exit 1
    
    # 실행 스크립트 생성
    run_install_step "실행 스크립트 생성" create_launch_script || exit 1
    
    log_success "모든 설치 단계 완료!"
    show_installation_summary
}

# 설치 요약 표시
show_installation_summary() {
    echo ""
    echo "=========================================="
    echo "  설치 완료 요약"
    echo "=========================================="
    echo ""
    echo "✅ 설치된 구성 요소:"
    echo "  - Ubuntu 22.04 LTS 환경"
    echo "  - Node.js 18 LTS"
    echo "  - Cursor AI IDE"
    echo "  - 실행 스크립트 (launch.sh)"
    echo ""
    echo "📁 설치 위치:"
    echo "  - Ubuntu 환경: ~/ubuntu/"
    echo "  - Cursor AI: ~/ubuntu/home/cursor-ide/"
    echo "  - 실행 스크립트: ~/launch.sh"
    echo ""
    echo "🚀 사용 방법:"
    echo "  ./launch.sh"
    echo ""
    echo "🔧 문제 해결:"
    echo "  ./scripts/fix_installation.sh"
    echo ""
}
```

## 🛠️ 트러블슈팅 스크립트 템플릿

### 문제 진단 스크립트
```bash
#!/bin/bash

# 문제 진단 스크립트 템플릿
# Author: Mobile IDE Team
# Version: 1.0.0

set -e

# 색상 및 로깅 함수 (위의 템플릿 사용)

# 진단 결과 저장
DIAGNOSTIC_RESULTS=()

# 진단 함수
run_diagnostic() {
    local test_name="$1"
    local test_function="$2"
    
    log_info "진단 중: $test_name"
    
    if "$test_function"; then
        log_success "$test_name: 정상"
        DIAGNOSTIC_RESULTS+=("✅ $test_name: 정상")
        return 0
    else
        log_error "$test_name: 문제 발견"
        DIAGNOSTIC_RESULTS+=("❌ $test_name: 문제 발견")
        return 1
    fi
}

# 시스템 진단
diagnose_system() {
    local issues=0
    
    # 사용자 권한 진단
    run_diagnostic "사용자 권한" check_user_permissions || ((issues++))
    
    # 시스템 요구사항 진단
    run_diagnostic "시스템 요구사항" check_system_requirements || ((issues++))
    
    # 네트워크 연결 진단
    run_diagnostic "네트워크 연결" check_network_connection || ((issues++))
    
    # Ubuntu 환경 진단
    run_diagnostic "Ubuntu 환경" check_ubuntu_environment || ((issues++))
    
    # Cursor AI 진단
    run_diagnostic "Cursor AI 설치" check_cursor_installation || ((issues++))
    
    return $issues
}

# 진단 결과 표시
show_diagnostic_results() {
    echo ""
    echo "=========================================="
    echo "  진단 결과"
    echo "=========================================="
    echo ""
    
    for result in "${DIAGNOSTIC_RESULTS[@]}"; do
        echo "$result"
    done
    
    echo ""
    echo "=========================================="
    
    local issue_count=$(echo "${DIAGNOSTIC_RESULTS[@]}" | grep -c "❌" || echo "0")
    
    if [ "$issue_count" -eq 0 ]; then
        log_success "모든 진단 통과!"
        echo "시스템이 정상적으로 작동하고 있습니다."
    else
        log_warning "$issue_count개 문제가 발견되었습니다."
        echo ""
        echo "해결 방법:"
        echo "1. 자동 수정 스크립트 실행: ./scripts/fix_installation.sh"
        echo "2. 수동 수정: docs/troubleshooting.md 참조"
        echo "3. GitHub 이슈 생성: https://github.com/huntkil/mobile_ide/issues"
    fi
}

# 메인 진단 함수
main_diagnostic() {
    echo "=========================================="
    echo "  시스템 진단 시작"
    echo "=========================================="
    echo ""
    
    local total_issues
    if diagnose_system; then
        total_issues=0
    else
        total_issues=$?
    fi
    
    show_diagnostic_results
    
    # 진단 결과를 파일로 저장
    {
        echo "진단 날짜: $(date)"
        echo "시스템 정보:"
        echo "  - Android 버전: $(getprop ro.build.version.release)"
        echo "  - 아키텍처: $(uname -m)"
        echo "  - 메모리: $(free -h | awk 'NR==2{print $2}')"
        echo ""
        echo "진단 결과:"
        printf '%s\n' "${DIAGNOSTIC_RESULTS[@]}"
    } > diagnostic_report.txt
    
    log_info "진단 보고서가 diagnostic_report.txt에 저장되었습니다."
    
    exit $total_issues
}
```

---

**마지막 업데이트**: 2025-07-25  
**버전**: 1.0.0  
**작성자**: Mobile IDE Team 