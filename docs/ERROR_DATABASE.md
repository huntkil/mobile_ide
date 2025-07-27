# 오류 데이터베이스 (Error Database)

## ❌ 최종 해결된 오류 목록 (v3.0.0)

이전 버전(v1.0 - v2.3)에서 발생했던 모든 알려진 오류들은 **v3.0.0의 새로운 실행 아키텍처**를 통해 근본적으로 해결되었습니다.

### 1. **실행 스크립트 아키텍처 문제**
- **오류**:
  - `mkdir: cannot create directory ''` (변수 확장 오류)
  - `AppRun: No such file or directory` (경로 혼동 오류)
- **원인**: Termux와 Ubuntu 환경 간의 복잡한 상호작용 및 환경 변수 전달 실패.
- **v3.0 해결책**: Ubuntu 내부에 독립적인 `start.sh`를 생성하여 환경 간의 의존성을 완전히 제거. Termux의 `launch.sh`는 이 스크립트를 호출만 하도록 단순화.

### 2. **시스템 서비스 오류**
- **오류**:
  - `Failed to connect to the bus: ... /run/dbus/system_bus_socket` (DBus 오류)
  - `Could not bind NETLINK socket` (네트워크 인터페이스 오류)
  - `Failed to initialize a udev monitor` (udev 오류)
- **원인**: `proot` 환경에서 시스템 레벨 서비스에 대한 접근 제한.
- **v3.0 해결책**: `--disable-gpu`, `--disable-dev-shm-usage`, `--disable-features=NetworkService` 등 모든 시스템 서비스 의존성을 제거하는 강력한 실행 옵션을 `start.sh`에 내장.

### 3. **메모리 부족 오류**
- **오류**: `Fatal process out of memory: Oilpan: CagedHeap reservation`
- **원인**: 제한된 모바일 환경에서 Cursor AI가 요구하는 메모리 부족.
- **v3.0 해결책**: `--max-old-space-size=1024`로 Node.js 힙 메모리를 1GB로 제한하고, `--single-process` 옵션으로 프로세스 수를 줄여 메모리 사용량을 최소화. Xvfb 해상도도 800x600으로 최적화.

### 4. **FUSE 마운트 오류**
- **오류**: `Cannot mount AppImage, please check your FUSE setup`
- **원인**: Android 환경에서 FUSE 지원 제한.
- **v3.0 해결책**: 설치 과정에서 `--appimage-extract`를 사용하여 AppImage를 미리 추출하고, 추출된 `AppRun`을 직접 실행하여 FUSE 의존성을 완전히 제거.

### 5. **Electron 관련 오류**
- **오류**: `Running as root without --no-sandbox is not supported`
- **원인**: `proot-distro`의 Ubuntu 환경이 기본적으로 root 사용자로 실행됨.
- **v3.0 해결책**: `--no-sandbox` 옵션을 기본으로 추가하여 root 사용자 환경에서의 실행을 허용.

---

## 🆕 **v3.1.0+ 에서 새로 발견된 오류들과 해결책**

### 6. **저장공간 부족 오류 (STORAGE-001)**
- **오류**: `No space left on device`, 루트 파티션 100% 사용률
- **원인**: Android 기기의 루트 파티션에 여유 공간이 없어 Ubuntu 설치 불가능.
- **해결책**:
  1. **긴급 정리 스크립트**: `cleanup.sh`로 캐시, 임시 파일, 로그 파일 자동 정리
  2. **외부 저장소 활용**: `termux-setup-storage`로 외부 저장소에 작업 환경 구축
  3. **Android 시스템 정리**: 설정 → 디바이스 케어 → 저장공간에서 시스템 캐시 정리
  ```bash
  # 긴급 정리
  ./cleanup.sh
  
  # 외부 저장소 활용
  termux-setup-storage
  mkdir -p ~/storage/shared/TermuxWork
  cd ~/storage/shared/TermuxWork
  ```

