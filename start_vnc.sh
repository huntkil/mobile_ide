#!/bin/bash

echo "[INFO] VNC 서버 시작 중..."

# VNC 서버 시작
vncserver :1 -geometry 1024x768 -depth 24 -localhost no

if [ $? -eq 0 ]; then
    echo "[SUCCESS] VNC 서버 시작됨"
    echo "[INFO] VNC 접속 정보:"
    echo "  - 주소: localhost:5901"
    echo "  - 해상도: 1024x768"
    echo "  - 비밀번호: cursor123"
    echo ""
    echo "[INFO] Android VNC Viewer 앱을 설치하고 위 정보로 접속하세요."
else
    echo "[ERROR] VNC 서버 시작 실패"
fi 