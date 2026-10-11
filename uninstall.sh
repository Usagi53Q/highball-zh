#!/bin/bash
# Highball 中文汉化补丁卸载与原版恢复脚本
set -e

APP_PATH="/Applications/Highball.app"
MACOS_DIR="$APP_PATH/Contents/MacOS"
RES_DIR="$APP_PATH/Contents/Resources"
TARGET_BIN="$MACOS_DIR/Highball"
BACKUP_BIN="$MACOS_DIR/Highball.orig"
BUNDLE_ID="app.highball.Highball"

echo "=================================================="
echo "  Highball 中文汉化补丁卸载程序"
echo "=================================================="

if [ ! -d "$APP_PATH" ]; then
    echo "[错误] 未找到 /Applications/Highball.app"
    exit 1
fi

if pgrep -x "Highball" > /dev/null; then
    echo "-> 正在关闭运行中的 Highball..."
    killall "Highball" || true
    sleep 1
fi

if [ -f "$BACKUP_BIN" ]; then
    echo "-> 正在从 Highball.orig 恢复原版程序..."
    mv -f "$BACKUP_BIN" "$TARGET_BIN"
    chmod +x "$TARGET_BIN"
else
    echo "-> 未找到备份文件 Highball.orig，将仅重置语言偏好为英文。"
    defaults write "$BUNDLE_ID" HighballLanguage -string "en"
fi

rm -rf "$RES_DIR/zh-Hans.lproj" "$RES_DIR/zh-Hant.lproj" 2>/dev/null || true
defaults delete "$BUNDLE_ID" HighballLanguage 2>/dev/null || true
defaults delete "$BUNDLE_ID" AppleLanguages 2>/dev/null || true

echo "=================================================="
echo "  已成功恢复原版 Highball！"
echo "=================================================="
