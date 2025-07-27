# Galaxy Android용 Cursor AI IDE

## 🚀 **v4.0 - npm 오류 완전 해결 버전**

Samsung Galaxy Android 기기에서 Cursor AI IDE를 실행할 수 있는 완벽한 환경을 제공합니다. **v4.0에서는 npm 오류를 완전히 해결**하고 안정적인 설치를 보장합니다.

## ✨ **v4.0 주요 개선사항**

### 🔧 **npm 오류 완전 해결**
- ✅ `double free or corruption (out)` 오류 해결
- ✅ `npm cache clean --force` 문제 해결
- ✅ 메모리 손상 문제 해결
- ✅ 안전한 npm 캐시 정리
- ✅ npm 없이 설치 옵션 제공

### 🛠️ **새로운 스크립트**
- `scripts/termux_perfect_setup_v4.sh` - 완벽한 설치 (npm 오류 해결)
- `scripts/complete_reset_v4.sh` - 완전 초기화 (npm 문제 해결)
- `scripts/fix_npm_issues_v4.sh` - npm 문제 전용 해결
- `scripts/quick_install_v4.sh` - 빠른 설치 (npm 없이)

### 🎯 **안정성 향상**
- 메모리 최적화
- 저장공간 자동 정리
- 네트워크 연결 안정화
- 완전한 오류 처리

## 📱 **지원 환경**

- **OS**: Android 10+ (권장: Android 13+)
- **아키텍처**: ARM64 (aarch64)
- **기기**: Samsung Galaxy 시리즈
- **메모리**: 최소 4GB, 권장 8GB+
- **저장공간**: 최소 10GB, 권장 20GB+

## 🚀 **빠른 시작**

### **방법 1: 빠른 설치 (권장)**
```bash
# 1. 프로젝트 다운로드
cd ~
git clone https://github.com/huntkil/mobile_ide.git
cd mobile_ide

# 2. 빠른 설치 (npm 오류 방지)
chmod +x scripts/quick_install_v4.sh
./scripts/quick_install_v4.sh

# 3. Cursor AI 실행
./run_cursor_fixed.sh
```

### **방법 2: 완벽 설치**
```bash
# 1. 프로젝트 다운로드
cd ~
git clone https://github.com/huntkil/mobile_ide.git
cd mobile_ide

# 2. 완벽 설치 (npm 포함)
chmod +x scripts/termux_perfect_setup_v4.sh
./scripts/termux_perfect_setup_v4.sh

# 3. Cursor AI 실행
./run_cursor_fixed.sh
```

### **방법 3: npm 없이 설치**
```bash
# npm 오류가 발생하는 경우
chmod +x scripts/termux_perfect_setup_v4.sh
./scripts/termux_perfect_setup_v4.sh --skip-npm
```

## 🔧 **문제 해결**

### **npm 오류가 발생하는 경우**
```bash
# npm 문제 전용 해결
chmod +x scripts/fix_npm_issues_v4.sh
./scripts/fix_npm_issues_v4.sh
```

### **완전 재설치가 필요한 경우**
```bash
# 모든 환경 완전 초기화
chmod +x scripts/complete_reset_v4.sh
./scripts/complete_reset_v4.sh
```

### **저장공간 부족**
```bash
# 저장공간 정리
pkg clean
pkg autoclean
rm -rf ~/.cache/*
```

## 📚 **사용법**

### **기본 실행**
```bash
# 권장 실행 방법 (권한 문제 해결됨)
./run_cursor_fixed.sh

# 기본 실행 방법
./launch.sh
```

### **VNC를 통한 GUI 표시**
```bash
# VNC 서버 설치
pkg install x11vnc

# VNC 서버 시작
vncserver :1 -geometry 1024x768 -depth 24

# Android VNC Viewer 앱에서 localhost:5901 접속
```

### **프로젝트 관리**
```bash
# 새 프로젝트 생성
mkdir ~/projects/my-project
cd ~/projects/my-project

# Cursor AI에서 프로젝트 열기
# File → Open Folder → ~/projects/my-project
```

## 📁 **프로젝트 구조**

