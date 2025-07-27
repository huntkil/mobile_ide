# 문제 해결 가이드

## 🔍 일반적인 문제들

### 0. **저장공간 부족 문제 (최우선 해결)**

#### 문제: 루트 파티션 100% 사용률
```
/dev/block/dm-6   6.3G 6.3G  2.0M 100% /
No space left on device
```

**원인**: Android 기기의 루트 파티션에 여유 공간이 없어 Ubuntu 설치 불가능

**해결 방법**:
```bash
# 1. 긴급 정리 스크립트 실행
cd ~/cursor-ide
./cleanup.sh

# 2. 수동 정리 (cleanup.sh가 없는 경우)
pkg clean
pkg autoclean
rm -rf /tmp/*
rm -rf ~/.cache/*
find ~ -name "*.log" -type f -size +10M -delete 2>/dev/null
rm -rf ~/ubuntu 2>/dev/null
rm -rf ~/.local/share/proot-distro 2>/dev/null

# 3. Android 시스템 정리
# 설정 → 디바이스 케어 → 저장공간 → 정리 실행

# 4. 외부 저장소 활용
termux-setup-storage
mkdir -p ~/storage/shared/TermuxWork
cd ~/storage/shared/TermuxWork
```

### 0.1. **GUI 화면 표시 문제**

#### 문제: Cursor AI가 실행되지만 화면이 보이지 않음
```
[INFO] Cursor AI 시작...
# 프로세스는 실행되지만 화면이 보이지 않음
```

**원인**: Android 환경에서 X11 가상 디스플레이만으로는 GUI를 볼 수 없음

**해결 방법**:
```bash
# 1. VNC 서버 설치 (여러 대안 시도)
pkg search vnc
pkg install x11vnc || pkg install tightvncserver || pkg install tigervnc

# 2. VNC 서버 시작
vncserver :1 -geometry 1024x768 -depth 24
# 비밀번호 설정: cursor123

# 3. Android VNC Viewer 앱 설치
# Google Play Store에서 "VNC Viewer" 검색
# RealVNC VNC Viewer 또는 bVNC Free 설치

# 4. VNC 접속
# 앱에서 localhost:5901 접속, 비밀번호: cursor123

# 5. VNC 지원 스크립트 사용
cat > ~/run_cursor_vnc.sh << 'EOF'
#!/bin/bash
export DISPLAY=:1
vncserver :1 -geometry 1024x768 -depth 24 -localhost no
sleep 3
cd ~
./squashfs-root/AppRun --no-sandbox --disable-gpu --single-process &
echo "VNC Viewer 앱으로 localhost:5901에 접속하세요"
EOF
chmod +x ~/run_cursor_vnc.sh
./run_cursor_vnc.sh
```

### 0.2. **네트워크 DNS 해석 실패**

#### 문제: 도메인 해석 실패
```
wget: unable to resolve host address 'download.cursor.sh'
```

**원인**: DNS 서버 설정 문제 또는 네트워크 연결 불안정

**해결 방법**:
```bash
# 1. DNS 서버 수동 설정
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf

# 2. 네트워크 연결 테스트
ping -c 3 8.8.8.8
ping -c 3 google.com

# 3. 기존 AppImage 활용 (다운로드 우회)
cp ~/Cursor-1.2.1-aarch64.AppImage ~/cursor.AppImage
chmod +x ~/cursor.AppImage
./cursor.AppImage --appimage-extract

# 4. 대체 다운로드 URL 시도
curl -L -o cursor.AppImage "https://cursor.sh/download/linux/arm64"
wget -O cursor.AppImage "https://github.com/getcursor/cursor/releases/latest/download/cursor-linux-arm64.AppImage"
```

### 0.3. **외부 저장소 실행 권한 문제**

#### 문제: 외부 저장소에서 실행 권한 거부
```
chmod +x cursor.AppImage
./cursor.AppImage --appimage-extract
bash: ./cursor.AppImage: Permission denied
```

**원인**: Android 보안 정책으로 외부 저장소에서 실행 권한(`+x`) 제한

**해결 방법**:
```bash
# 1. 파일을 Termux 내부 저장소로 복사
cp ~/storage/shared/TermuxWork/cursor.AppImage ~/cursor.AppImage

# 2. 내부 저장소에서 권한 부여 및 실행
cd ~
chmod +x cursor.AppImage
./cursor.AppImage --appimage-extract

# 3. 실행 스크립트 생성
cat > ~/run_cursor.sh << 'EOF'
#!/bin/bash
cd ~
export DISPLAY=:0
if ! pgrep -x "Xvfb" > /dev/null; then
    Xvfb :0 -screen 0 1024x768x16 -ac +extension GLX +render -noreset &
    sleep 3
fi
if [ -f "./squashfs-root/AppRun" ]; then
    ./squashfs-root/AppRun --no-sandbox --disable-gpu --single-process "$@"
else
    echo "AppImage 추출이 필요합니다: ./cursor.AppImage --appimage-extract"
fi
EOF
chmod +x ~/run_cursor.sh
./run_cursor.sh
```

