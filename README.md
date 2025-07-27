# Galaxy Android용 Cursor AI IDE

## 🚀 **최신 버전 v3.1.1 업데이트 완료!**

**모든 알려진 문제가 해결되었습니다!** 🎉

### ✅ **해결된 문제들**
- ✅ 스크립트 문법 오류 수정
- ✅ 권한 문제 해결 (XDG_RUNTIME_DIR)
- ✅ VNC 서버 통합
- ✅ 네트워크 DNS 해석 실패 해결
- ✅ 외부 저장소 실행 권한 제한 해결
- ✅ 저장공간 부족 문제 해결
- ✅ GUI 화면 표시 문제 해결

---

## 📱 프로젝트 개요

Samsung Galaxy Android 기기에서 **Cursor AI IDE**를 실행하기 위한 완전한 솔루션입니다. Termux 기반 Linux 환경을 통해 모바일에서도 강력한 개발 환경을 제공합니다.

### 🎯 주요 기능
- **완전 자동화된 설치**: 원클릭 설치 스크립트
- **모바일 최적화**: 터치 인터페이스 및 배터리 최적화
- **VNC 서버 통합**: Android VNC Viewer를 통한 GUI 표시
- **오프라인 지원**: 로컬 AppImage 파일 활용
- **자동 복구**: 문제 발생 시 자동 해결

### 🛠️ 지원 환경
- **OS**: Android 10+ (API 29+)
- **아키텍처**: ARM64 (aarch64)
- **기기**: Samsung Galaxy 시리즈
- **메모리**: 최소 4GB, 권장 8GB+
- **저장공간**: 최소 10GB, 권장 20GB+

---

## 🚀 **빠른 시작 (v3.1.1)**

### 1단계: 최신 버전 받기
```bash
# 기존 설치가 있다면 최신 버전으로 업데이트
cd ~/mobile_ide
git pull origin main

# 또는 새로 클론
git clone https://github.com/huntkil/mobile_ide.git
cd mobile_ide
```

### 2단계: 완전 설치
```bash
# 자동 설치 스크립트 실행 (모든 문제 해결됨)
./scripts/termux_local_setup.sh
```

### 3단계: Cursor AI 실행
```bash
# 권한 문제 해결된 실행 스크립트
./run_cursor_fixed.sh

# 또는 Ubuntu 환경에서 실행
./launch.sh
```

### 4단계: GUI 화면 보기 (선택사항)
```bash
# VNC 서버 설치
pkg install x11vnc

# VNC 서버 시작
vncserver :1 -geometry 1024x768 -depth 24

# Android VNC Viewer 앱에서 localhost:5901 접속
```

---

## 📦 설치 방법

### 자동 설치 (권장)
```bash
# 1. 프로젝트 클론
git clone https://github.com/huntkil/mobile_ide.git
cd mobile_ide

# 2. 자동 설치 실행
./scripts/termux_local_setup.sh

# 3. 설치 완료 확인
ls -la ~/launch.sh ~/run_cursor_fixed.sh
```

### 수동 설치
```bash
# 1. Termux 필수 패키지 설치
pkg update -y
pkg install -y proot-distro curl wget proot tar unzip

# 2. Ubuntu 환경 설치
proot-distro install ubuntu

# 3. Ubuntu 환경 설정
proot-distro login ubuntu -- bash -c "
apt update
apt install -y curl wget git build-essential python3 python3-pip
apt install -y xvfb x11-apps x11-utils x11-xserver-utils dbus-x11
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs
"

# 4. Cursor AI 설치
proot-distro login ubuntu -- bash -c "
mkdir -p /home/cursor-ide
cd /home/cursor-ide
wget -O cursor.AppImage 'https://download.cursor.sh/linux/appImage/arm64'
chmod +x cursor.AppImage
./cursor.AppImage --appimage-extract
"
```

---

## 🔧 사용법

### 기본 실행
```bash
# 권한 문제 해결된 실행 (권장)
./run_cursor_fixed.sh

# Ubuntu 환경에서 실행
./launch.sh

# 프로세스 확인
ps aux | grep -E "(cursor|AppRun)" | grep -v grep
```

### VNC를 통한 GUI 표시
```bash
# 1. VNC 서버 설치
pkg install x11vnc

# 2. VNC 서버 시작
vncserver :1 -geometry 1024x768 -depth 24

# 3. Android VNC Viewer 앱 설치
# Google Play Store에서 "VNC Viewer" 검색

# 4. VNC 접속
# 앱에서 localhost:5901 접속
# 비밀번호: cursor123
```

