; Claude Code Notifier Simple Installer - English Version
!include "MUI2.nsh"
!include "LogicLib.nsh"

; Basic Settings
Name "Claude Code Notification System"
OutFile "..\builds\ClaudeCodeNotifier-Setup.exe"
InstallDir "$PROGRAMFILES\ClaudeCodeNotifier"
RequestExecutionLevel admin

; Version info
VIProductVersion "1.0.0.0"
VIAddVersionKey /LANG=1033 "ProductName" "Claude Code Notification System"
VIAddVersionKey /LANG=1033 "ProductVersion" "1.0.0"
VIAddVersionKey /LANG=1033 "CompanyName" "Claude Code Notifier Project"
VIAddVersionKey /LANG=1033 "FileDescription" "Claude Code Notification System Installer"
VIAddVersionKey /LANG=1033 "LegalCopyright" "© Claude Code Notifier Project"

; Modern UI Settings
!define MUI_ABORTWARNING
!define MUI_WELCOMEPAGE_TITLE "Claude Code Notification System Setup Wizard"
!define MUI_WELCOMEPAGE_TEXT "This program will install Claude Code Notification System on your computer.$\r$\n$\r$\nDisplays Windows notifications when Claude Code completes tasks or waits for confirmation.$\r$\n$\r$\nClick [Next] to continue."
!define MUI_FINISHPAGE_TITLE "Claude Code Notification System Installation Complete"
!define MUI_FINISHPAGE_TEXT "Claude Code Notification System installation is complete.$\r$\n$\r$\nPlease configure detailed settings using the settings app."

; Page Settings
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Uninstall Pages
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; Language Settings
!insertmacro MUI_LANGUAGE "English"

; Variables
Var /GLOBAL PYTHON_PATH

; Section: Notification Core (Required)
Section "Notification Core" SecCore
  SectionIn RO  ; Required
  
  ; Check Python Environment
  Call CheckPython
  
  ; Create Directories
  CreateDirectory "$INSTDIR"
  CreateDirectory "$INSTDIR\src"
  
  ; Copy Files
  SetOutPath "$INSTDIR\src"
  File "..\src\notify.py"
  File "..\src\config.json"
  File "..\src\settings_template.json"
  
  ; Install Python Libraries
  DetailPrint "Installing Python libraries..."
  ExecWait '"$PYTHON_PATH" -m pip install win10toast-click' $0
  ${If} $0 != 0
    MessageBox MB_ICONEXCLAMATION "Python library installation failed. Please run manually:$\r$\npip install win10toast-click"
  ${EndIf}
  
  ; Registry Registration
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCodeNotifier" "DisplayName" "Claude Code Notification System"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCodeNotifier" "UninstallString" "$INSTDIR\uninstall.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCodeNotifier" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCodeNotifier" "DisplayVersion" "1.0.0"
  
  ; Create Uninstaller
  WriteUninstaller "$INSTDIR\uninstall.exe"
  
  ; Create Settings App Directory
  CreateDirectory "$INSTDIR\settings-app"
  
  ; Copy Electron Built App
  CreateDirectory "$INSTDIR\settings-app\dist"
  SetOutPath "$INSTDIR\settings-app\dist"
  File /r "..\settings-app\dist\win-unpacked"
  
  ; Copy Basic Config Files (for development)
  SetOutPath "$INSTDIR\settings-app"
  File "..\settings-app\main.js"
  File "..\settings-app\preload.js"
  File "..\settings-app\claude-hooks-manager.js"
  File "..\settings-app\package.json"
  
  ; Copy renderer directory
  CreateDirectory "$INSTDIR\settings-app\renderer"
  SetOutPath "$INSTDIR\settings-app\renderer"
  File "..\settings-app\renderer\*.*"
  
  ; Create Start Menu Shortcuts
  CreateDirectory "$SMPROGRAMS\Claude Code Notification System"
  Call CreateElectronShortcut
  CreateShortcut "$SMPROGRAMS\Claude Code Notification System\Test Notification.lnk" "$INSTDIR\test-notification.bat"
  CreateShortcut "$SMPROGRAMS\Claude Code Notification System\Uninstall.lnk" "$INSTDIR\uninstall.exe"
  
  ; Create Utility Batch Files
  Call CreateUtilityBatches
SectionEnd

; Function: Check Python Environment
Function CheckPython
  ; First look for python in PATH
  ExecWait 'where python' $0
  ${If} $0 == 0
    StrCpy $PYTHON_PATH "python"
  ${Else}
    ; If Python not found
    MessageBox MB_ICONEXCLAMATION|MB_YESNO "Python 3.x not found.$\r$\nPlease install Python.$\r$\n$\r$\nContinue anyway?" IDYES +2
    Quit
    StrCpy $PYTHON_PATH "python"
  ${EndIf}