### 0.4. **VNC 패키지 부재 문제**

#### 문제: VNC 서버 패키지를 찾을 수 없음
```
E: Unable to locate package tigervnc
```

**원인**: Termux 저장소에 특정 VNC 패키지가 없음

**해결 방법**:
```bash
# 1. 사용 가능한 VNC 패키지 검색
pkg search vnc
pkg search x11

# 2. 대안 VNC 패키지 설치 시도
pkg install x11vnc || pkg install tightvncserver || pkg install vncserver

# 3. VNC 없이 헤드리스 모드 실행
cat > ~/run_cursor_headless.sh << 'EOF'
#!/bin/bash
cd ~
export DISPLAY=:0
if ! pgrep -x "Xvfb" > /dev/null; then
    Xvfb :0 -screen 0 1024x768x16 -ac +extension GLX +render -noreset &
    sleep 3
fi
./squashfs-root/AppRun --no-sandbox --disable-gpu --single-process "$@" &
CURSOR_PID=$!
echo "Cursor AI가 백그라운드에서 실행 중입니다 (PID: $CURSOR_PID)"
echo "종료하려면: kill $CURSOR_PID"
EOF
chmod +x ~/run_cursor_headless.sh
./run_cursor_headless.sh

# 4. Termux:X11 사용 (대안)
pkg install termux-x11-nightly
termux-x11 :0 &
export DISPLAY=:0
```

### 0.5. **스크립트 문법 오류**

#### 문제: 스크립트 실행 시 문법 오류
```
./run_cursor.sh: line 16:  : command not found
```

**원인**: 스크립트 생성 시 `if` 문 조건부가 제대로 작성되지 않음

**해결 방법**:
```bash
# 1. 잘못된 스크립트 삭제
rm -f ~/run_cursor.sh

# 2. 올바른 문법으로 스크립트 재생성
cat > ~/run_cursor.sh << 'EOF'
#!/bin/bash
cd ~
export DISPLAY=:0

echo "[INFO] Cursor AI 실행 중..."

# X11 환경 설정
if ! pgrep -x "Xvfb" > /dev/null; then
    echo "[INFO] Xvfb 시작 중..."
    Xvfb :0 -screen 0 1024x768x16 -ac +extension GLX +render -noreset &
    sleep 3
    echo "[INFO] Xvfb 시작됨"
fi

# Cursor AI 실행
if [ -f "./squashfs-root/AppRun" ]; then
    echo "[INFO] AppRun으로 실행..."
    ./squashfs-root/AppRun --no-sandbox --disable-gpu --single-process "$@"
elif [ -f "./squashfs-root/cursor" ]; then
    echo "[INFO] cursor로 실행..."
    ./squashfs-root/cursor --no-sandbox --disable-gpu --single-process "$@"
else
    echo "[ERROR] 실행 파일을 찾을 수 없습니다."
    echo "AppImage 추출: ./cursor.AppImage --appimage-extract"
fi
EOF

chmod +x ~/run_cursor.sh

# 3. 문법 검사
bash -n ~/run_cursor.sh
```

### 0. launch_cursor.sh 스크립트 오류

#### 문제: mkdir/chmod 명령어 오류 및 실행 파일 없음
```
mkdir: missing operand
chmod: missing operand after '700'
./squashfs-root/cursor: No such file or directory
```

**원인**: `launch_cursor.sh` 스크립트에서 변수 확장 문제 및 경로 확인 부족

**해결 방법**:
```bash
# 1. Ubuntu 환경 진입
proot-distro login ubuntu

# 2. Cursor IDE 디렉토리 확인
cd /home/cursor-ide
ls -la

# 3. 수정된 launch_cursor.sh 생성
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

# 4. 실행
./launch_cursor.sh
```

### 1. Ubuntu 환경 경로 문제

#### 문제: Ubuntu 환경이 설치되지 않았습니다
```
Error: Ubuntu 환경이 설치되지 않았습니다.
Ubuntu 환경 경로: /data/data/com.termux/files/home/ubuntu
```

