# Galaxy Android용 Cursor AI IDE 설치 가이드

## 📋 **목차**
1. [시스템 요구사항](#시스템-요구사항)
2. [빠른 시작](#빠른-시작)
3. [설치 방법](#설치-방법)
4. [GUI 설정](#gui-설정)
5. [문제 해결](#문제-해결)
6. [사용법](#사용법)
7. [성능 최적화](#성능-최적화)

---

## 🖥️ **시스템 요구사항**

### **최소 요구사항**
- **Android 버전**: 10+ (권장: Android 13+)
- **아키텍처**: ARM64 (aarch64)
- **메모리**: 최소 4GB RAM
- **저장공간**: 최소 10GB 여유 공간
- **기기**: Samsung Galaxy 시리즈 (권장)

### **권장 사양**
- **Android 버전**: 14+
- **메모리**: 8GB+ RAM
- **저장공간**: 20GB+ 여유 공간
- **네트워크**: Wi-Fi 연결 (안정적인 인터넷)

### **지원되지 않는 환경**
- ❌ x86/x64 아키텍처
- ❌ Android 9 이하
- ❌ 루팅된 기기 (권장하지 않음)
- ❌ 에뮬레이터 (실제 기기 권장)

---

## 🚀 **빠른 시작**

### **1단계: Termux 설치**
```bash
# F-Droid에서 Termux 설치
# https://f-droid.org/packages/com.termux/
```

### **2단계: 프로젝트 다운로드**
```bash
# 프로젝트 클론
git clone https://github.com/huntkil/mobile_ide.git
cd mobile_ide
```

### **3단계: 자동 설치**
```bash
# 자동 설치 실행
chmod +x scripts/termux_local_setup.sh
./scripts/termux_local_setup.sh
```

### **4단계: Cursor AI 실행**
```bash
# Cursor AI 실행
./run_cursor_fixed.sh
```

### **5단계: GUI 화면 보기 (선택사항)**
```bash
# VNC 서버 설치
pkg install x11vnc

# VNC 서버 시작
vncserver :1 -geometry 1024x768 -depth 24

# Android VNC Viewer 앱에서 localhost:5901 접속
```

---

## 📦 **설치 방법**

### **방법 1: 완전 자동 설치 (권장)**

#### **새로운 사용자를 위한 완전 자동 설치**
```bash
# 1. 프로젝트 다운로드
git clone https://github.com/huntkil/mobile_ide.git
cd mobile_ide

# 2. 자동 설치 실행
./scripts/termux_local_setup.sh

# 3. 설치 완료 확인
ls -la ~/launch.sh ~/run_cursor_fixed.sh

# 4. Cursor AI 실행
./run_cursor_fixed.sh
```

#### **기존 환경 문제가 있는 경우 완전 초기화**
```bash
# 1. 완전 초기화 및 재설치
./scripts/complete_reset.sh

# 2. 자동 설치 실행
./scripts/termux_local_setup.sh

# 3. Cursor AI 실행
./run_cursor_fixed.sh
```

### **방법 2: 수동 설치**

#### **1단계: Termux 환경 설정**
```bash
# 패키지 업데이트
pkg update -y
pkg upgrade -y

# 필수 패키지 설치
pkg install -y proot-distro curl wget proot tar unzip git

# 저장공간 설정
termux-setup-storage
```

#### **2단계: Ubuntu 환경 설치**
```bash
# Ubuntu 22.04 LTS 설치
proot-distro install ubuntu

# Ubuntu 환경 진입
proot-distro login ubuntu
```

#### **3단계: Ubuntu 환경 설정**
```bash
# 패키지 업데이트
apt update

# 필수 패키지 설치
apt install -y curl wget git build-essential python3 python3-pip

# X11 관련 패키지 설치
apt install -y xvfb x11-apps x11-utils x11-xserver-utils dbus-x11

# Node.js 설치
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# npm 호환성 문제 해결
npm install -g npm@10.8.2
npm cache clean --force

# 작업 디렉토리 생성
mkdir -p /home/cursor-ide
cd /home/cursor-ide
```

#### **4단계: Cursor AI 설치**
```bash
# AppImage 다운로드 (ARM64)
wget -O cursor.AppImage "https://download.cursor.sh/linux/appImage/arm64"

# 실행 권한 부여
chmod +x cursor.AppImage

# AppImage 추출
./cursor.AppImage --appimage-extract
```

#### **5단계: 실행 스크립트 생성**
```bash
# Ubuntu 환경에서 실행할 스크립트
cat > /home/cursor-ide/start.sh << 'EOF'
#!/bin/bash
export DISPLAY=:0
export XDG_RUNTIME_DIR="$HOME/.runtime-cursor"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

Xvfb :0 -screen 0 1024x768x16 -ac +extension GLX +render -noreset &
sleep 3

./squashfs-root/AppRun --no-sandbox --disable-gpu --single-process --disable-dev-shm-usage &
EOF

chmod +x /home/cursor-ide/start.sh
```

#### **6단계: Termux에서 실행 스크립트 생성**
```bash
# Termux에서 실행할 스크립트
cat > ~/launch.sh << 'EOF'
#!/bin/bash
proot-distro login ubuntu -- bash /home/cursor-ide/start.sh
EOF

chmod +x ~/launch.sh
```

### **방법 3: 외부 저장소 활용 설치**

#### **저장공간이 부족한 경우**
```bash
# 1. 외부 저장소 설정
termux-setup-storage
mkdir -p ~/storage/shared/TermuxWork
cd ~/storage/shared/TermuxWork

# 2. 프로젝트 다운로드
git clone https://github.com/huntkil/mobile_ide.git
cd mobile_ide

# 3. 저장공간 정리
./cleanup.sh

# 4. 자동 설치 실행
./scripts/termux_local_setup.sh
```

---

## 🖥️ **GUI 설정**

### **VNC 서버 설정 (권장)**

#### **1단계: VNC 서버 설치**
```bash
# VNC 서버 패키지 검색
pkg search vnc

# VNC 서버 설치 (여러 대안 시도)
pkg install x11vnc || pkg install tightvncserver || pkg install tigervnc
```

#### **2단계: VNC 서버 시작**
```bash
# VNC 서버 시작
vncserver :1 -geometry 1024x768 -depth 24 -localhost no

# 비밀번호 설정 (선택사항)
# 기본 비밀번호: cursor123
```

#### **3단계: Android VNC Viewer 설치**
1. **Google Play Store**에서 "VNC Viewer" 검색
2. **RealVNC VNC Viewer** 또는 **bVNC Free** 설치
3. 앱에서 **localhost:5901** 접속
4. 비밀번호 입력: **cursor123**

### **VNC 지원 실행 스크립트**
```bash
# VNC 지원 실행 스크립트 생성
cat > ~/run_cursor_vnc.sh << 'EOF'
#!/bin/bash
export DISPLAY=:1

# VNC 서버 시작
vncserver :1 -geometry 1024x768 -depth 24 -localhost no &
sleep 3

# Cursor AI 실행
cd ~
./squashfs-root/AppRun --no-sandbox --disable-gpu --single-process --disable-dev-shm-usage &

echo "VNC Viewer 앱으로 localhost:5901에 접속하세요"
echo "비밀번호: cursor123"
EOF

chmod +x ~/run_cursor_vnc.sh
./run_cursor_vnc.sh
```

### **헤드리스 모드 (VNC 없이)**

#### **백그라운드 실행**
```bash
# 헤드리스 모드 실행 스크립트
cat > ~/run_cursor_headless.sh << 'EOF'
#!/bin/bash
cd ~
export DISPLAY=:0

# Xvfb 시작
Xvfb :0 -screen 0 1024x768x16 -ac +extension GLX +render -noreset &
sleep 3

# Cursor AI 백그라운드 실행
./squashfs-root/AppRun --no-sandbox --disable-gpu --single-process --disable-dev-shm-usage &
CURSOR_PID=$!

echo "Cursor AI가 백그라운드에서 실행 중입니다 (PID: $CURSOR_PID)"
echo "종료하려면: kill $CURSOR_PID"
EOF

chmod +x ~/run_cursor_headless.sh
./run_cursor_headless.sh
```

---

## 🔧 **문제 해결**

### **저장공간 부족 문제**

#### **증상**
```bash
No space left on device
/dev/block/dm-6   6.3G 6.3G  2.0M 100% /
```

#### **해결 방법**
```bash
# 1. 긴급 정리
./cleanup.sh

# 2. 수동 정리
pkg clean
pkg autoclean
rm -rf /tmp/*
rm -rf ~/.cache/*
find ~ -name "*.log" -type f -size +10M -delete

# 3. Android 시스템 정리
# 설정 → 디바이스 케어 → 저장공간 → 정리 실행

# 4. 외부 저장소 활용
termux-setup-storage
mkdir -p ~/storage/shared/TermuxWork
```

### **GUI 화면 표시 문제**

#### **증상**
- Cursor AI가 실행되지만 화면이 보이지 않음

#### **해결 방법**
```bash
# 1. VNC 서버 설치
pkg install x11vnc

# 2. VNC 서버 시작
vncserver :1 -geometry 1024x768 -depth 24

# 3. Android VNC Viewer 앱 설치 후 localhost:5901 접속
```

### **네트워크 DNS 해석 실패**

#### **증상**
```bash
wget: unable to resolve host address 'download.cursor.sh'
```

#### **해결 방법**
```bash
# 1. DNS 서버 설정
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf

# 2. 네트워크 연결 테스트
ping -c 3 google.com

# 3. 기존 AppImage 활용
cp ~/Cursor-1.2.1-aarch64.AppImage ~/cursor.AppImage
```

### **권한 문제**

#### **증상**
```bash
bash: ./cursor.AppImage: Permission denied
```

#### **해결 방법**
```bash
# 1. 파일을 내부 저장소로 복사
cp ~/storage/shared/TermuxWork/cursor.AppImage ~/cursor.AppImage

# 2. 실행 권한 부여
chmod +x ~/cursor.AppImage

# 3. 실행
./cursor.AppImage --appimage-extract
```

### **VNC 패키지 부재 문제**

#### **증상**
```bash
E: Unable to locate package tigervnc
```

#### **해결 방법**
```bash
# 1. 사용 가능한 VNC 패키지 검색
pkg search vnc
pkg search x11

# 2. 대안 VNC 패키지 설치
pkg install x11vnc || pkg install tightvncserver

# 3. VNC 없이 헤드리스 모드 실행
./run_cursor_headless.sh
```

### **스크립트 문법 오류**

#### **증상**
```bash
./run_cursor.sh: line 16: : command not found
```

#### **해결 방법**
```bash
# 1. 잘못된 스크립트 삭제
rm -f ~/run_cursor.sh

# 2. 올바른 스크립트 재생성
# 위의 "실행 스크립트 생성" 섹션 참조

# 3. 문법 검사
bash -n ~/run_cursor.sh
```

---

## 📱 **사용법**

### **기본 실행**
```bash
# 권한 문제 해결된 실행 (권장)
./run_cursor_fixed.sh

# Ubuntu 환경에서 실행
./launch.sh

# VNC 지원 실행
./run_cursor_vnc.sh

# 헤드리스 모드 실행
./run_cursor_headless.sh
```

### **프로젝트 관리**
```bash
# 새 프로젝트 생성
mkdir ~/projects/my-project
cd ~/projects/my-project

# Cursor AI에서 프로젝트 열기
# File → Open Folder → ~/projects/my-project
```

### **프로세스 관리**
```bash
# 실행 중인 프로세스 확인
ps aux | grep -E "(cursor|AppRun)" | grep -v grep

# 프로세스 종료
kill [PID]

# 모든 Cursor AI 프로세스 종료
pkill -f "cursor"
```

### **로그 확인**
```bash
# 시스템 로그 확인
dmesg | tail -20

# Termux 로그 확인
logcat | grep termux

# Ubuntu 환경 로그 확인
proot-distro login ubuntu -- journalctl -f
```

---

## ⚡ **성능 최적화**

### **메모리 최적화**
```bash
# 메모리 캐시 정리
echo 3 > /proc/sys/vm/drop_caches

# 메모리 상태 확인
free -h

# 불필요한 프로세스 종료
pkill -f "Xvfb"
```

### **CPU 최적화**
```bash
# CPU 성능 모드 설정
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# CPU 사용량 확인
top -n 1

# 배터리 최적화 비활성화
dumpsys deviceidle disable
```

### **저장공간 최적화**
```bash
# 정기적인 정리
./cleanup.sh

# 대용량 파일 찾기
find ~ -type f -size +100M -exec ls -lh {} \;

# 로그 파일 정리
find ~ -name "*.log" -type f -size +10M -delete
```

### **네트워크 최적화**
```bash
# DNS 캐시 정리
nscd -i hosts

# 네트워크 연결 확인
ping -c 3 google.com

# 프록시 설정 (필요한 경우)
export http_proxy=http://proxy:port
export https_proxy=http://proxy:port
```

---

## 🔍 **진단 및 모니터링**

### **시스템 진단**
```bash
# 시스템 정보 확인
uname -a
getprop ro.build.version.release
free -h
df -h

# 네트워크 확인
ping google.com
nslookup google.com

# 프로세스 확인
ps aux | grep -E "(cursor|Xvfb|vnc)"
```

### **설치 상태 확인**
```bash
# Ubuntu 환경 확인
proot-distro list
ls -la ~/ubuntu

# Cursor AI 확인
ls -la ~/ubuntu/home/cursor-ide/

# 실행 스크립트 확인
ls -la ~/launch.sh ~/run_cursor_fixed.sh
```

### **성능 모니터링**
```bash
# 실시간 시스템 모니터링
htop

# 디스크 사용량 모니터링
iotop

# 네트워크 모니터링
iftop
```

---

## 📞 **지원 및 문의**

### **문제 보고**
- **GitHub Issues**: [프로젝트 이슈 페이지](https://github.com/huntkil/mobile_ide/issues)
- **이메일**: huntkil@github.com

### **커뮤니티**
- **Discord**: [Mobile IDE Community](https://discord.gg/mobile-ide)
- **Reddit**: r/mobile_ide

### **문서**
- **완전 설치 가이드**: [docs/COMPLETE_SETUP_GUIDE.md](docs/COMPLETE_SETUP_GUIDE.md)
- **문제 해결**: [docs/troubleshooting.md](docs/troubleshooting.md)
- **오류 데이터베이스**: [docs/ERROR_DATABASE.md](docs/ERROR_DATABASE.md)
- **개발 가이드**: [docs/DEVELOPMENT_GUIDE.md](docs/DEVELOPMENT_GUIDE.md)

### **로그 수집**
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

---

## 🎯 **권장사항**

### **성공적인 설치를 위한 팁**
1. **완전 초기화**: 기존 환경을 완전히 정리하고 새로 시작
2. **충분한 저장공간**: 최소 10GB 이상의 여유 공간 확보
3. **안정적인 네트워크**: Wi-Fi 연결로 안정적인 다운로드
4. **VNC 서버**: GUI 화면을 보려면 VNC 서버 설정 필수
5. **정기적인 정리**: `cleanup.sh`로 정기적인 저장공간 정리

### **성능 최적화 팁**
1. **메모리 관리**: 정기적인 메모리 캐시 정리
2. **CPU 최적화**: 성능 모드 설정으로 빠른 실행
3. **저장공간 관리**: 대용량 파일 정기 정리
4. **네트워크 최적화**: 안정적인 DNS 설정

### **사용 팁**
1. **프로젝트 관리**: 외부 저장소 활용으로 대용량 프로젝트 관리
2. **VNC 사용**: 모바일 친화적인 VNC Viewer 앱 사용
3. **백업**: 중요한 프로젝트는 정기적으로 백업
4. **업데이트**: 최신 버전으로 정기 업데이트

---

**🔄 최신 업데이트**: v3.1.1 (2025-07-27) - 모든 알려진 문제 해결 완료!

**💡 핵심 메시지**: 지속적인 문제가 발생한다면 **완전 초기화**를 통해 새로 시작하는 것을 강력히 권장합니다!

**🚀 빠른 시작**: `./scripts/complete_reset.sh` → `./scripts/termux_local_setup.sh` → `./run_cursor_fixed.sh` 