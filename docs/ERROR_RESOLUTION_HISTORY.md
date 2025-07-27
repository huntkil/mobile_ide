# Cursor AI Mobile IDE - 오류 해결 히스토리

## 개요
이 문서는 Cursor AI Mobile IDE 프로젝트에서 발생한 모든 오류들과 그 해결 방법들을 체계적으로 정리한 것입니다.

## 주요 오류 카테고리

### 1. 환경 설정 오류

#### 1.1 WSL vs Termux 환경 혼동
**오류**: `bash: ./scripts/complete_reset.sh: No such file or directory`
**원인**: 사용자가 WSL에서 실행하려고 했지만 스크립트는 Termux용
**해결**: Termux 환경에서 실행하도록 안내

#### 1.2 Git 동기화 문제
**오류**: `error: Your local changes to the following files would be overwritten by merge`
**원인**: 로컬 변경사항과 원격 저장소 충돌
**해결**: `git reset --hard origin/main` 또는 `git stash`

### 2. npm 및 Node.js 오류

#### 2.1 npm 캐시 오류
**오류**: 
```
npm warn using --force
double free or corruption (out)
[ERROR] Ubuntu 환경 설정 실패
```
**원인**: `npm cache clean --force` 명령어로 인한 메모리 손상
**해결**: 
- npm 완전 재설치
- 안전한 npm 캐시 정리 방법 사용
- Node.js 18 LTS 버전 사용

### 3. 네트워크 및 다운로드 오류

#### 3.1 DNS 해석 실패
**오류**: `failed: Name or service not known`
**원인**: DNS 서버 설정 문제
**해결**: 
- 환경 변수로 DNS 설정
- 여러 DNS 서버 시도 (8.8.8.8, 1.1.1.1, 208.67.222.222, 9.9.9.9)
- 대체 DNS 서버 사용 (223.5.5.5, 119.29.29.29, 180.76.76.76, 114.114.114.114)

#### 3.2 다운로드 URL 테스트 실패
**오류**: `[ERROR] 모든 다운로드 URL 테스트 실패`
**원인**: 네트워크 연결 문제
**해결**: 
- 직접 IP 주소 사용
- Host 헤더 추가
- 로컬 AppImage 파일 우선 사용

#### 3.3 Read-only 파일 시스템
**오류**: `/etc/resolv.conf: Read-only file system`
**원인**: 시스템 파일 쓰기 권한 없음
**해결**: 환경 변수로 DNS 설정

### 4. FUSE 및 AppImage 오류

#### 4.1 FUSE 권한 오류
**오류**: 
```
Error: No suitable fusermount binary found on the $PATH
fuse: failed to open /dev/fuse: Permission denied
Cannot mount AppImage, please check your FUSE setup
```
**원인**: FUSE 권한 및 설정 문제
**해결**: AppImage 추출 방식 사용
```bash
./Cursor-1.2.1-aarch64.AppImage --appimage-extract
```

### 5. 스크립트 실행 오류

#### 5.1 스크립트 종료 (Killed/Terminated)
**오류**: 스크립트가 중간에 종료됨
**원인**: 
- `set -e` 명령어로 인한 오류 시 종료
- 권한 문제
- 메모리 부족
**해결**: 
- `set -e` 제거
- `|| true`, `|| log_warning`, `|| log_error` 추가
- 권한 확인 로직 추가
- `safe_run` 함수 사용

#### 5.2 프로세스 종료 실패
**오류**: `pkill` 명령어로 프로세스 종료 실패
**원인**: Termux 환경에서 `pkill` 제한
**해결**: 
```bash
ps aux | grep -E "(cursor|AppRun)" | grep -v grep | awk '{print $2}' | xargs kill -9
```

### 6. X11 및 VNC 오류

#### 6.1 X11 연결 실패
**오류**: `Missing X server or $DISPLAY`
**원인**: 
- proot 환경에서 X11 연결 문제
- DISPLAY 환경 변수 설정 오류
**해결**: 
- proot 환경 우회
- 네이티브 실행 방식 사용
- 완전한 환경 변수 설정

#### 6.2 VNC 검은 화면
**오류**: VNC 연결은 되지만 검은 화면만 표시
**원인**: 
- 윈도우 매니저 없음
- X11 환경 설정 불완전
**해결**: 
- `twm`, `openbox` 설치
- `xstartup` 스크립트 수정
- 배경색 설정

