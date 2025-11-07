@echo off
SETLOCAL

echo === Setting up Flutter project (generating platforms) ===
flutter --version >NUL 2>&1
IF ERRORLEVEL 1 (
  echo [Error] Flutter is not installed or not on PATH.
  echo Download: https://docs.flutter.dev/get-started/install
  exit /b 1
)

REM Create missing platform folders and project files
flutter create .
IF ERRORLEVEL 1 (
  echo [Error] flutter create failed.
  exit /b 1
)

echo === Restoring packages ===
flutter pub get

echo === Running the app ===
flutter run