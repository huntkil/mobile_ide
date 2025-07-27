#!/bin/bash

echo "=========================================="
echo "  Cursor AI IDE 실행"
echo "=========================================="
echo ""

# Ubuntu 환경에서 Cursor AI 실행
proot-distro login ubuntu -- bash /home/cursor-ide/start.sh

echo ""
echo "[INFO] Cursor AI가 실행되었습니다."
echo "[INFO] GUI 화면을 보려면 VNC 서버를 시작하세요:"
echo "  ./start_vnc.sh" 