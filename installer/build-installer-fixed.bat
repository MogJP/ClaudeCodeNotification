@echo off
setlocal EnableDelayedExpansion

echo ===============================================
echo Claude Code Notifier Installer Build
echo ===============================================
echo.

:: Environment Check
echo [1/6] Checking environment...

:: NSIS Detection
echo Searching for NSIS...

:: Check common installation locations
set "NSIS_PATH="
if exist "C:\Program Files (x86)\NSIS\makensis.exe" (
    set "NSIS_PATH=C:\Program Files (x86)\NSIS\makensis.exe"
) else (
    if exist "C:\Program Files\NSIS\makensis.exe" (
        set "NSIS_PATH=C:\Program Files\NSIS\makensis.exe"
    ) else (
        if exist "%ProgramFiles(x86)%\NSIS\makensis.exe" (
            set "NSIS_PATH=%ProgramFiles(x86)%\NSIS\makensis.exe"
        ) else (
            if exist "%ProgramFiles%\NSIS\makensis.exe" (
                set "NSIS_PATH=%ProgramFiles%\NSIS\makensis.exe"
            )
        )
    )
)

:: Search in PATH
if "%NSIS_PATH%"=="" (
    where makensis >nul 2>&1
    if not errorlevel 1 (
        for /f "delims=" %%i in ('where makensis') do set "NSIS_PATH=%%i"
    )
)

:: Manual input if not found
if "%NSIS_PATH%"=="" (
    echo.
    echo ===============================================
    echo NSIS not found automatically
    echo ===============================================
    echo.
    echo If NSIS is not installed:
    echo Download from https://nsis.sourceforge.io/
    echo.
    echo If already installed:
    echo Enter full path to makensis.exe
    echo Example: C:\Tools\NSIS\makensis.exe
    echo.
    set /p "NSIS_PATH=Path to makensis.exe (or Enter to skip): "
    
    if "%NSIS_PATH%"=="" (
        echo Cannot create installer without NSIS
        pause
        exit /b 1
    )
    
    if not exist "%NSIS_PATH%" (
        echo Error: makensis.exe not found at specified path
        pause
        exit /b 1
    )
)

echo NSIS found: %NSIS_PATH%

:: Move to project root
cd /d "%~dp0"
cd ..

echo [2/6] Creating builds folder...

:: Create builds folder
if not exist "builds" mkdir "builds"

echo [3/6] File verification...

:: Check required files
if not exist "src\notify.py" (
    echo Error: src\notify.py not found
    pause
    exit /b 1
)

echo [4/6] Node.js environment check...

:: Node.js environment check
where node >nul 2>&1
if errorlevel 1 (
    echo Error: Node.js not found
    echo Please install Node.js: https://nodejs.org/
    pause
    exit /b 1
)

echo Node.js found
node --version

echo [5/6] Electron app check and build...

:: Electron app existence check
if not exist "settings-app\dist\win-unpacked\Claude通知設定.exe" (
    echo Electron app not found. Building automatically...
    
    :: Move to settings-app directory
    cd settings-app
    
    echo Checking npm dependencies...
    if not exist "node_modules" (
        echo Running npm install...
        npm install
        if errorlevel 1 (
            echo Error: npm install failed
            cd ..
            pause
            exit /b 1
        )
    )
    
    echo Building Electron app... (this may take several minutes)
    npm run build
    if errorlevel 1 (
        echo Error: Electron app build failed
        cd ..
        pause
        exit /b 1
    )
    
    :: Return to original directory
    cd ..
    
    echo Electron app build completed!
) else (
    echo Electron app found
)

echo [6/6] Creating installer...

:: Build installer
cd installer
"%NSIS_PATH%" ClaudeCodeNotifier-Simple.nsi
if errorlevel 1 (
    echo Error: Installer creation failed
    pause
    exit /b 1
)

cd ..

echo Complete!

:: Display created installer file information
if exist "builds\ClaudeCodeNotifier-Setup.exe" (
    for %%A in ("builds\ClaudeCodeNotifier-Setup.exe") do (
        set /a size=%%~zA/1024/1024
        echo.
        echo ===============================================
        echo Installer created successfully
        echo ===============================================
        echo File: ClaudeCodeNotifier-Setup.exe
        echo Size: !size! MB
        echo Location: %CD%\builds\ClaudeCodeNotifier-Setup.exe
        echo ===============================================
    )
) else (
    echo Error: Installer file not found
    pause
    exit /b 1
)

echo.
echo Ready for distribution!
echo Upload this Setup.exe to GitHub Releases for easy user installation.
echo.
pause