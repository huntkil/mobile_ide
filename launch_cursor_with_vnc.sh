#!/bin/bash

echo "=========================================="
echo "  Cursor AI IDE + VNC 실행"
echo "=========================================="
echo ""

# VNC 서버 시작
echo "[INFO] VNC 서버 시작 중..."
./start_vnc.sh

# 잠시 대기
sleep 2

# Ubuntu 환경에서 Cursor AI 실행
echo "[INFO] Cursor AI 실행 중..."
proot-distro login ubuntu -- bash /home/cursor-ide/start.sh

echo ""
echo "[SUCCESS] Cursor AI + VNC 실행 완료!"
echo "[INFO] Android VNC Viewer 앱에서 localhost:5901로 접속하세요."
echo "[INFO] VNC 비밀번호: cursor123" 