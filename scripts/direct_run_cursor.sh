#!/bin/bash

echo "Cursor AI 직접 실행 중..."

proot-distro login ubuntu -- bash -c "
cd /home/cursor-ide
export DISPLAY=:1
export XDG_RUNTIME_DIR=\$HOME/.runtime-cursor
mkdir -p \$XDG_RUNTIME_DIR
chmod 700 \$XDG_RUNTIME_DIR
echo 'Cursor AI 실행...'
./squashfs-root/AppRun --no-sandbox --disable-gpu --single-process --disable-dev-shm-usage --max-old-space-size=1024 &
echo 'Cursor AI 시작됨'
sleep 5
ps aux | grep AppRun | grep -v grep || echo '프로세스 없음'
"

echo "Cursor AI 직접 실행 완료" 