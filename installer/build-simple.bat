@echo off
echo Creating Claude Code Notifier installer...
:: Check NSIS
if exist "C:\Program Files (x86)\NSIS\makensis.exe" (
    set NSIS_EXE=C:\Program Files (x86)\NSIS\makensis.exe
) else (
    if exist "C:\Program Files\NSIS\makensis.exe" (
        set NSIS_EXE=C:\Program Files\NSIS\makensis.exe
    ) else (
        echo Error: NSIS not found
        echo Please install NSIS from https://nsis.sourceforge.io/
        pause
        exit /b 1
    )
)
echo NSIS found: %NSIS_EXE%
:: Move to project root
cd /d "%~dp0"
cd ..
:: Create builds folder
if not exist "builds" mkdir "builds"
:: Check Node.js
where node >nul 2>&1
if errorlevel 1 (
    echo Error: Node.js not found
    pause
    exit /b 1
)
echo Node.js found
:: Build Electron app if needed
if not exist "settings-app\dist\win-unpacked\Claude通知設定.exe" (
    echo Building Electron app...
    cd settings-app
    npm install
    npm run build
    cd ..
)
:: Build installer
cd installer
"%NSIS_EXE%" ClaudeCodeNotifier-Simple.nsi
cd ..
echo Done! Check builds folder for Setup.exe
pause