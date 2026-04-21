#!/usr/bin/env bash
# Sergi — первичная настройка проекта.
# Требуется macOS с Xcode 15+.

set -euo pipefail

echo "▶︎ Проверяю окружение…"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "✖︎ Этот скрипт работает только на macOS. Обнаружено: $(uname -s)"
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "✖︎ Xcode не найден. Установите Xcode 15+ из App Store и выполните: xcode-select --install"
  exit 1
fi

XCODE_VERSION="$(xcodebuild -version | head -1 | awk '{print $2}')"
echo "✓ Xcode $XCODE_VERSION"

if ! command -v brew >/dev/null 2>&1; then
  echo "▶︎ Homebrew не найден. Устанавливаю…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "▶︎ Устанавливаю XcodeGen…"
  brew install xcodegen
fi

echo "✓ XcodeGen $(xcodegen --version)"

echo "▶︎ Валидирую plist-файлы…"
plutil -lint Sergi/Info.plist
plutil -lint Sergi/Sergi.entitlements
plutil -lint Sergi/PrivacyInfo.xcprivacy

echo "▶︎ Генерирую Xcode-проект…"
xcodegen generate

echo ""
echo "✅ Готово. Дальше:"
echo "   1) open Sergi.xcodeproj"
echo "   2) target Sergi → Signing & Capabilities → выберите Team"
echo "   3) (опц.) Scheme → Edit Scheme → Run → Environment Variables → OPENAI_API_KEY"
echo "   4) Выберите симулятор iPhone 15 (iOS 17+) и нажмите ⌘R"
