# Galaxy Android용 Cursor AI IDE 설치 가이드

## 📋 사전 요구사항

### 하드웨어 요구사항
- **RAM**: 최소 4GB (8GB 권장)
- **저장공간**: 최소 10GB (15GB 권장)
- **CPU**: ARM64 아키텍처 (Exynos, Snapdragon)
- **화면**: 최소 6인치 (터치 인터페이스 최적화)

### 소프트웨어 요구사항
- **Android**: 7.0 (API 24) 이상
- **Termux**: 최신 버전 (F-Droid에서 설치)
- **인터넷**: 안정적인 Wi-Fi 또는 모바일 데이터 연결

## 🚀 설치 과정

### 1단계: Termux 설치

1. **F-Droid 설치** (Google Play Store 대신 사용)
   - [F-Droid 공식 사이트](https://f-droid.org/)에서 APK 다운로드
   - 알 수 없는 소스 설치 허용
   - F-Droid 설치 및 실행

2. **Termux 설치**
   - F-Droid에서 "Termux" 검색
   - 최신 버전 설치
   - 설치 완료 후 Termux 실행

### 2단계: 자동 설치 스크립트 실행

```bash
# 로컬 AppImage 설치 (권장)
./scripts/termux_local_setup.sh

# 또는 온라인 다운로드 설치
./scripts/termux_complete_setup.sh

# 또는 최소 설치
./scripts/termux_minimal_setup.sh
```

### 3단계: 설치 과정 모니터링

설치 과정에서 다음과 같은 단계들이 진행됩니다:

1. **시스템 정보 확인**
   - Android 버전, 아키텍처, 메모리 확인
   - 저장공간 충분성 검증

2. **의존성 설치**
   - curl, wget, proot, tar, unzip 설치
   - proot-distro 설치

3. **Ubuntu 환경 구축**
   - Ubuntu 22.04 LTS 다운로드 (약 1-2GB)
   - 필수 패키지 설치 (Node.js, npm, git 등)
   - X11 환경 설정

4. **Cursor AI 설치**
   - ARM64 AppImage 다운로드
   - 실행 권한 설정
   - 모바일 최적화 설정 적용

### 4단계: 설치 완료 확인

```bash
# 설치 상태 확인
ls -la ~/ubuntu/home/cursor-ide/

# Cursor AI 실행
./launch.sh
```

## ⚙️ 수동 설치 (자동 설치 실패 시)

### 1. Termux 환경 설정

```bash
# 패키지 업데이트
pkg update -y

# 필수 패키지 설치
pkg install -y curl wget proot tar unzip proot-distro
```

### 2. Ubuntu 설치

```bash
# Ubuntu 22.04 설치
proot-distro install ubuntu

# Ubuntu 환경 진입
proot-distro login ubuntu
```

### 3. Ubuntu 환경 설정

```bash
# 패키지 목록 업데이트
apt update

# 필수 패키지 설치
apt install -y curl wget git build-essential python3 python3-pip nodejs npm

# Node.js 최신 버전 설치
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs

# X11 관련 패키지 설치
apt install -y xvfb x11-apps x11-utils x11-xserver-utils dbus-x11

# 작업 디렉토리 생성
mkdir -p /home/cursor-ide
cd /home/cursor-ide
```

### 4. Cursor AI 설치

```bash
# Cursor AI 다운로드
wget -O cursor.AppImage "https://download.cursor.sh/linux/appImage/arm64"

# 실행 권한 부여
chmod +x cursor.AppImage

# AppImage 추출
./cursor.AppImage --appimage-extract
```

## 🔧 설정 및 최적화

### 성능 최적화

```bash
# 성능 최적화 실행
cd ~/cursor-ide
./optimize.sh

# 또는 수동 최적화
# 메모리 캐시 정리
echo 3 > /proc/sys/vm/drop_caches

# CPU 성능 모드 설정
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# 배터리 최적화 비활성화 (성능 우선)
dumpsys deviceidle disable
```

### Cursor AI 설정 커스터마이징

```bash
# 설정 파일 편집
nano ~/ubuntu/home/cursor-ide/cursor-config.json

# 주요 설정 옵션:
# - editor.fontSize: 폰트 크기
# - window.zoomLevel: UI 확대/축소
# - workbench.colorTheme: 테마 변경
```

## 🐛 문제 해결

### 일반적인 문제들

#### 1. 메모리 부족 오류
```bash
# 메모리 상태 확인
free -h

# 다른 앱 종료 후 재시도
# 또는 가상 메모리 증가
```

#### 2. 저장공간 부족
```bash
# 저장공간 확인
df -h

# 불필요한 파일 정리
apt clean
apt autoremove -y
```

#### 3. 네트워크 연결 문제
```bash
# 네트워크 상태 확인
ping google.com

# DNS 설정 확인
cat /etc/resolv.conf
```

#### 4. X11 서버 오류
```bash
# Xvfb 프로세스 확인
ps aux | grep Xvfb

# X11 서버 재시작
pkill Xvfb
Xvfb :0 -screen 0 1200x800x24 &
```

### 환경 복구

```bash
# 환경 복구 실행
./scripts/termux_perfect_restore.sh

# 또는 안전 복구
./scripts/termux_safe_restore.sh

# 또는 수동 복구
rm -rf ~/ubuntu
proot-distro install ubuntu
# 위의 수동 설치 과정 반복
```

## 📱 사용법

### 기본 사용법

1. **Cursor AI 실행**
   ```bash
   cd ~/cursor-ide
   ./launch.sh
   ```

2. **프로젝트 열기**
   - File → Open Folder
   - 원하는 프로젝트 디렉토리 선택

3. **터미널 사용**
   - Ctrl + ` (백틱) 또는 Terminal → New Terminal

4. **AI 기능 사용**
   - Ctrl + K: AI 채팅
   - Ctrl + L: 코드 생성
   - Ctrl + I: 코드 설명

### 모바일 최적화 팁

1. **터치 제스처**
   - 확대/축소: 두 손가락 핀치
   - 스크롤: 한 손가락 스와이프
   - 롱프레스: 컨텍스트 메뉴

2. **키보드 단축키**
   - Ctrl + S: 저장
   - Ctrl + Z: 실행 취소
   - Ctrl + F: 찾기
   - Ctrl + H: 바꾸기

3. **성능 최적화**
   - 큰 파일 편집 시 가상 스크롤링 사용
   - 불필요한 확장 프로그램 비활성화
   - 정기적인 메모리 정리

## 🔒 보안 고려사항

### 권한 관리
- 필요한 최소 권한만 요청
- 파일 시스템 접근 제한
- 네트워크 보안 설정

### 데이터 보호
- 로컬 파일 암호화
- 클라우드 동기화 시 보안 연결 사용
- 정기적인 백업 생성

## 📞 지원 및 문의

### 문제 보고
- GitHub Issues: [프로젝트 이슈 페이지](https://github.com/huntkil/mobile_ide/issues)
- 이메일: support@mobile-ide.com

### 커뮤니티
- Discord: [Mobile IDE Community](https://discord.gg/mobile-ide)
- Reddit: r/mobile_ide

### 기여하기
- Pull Request 환영
- 문서 개선 제안
- 버그 리포트 및 기능 요청

---

**⚠️ 주의사항**: 이 가이드는 개발 및 테스트 목적으로 작성되었습니다. 프로덕션 환경에서 사용하기 전에 충분한 테스트를 진행하세요. 