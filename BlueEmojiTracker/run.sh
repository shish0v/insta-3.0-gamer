#!/bin/bash

APP_NAME="BlueEmojiTracker"
APP_VERSION="4.0"
SCRIPT_DIR=$(dirname "$0")

echo ""
echo "🔵 $APP_NAME v$APP_VERSION"
echo "Отслеживает синие объекты на экране и автоматически перемещает курсор."
echo ""
echo "💡 Совет: При первом запуске предоставьте разрешение на запись экрана."
echo ""

# Запуск приложения
cd "$SCRIPT_DIR" && swift run