**원인**: `proot-distro`가 Ubuntu 환경을 예상과 다른 경로에 설치

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
```

### 1. 환경 불일치 문제

#### 문제: 잘못된 환경에서 스크립트 실행
```
Error: Ubuntu 환경이 설치되지 않았습니다.
```

**원인**: Android Termux 환경이 아닌 곳에서 Termux용 스크립트를 실행했을 때 발생

**해결 방법**:
```bash
# 1. 환경 확인
echo $TERMUX_VERSION  # Termux인지 확인
uname -a  # 시스템 정보 확인

# 2. Android Termux에서만 실행
# 다른 환경에서는 실행 불가

# 3. 올바른 스크립트 사용
./scripts/termux_local_setup.sh  # 로컬 AppImage 설치
```

### 1. 설치 과정에서 발생하는 문제

#### 문제: "Permission denied" 오류
```
Error: Permission denied
```

**해결 방법:**
```bash
# 실행 권한 확인 및 수정
chmod +x setup.sh
chmod +x launch.sh
chmod +x optimize.sh
chmod +x restore.sh

# 또는 sudo 권한으로 실행 (가능한 경우)
sudo ./setup.sh
```

#### 문제: "No space left on device" 오류
```
Error: No space left on device
```

**해결 방법:**
```bash
# 저장공간 확인
df -h

# 불필요한 파일 정리
pkg clean
rm -rf ~/.cache
rm -rf ~/ubuntu  # 기존 설치 제거 후 재설치

# 또는 외부 저장소 사용
# Termux에서 외부 저장소 접근 권한 확인
termux-setup-storage
```

#### 문제: "Network is unreachable" 오류
```
Error: Network is unreachable
```

**해결 방법:**
```bash
# 네트워크 연결 확인
ping google.com

# DNS 설정 확인
cat /etc/resolv.conf

# 프록시 설정 (필요한 경우)
export http_proxy=http://proxy:port
export https_proxy=http://proxy:port
```

### 2. Ubuntu 환경 관련 문제

#### 문제: Ubuntu 설치 실패
```
Error: Failed to install Ubuntu
```

**해결 방법:**
```bash
# proot-distro 재설치
pkg remove proot-distro
pkg install proot-distro

# 캐시 정리 후 재시도
pkg clean
proot-distro install ubuntu
```

#### 문제: Ubuntu 환경에서 패키지 설치 실패
```
Error: Unable to locate package
```

**해결 방법:**
```bash
# Ubuntu 환경 진입
proot-distro login ubuntu

# 패키지 목록 업데이트
apt update

# 저장소 추가 (필요한 경우)
apt install software-properties-common
add-apt-repository ppa:deadsnakes/ppa  # Python 예시
apt update
```

#### 문제: Node.js 설치 실패
```
Error: Node.js installation failed
```

**해결 방법:**
```bash
# Ubuntu 환경에서
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs

# 또는 Node Version Manager 사용
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install node
nvm use node
```

### 3. X11 환경 관련 문제

#### 문제: Xvfb 시작 실패
```
Error: Xvfb failed to start
```

**해결 방법:**
```bash
# Xvfb 프로세스 확인
ps aux | grep Xvfb

# 기존 프로세스 종료
pkill Xvfb

# Xvfb 재시작
Xvfb :0 -screen 0 1200x800x24 -ac +extension GLX +render -noreset &
sleep 3

# DISPLAY 변수 설정
export DISPLAY=:0
```

#### 문제: "Cannot open display" 오류
```
Error: Cannot open display :0
```

**해결 방법:**
```bash
# DISPLAY 변수 확인
echo $DISPLAY

# DISPLAY 변수 설정
export DISPLAY=:0

# X11 권한 확인
xhost +local:
```

### 4. Cursor AI 실행 관련 문제

#### 문제: AppImage 실행 실패
```
Error: AppImage execution failed
```

**해결 방법:**
```bash
# 실행 권한 확인
ls -la cursor.AppImage

# 실행 권한 부여
chmod +x cursor.AppImage

# AppImage 추출
./cursor.AppImage --appimage-extract

# 추출된 버전 실행
./squashfs-root/cursor
```

#### 문제: "GLIBC version not found" 오류
```
Error: GLIBC_2.34 not found
```

**해결 방법:**
```bash
# Ubuntu 환경에서 GLIBC 버전 확인
ldd --version

# 필요한 라이브러리 설치
apt install -y libc6

# 또는 호환되는 Cursor AI 버전 다운로드
wget -O cursor.AppImage "https://download.cursor.sh/linux/appImage/arm64-legacy"
```

#### 문제: 메모리 부족으로 인한 실행 실패
```
Error: Out of memory
```

**해결 방법:**
```bash
# 메모리 상태 확인
free -h

