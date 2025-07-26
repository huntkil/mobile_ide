# Galaxy Android용 Cursor AI IDE 개발 가이드

## 📋 목차
1. [프로젝트 개요](#프로젝트-개요)
2. [기술 스택](#기술-스택)
3. [아키텍처](#아키텍처)
4. [설치 프로세스](#설치-프로세스)
5. [발생한 오류들과 해결 방법](#발생한-오류들과-해결-방법)
6. [스크립트 개발 가이드](#스크립트-개발-가이드)
7. [테스트 및 검증](#테스트-및-검증)
8. [향후 업데이트 계획](#향후-업데이트-계획)
9. [트러블슈팅 가이드](#트러블슈팅-가이드)

## 🎯 프로젝트 개요

### 목표
- Samsung Galaxy Android 기기에서 Cursor AI IDE 실행 환경 구축
- Termux + Ubuntu 환경을 통한 Linux 기반 IDE 제공
- 모바일 최적화된 개발 환경 제공

### 지원 환경
- **OS**: Android 10+ (권장: Android 13+)
- **아키텍처**: ARM64 (aarch64)
- **기기**: Samsung Galaxy 시리즈
- **메모리**: 최소 4GB, 권장 8GB+
- **저장공간**: 최소 10GB, 권장 20GB+

## 🛠️ 기술 스택

### 핵심 기술
- **Termux**: Android용 Linux 터미널 에뮬레이터
- **proot-distro**: Linux 배포판 설치 도구
- **Ubuntu 22.04 LTS**: Linux 환경
- **X11 (Xvfb)**: 가상 디스플레이 서버
- **Cursor AI IDE**: ARM64 Linux AppImage

### 의존성 패키지
```bash
# Termux 패키지
pkg install proot-distro curl wget proot tar unzip

# Ubuntu 패키지
apt install curl wget git build-essential python3 python3-pip
apt install xvfb x11-apps x11-utils x11-xserver-utils dbus-x11
apt install libx11-6 libxext6 libxrender1 libxtst6 libxi6
apt install libxrandr2 libxss1 libxcb1 libxcomposite1
apt install libxcursor1 libxdamage1 libxfixes3 libxinerama1
apt install libnss3 libcups2t64 libdrm2 libxkbcommon0
apt install libatspi2.0-0t64 libgtk-3-0t64 libgbm1 libasound2t64

# Node.js 18 LTS
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs
npm install -g npm@10.8.2
npm install -g yarn@1.22.19 typescript@5.3.3 ts-node@10.9.2
```

## 🏗️ 아키텍처

### 시스템 구조
```
Android Device
├── Termux
│   ├── proot-distro
│   │   └── Ubuntu 22.04 LTS
│   │       ├── X11 Environment (Xvfb)
│   │       ├── Node.js 18 LTS
│   │       ├── Cursor AI IDE
│   │       └── Development Tools
│   └── Scripts
│       ├── setup.sh
│       ├── launch.sh
│       └── optimize.sh
└── User Files
    └── Projects
```

### 파일 구조
```
mobile_ide/
├── scripts/
│   ├── termux_local_setup.sh       # 로컬 AppImage 설치 (권장)
│   ├── termux_complete_setup.sh    # 온라인 다운로드 완전 설치
│   ├── termux_minimal_setup.sh     # 최소 설치
│   ├── termux_safe_setup.sh        # 안전 설치
│   ├── termux_perfect_setup.sh     # 완벽 설치
│   ├── termux_ultimate_setup.sh    # 최종 완벽 설치
│   ├── termux_perfect_restore.sh   # 완벽 복구
│   ├── termux_safe_restore.sh      # 안전 복구
│   ├── setup_with_existing.sh      # 기존 환경 처리
│   ├── install_from_local.sh       # 로컬 AppImage 설치
│   ├── complete_setup_from_root.sh # 루트 AppImage 완벽 설치
│   ├── fix_script_syntax.sh        # 문법 오류 수정
│   ├── fix_user_permissions.sh     # 사용자 권한 해결
│   ├── fix_network_issues.sh       # 네트워크 문제 해결
│   ├── fix_npm_compatibility.sh    # npm 호환성 해결
│   ├── launch.sh                   # 실행
│   ├── restore.sh                  # 복구
│   └── optimize.sh                 # 최적화
├── config/
│   └── cursor-config.json          # Cursor AI 설정
├── docs/
│   ├── installation.md             # 설치 가이드
│   ├── troubleshooting.md          # 문제 해결
│   ├── ERROR_DATABASE.md           # 오류 데이터베이스
│   ├── SCRIPT_TEMPLATES.md         # 스크립트 템플릿
│   └── DEVELOPMENT_GUIDE.md        # 개발 가이드
├── tests/
│   └── compatibility.sh            # 호환성 테스트
├── README.md                       # 프로젝트 개요
├── LICENSE                         # 라이선스
└── .gitignore                      # Git 제외 파일
```

## 📦 설치 프로세스

### 1단계: 환경 확인
```bash
# 시스템 정보 확인
Android 버전: 15
아키텍처: aarch64
메모리: 10GB
저장공간: 28GB
```

### 2단계: Termux 설정
```bash
# 필수 패키지 설치
pkg update
pkg install proot-distro curl wget proot tar unzip
```

### 3단계: Ubuntu 환경 설치
```bash
# Ubuntu 22.04 LTS 설치
proot-distro install ubuntu
```

### 4단계: Ubuntu 환경 설정
```bash
# Ubuntu 환경에서 실행
proot-distro login ubuntu

# 패키지 업데이트
apt update

# 필수 패키지 설치
apt install -y curl wget git build-essential python3 python3-pip
# ... (위의 의존성 패키지 목록)
```

### 5단계: Node.js 설치
```bash
# 기존 Node.js 제거 (충돌 방지)
apt remove -y nodejs npm 2>/dev/null || true
apt autoremove -y

# Node.js 18 LTS 설치
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# npm 호환성 문제 해결
npm install -g npm@10.8.2
npm cache clean --force
```

### 6단계: Cursor AI 설치
```bash
# 작업 디렉토리 생성
mkdir -p /home/cursor-ide
cd /home/cursor-ide

# AppImage 다운로드 (ARM64)
wget -O cursor.AppImage "https://download.cursor.sh/linux/appImage/arm64"

# 실행 권한 부여
chmod +x cursor.AppImage

# AppImage 추출
./cursor.AppImage --appimage-extract
```

### 7단계: 실행 스크립트 생성
```bash
# launch.sh 생성
cat > ~/launch.sh << 'EOF'
#!/bin/bash
export DISPLAY=:0
Xvfb :0 -screen 0 1200x800x24 -ac +extension GLX +render -noreset &
sleep 3
cd "$HOME/ubuntu/home/cursor-ide"
proot-distro login ubuntu -- ./squashfs-root/cursor
EOF

chmod +x ~/launch.sh
```

## ❌ 발생한 오류들과 해결 방법

### 1. **실행 스크립트 아키텍처 문제 (v1.0 - v2.3)**
**오류**: 
- `mkdir: cannot create directory ''` (변수 확장 문제)
- `AppRun: No such file or directory` (경로 혼동 문제)
- `Failed to connect to the bus` (시스템 서비스 오류)
- `Fatal process out of memory` (메모리 부족 문제)

**원인**:
- Termux 환경과 proot-distro Ubuntu 환경 간의 복잡한 상호작용
- 환경 변수 전달 실패, 경로 불일치, 시스템 서비스 접근 제한
- 제한된 모바일 환경에서의 메모리 부족

**해결 방법 (v3.0.0 아키텍처):**
- **독립 실행 스크립트**: Ubuntu 내부에 모든 실행 로직을 포함하는 `start.sh`를 생성하여 환경 간의 의존성을 제거.
- **단순화된 런처**: Termux의 `launch.sh`는 Ubuntu의 `start.sh`를 호출만 하도록 단순화.
- **강력한 실행 옵션**: 메모리 제한, GPU 비활성화, 모든 시스템 서비스 오류를 우회하는 옵션을 `start.sh`에 내장.
- **오류 메시지 숨김**: `> /dev/null 2>&1`을 사용하여 사용자에게 불필요한 오류 메시지를 숨기고 안정적인 실행 환경 제공.

```bash
# 새로운 아키텍처로 완전 재설치
cd ~/mobile_ide
git pull origin main
./scripts/termux_local_setup.sh
```

## 🔧 스크립트 개발 가이드

### 스크립트 작성 원칙

#### 1. 에러 처리
```bash
#!/bin/bash
set -e  # 에러 발생 시 스크립트 중단

# 함수별 에러 처리
function_name() {
    if [ $? -ne 0 ]; then
        log_error "함수 실행 실패"
        return 1
    fi
}
```

#### 2. 로깅 시스템
```bash
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
```

#### 3. 사용자 권한 확인
```bash
check_user_permissions() {
    # root 사용자 확인
    if [ "$(id -u)" -eq 0 ]; then
        log_error "root 사용자로 실행할 수 없습니다."
        exit 1
    fi
    
    # proot-distro 확인
    if ! command -v proot-distro &> /dev/null; then
        log_error "proot-distro가 설치되지 않았습니다."
        exit 1
    fi
}
```

#### 4. 파일 존재 확인
```bash
check_file_exists() {
    local file_path="$1"
    if [ ! -f "$file_path" ]; then
        log_error "파일을 찾을 수 없습니다: $file_path"
        return 1
    fi
    return 0
}
```

#### 5. 네트워크 연결 확인
```bash
check_network_connection() {
    if ! nslookup google.com >/dev/null 2>&1; then
        log_warning "DNS 확인 실패"
        return 1
    fi
    
    if ! curl -s --connect-timeout 10 https://www.google.com >/dev/null; then
        log_warning "HTTP 연결 실패"
        return 1
    fi
    
    return 0
}
```

### 스크립트 템플릿

#### 기본 스크립트 구조
```bash
#!/bin/bash

# 스크립트 설명
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

## 🧪 테스트 및 검증

### 호환성 테스트
```bash
# 시스템 정보 수집
./tests/compatibility.sh

# 테스트 결과 확인
cat compatibility_report.txt
```

### 설치 검증
```bash
# Ubuntu 환경 확인
ls -la ~/ubuntu

# Cursor AI 설치 확인
ls -la ~/ubuntu/home/cursor-ide/

# 실행 스크립트 확인
ls -la ~/launch.sh

# 실행 테스트
./launch.sh
```

### 성능 테스트
```bash
# 메모리 사용량 확인
free -h

# CPU 사용량 확인
top -n 1

# 디스크 사용량 확인
df -h
```

## 🚀 향후 업데이트 계획

### 단기 계획 (1-2개월)
1. **자동화 개선**
   - 원클릭 설치 스크립트
   - 자동 업데이트 기능
   - 백업 및 복구 기능

2. **성능 최적화**
   - 메모리 사용량 최적화
   - 시작 시간 단축
   - 배터리 사용량 최적화

3. **사용자 경험 개선**
   - GUI 설치 도구
   - 진행 상황 표시
   - 오류 메시지 개선

### 중기 계획 (3-6개월)
1. **확장성 개선**
   - 다른 Linux 배포판 지원 (Debian, Arch)
   - 다른 IDE 지원 (VS Code, IntelliJ)
   - 플러그인 시스템

2. **클라우드 통합**
   - GitHub 연동
   - 클라우드 저장소 지원
   - 실시간 동기화

3. **모바일 최적화**
   - 터치 제스처 지원
   - 가상 키보드 최적화
   - 화면 크기 자동 조정

### 장기 계획 (6개월+)
1. **AI 기능 통합**
   - 코드 자동 완성
   - 버그 예측
   - 성능 분석

2. **협업 기능**
   - 실시간 코드 편집
   - 화면 공유
   - 음성 통화

3. **플랫폼 확장**
   - iOS 지원
   - Windows 지원
   - 웹 버전

## 🔍 트러블슈팅 가이드

### 일반적인 문제 해결

#### 1. 설치 실패
```bash
# 로그 확인
tail -f /var/log/apt/history.log

# 패키지 캐시 정리
apt clean
apt autoclean

# 재설치
./scripts/restore.sh
```

#### 2. 실행 실패
```bash
# X11 서버 확인
ps aux | grep Xvfb

# 디스플레이 설정 확인
echo $DISPLAY

# 권한 확인
ls -la ~/launch.sh
```

#### 3. 성능 문제
```bash
# 메모리 확인
free -h

# CPU 확인
top

# 디스크 확인
df -h

# 최적화 실행
./scripts/optimize.sh
```

### 디버깅 도구

#### 1. 시스템 정보 수집
```bash
# 시스템 정보
uname -a
cat /proc/version
cat /proc/cpuinfo
cat /proc/meminfo

# 환경 변수
env | grep -E "(TERMUX|PATH|HOME)"

# 설치된 패키지
pkg list-installed
```

#### 2. 로그 분석
```bash
# 시스템 로그
logcat

# Termux 로그
tail -f ~/.termux/shell.log

# Ubuntu 로그
proot-distro login ubuntu -- journalctl -f
```

#### 3. 네트워크 진단
```bash
# 연결 테스트
ping google.com
nslookup google.com
curl -I https://www.google.com

# DNS 설정 확인
cat /etc/resolv.conf
```

### 지원 및 문의

#### 문제 보고
1. **시스템 정보 수집**
   ```bash
   ./tests/compatibility.sh
   ```

2. **오류 로그 수집**
   ```bash
   # 오류 발생 시 로그 저장
   ./scripts/launch.sh 2>&1 | tee error.log
   ```

3. **GitHub 이슈 생성**
   - 제목: 간단한 문제 설명
   - 내용: 시스템 정보, 오류 로그, 재현 방법

#### 연락처
- **GitHub**: https://github.com/huntkil/mobile_ide
- **이메일**: huntkil@github.com
- **문서**: docs/ 디렉토리 참조

---

## 📝 변경 이력

### v1.0.0 (2025-07-25)
- 초기 프로젝트 생성
- 기본 설치 스크립트 구현
- Ubuntu 환경 설정
- Cursor AI IDE 설치

### v1.1.0 (2025-07-25)
- npm 호환성 문제 해결
- ARM64 패키지 호환성 개선
- 네트워크 문제 해결 스크립트 추가

### v1.2.0 (2025-07-25)
- 사용자 권한 문제 해결
- 스크립트 문법 오류 수정
- 로컬 AppImage 설치 지원

### v1.3.0 (2025-07-25)
- 루트 AppImage 완벽 설치 스크립트
- 개발 가이드 문서화
- 트러블슈팅 가이드 추가

---

**마지막 업데이트**: 2025-07-25  
**버전**: 1.3.0  
**작성자**: Mobile IDE Team 