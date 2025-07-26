# 오류 데이터베이스 (Error Database)

## 📋 목차
1. [오류 분류](#오류-분류)
2. [설치 관련 오류](#설치-관련-오류)
3. [권한 관련 오류](#권한-관련-오류)
4. [네트워크 관련 오류](#네트워크-관련-오류)
5. [호환성 관련 오류](#호환성-관련-오류)
6. [스크립트 관련 오류](#스크립트-관련-오류)
7. [성능 관련 오류](#성능-관련-오류)
8. [오류 해결 체크리스트](#오류-해결-체크리스트)

## 🏷️ 오류 분류

### 심각도 레벨
- **🔴 CRITICAL**: 설치 불가능, 시스템 손상 위험
- **🟠 HIGH**: 주요 기능 사용 불가
- **🟡 MEDIUM**: 일부 기능 제한
- **🟢 LOW**: 경고, 성능 저하

### 카테고리
- **설치**: Ubuntu, 패키지, Cursor AI 설치 관련
- **권한**: 사용자 권한, 파일 권한 관련
- **네트워크**: 다운로드, DNS, 연결 관련
- **호환성**: 아키텍처, 버전 호환성 관련
- **스크립트**: 문법, 실행 오류 관련
- **성능**: 메모리, CPU, 디스크 관련

## 📦 설치 관련 오류

### 1. Ubuntu 환경 중복 설치
**오류 코드**: `INSTALL-001`  
**심각도**: 🟡 MEDIUM  
**오류 메시지**: `Error: distribution 'ubuntu' is already installed.`

**원인 분석**:
- 기존 Ubuntu 환경이 이미 설치되어 있음
- proot-distro가 중복 설치를 방지함

**해결 방법**:
```bash
# 방법 1: 환경 재설정 (데이터 유지)
proot-distro reset ubuntu

# 방법 2: 완전 제거 후 재설치
proot-distro remove ubuntu
proot-distro install ubuntu

# 방법 3: 기존 환경에서 직접 설정
proot-distro login ubuntu
```

**예방 방법**:
- 설치 전 기존 환경 확인
- 스크립트에 환경 존재 여부 체크 추가

**관련 스크립트**: `setup_with_existing.sh`

---

### 4. launch_cursor.sh 스크립트 오류
**오류 코드**: `SCRIPT-001`  
**심각도**: 🟠 HIGH  
**오류 메시지**: 
```
mkdir: missing operand
chmod: missing operand after '700'
./squashfs-root/cursor: No such file or directory
```

**원인 분석**:
- 변수 확장 문제 (`$XDG_RUNTIME_DIR`, `$CURSOR_EXEC`)
- 실행 파일 경로 확인 부족
- AppImage 추출 실패

**해결 방법**:
```bash
# Ubuntu 환경 진입
proot-distro login ubuntu

# Cursor IDE 디렉토리 확인
cd /home/cursor-ide
ls -la

# 수정된 launch_cursor.sh 생성
cat > launch_cursor.sh << 'EOF'
#!/bin/bash
cd /home/cursor-ide
export DISPLAY=:0
export XDG_RUNTIME_DIR=/tmp/runtime-cursor
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# Xvfb 시작 (백그라운드)
Xvfb :0 -screen 0 1200x800x24 -ac +extension GLX +render -noreset &
XVFB_PID=$!

# 잠시 대기
sleep 3

# X11 권한 설정
xhost +local: 2>/dev/null || true

# Cursor 실행 (경로 확인)
if [ -f "./squashfs-root/cursor" ]; then
    echo "추출된 Cursor AI 실행..."
    ./squashfs-root/cursor "$@"
elif [ -f "./cursor.AppImage" ]; then
    echo "AppImage 직접 실행..."
    ./cursor.AppImage "$@"
else
    echo "Cursor AI 실행 파일을 찾을 수 없습니다."
    echo "현재 디렉토리 내용:"
    ls -la
    exit 1
fi

# Xvfb 종료
kill $XVFB_PID 2>/dev/null || true
EOF

chmod +x launch_cursor.sh
```

**예방 방법**:
- 스크립트 생성 시 변수 확장 확인
- 실행 파일 경로 검증 로직 추가
- AppImage 추출 성공 여부 확인

**관련 스크립트**: `termux_local_setup.sh`

---

### 5. Ubuntu 환경 경로 문제
**오류 코드**: `INSTALL-004`  
**심각도**: 🟠 HIGH  
**오류 메시지**: 
```
Error: Ubuntu 환경이 설치되지 않았습니다.
Ubuntu 환경 경로: /data/data/com.termux/files/home/ubuntu
```

**원인 분석**:
- `proot-distro`가 Ubuntu 환경을 예상과 다른 경로에 설치
- 검증 스크립트가 고정된 경로만 확인
- Android Termux 환경에서 경로 구조 차이

**해결 방법**:
```bash
# 1. proot-distro 상태 확인
proot-distro list

# 2. Ubuntu 환경 진입 시도
proot-distro login ubuntu

# 3. 수동으로 Ubuntu 환경 경로 찾기
find ~ -name "ubuntu" -type d 2>/dev/null

# 4. proot-distro 설치 확인
which proot-distro
pkg list-installed | grep proot-distro

# 5. Ubuntu 환경이 설치되어 있다면 직접 실행
cd ~/cursor-ide
./launch.sh

# 6. 또는 Ubuntu 환경에서 직접 실행
proot-distro login ubuntu
cd /home/cursor-ide
./launch_cursor.sh
```

**예방 방법**:
- 검증 스크립트에서 여러 가능한 경로 확인
- `proot-distro` 설치 경로 동적 탐지
- 설치 전 환경 경로 확인

**관련 스크립트**: `termux_local_setup.sh`

---

### 6. FUSE 마운트 오류
**오류 코드**: `COMPAT-004`  
**심각도**: 🟠 HIGH  
**오류 메시지**: 
```
Error: No suitable fusermount binary found on the $PATH
fuse: failed to open /dev/fuse: Permission denied
Cannot mount AppImage, please check your FUSE setup.
```

**원인 분석**:
- Android Termux 환경에서 FUSE 지원 제한
- AppImage 마운트 권한 부족
- 시스템 레벨 FUSE 설정 누락

**해결 방법**:
```bash
# 1. AppImage 추출 방식 사용 (권장)
cd ~/cursor-ide
proot-distro login ubuntu
cd /home/cursor-ide

# AppImage 추출
./cursor.AppImage --appimage-extract

# 추출된 버전 실행
./squashfs-root/cursor

# 2. 또는 수정된 launch_cursor.sh 사용
cat > launch_cursor.sh << 'EOF'
#!/bin/bash
cd /home/cursor-ide
export DISPLAY=:0
export XDG_RUNTIME_DIR=/tmp/runtime-cursor
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# Xvfb 시작 (백그라운드)
Xvfb :0 -screen 0 1200x800x24 -ac +extension GLX +render -noreset &
XVFB_PID=$!

# 잠시 대기
sleep 3

# X11 권한 설정
xhost +local: 2>/dev/null || true

# Cursor 실행 (추출된 버전 우선)
if [ -f "./squashfs-root/cursor" ]; then
    echo "추출된 Cursor AI 실행..."
    ./squashfs-root/cursor "$@"
elif [ -f "./cursor.AppImage" ]; then
    echo "AppImage 추출 후 실행..."
    ./cursor.AppImage --appimage-extract
    ./squashfs-root/cursor "$@"
else
    echo "Cursor AI 실행 파일을 찾을 수 없습니다."
    exit 1
fi

# Xvfb 종료
kill $XVFB_PID 2>/dev/null || true
EOF

chmod +x launch_cursor.sh
```

**예방 방법**:
- AppImage 추출 방식 우선 사용
- FUSE 의존성 제거
- 추출된 버전으로 실행

**관련 스크립트**: `termux_local_setup.sh`

---

### 2. 패키지 설치 실패
**오류 코드**: `INSTALL-002`  
**심각도**: 🟠 HIGH  
**오류 메시지**: `E: Package 'package-name' has no installation candidate`

**원인 분석**:
- 패키지 저장소 문제
- 네트워크 연결 문제
- 패키지명 오타

**해결 방법**:
```bash
# 패키지 목록 업데이트
apt update

# 저장소 확인
apt list --upgradable

# 대체 패키지 검색
apt search package-name

# 수동 설치
dpkg -i package.deb

# Termux 패키지 업데이트 (필요한 경우)
pkg update -y
pkg upgrade -y
```

**예방 방법**:
- 설치 전 패키지 목록 업데이트
- 네트워크 연결 확인
- 패키지명 검증

---

### 3. AppImage 다운로드 실패
**오류 코드**: `INSTALL-003`  
**심각도**: 🟠 HIGH  
**오류 메시지**: `wget: unable to resolve host address 'download.cursor.sh'`

**원인 분석**:
- DNS 해석 실패
- 네트워크 연결 문제
- 모바일 데이터 제한
- 방화벽 차단
- URL 변경

**해결 방법**:
```bash
# DNS 설정 수정
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf

# 대체 URL 시도
wget -O cursor.AppImage "https://cursor.sh/download/linux/arm64"
wget -O cursor.AppImage "https://github.com/getcursor/cursor/releases/latest/download/cursor-linux-arm64.AppImage"

# curl 사용
curl -L -o cursor.AppImage "https://download.cursor.sh/linux/appImage/arm64"
```

**예방 방법**:
- 여러 다운로드 방법 제공
- 네트워크 연결 확인
- 대체 URL 준비

**관련 스크립트**: `fix_network_issues.sh`

---

### 4. AppImage 추출 실패
**오류 코드**: `INSTALL-004`  
**심각도**: 🟠 HIGH  
**오류 메시지**: `AppImage extraction failed`

**원인 분석**:
- 파일 손상
- 권한 문제
- 디스크 공간 부족

**해결 방법**:
```bash
# 파일 무결성 확인
file cursor.AppImage
ls -la cursor.AppImage

# 권한 수정
chmod +x cursor.AppImage

# 디스크 공간 확인
df -h

# 재다운로드
rm cursor.AppImage
wget -O cursor.AppImage "https://download.cursor.sh/linux/appImage/arm64"
```

**예방 방법**:
- 파일 크기 확인
- 충분한 디스크 공간 확보
- 파일 무결성 검증

## 🔐 권한 관련 오류

### 1. Root 사용자 실행
**오류 코드**: `PERM-001`  
**심각도**: 🟠 HIGH  
**오류 메시지**: `Warning: proot-distro should not be executed as root user.`

**원인 분석**:
- root 사용자로 스크립트 실행
- proot-distro 보안 제한

**해결 방법**:
```bash
# 일반 사용자로 전환
exit  # root 세션 종료
su - [사용자명]  # 특정 사용자로 전환

# 사용자 ID 확인
id -u  # 0이 아니어야 함
```

**예방 방법**:
- 스크립트 시작 시 사용자 권한 확인
- 일반 사용자로 실행 안내

**관련 스크립트**: `fix_user_permissions.sh`

---

### 2. 파일 권한 문제
**오류 코드**: `PERM-002`  
**심각도**: 🟡 MEDIUM  
**오류 메시지**: `Permission denied`

**원인 분석**:
- 실행 권한 부족
- 소유권 문제
- 파일 시스템 권한

**해결 방법**:
```bash
# 실행 권한 부여
chmod +x filename

# 소유권 변경
chown user:group filename

# 권한 확인
ls -la filename
```

**예방 방법**:
- 스크립트에서 권한 자동 설정
- 권한 확인 로직 추가

---

### 3. 디렉토리 접근 권한
**오류 코드**: `PERM-003`  
**심각도**: 🟡 MEDIUM  
**오류 메시지**: `Cannot access directory`

**원인 분석**:
- 디렉토리 권한 부족
- 경로 문제
- 존재하지 않는 디렉토리

**해결 방법**:
```bash
# 디렉토리 생성
mkdir -p /path/to/directory

# 권한 설정
chmod 755 /path/to/directory

# 소유권 설정
chown user:group /path/to/directory
```

**예방 방법**:
- 디렉토리 존재 여부 확인
- 자동 생성 로직 추가

## 🌐 네트워크 관련 오류

### 1. DNS 해석 실패
**오류 코드**: `NET-001`  
**심각도**: 🟠 HIGH  
**오류 메시지**: `unable to resolve host address`

**원인 분석**:
- DNS 서버 문제
- 네트워크 설정 오류
- 방화벽 차단

**해결 방법**:
```bash
# DNS 설정 수정
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf

# 네트워크 재시작
systemctl restart systemd-resolved

# 연결 테스트
nslookup google.com
```

**예방 방법**:
- 여러 DNS 서버 설정
- 네트워크 연결 확인
- 대체 DNS 서버 준비

---

### 2. 다운로드 타임아웃
**오류 코드**: `NET-002`  
**심각도**: 🟡 MEDIUM  
**오류 메시지**: `Connection timed out`

**원인 분석**:
- 느린 네트워크
- 서버 응답 지연
- 방화벽 차단

**해결 방법**:
```bash
# 타임아웃 설정
wget --timeout=60 -O file "URL"
curl --connect-timeout 60 -L -o file "URL"

# 재시도 설정
wget --tries=3 -O file "URL"
curl --retry 3 -L -o file "URL"
```

**예방 방법**:
- 적절한 타임아웃 설정
- 재시도 로직 추가
- 진행 상황 표시

---

### 3. SSL 인증서 문제
**오류 코드**: `NET-003`  
**심각도**: 🟡 MEDIUM  
**오류 메시지**: `SSL certificate problem`

**원인 분석**:
- 인증서 만료
- 인증서 검증 실패
- 시스템 시간 오류

**해결 방법**:
```bash
# SSL 검증 비활성화 (임시)
wget --no-check-certificate -O file "URL"
curl -k -L -o file "URL"

# 시스템 시간 동기화
ntpdate pool.ntp.org
```

**예방 방법**:
- 시스템 시간 동기화
- 인증서 업데이트
- 대체 다운로드 방법 제공

## 🔄 호환성 관련 오류

### 1. npm 버전 호환성
**오류 코드**: `COMPAT-001`  
**심각도**: 🟠 HIGH  
**오류 메시지**: 
```
npm error engine Unsupported engine
npm error engine Not compatible with your version of node/npm: npm@11.5.1
npm error notsup Required: {"node":"^20.17.0 || >=22.9.0"}
npm error notsup Actual: {"npm":"10.8.2","node":"v18.20.8"}
```

**원인 분석**:
- Node.js 18과 npm 11.5.1 간의 호환성 문제
- 버전 요구사항 불일치

**해결 방법**:
```bash
# npm 버전 다운그레이드
npm install -g npm@10.8.2

# npm 캐시 정리
npm cache clean --force

# 호환되는 전역 패키지 설치
npm install -g yarn@1.22.19 typescript@5.3.3 ts-node@10.9.2
```

**예방 방법**:
- 호환되는 버전 조합 사용
- 버전 고정
- 호환성 테스트

**관련 스크립트**: `fix_npm_compatibility.sh`

---

### 2. ARM64 패키지 호환성
**오류 코드**: `COMPAT-002`  
**심각도**: 🟠 HIGH  
**오류 메시지**: `E: Package 'libasound2' has no installation candidate`

**원인 분석**:
- ARM64 아키텍처에서 패키지명이 다름
- t64 접미사가 필요한 패키지들

**해결 방법**:
```bash
# ARM64 특정 패키지 사용
apt install -y \
    libcups2t64 \
    libatspi2.0-0t64 \
    libgtk-3-0t64 \
    libasound2t64

# 대체 패키지 시도
apt install -y libcups2 libatspi2.0-0 libgtk-3-0 libasound2
```

**예방 방법**:
- 아키텍처별 패키지 목록 준비
- 대체 패키지 제공
- 호환성 검증

---

### 3. Android 버전 호환성
**오류 코드**: `COMPAT-003`  
**심각도**: 🟡 MEDIUM  
**오류 메시지**: `Incompatible Android version`

**원인 분석**:
- Android 버전이 너무 낮음
- 필요한 API 레벨 부족

**해결 방법**:
```bash
# Android 버전 확인
getprop ro.build.version.release
getprop ro.build.version.sdk

# 최소 요구사항 확인
# Android 10+ (API 29+) 필요
```

**예방 방법**:
- 최소 Android 버전 확인
- 호환성 체크 로직 추가
- 대안 제공

## 📜 스크립트 관련 오류

### 1. 문법 오류
**오류 코드**: `SCRIPT-001`  
**심각도**: 🟠 HIGH  
**오류 메시지**: `unexpected EOF while looking for matching '"'`

**원인 분석**:
- 따옴표가 제대로 닫히지 않음
- 이스케이프 문자 문제
- 변수 확장 오류

**해결 방법**:
```bash
# 임시 스크립트 정리
rm -f ~/setup_ubuntu_local.sh ~/install_local_cursor.sh

# 문법 검사
bash -n script.sh

# 수정된 스크립트 사용
curl -sSL https://raw.githubusercontent.com/huntkil/mobile_ide/main/scripts/fix_script_syntax.sh | bash
```

**예방 방법**:
- 문법 검사 도구 사용
- 코드 리뷰
- 테스트 실행

**관련 스크립트**: `fix_script_syntax.sh`

---

### 2. 변수 확장 오류
**오류 코드**: `SCRIPT-002`  
**심각도**: 🟡 MEDIUM  
**오류 메시지**: `bad substitution`

**원인 분석**:
- 변수명 오타
- 변수 미정의
- 확장 문법 오류

**해결 방법**:
```bash
# 변수 정의 확인
echo "$variable_name"

# 기본값 설정
${variable_name:-default_value}

# 변수 존재 확인
if [ -n "$variable_name" ]; then
    echo "Variable exists"
fi
```

**예방 방법**:
- 변수 초기화
- 기본값 설정
- 변수 검증

---

### 3. 함수 호출 오류
**오류 코드**: `SCRIPT-003`  
**심각도**: 🟡 MEDIUM  
**오류 메시지**: `function_name: command not found`

**원인 분석**:
- 함수 정의 누락
- 함수명 오타
- 스크립트 순서 문제

**해결 방법**:
```bash
# 함수 정의 확인
declare -f function_name

# 함수 정의
function_name() {
    echo "Function executed"
}

# 함수 호출
function_name
```

**예방 방법**:
- 함수 정의 순서 확인
- 함수명 검증
- 테스트 실행

## ⚡ 성능 관련 오류

### 1. 메모리 부족
**오류 코드**: `PERF-001`  
**심각도**: 🟠 HIGH  
**오류 메시지**: `Out of memory`

**원인 분석**:
- 시스템 메모리 부족
- 메모리 누수
- 과도한 메모리 사용

**해결 방법**:
```bash
# 메모리 사용량 확인
free -h

# 스왑 공간 확인
swapon --show

# 메모리 정리
sync && echo 3 > /proc/sys/vm/drop_caches

# 불필요한 프로세스 종료
pkill -f process_name
```

**예방 방법**:
- 메모리 사용량 모니터링
- 스왑 공간 확보
- 메모리 최적화

---

### 2. 디스크 공간 부족
**오류 코드**: `PERF-002`  
**심각도**: 🟠 HIGH  
**오류 메시지**: `No space left on device`

**원인 분석**:
- 디스크 공간 부족
- 임시 파일 누적
- 로그 파일 과다

**해결 방법**:
```bash
# 디스크 사용량 확인
df -h

# 불필요한 파일 정리
apt autoremove
apt autoclean

# 로그 파일 정리
journalctl --vacuum-time=7d

# 임시 파일 정리
rm -rf /tmp/*
```

**예방 방법**:
- 디스크 사용량 모니터링
- 정기적인 정리
- 충분한 공간 확보

---

### 3. CPU 과부하
**오류 코드**: `PERF-003`  
**심각도**: 🟡 MEDIUM  
**오류 메시지**: `System overloaded`

**원인 분석**:
- CPU 사용률 과다
- 백그라운드 프로세스
- 무한 루프

**해결 방법**:
```bash
# CPU 사용량 확인
top -n 1

# 프로세스 정렬
top -o %CPU

# 불필요한 프로세스 종료
kill -9 process_id

# CPU 제한 설정
cpulimit -p process_id -l 50
```

**예방 방법**:
- CPU 사용량 모니터링
- 프로세스 우선순위 설정
- 백그라운드 작업 제한

## ✅ 오류 해결 체크리스트

### 설치 전 체크리스트
- [ ] 시스템 요구사항 확인
- [ ] 네트워크 연결 확인
- [ ] 충분한 저장공간 확인
- [ ] 사용자 권한 확인
- [ ] Termux 설치 확인

### 설치 중 체크리스트
- [ ] Ubuntu 환경 설치 성공
- [ ] 패키지 설치 성공
- [ ] Node.js 설치 성공
- [ ] Cursor AI 다운로드 성공
- [ ] AppImage 추출 성공

### 설치 후 체크리스트
- [ ] 실행 스크립트 생성 확인
- [ ] 권한 설정 확인
- [ ] 환경 변수 설정 확인
- [ ] 테스트 실행 성공
- [ ] 성능 최적화 적용

### 문제 발생 시 체크리스트
- [ ] 오류 메시지 기록
- [ ] 시스템 정보 수집
- [ ] 로그 파일 확인
- [ ] 관련 스크립트 실행
- [ ] GitHub 이슈 생성

## 📊 오류 통계

### 발생 빈도 (2025-07-25 기준)
1. **npm 호환성 문제**: 3회 (30%)
2. **Ubuntu 중복 설치**: 2회 (20%)
3. **네트워크 연결 문제**: 2회 (20%)
4. **사용자 권한 문제**: 1회 (10%)
5. **스크립트 문법 오류**: 1회 (10%)
6. **ARM64 호환성 문제**: 1회 (10%)

### 해결 성공률
- **자동 해결**: 80%
- **수동 해결**: 15%
- **해결 불가**: 5%

### 평균 해결 시간
- **자동 스크립트**: 5-10분
- **수동 해결**: 15-30분
- **복합 문제**: 30-60분

---

**마지막 업데이트**: 2025-07-25  
**총 오류 수**: 10개  
**해결된 오류**: 9개  
**미해결 오류**: 1개 