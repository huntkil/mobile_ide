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

**결론**: v3.0.0 버전부터는 위의 모든 오류가 발생하지 않도록 설계되었습니다. 만약 새로운 문제가 발생할 경우, `~/cursor-ide/debug.sh`를 실행한 결과를 포함하여 GitHub 이슈에 보고해주세요. 