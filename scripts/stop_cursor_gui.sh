#!/bin/bash

# ==========================================
# Cursor AI GUI 종료 스크립트
# ==========================================
# Author: Mobile IDE Team
# Version: 1.0.0

echo "=========================================="
echo "  Cursor AI GUI 종료"
echo "=========================================="
echo ""

echo "Cursor AI 프로세스 종료 중..."
ps aux | grep -E "(cursor|AppRun)" | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null || echo "Cursor 프로세스 없음"

echo ""
echo "VNC 서버 종료 중..."
vncserver -kill :1 2>/dev/null || echo "VNC 서버 없음"

echo ""
echo "프로세스 확인..."
ps aux | grep -E "(cursor|AppRun|Xvnc)" | grep -v grep || echo "모든 프로세스 종료됨"

echo ""
echo "Cursor AI GUI 종료 완료!" 