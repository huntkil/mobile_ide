#!/bin/bash

echo "간단한 Cursor AI 테스트..."

# VNC 서버 시작
vncserver :1 -geometry 1024x768 -depth 24 -localhost no &
sleep 3

# 환경 변수 설정
export DISPLAY=:1

# Cursor AI 실행 (최소 옵션)
cd ~/mobile_ide
chmod +x ./Cursor-1.2.1-aarch64.AppImage

echo "Cursor AI 실행 중..."
./Cursor-1.2.1-aarch64.AppImage --no-sandbox --disable-gpu --single-process --max-old-space-size=512 &

echo "완료. VNC Viewer에서 localhost:5901 접속하세요."
echo "비밀번호: cursor123" 