# 다른 프로세스 종료
pkill -f "chrome"
pkill -f "firefox"

# 스왑 파일 생성 (필요한 경우)
dd if=/dev/zero of=/swapfile bs=1M count=2048
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
```

### 5. 성능 관련 문제

#### 문제: Cursor AI가 느리게 실행됨
```
Performance issue: Slow startup
```

**해결 방법:**
```bash
# 성능 최적화 실행
./optimize.sh

# 메모리 캐시 정리
echo 3 > /proc/sys/vm/drop_caches

# CPU 성능 모드 설정
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# 불필요한 프로세스 종료
pkill -f "Xvfb"
```

#### 문제: 배터리 소모가 심함
```
Battery drain issue
```

**해결 방법:**
```bash
# 배터리 최적화 비활성화
dumpsys deviceidle disable

# Doze 모드 비활성화
dumpsys deviceidle whitelist +com.termux

# CPU 주파수 조정 (성능과 배터리 절약 사이의 균형)
echo ondemand > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
```

### 6. 네트워크 관련 문제

#### 문제: AI 기능이 작동하지 않음
```
Error: AI features not working
```

**해결 방법:**
```bash
# 네트워크 연결 확인
curl -I https://api.cursor.sh

# DNS 설정 확인
nslookup api.cursor.sh

# 프록시 설정 (회사/학교 네트워크)
export http_proxy=http://proxy:port
export https_proxy=http://proxy:port

# 방화벽 설정 확인
iptables -L
```

#### 문제: 확장 프로그램 다운로드 실패
```
Error: Extension download failed
```

**해결 방법:**
```bash
# 네트워크 연결 확인
ping marketplace.visualstudio.com

# 프록시 설정
export http_proxy=http://proxy:port
export https_proxy=http://proxy:port

# 또는 수동으로 확장 프로그램 설치
# .vsix 파일 다운로드 후 설치
```

## 🔧 고급 문제 해결

### 시스템 로그 확인

```bash
# 시스템 로그 확인
dmesg | tail -20

# Termux 로그 확인
logcat | grep termux

# Ubuntu 환경 로그 확인
journalctl -f
```

### 디버깅 모드 실행

```bash
# Cursor AI 디버깅 모드 실행
./cursor.AppImage --verbose --log-level=debug

# 또는 추출된 버전에서
./squashfs-root/cursor --verbose --log-level=debug
```

### 환경 변수 확인

```bash
# 환경 변수 확인
env | grep -E "(DISPLAY|PATH|LD_LIBRARY_PATH)"

# 필요한 환경 변수 설정
export DISPLAY=:0
export PATH=$PATH:/usr/local/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
```

### 파일 권한 문제 해결

```bash
# 파일 권한 확인
ls -la ~/ubuntu/home/cursor-ide/

# 권한 수정
chmod 755 ~/ubuntu/home/cursor-ide/
chmod 644 ~/ubuntu/home/cursor-ide/cursor-config.json
chmod 755 ~/ubuntu/home/cursor-ide/cursor.AppImage
```

## 📞 추가 지원

### 로그 수집

문제 해결을 위해 다음 정보를 수집해주세요:

```bash
# 시스템 정보
uname -a
cat /proc/version
getprop ro.build.version.release

# 메모리 정보
free -h
cat /proc/meminfo

# 저장공간 정보
df -h
du -sh ~/ubuntu

# 네트워크 정보
ifconfig
ping google.com

# 프로세스 정보
ps aux | grep -E "(cursor|Xvfb|proot)"
```

### 커뮤니티 지원

- **GitHub Issues**: [프로젝트 이슈 페이지](https://github.com/your-repo/mobile_ide/issues)
- **Discord**: [Mobile IDE Community](https://discord.gg/mobile-ide)
- **Reddit**: r/mobile_ide

### 전문 지원

복잡한 문제의 경우 다음 정보와 함께 문의해주세요:

1. **기기 정보**: 모델명, Android 버전, 아키텍처
2. **오류 메시지**: 정확한 오류 메시지 전체
3. **재현 단계**: 문제가 발생하는 정확한 단계
4. **시도한 해결 방법**: 이미 시도한 해결 방법들
5. **로그 파일**: 관련 로그 파일들

---

**💡 팁**: 대부분의 문제는 시스템 재부팅이나 환경 재설치로 해결됩니다. 문제가 지속되면 `./restore.sh`를 실행하여 환경을 완전히 재설치해보세요. 