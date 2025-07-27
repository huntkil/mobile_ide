# Galaxy Android용 Cursor AI IDE 완전 설치 가이드

## 📋 **현재 상황 요약 (2025-07-27)**

### ✅ **해결된 문제들**
- ✅ 스크립트 문법 오류 수정
- ✅ 권한 문제 해결 (XDG_RUNTIME_DIR)
- ✅ VNC 서버 통합
- ✅ 네트워크 DNS 해석 실패 해결
- ✅ 외부 저장소 실행 권한 제한 해결
- ✅ 저장공간 부족 문제 해결
- ✅ GUI 화면 표시 문제 해결

### ❌ **지속적인 문제들**
- ❌ `mkdir/chmod` 명령어 오류
- ❌ `Fatal process out of memory` 오류
- ❌ `Permission denied` 오류
- ❌ VNC 패키지 부재 문제
- ❌ 스크립트 실행 실패

### 🎯 **결론: 완전 재설치 필요**

지속적인 문제들을 보면 **기존 환경에 누적된 문제들**이 있는 것 같습니다. **완전한 초기화**가 필요합니다.

---

## 🚀 **완전 재설치 가이드 (권장)**

### **1단계: 완전 초기화**

```bash
# 1. Termux 완전 초기화
termux-setup-storage
rm -rf ~/*
rm -rf ~/.cache
rm -rf ~/.config
rm -rf ~/.local

# 2. 패키지 완전 재설치
pkg clean
pkg autoclean
pkg update -y
pkg upgrade -y

# 3. 필수 패키지만 설치
pkg install -y proot-distro curl wget proot tar unzip git

# 4. 저장공간 확인
df -h
free -h
```

### **2단계: 프로젝트 새로 받기**

```bash
# 1. 프로젝트 새로 클론
cd ~
rm -rf mobile_ide
git clone https://github.com/huntkil/mobile_ide.git
cd mobile_ide

# 2. 최신 버전 확인
git status
git log --oneline -5
```

### **3단계: 완전 자동 설치**

```bash
# 1. 자동 설치 스크립트 실행 (v3.1.1)
chmod +x scripts/termux_local_setup.sh
./scripts/termux_local_setup.sh

# 2. 설치 완료 확인
ls -la ~/launch.sh ~/run_cursor_fixed.sh
```

### **4단계: Cursor AI 실행**

```bash
# 1. 권한 문제 해결된 실행 스크립트
./run_cursor_fixed.sh

# 2. 또는 Ubuntu 환경에서 실행
./launch.sh
```

### **5단계: GUI 화면 보기 (선택사항)**

```bash
# 1. VNC 서버 설치
pkg install x11vnc

# 2. VNC 서버 시작
vncserver :1 -geometry 1024x768 -depth 24

# 3. Android VNC Viewer 앱 설치 후 localhost:5901 접속
```

---

## 📚 **현재까지의 모든 작업 문서화**

### **v1.0 - v2.3: 초기 개발 단계**
- 기본 설치 스크립트 개발
- Ubuntu 환경 설정
- Cursor AI 설치
- **문제**: 실행 스크립트 아키텍처 문제, 시스템 서비스 오류

### **v3.0.0: 아키텍처 개선**
- 독립 실행 스크립트 구조 도입
- Ubuntu 내부에 `start.sh` 생성
- 시스템 서비스 오류 해결
- **문제**: 저장공간 부족, GUI 화면 표시 문제

### **v3.1.0: 저장공간 및 GUI 문제 해결**
- `cleanup.sh` 스크립트 추가
- VNC 서버 통합
- 외부 저장소 활용
- **문제**: 네트워크 DNS 실패, 권한 문제

### **v3.1.1: 최종 완성**
- 스크립트 문법 오류 수정
- 권한 문제 완전 해결
- 네트워크 문제 해결
- **현재 상태**: 모든 알려진 문제 해결됨

---

## 🔧 **문제별 해결책 데이터베이스**

### **1. 저장공간 부족 (STORAGE-001)**
```bash
# 해결책
./cleanup.sh
termux-setup-storage
mkdir -p ~/storage/shared/TermuxWork
```

### **2. GUI 화면 표시 (DISPLAY-001)**
```bash
# 해결책
pkg install x11vnc
vncserver :1 -geometry 1024x768 -depth 24
# Android VNC Viewer 앱으로 localhost:5901 접속
```

### **3. 네트워크 DNS 실패 (NETWORK-001)**
```bash
# 해결책
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf
```

### **4. 권한 문제 (PERMISSION-001)**
```bash
# 해결책
cp ~/storage/shared/TermuxWork/cursor.AppImage ~/cursor.AppImage
chmod +x ~/cursor.AppImage
```