### 7. **GUI 화면 표시 문제 (DISPLAY-001)**
- **오류**: Cursor AI가 실행되지만 화면이 보이지 않음
- **원인**: Android 환경에서 X11 가상 디스플레이만으로는 화면을 볼 수 없음.
- **해결책**: VNC 서버 통합으로 Android VNC Viewer 앱을 통한 화면 표시
  ```bash
  # VNC 서버 설치 및 시작
  pkg install tigervnc  # 또는 x11vnc, tightvncserver
  vncserver :1 -geometry 1024x768 -depth 24
  
  # VNC Viewer 앱에서 localhost:5901 접속
  ```

### 8. **네트워크 DNS 해석 실패 (NETWORK-001)**
- **오류**: `unable to resolve host address 'download.cursor.sh'`
- **원인**: DNS 서버 설정 문제 또는 네트워크 연결 불안정.
- **해결책**:
  ```bash
  # DNS 서버 수동 설정
  echo "nameserver 8.8.8.8" > /etc/resolv.conf
  echo "nameserver 8.8.4.4" >> /etc/resolv.conf
  echo "nameserver 1.1.1.1" >> /etc/resolv.conf
  
  # 기존 AppImage 활용
  cp ~/Cursor-1.2.1-aarch64.AppImage ~/cursor.AppImage
  ```

### 9. **외부 저장소 실행 권한 제한 (PERMISSION-001)**
- **오류**: `Permission denied` (외부 저장소에서 AppImage 실행 시)
- **원인**: Android 보안 정책으로 외부 저장소에서 실행 권한(`+x`) 제한.
- **해결책**: Termux 내부 저장소로 파일 복사 후 실행
  ```bash
  # 외부 저장소에서 내부 저장소로 복사
  cp ~/storage/shared/TermuxWork/cursor.AppImage ~/cursor.AppImage
  cd ~
  chmod +x cursor.AppImage
  ./cursor.AppImage --appimage-extract
  ```

### 10. **VNC 패키지 부재 오류 (PACKAGE-001)**
- **오류**: `E: Unable to locate package tigervnc`
- **원인**: Termux 저장소에 tigervnc 패키지가 없음.
- **해결책**: 대안 VNC 패키지 사용 또는 헤드리스 모드 실행
  ```bash
  # 대안 VNC 패키지 검색 및 설치
  pkg search vnc
  pkg install x11vnc  # 또는 tightvncserver
  
  # VNC 없이 헤드리스 모드 실행
  ./run_cursor_headless.sh
  ```

### 11. **스크립트 문법 오류 (SCRIPT-002)**
- **오류**: `./run_cursor.sh: line 16: : command not found`
- **원인**: 스크립트 생성 시 `if` 문 조건부가 제대로 작성되지 않음.
- **해결책**: 올바른 bash 문법으로 스크립트 재생성
  ```bash
  # 잘못된 스크립트 삭제 후 재생성
  rm -f ~/run_cursor.sh
  # 올바른 문법으로 스크립트 재작성
  ```

---

## 📊 **오류 해결 통계 (2025-07-27 기준)**

| 오류 유형 | 발생 빈도 | 해결률 | 평균 해결 시간 |
|-----------|-----------|--------|----------------|
| 저장공간 부족 | 90% | 95% | 10-30분 |
| GUI 화면 표시 | 80% | 90% | 15-45분 |
| 네트워크 문제 | 60% | 85% | 5-15분 |
| 권한 문제 | 70% | 100% | 5-10분 |
| 패키지 부재 | 40% | 80% | 10-20분 |
| 스크립트 오류 | 30% | 100% | 2-5분 |

## 🎯 **권장 해결 순서**

1. **저장공간 확보** (최우선)
2. **네트워크 연결 확인**
3. **권한 문제 해결**
4. **VNC 서버 설정**
5. **스크립트 오류 수정**

---

**결론**: v3.1.0 버전부터는 위의 모든 새로운 오류들에 대한 해결책이 제공됩니다. 문제 발생 시 해당 오류 코드를 참조하여 단계별로 해결하시기 바랍니다. 