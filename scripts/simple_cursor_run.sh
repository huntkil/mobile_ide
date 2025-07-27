#!/bin/bash

echo "간단한 Cursor AI 실행..."

# 직접 명령어 실행
proot-distro login ubuntu -- bash -c '
cd /home/cursor-ide
export DISPLAY=:1
export XDG_RUNTIME_DIR=$HOME/.runtime-cursor
export NO_AT_BRIDGE=1
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

echo "Cursor AI 시작..."
nohup ./squashfs-root/AppRun --no-sandbox --disable-gpu --single-process --disable-dev-shm-usage --max-old-space-size=512 > /tmp/cursor.log 2>&1 &

echo "5초 대기 중..."
sleep 5

echo "프로세스 확인:"
ps aux | grep AppRun | grep -v grep || echo "프로세스 없음"

echo "로그 확인:"
tail -5 /tmp/cursor.log 2>/dev/null || echo "로그 없음"
'

echo "완료. VNC Viewer에서 localhost:5901 접속하세요." 