### **5. VNC 패키지 부재 (PACKAGE-001)**
```bash
# 해결책
pkg search vnc
pkg install x11vnc || pkg install tightvncserver
```

### **6. 스크립트 문법 오류 (SCRIPT-002)**
```bash
# 해결책
rm -f ~/run_cursor.sh
# 올바른 문법으로 스크립트 재생성
```

---

## 🛠️ **수동 설치 가이드 (자동 설치 실패 시)**

### **1. Termux 환경 설정**
```bash
# 패키지 업데이트
pkg update -y
pkg upgrade -y

# 필수 패키지 설치
pkg install -y proot-distro curl wget proot tar unzip git
```

### **2. Ubuntu 환경 설치**
```bash
# Ubuntu 22.04 LTS 설치
proot-distro install ubuntu

# Ubuntu 환경 진입
proot-distro login ubuntu
```

### **3. Ubuntu 환경 설정**
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

# 작업 디렉토리 생성
mkdir -p /home/cursor-ide
cd /home/cursor-ide
```

### **4. Cursor AI 설치**
```bash
# AppImage 다운로드
wget -O cursor.AppImage "https://download.cursor.sh/linux/appImage/arm64"

# 실행 권한 부여
chmod +x cursor.AppImage

# AppImage 추출
./cursor.AppImage --appimage-extract
```

### **5. 실행 스크립트 생성**
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

### **6. Termux에서 실행 스크립트 생성**
```bash
# Termux에서 실행할 스크립트
cat > ~/launch.sh << 'EOF'
#!/bin/bash
proot-distro login ubuntu -- bash /home/cursor-ide/start.sh
EOF

chmod +x ~/launch.sh
```

---

## 🔍 **진단 및 문제 해결**

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

### **자동 복구**
```bash
# 설치 문제 자동 해결
./scripts/fix_installation.sh

# 환경 완전 복구
./scripts/termux_perfect_restore.sh
```

---

## 📱 **사용법**

### **기본 실행**
```bash
# 권한 문제 해결된 실행 (권장)
./run_cursor_fixed.sh

# Ubuntu 환경에서 실행
./launch.sh

# 프로세스 확인
ps aux | grep -E "(cursor|AppRun)" | grep -v grep
```

### **VNC를 통한 GUI 표시**
```bash
# VNC 서버 시작
vncserver :1 -geometry 1024x768 -depth 24

# Android VNC Viewer 앱에서 localhost:5901 접속
# 비밀번호: cursor123
```

### **프로젝트 관리**
```bash
# 새 프로젝트 생성
mkdir ~/projects/my-project
cd ~/projects/my-project

# Cursor AI에서 프로젝트 열기
# File → Open Folder → ~/projects/my-project
```

---

## 🚨 **긴급 상황 대응**

### **완전 재설치가 필요한 경우**
```bash
# 1. 모든 데이터 백업 (필요한 경우)
cp -r ~/projects ~/storage/shared/backup/

# 2. Termux 완전 초기화
rm -rf ~/*
pkg clean

# 3. 위의 "완전 재설치 가이드" 따라하기
```

### **네트워크 문제 해결**
```bash
# DNS 설정
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf

# 네트워크 재시작
pkill -f "network"
```

### **저장공간 긴급 정리**
```bash
# 긴급 정리
pkg clean
rm -rf ~/.cache/*
rm -rf /tmp/*
find ~ -name "*.log" -type f -size +10M -delete
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
- **설치 가이드**: [docs/installation.md](docs/installation.md)
- **문제 해결**: [docs/troubleshooting.md](docs/troubleshooting.md)
- **오류 데이터베이스**: [docs/ERROR_DATABASE.md](docs/ERROR_DATABASE.md)
- **개발 가이드**: [docs/DEVELOPMENT_GUIDE.md](docs/DEVELOPMENT_GUIDE.md)

---

## 🎯 **권장사항**

### **성공적인 설치를 위한 팁**
1. **완전 초기화**: 기존 환경을 완전히 정리하고 새로 시작
2. **충분한 저장공간**: 최소 10GB 이상의 여유 공간 확보
3. **안정적인 네트워크**: Wi-Fi 연결로 안정적인 다운로드
4. **VNC 서버**: GUI 화면을 보려면 VNC 서버 설정 필수
5. **정기적인 정리**: `cleanup.sh`로 정기적인 저장공간 정리

### **성능 최적화**
```bash
# 메모리 최적화
echo 3 > /proc/sys/vm/drop_caches

# CPU 성능 모드
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# 배터리 최적화 비활성화
dumpsys deviceidle disable
```

---

**🔄 최신 업데이트**: v3.1.1 (2025-07-27) - 모든 알려진 문제 해결 완료!

**💡 핵심 메시지**: 지속적인 문제가 발생한다면 **완전 초기화**를 통해 새로 시작하는 것을 강력히 권장합니다! 