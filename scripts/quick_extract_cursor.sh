#!/bin/bash

echo "빠른 Cursor AI 추출..."

cd ~/mobile_ide

# AppImage 추출
echo "AppImage 추출 중..."
./Cursor-1.2.1-aarch64.AppImage --appimage-extract

if [ -d "squashfs-root" ]; then
    echo "✅ 추출 완료!"
    echo ""
    echo "이제 다음 명령어로 실행하세요:"
    echo "cd ~/mobile_ide/squashfs-root"
    echo "./AppRun --no-sandbox --disable-gpu"
else
    echo "❌ 추출 실패"
fi 