```
mobile_ide/
├── scripts/
│   ├── termux_perfect_setup_v4.sh    # 완벽 설치 (v4.0)
│   ├── complete_reset_v4.sh          # 완전 초기화 (v4.0)
│   ├── fix_npm_issues_v4.sh          # npm 문제 해결 (v4.0)
│   ├── quick_install_v4.sh           # 빠른 설치 (v4.0)
│   └── ... (기존 스크립트들)
├── docs/
│   ├── COMPLETE_SETUP_GUIDE.md       # 완전 설치 가이드
│   ├── DEVELOPMENT_GUIDE.md          # 개발 가이드
│   ├── ERROR_DATABASE.md             # 오류 데이터베이스
│   └── ... (기타 문서들)
├── README.md                         # 이 파일
└── ... (기타 파일들)
```

## 🎯 **v4.0 스크립트 비교**

| 스크립트 | 용도 | npm 포함 | 권장 상황 |
|----------|------|----------|-----------|
| `quick_install_v4.sh` | 빠른 설치 | ❌ | 처음 설치, npm 오류 우려 |
| `termux_perfect_setup_v4.sh` | 완벽 설치 | ✅ | 완전한 환경 필요 |
| `complete_reset_v4.sh` | 완전 초기화 | 선택 | 문제 해결, 재설치 |
| `fix_npm_issues_v4.sh` | npm 문제 해결 | ✅ | npm 오류 발생 시 |

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

## 📞 **지원 및 문의**

### **문제 보고**
- **GitHub Issues**: [프로젝트 이슈 페이지](https://github.com/huntkil/mobile_ide/issues)
- **이메일**: huntkil@github.com

### **커뮤니티**
- **Discord**: [Mobile IDE Community](https://discord.gg/mobile-ide)
- **Reddit**: r/mobile_ide

### **문서**
- **설치 가이드**: [docs/COMPLETE_SETUP_GUIDE.md](docs/COMPLETE_SETUP_GUIDE.md)
- **문제 해결**: [docs/troubleshooting.md](docs/troubleshooting.md)
- **오류 데이터베이스**: [docs/ERROR_DATABASE.md](docs/ERROR_DATABASE.md)
- **개발 가이드**: [docs/DEVELOPMENT_GUIDE.md](docs/DEVELOPMENT_GUIDE.md)

## 🎯 **권장사항**

### **성공적인 설치를 위한 팁**
1. **빠른 설치 사용**: npm 오류를 방지하려면 `quick_install_v4.sh` 사용
2. **충분한 저장공간**: 최소 10GB 이상의 여유 공간 확보
3. **안정적인 네트워크**: Wi-Fi 연결로 안정적인 다운로드
4. **VNC 서버**: GUI 화면을 보려면 VNC 서버 설정 필수
5. **정기적인 정리**: 저장공간 정리로 성능 유지

### **성능 최적화**
```bash
# 메모리 최적화
echo 3 > /proc/sys/vm/drop_caches

# CPU 성능 모드
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# 배터리 최적화 비활성화
dumpsys deviceidle disable
```

## 📝 **변경 이력**

### **v4.0.0 (2025-07-27)**
- ✅ npm 오류 완전 해결
- ✅ 새로운 v4.0 스크립트 추가
- ✅ 메모리 최적화 개선
- ✅ 안정성 향상
- ✅ 완전한 오류 처리

### **v3.1.1 (2025-07-27)**
- ✅ 스크립트 문법 오류 수정
- ✅ 권한 문제 완전 해결
- ✅ 네트워크 문제 해결

### **v3.1.0 (2025-07-27)**
- ✅ 저장공간 및 GUI 문제 해결
- ✅ VNC 서버 통합
- ✅ 외부 저장소 활용

### **v3.0.0 (2025-07-27)**
- ✅ 아키텍처 개선
- ✅ 독립 실행 스크립트 구조
- ✅ 시스템 서비스 오류 해결

---

**🔄 최신 업데이트**: v4.0.0 (2025-07-27) - npm 오류 완전 해결!

**💡 핵심 메시지**: npm 오류가 발생하면 **빠른 설치** 또는 **npm 없이 설치**를 사용하세요! 