#### 6.3 VNC 회색 화면
**오류**: 회색 화면만 표시되고 Cursor AI GUI가 나타나지 않음
**원인**: 
- Cursor AI 프로세스 종료
- D-Bus 연결 실패
- X11 렌더링 문제
**해결**: 
- D-Bus 서비스 설치 및 설정
- Cursor AI 실행 옵션 최적화
- 환경 변수 완전 설정

### 7. D-Bus 및 시스템 오류

#### 7.1 D-Bus 연결 실패
**오류**: 
```
Failed to connect to the bus: Failed to connect to socket /run/dbus/system_bus_socket: No such file or directory
```
**원인**: D-Bus 서비스가 실행되지 않음
**해결**: 
```bash
# D-Bus 설치 및 설정
apt install -y dbus dbus-x11
mkdir -p /run/dbus
chmod 755 /run/dbus
dbus-daemon --system --fork
dbus-daemon --session --fork
```

#### 7.2 시스템 오류
**오류**: 
```
SystemError [ERR_SYSTEM_ERROR]: A system error occurred: uv_interface_addresses returned Unknown system error 13
```
**원인**: proot 환경에서 네트워크 인터페이스 접근 문제
**해결**: 네이티브 실행 방식 사용

### 8. 메모리 및 성능 오류

#### 8.1 메모리 부족
**오류**: `Permission denied` for `/proc/sys/vm/drop_caches`
**원인**: 메모리 캐시 정리 권한 없음
**해결**: 
- 권한 확인 후 실행
- `|| log_warning` 추가
- 메모리 사용량 최적화

#### 8.2 Segmentation Fault
**오류**: Cursor AI 프로세스가 Segmentation fault로 종료
**원인**: proot 환경에서 메모리 접근 문제
**해결**: 네이티브 실행 방식 사용

## 해결 방법 분류

### 1. 환경별 해결 방법

#### Termux 환경
- proot-distro 사용
- 네이티브 실행 우선
- 권한 문제 주의

#### WSL 환경
- Windows에서 실행
- 파일 복사 시 주의
- 경로 설정 확인

### 2. 실행 방식별 해결 방법

#### AppImage 직접 실행
- FUSE 문제 발생
- 권한 문제
- 해결: AppImage 추출

#### AppImage 추출 실행
- FUSE 문제 해결
- 안정적 실행
- 권장 방식

#### proot 환경 실행
- X11 연결 문제
- 시스템 오류
- 해결: 네이티브 실행

#### 네이티브 실행
- 가장 안정적
- 권장 방식
- 모든 문제 해결

### 3. 스크립트 안정성 개선

#### 오류 처리
```bash
# 기존
set -e

# 개선
# set -e 제거
command || log_warning "명령어 실패"
command || log_error "명령어 실패"
```

#### 프로세스 관리
```bash
# 기존
pkill -f cursor

# 개선
ps aux | grep -E "(cursor|AppRun)" | grep -v grep | awk '{print $2}' | xargs kill -9
```

#### 권한 확인
```bash
# 권한 확인 후 실행
if [ -w /proc/sys/vm/drop_caches ]; then
    echo 3 > /proc/sys/vm/drop_caches
else
    log_warning "메모리 캐시 정리 권한 없음"
fi
```

## 최종 권장 해결 방법

### 1. 완전 새로 시작
```bash
./scripts/complete_fresh_start.sh
```

### 2. AppImage 추출
```bash
./Cursor-1.2.1-aarch64.AppImage --appimage-extract
```

### 3. 네이티브 실행
```bash
cd squashfs-root
./AppRun --no-sandbox --disable-gpu --single-process --max-old-space-size=512
```

### 4. VNC 설정
```bash
vncserver :1 -geometry 1024x768 -depth 24 -localhost no -SecurityTypes VncAuth -dpi 96
```

## 예방 방법

### 1. 환경 확인
- Termux vs WSL 구분
- Git 동기화 상태 확인
- 권한 확인

### 2. 단계별 테스트
- 각 단계별 성공 확인
- 로그 확인
- 오류 발생 시 즉시 중단

### 3. 백업 및 복구
- 중요 설정 백업
- 롤백 방법 준비
- 단계별 체크포인트

## 결론

가장 안정적인 방법은 **완전 새로 시작** 스크립트를 사용하여 **AppImage 추출** 후 **네이티브 실행**하는 것입니다. 이 방법으로 모든 오류를 해결할 수 있습니다. 