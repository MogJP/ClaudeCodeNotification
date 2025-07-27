@echo off
setlocal EnableDelayedExpansion

echo ===============================================
echo Claude Code Notifier - Build Script
echo ===============================================
echo.

:: Environment Check
echo [1/4] Checking environment...

:: Check Node.js
where node >nul 2>&1
if errorlevel 1 (
    echo Error: Node.js not found
    echo Download Node.js: https://nodejs.org/
    pause
    exit /b 1
)

:: Check Python
where python >nul 2>&1
if errorlevel 1 (
    echo Error: Python not found
    echo Download Python: https://www.python.org/
    pause
    exit /b 1
)

echo [2/4] Building Electron settings tool...
cd settings-app

:: Check npm dependencies
if not exist "node_modules" (
    echo Installing npm dependencies...
    call npm install
    if errorlevel 1 (
        echo Error: npm install failed
        pause
        exit /b 1
    )
)

:: Build Electron
echo Building Electron app...
call npm run build
if errorlevel 1 (
    echo Error: Electron build failed
    pause
    exit /b 1
)

cd ..

echo [3/4] Installing Python dependencies...
pip install win10toast-click
if errorlevel 1 (
    echo Warning: win10toast-click install failed
    echo User needs to install manually
)

echo [4/4] Complete!
echo.
echo ===============================================
echo Build completed successfully!
echo ===============================================
echo.
echo Next steps:
echo 1. Run test-electron.bat to test Electron settings tool
echo 2. Run test-python.bat to test Python notifications
echo 3. Run installer/build-installer.bat to create installer
echo.
pause