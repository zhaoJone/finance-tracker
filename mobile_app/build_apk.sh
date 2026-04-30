#!/usr/bin/env bash
# 构建 APK 脚本
# 自动从 .env 读取 API_BASE_URL 并通过 --dart-define 传入 Flutter
# 自动查找 JAVA_HOME，无需手动设置
# 用法: ./build_apk.sh [--release|--debug]
#
# 如果没有 .env 文件，复制 .env.example 并修改 API_BASE_URL
# .env 文件已加入 .gitignore，地址不会提交到仓库

set -euo pipefail

cd "$(dirname "$0")"

# ── 自动查找 JAVA_HOME ──────────────────────────────────────────────
if [ -z "${JAVA_HOME:-}" ]; then
    for JDK_CANDIDATE in /home/zhao/jdk17/jdk-* /usr/lib/jvm/java-17-* /usr/local/lib/jvm/*; do
        if [ -x "$JDK_CANDIDATE/bin/java" ]; then
            export JAVA_HOME="$JDK_CANDIDATE"
            break
        fi
    done
    if [ -z "${JAVA_HOME:-}" ]; then
        echo "❌ 未找到 JDK 17，请设置 JAVA_HOME"
        exit 1
    fi
    echo "☕ JAVA_HOME: $JAVA_HOME"
fi
export PATH="$JAVA_HOME/bin:$PATH"

# ── 读取 .env 配置 ──────────────────────────────────────────────────
BUILD_MODE="${1:---debug}"
ENV_FILE=".env"
DART_DEFINES=""

if [ -f "$ENV_FILE" ]; then
    # shellcheck disable=SC2046
    export $(grep -v '^\s*#' "$ENV_FILE" | grep -v '^\s*$' | xargs)
    if [ -n "${API_BASE_URL:-}" ]; then
        DART_DEFINES="--dart-define=API_BASE_URL=$API_BASE_URL"
        echo "📡 API_BASE_URL: $API_BASE_URL"
    fi
else
    echo "⚠️  未找到 .env 文件，使用默认地址 http://localhost:8000"
    echo "   请 cp .env.example .env 并修改 API_BASE_URL"
fi

# ── 构建 ────────────────────────────────────────────────────────────
echo "🔨 flutter pub get ..."
/home/zhao/flutter/bin/flutter pub get

echo "🔨 Building APK ($BUILD_MODE) ..."
/home/zhao/flutter/bin/flutter build apk "$BUILD_MODE" $DART_DEFINES --split-per-abi

echo "✅ 构建完成！"
ls -lh build/app/outputs/flutter-apk/*.apk
