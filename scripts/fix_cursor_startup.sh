#!/bin/bash

echo "Cursor AI 시작 문제 해결 중..."

echo "1단계: D-Bus 서비스 설정..."
proot-distro login ubuntu -- bash -c "
# D-Bus 설치 및 설정
apt update -y
apt install -y dbus dbus-x11 2>/dev/null || echo 'D-Bus 설치 실패 (무시됨)'

# D-Bus 디렉토리 생성
mkdir -p /run/dbus
chmod 755 /run/dbus

# D-Bus 데몬 시작
dbus-daemon --system --fork 2>/dev/null || echo 'D-Bus 시스템 데몬 시작 실패 (무시됨)'
dbus-daemon --session --fork 2>/dev/null || echo 'D-Bus 세션 데몬 시작 실패 (무시됨)'

echo 'D-Bus 설정 완료'
"

echo ""
echo "2단계: Cursor AI 환경 설정 및 실행..."
proot-distro login ubuntu -- bash -c "
cd /home/cursor-ide

# 환경 변수 설정
export DISPLAY=:1
export XDG_RUNTIME_DIR=\$HOME/.runtime-cursor
export DBUS_SESSION_BUS_ADDRESS='unix:path=\$XDG_RUNTIME_DIR/bus'
export NO_AT_BRIDGE=1
export ELECTRON_DISABLE_SECURITY_WARNINGS=true

# 런타임 디렉토리 생성
mkdir -p \$XDG_RUNTIME_DIR
chmod 700 \$XDG_RUNTIME_DIR

# D-Bus 세션 버스 시작
dbus-daemon --session --address=unix:path=\$XDG_RUNTIME_DIR/bus --nofork --nopidfile --syslog-only &
sleep 2

echo 'Cursor AI 실행 중...'

# Cursor AI 실행 (더 많은 비활성화 옵션)
./squashfs-root/AppRun \
  --no-sandbox \
  --disable-gpu \
  --disable-software-rasterizer \
  --single-process \
  --disable-dev-shm-usage \
  --disable-background-timer-throttling \
  --disable-renderer-backgrounding \
  --disable-backgrounding-occluded-windows \
  --disable-features=TranslateUI,VizDisplayCompositor \
  --disable-ipc-flooding-protection \
  --disable-web-security \
  --disable-features=VizDisplayCompositor \
  --max-old-space-size=1024 \
  --js-flags='--max-old-space-size=1024' \
  --no-first-run \
  --no-default-browser-check \
  --disable-default-apps \
  --disable-extensions \
  --disable-plugins \
  --disable-sync \
  --disable-translate \
  --disable-background-networking \
  --disable-component-extensions-with-background-pages &

CURSOR_PID=\$!
echo 'Cursor AI PID:' \$CURSOR_PID

# 프로세스가 실행 중인지 확인
sleep 5
if kill -0 \$CURSOR_PID 2>/dev/null; then
    echo 'Cursor AI 실행 중 (PID: '\$CURSOR_PID')'
    ps aux | grep AppRun | grep -v grep
else
    echo 'Cursor AI 프로세스 종료됨'
fi

# 백그라운드에서 계속 실행
wait
"

echo ""
echo "Cursor AI 시작 문제 해결 완료"
echo "VNC Viewer에서 localhost:5901에 접속하여 확인하세요" 