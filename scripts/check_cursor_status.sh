#!/bin/bash

# ==========================================
# Cursor AI GUI 상태 확인 스크립트
# ==========================================
# Author: Mobile IDE Team
# Version: 1.0.0

echo "=========================================="
echo "  Cursor AI GUI 상태 확인"
echo "=========================================="
echo ""

echo "실행 중인 프로세스:"
ps aux | grep -E "(cursor|AppRun|Xvnc)" | grep -v grep || echo "실행 중인 프로세스 없음"

echo ""
echo "네트워크 포트 확인:"
netstat -tlnp 2>/dev/null | grep 5901 || echo "VNC 포트 5901 비활성"

echo ""
echo "VNC 로그 파일:"
if [ -f ~/.vnc/localhost:1.log ]; then
    echo "로그 파일 위치: ~/.vnc/localhost:1.log"
    echo "최근 로그 (마지막 10줄):"
    tail -10 ~/.vnc/localhost:1.log
else
    echo "VNC 로그 파일 없음"
fi

echo ""
echo "연결 정보:"
echo "  서버 주소: localhost:5901"
echo "  비밀번호: cursor123"
echo "  해상도: 1024x768"

echo ""
echo "상태 확인 완료!" 