# 문제 해결 가이드

## 🔍 일반적인 문제들

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