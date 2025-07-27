#!/bin/bash

echo "Cursor AI AppImage 추출..."

cd ~/mobile_ide

# 기존 추출 폴더 정리
rm -rf cursor-extracted 2>/dev/null || echo "기존 추출 폴더 없음"

# AppImage 추출
echo "AppImage 추출 중..."
./Cursor-1.2.1-aarch64.AppImage --appimage-extract

# 추출된 폴더 이름 변경
if [ -d "squashfs-root" ]; then
    mv squashfs-root cursor-extracted
    echo "✅ AppImage 추출 완료: cursor-extracted/"
    echo ""
    echo "이제 다음 명령어로 실행하세요:"
    echo "cd ~/mobile_ide/cursor-extracted"
    echo "./AppRun --no-sandbox --disable-gpu --single-process"
else
    echo "❌ AppImage 추출 실패"
    exit 1
fi 