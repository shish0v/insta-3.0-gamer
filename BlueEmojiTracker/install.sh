#!/bin/bash

# Переменные
APP_NAME="BlueEmojiTracker"
APP_VERSION="4.0"
SCRIPT_DIR=$(dirname "$0")
PROJECT_DIR=$(cd "$SCRIPT_DIR" && pwd)

echo "Скрипт запущен из директории: $SCRIPT_DIR"
echo "Директория проекта: $PROJECT_DIR"

# Удаляем старую сборку, если она существует
if [ -d "$PROJECT_DIR/../$APP_NAME.app" ]; then
    echo "Удаляем старую сборку..."
    rm -rf "$PROJECT_DIR/../$APP_NAME.app"
fi

# Собираем приложение
echo "Сборка $APP_NAME v$APP_VERSION..."
cd "$PROJECT_DIR" && swift build --configuration release

# Проверяем, был ли успешным предыдущий шаг
if [ $? -ne 0 ]; then
    echo "❌ Ошибка при сборке проекта!"
    echo "Проверьте вывод выше на наличие ошибок компиляции."
    exit 1
fi

# Создаем .app пакет
mkdir -p "$PROJECT_DIR/../$APP_NAME.app/Contents/MacOS"
mkdir -p "$PROJECT_DIR/../$APP_NAME.app/Contents/Resources"

# Копируем исполняемый файл
cp "$PROJECT_DIR/.build/release/$APP_NAME" "$PROJECT_DIR/../$APP_NAME.app/Contents/MacOS/"

# Создаем Info.plist
cat > "$PROJECT_DIR/../$APP_NAME.app/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.$APP_NAME</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME v$APP_VERSION</string>
    <key>CFBundleVersion</key>
    <string>$APP_VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$APP_VERSION</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSMainNibFile</key>
    <string></string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSScreenCaptureUsageDescription</key>
    <string>$APP_NAME требует доступа к экрану для отслеживания синих объектов.</string>
</dict>
</plist>
EOF

echo "✅ Приложение $APP_NAME v$APP_VERSION успешно собрано в директории:"
echo "$PROJECT_DIR/../$APP_NAME.app"
echo ""
echo "Для запуска приложения:"
echo "1. Дважды щелкните $APP_NAME.app в Finder"
echo "   ИЛИ"
echo "2. Выполните ./run.sh в терминале"
echo "" 