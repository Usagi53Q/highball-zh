#!/bin/bash
# Highball 中文汉化补丁（简体中文 & 繁體中文）一键安装脚本
set -e

APP_PATH="/Applications/Highball.app"
MACOS_DIR="$APP_PATH/Contents/MacOS"
RES_DIR="$APP_PATH/Contents/Resources"
TARGET_BIN="$MACOS_DIR/Highball"
BACKUP_BIN="$MACOS_DIR/Highball.orig"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENTITLEMENTS="$SCRIPT_DIR/entitlements.plist"
BUNDLE_ID="app.highball.Highball"

echo "=================================================="
echo "  Highball 中文汉化补丁安装程序 (简体中文 / 繁體中文)"
echo "=================================================="

# 解析命令行参数
LANG_CHOICE=""
for arg in "$@"; do
    case "$arg" in
        --zh-hans|--hans|-s|1)
            LANG_CHOICE="zh-Hans"
            ;;
        --zh-hant|--hant|-t|2)
            LANG_CHOICE="zh-Hant"
            ;;
    esac
done

# 若未通过参数指定，则提示选择
if [ -z "$LANG_CHOICE" ]; then
    echo ""
    echo "请选择要安装的中文语言版本 / 請選擇要安裝的語言版本："
    echo "  1) 简体中文 (Simplified Chinese) [默认]"
    echo "  2) 繁體中文 (Traditional Chinese)"
    echo ""
    if [ -t 0 ]; then
        read -p "请输入选项 [1/2，默认 1]: " USER_INPUT
    else
        USER_INPUT="1"
    fi
    case "$USER_INPUT" in
        2|t|T|hant|zh-Hant)
            LANG_CHOICE="zh-Hant"
            ;;
        *)
            LANG_CHOICE="zh-Hans"
            ;;
    esac
fi

if [ "$LANG_CHOICE" = "zh-Hant" ]; then
    LANG_LABEL="繁體中文 (zh-Hant)"
    PATCH_BIN="$SCRIPT_DIR/bin/zh-Hant/Highball"
else
    LANG_LABEL="简体中文 (zh-Hans)"
    PATCH_BIN="$SCRIPT_DIR/bin/zh-Hans/Highball"
    if [ ! -f "$PATCH_BIN" ]; then
        PATCH_BIN="$SCRIPT_DIR/bin/Highball"
    fi
fi

echo "-> 已选择语言版本: $LANG_LABEL"

# 1. 检查应用是否存在
if [ ! -d "$APP_PATH" ]; then
    echo "[错误] 未在 /Applications 中找到 Highball.app，请先安装原版应用。"
    exit 1
fi

# 2. 检查补丁文件是否存在
if [ ! -f "$PATCH_BIN" ]; then
    echo "[错误] 未找到汉化二进制文件: $PATCH_BIN"
    exit 1
fi

# 3. 关闭正在运行的 Highball
if pgrep -x "Highball" > /dev/null; then
    echo "-> 正在关闭运行中的 Highball..."
    killall "Highball" || true
    sleep 1
fi

# 4. 备份原始可执行文件（仅在首次安装时备份）
if [ ! -f "$BACKUP_BIN" ]; then
    echo "-> 正在备份原版二进制文件至 Highball.orig..."
    cp -p "$TARGET_BIN" "$BACKUP_BIN"
else
    echo "-> 检测到已存在原版备份 Highball.orig，跳过备份。"
fi

# 5. 创建语言资源目录以启用 macOS 原生中文菜单栏
mkdir -p "$RES_DIR/zh-Hans.lproj" "$RES_DIR/zh-Hant.lproj"

# 6. 替换汉化二进制文件并配置语言偏好
echo "-> 正在写入 $LANG_LABEL 汉化版二进制文件..."
cp "$PATCH_BIN" "$TARGET_BIN"
chmod +x "$TARGET_BIN"

defaults write "$BUNDLE_ID" HighballLanguage -string "$LANG_CHOICE"
defaults write "$BUNDLE_ID" AppleLanguages -array "$LANG_CHOICE"

# 7. 重新签名二进制文件并清理隔离属性
echo "-> 正在对应用进行本地重签名..."
xattr -cr "$APP_PATH" 2>/dev/null || true
if [ -f "$ENTITLEMENTS" ]; then
    codesign --force --sign - --entitlements "$ENTITLEMENTS" "$TARGET_BIN"
else
    codesign --force --sign - "$TARGET_BIN"
fi

echo "=================================================="
echo "  汉化补丁 [${LANG_LABEL}] 安装完成！"
echo "  现在可以直接打开 Highball 体验完整中文界面。"
echo "=================================================="