### 프로젝트 관리
```bash
# 새 프로젝트 생성
mkdir ~/projects/my-project
cd ~/projects/my-project

# Cursor AI에서 프로젝트 열기
# File → Open Folder → ~/projects/my-project
```

---

## 🛠️ 문제 해결

### 일반적인 문제들

#### 1. 저장공간 부족
```bash
# 긴급 정리
./cleanup.sh

# 또는 수동 정리
pkg clean
rm -rf ~/.cache/*
df -h
```

#### 2. 네트워크 연결 문제
```bash
# DNS 설정
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf

# 연결 테스트
ping google.com
```

#### 3. 권한 문제
```bash
# 실행 권한 확인
chmod +x ~/run_cursor_fixed.sh
chmod +x ~/launch.sh

# 외부 저장소에서 내부로 복사
cp ~/storage/shared/TermuxWork/cursor.AppImage ~/cursor.AppImage
```

#### 4. GUI 화면이 보이지 않음
```bash
# VNC 서버 설정
pkg install x11vnc
vncserver :1 -geometry 1024x768 -depth 24

# Android VNC Viewer 앱으로 localhost:5901 접속
```

### 자동 복구
```bash
# 설치 문제 자동 해결
./scripts/fix_installation.sh

# 환경 완전 복구
./scripts/termux_perfect_restore.sh
```

---

## 📊 성능 최적화

### 메모리 최적화
```bash
# 메모리 캐시 정리
echo 3 > /proc/sys/vm/drop_caches

# 불필요한 프로세스 종료
pkill -f "chrome"
pkill -f "firefox"
```

### 배터리 최적화
```bash
# 배터리 최적화 비활성화
dumpsys deviceidle disable

# CPU 성능 모드
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
```

### 저장공간 최적화
```bash
# 자동 정리 스크립트
./cleanup.sh

# 외부 저장소 활용
termux-setup-storage
mkdir -p ~/storage/shared/TermuxWork
```

---

## 🔍 디버깅

### 시스템 정보 확인
```bash
# 시스템 진단
./debug.sh

# 상세 정보
uname -a
free -h
df -h
```

### 로그 확인
```bash
# Cursor AI 로그
tail -f ~/.cursor/logs/main.log

# 시스템 로그
logcat | grep termux
```

### 프로세스 확인
```bash
# 실행 중인 프로세스
ps aux | grep -E "(cursor|Xvfb|vnc)"

# 포트 사용 확인
netstat -tlnp
```

---

## 📚 문서

### 상세 가이드
- [📖 설치 가이드](docs/installation.md)
- [🔧 문제 해결](docs/troubleshooting.md)
- [📋 개발 가이드](docs/DEVELOPMENT_GUIDE.md)
- [❌ 오류 데이터베이스](docs/ERROR_DATABASE.md)
- [📝 스크립트 템플릿](docs/SCRIPT_TEMPLATES.md)

### 스크립트 목록
- `scripts/termux_local_setup.sh` - 메인 설치 스크립트 (v3.1.1)
- `scripts/cleanup.sh` - 저장공간 정리
- `scripts/fix_installation.sh` - 설치 문제 해결
- `run_cursor_fixed.sh` - 권한 문제 해결된 실행 스크립트
- `launch.sh` - Ubuntu 환경 실행 스크립트

---

## 🤝 기여하기

### 버그 리포트
- [GitHub Issues](https://github.com/huntkil/mobile_ide/issues)에서 버그 리포트
- 상세한 오류 메시지와 시스템 정보 포함

### 기능 요청
- 새로운 기능 아이디어 제안
- 개선 사항 제안

### 코드 기여
- Pull Request 환영
- 코드 리뷰 및 테스트 참여

---

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

---

## 🙏 감사의 말

- **Termux** 팀 - Android용 Linux 환경 제공
- **Cursor AI** 팀 - 강력한 AI 기반 IDE 개발
- **Ubuntu** 팀 - 안정적인 Linux 배포판 제공
- **커뮤니티** - 버그 리포트 및 개선 제안

---

## 📞 지원

### 연락처
- **GitHub**: [huntkil/mobile_ide](https://github.com/huntkil/mobile_ide)
- **이메일**: huntkil@github.com
- **문서**: [docs/](docs/) 디렉토리

### 커뮤니티
- **Discord**: [Mobile IDE Community](https://discord.gg/mobile-ide)
- **Reddit**: r/mobile_ide

---

**⭐ 이 프로젝트가 도움이 되었다면 스타를 눌러주세요!**

**🔄 최신 업데이트**: v3.1.1 (2025-07-27) - 모든 알려진 문제 해결 완료! 