#!/bin/bash

echo "=========================================="
echo "  Cursor AI 상태 확인"
echo "=========================================="
echo ""

# Ubuntu 환경 확인
if [ -d "$HOME/ubuntu" ]; then
    echo "✅ Ubuntu 환경: 설치됨"
else
    echo "❌ Ubuntu 환경: 설치되지 않음"
fi

# Cursor AI 확인
if [ -f "$HOME/ubuntu/home/cursor-ide/squashfs-root/AppRun" ]; then
    echo "✅ Cursor AI: 설치됨"
else
    echo "❌ Cursor AI: 설치되지 않음"
fi

# 실행 스크립트 확인
if [ -f "$HOME/launch_cursor.sh" ]; then
    echo "✅ 실행 스크립트: 생성됨"
else
    echo "❌ 실행 스크립트: 생성되지 않음"
fi

# VNC 서버 확인
if pgrep -x "vncserver" > /dev/null; then
    echo "✅ VNC 서버: 실행 중"
else
    echo "❌ VNC 서버: 실행되지 않음"
fi

# Cursor AI 프로세스 확인
if proot-distro login ubuntu -- ps aux | grep -v grep | grep -q "AppRun"; then
    echo "✅ Cursor AI 프로세스: 실행 중"
else
    echo "❌ Cursor AI 프로세스: 실행되지 않음"
fi

echo ""
echo "==========================================" 