FunctionEnd

; Function: Create Electron App Shortcut
Function CreateElectronShortcut
  ; Find the .exe file in the Electron directory
  FindFirst $0 $1 "$INSTDIR\settings-app\dist\win-unpacked\*.exe"
  StrCmp $1 "" done
  CreateShortcut "$SMPROGRAMS\Claude Code Notification System\Claude Notification Settings.lnk" "$INSTDIR\settings-app\dist\win-unpacked\$1"
  done:
  FindClose $0
FunctionEnd

; Function: Create Utility Batch Files
Function CreateUtilityBatches
  ; Settings App Launch Batch
  FileOpen $0 "$INSTDIR\start-settings.bat" w
  FileWrite $0 "@echo off$\r$\n"
  FileWrite $0 "cd /d $\"$INSTDIR\settings-app$\"$\r$\n"
  FileWrite $0 "echo Claude Code Notification System Settings App$\r$\n"
  FileWrite $0 "echo =========================================$\r$\n"
  FileWrite $0 "echo.$\r$\n"
  FileWrite $0 "echo Checking Node.js environment...$\r$\n"
  FileWrite $0 "where node >nul 2>&1$\r$\n"
  FileWrite $0 "if errorlevel 1 ($\r$\n"
  FileWrite $0 "    echo Node.js is not installed.$\r$\n"
  FileWrite $0 "    echo Please download and install from https://nodejs.org/$\r$\n"
  FileWrite $0 "    echo.$\r$\n"
  FileWrite $0 "    echo For manual Claude Code configuration:$\r$\n"
  FileWrite $0 "    echo Add the following to C:\Users\%USERNAME%\.claude\settings.local.json$\r$\n"
  FileWrite $0 "    echo.$\r$\n"
  FileWrite $0 "    echo $\"hooks$\": {$\r$\n"
  FileWrite $0 "    echo   $\"Stop$\": [{$\"matcher$\": $\"$\", $\"hooks$\": [{$\"type$\": $\"command$\", $\"command$\": $\"python \\$\"$INSTDIR\src\\notify.py\\$\"$\"}]}],$\r$\n"
  FileWrite $0 "    echo   $\"Notification$\": [{$\"matcher$\": $\"$\", $\"hooks$\": [{$\"type$\": $\"command$\", $\"command$\": $\"python \\$\"$INSTDIR\src\\notify.py\\$\"$\"}]}]$\r$\n"
  FileWrite $0 "    echo }$\r$\n"
  FileWrite $0 "    pause$\r$\n"
  FileWrite $0 "    exit /b 1$\r$\n"
  FileWrite $0 ")$\r$\n"
  FileWrite $0 "echo.$\r$\n"
  FileWrite $0 "echo Installing npm dependencies...$\r$\n"
  FileWrite $0 "npm install$\r$\n"
  FileWrite $0 "if errorlevel 1 ($\r$\n"
  FileWrite $0 "    echo npm install failed.$\r$\n"
  FileWrite $0 "    pause$\r$\n"
  FileWrite $0 "    exit /b 1$\r$\n"
  FileWrite $0 ")$\r$\n"
  FileWrite $0 "echo.$\r$\n"
  FileWrite $0 "echo Starting settings app...$\r$\n"
  FileWrite $0 "npm start$\r$\n"
  FileClose $0
  
  ; Notification Test Batch
  FileOpen $0 "$INSTDIR\test-notification.bat" w
  FileWrite $0 "@echo off$\r$\n"
  FileWrite $0 "echo Claude Code Notification Test$\r$\n"
  FileWrite $0 "echo ========================$\r$\n"
  FileWrite $0 "echo.$\r$\n"
  FileWrite $0 "python $\"$INSTDIR\src\notify.py$\"$\r$\n"
  FileWrite $0 "echo.$\r$\n"
  FileWrite $0 "echo Did you see the notification?$\r$\n"
  FileWrite $0 "pause$\r$\n"
  FileClose $0
FunctionEnd

; Uninstall Section
Section "Uninstall"
  ; Delete Files
  Delete "$INSTDIR\src\*.*"
  Delete "$INSTDIR\settings-app\renderer\*.*"
  Delete "$INSTDIR\settings-app\*.*"
  Delete "$INSTDIR\*.bat"
  Delete "$INSTDIR\uninstall.exe"
  
  ; Delete Directories
  RMDir "$INSTDIR\src"
  RMDir "$INSTDIR\settings-app\renderer"
  RMDir "$INSTDIR\settings-app"
  RMDir "$INSTDIR"
  
  ; Delete Shortcuts
  Delete "$SMPROGRAMS\Claude Code Notification System\*.*"
  RMDir "$SMPROGRAMS\Claude Code Notification System"
  
  ; Delete Registry
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCodeNotifier"
SectionEnd