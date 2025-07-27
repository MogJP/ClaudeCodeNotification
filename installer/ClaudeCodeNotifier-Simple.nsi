; Claude Code Notifier Simple Installer
!include "MUI2.nsh"
!include "LogicLib.nsh"

; 基本設定
Name "Claude Code 通知システム"
OutFile "..\builds\ClaudeCodeNotifier-Setup.exe"
InstallDir "$PROGRAMFILES\ClaudeCodeNotifier"
RequestExecutionLevel admin

; Version info
VIProductVersion "1.0.0.0"
VIAddVersionKey /LANG=1041 "ProductName" "Claude Code 通知システム"
VIAddVersionKey /LANG=1041 "ProductVersion" "1.0.0"
VIAddVersionKey /LANG=1041 "CompanyName" "Claude Code Notifier Project"
VIAddVersionKey /LANG=1041 "FileDescription" "Claude Code 通知システム インストーラー"
VIAddVersionKey /LANG=1041 "LegalCopyright" "© Claude Code Notifier Project"

; Modern UI設定
!define MUI_ABORTWARNING
!define MUI_WELCOMEPAGE_TITLE "Claude Code 通知システム セットアップウィザード"
!define MUI_WELCOMEPAGE_TEXT "このプログラムはClaude Code 通知システムをお使いのコンピューターにインストールします。$\r$\n$\r$\nClaude Code の作業完了時や確認待ち時にWindows通知を表示します。$\r$\n$\r$\n[次へ] をクリックして続行してください。"
!define MUI_FINISHPAGE_TITLE "Claude Code 通知システム インストール完了"
!define MUI_FINISHPAGE_TEXT "Claude Code 通知システムのインストールが完了しました。$\r$\n$\r$\n設定アプリで詳細設定を行ってください。"

; ページ設定
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; アンインストール用
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; 言語設定
!insertmacro MUI_LANGUAGE "Japanese"

; 変数
Var /GLOBAL PYTHON_PATH

; セクション: 通知コア（必須）
Section "通知コア" SecCore
  SectionIn RO  ; 必須選択
  
  ; Python環境確認
  Call CheckPython
  
  ; ディレクトリ作成
  CreateDirectory "$INSTDIR"
  CreateDirectory "$INSTDIR\src"
  
  ; ファイルコピー
  SetOutPath "$INSTDIR\src"
  File "..\src\notify.py"
  File "..\src\config.json"
  File "..\src\settings_template.json"
  
  ; Pythonライブラリインストール
  DetailPrint "Python ライブラリをインストール中..."
  ExecWait '"$PYTHON_PATH" -m pip install win10toast-click' $0
  ${If} $0 != 0
    MessageBox MB_ICONEXCLAMATION "Python ライブラリのインストールに失敗しました。手動で実行してください:$\r$\npip install win10toast-click"
  ${EndIf}
  
  ; レジストリ登録
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCodeNotifier" "DisplayName" "Claude Code 通知システム"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCodeNotifier" "UninstallString" "$INSTDIR\uninstall.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCodeNotifier" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCodeNotifier" "DisplayVersion" "1.0.0"
  
  ; アンインストーラー作成
  WriteUninstaller "$INSTDIR\uninstall.exe"
  
  ; 設定アプリディレクトリ作成
  CreateDirectory "$INSTDIR\settings-app"
  
  ; Electronビルド済みアプリをコピー
  CreateDirectory "$INSTDIR\settings-app\dist"
  SetOutPath "$INSTDIR\settings-app\dist"
  File /r "..\settings-app\dist\win-unpacked"
  
  ; 基本的な設定ファイルもコピー（開発用）
  SetOutPath "$INSTDIR\settings-app"
  File "..\settings-app\main.js"
  File "..\settings-app\preload.js"
  File "..\settings-app\claude-hooks-manager.js"
  File "..\settings-app\package.json"
  
  ; rendererディレクトリをコピー
  CreateDirectory "$INSTDIR\settings-app\renderer"
  SetOutPath "$INSTDIR\settings-app\renderer"
  File "..\settings-app\renderer\*.*"
  
  ; スタートメニューショートカット作成
  CreateDirectory "$SMPROGRAMS\Claude Code 通知システム"
  CreateShortcut "$SMPROGRAMS\Claude Code 通知システム\Claude通知設定.lnk" "$INSTDIR\settings-app\dist\win-unpacked\Claude通知設定.exe"
  CreateShortcut "$SMPROGRAMS\Claude Code 通知システム\通知テスト.lnk" "$INSTDIR\test-notification.bat"
  CreateShortcut "$SMPROGRAMS\Claude Code 通知システム\アンインストール.lnk" "$INSTDIR\uninstall.exe"
  
  ; 便利なバッチファイルを作成
  Call CreateUtilityBatches
SectionEnd

; 関数: Python環境確認
Function CheckPython
  ; まずPATHからpythonを探す
  ExecWait 'where python' $0
  ${If} $0 == 0
    StrCpy $PYTHON_PATH "python"
  ${Else}
    ; Pythonが見つからない場合
    MessageBox MB_ICONEXCLAMATION|MB_YESNO "Python 3.x が見つかりません。$\r$\nPythonをインストールしてください。$\r$\n$\r$\n続行しますか？" IDYES +2
    Quit
    StrCpy $PYTHON_PATH "python"
  ${EndIf}
FunctionEnd

; 関数: ユーティリティバッチファイル作成
Function CreateUtilityBatches
  ; 設定アプリ起動バッチ
  FileOpen $0 "$INSTDIR\start-settings.bat" w
  FileWrite $0 "@echo off$\r$\n"
  FileWrite $0 "cd /d $\"$INSTDIR\settings-app$\"$\r$\n"
  FileWrite $0 "echo Claude Code 通知システム 設定アプリ$\r$\n"
  FileWrite $0 "echo =========================================$\r$\n"
  FileWrite $0 "echo.$\r$\n"
  FileWrite $0 "echo Node.js環境の確認中...$\r$\n"
  FileWrite $0 "where node >nul 2>&1$\r$\n"
  FileWrite $0 "if errorlevel 1 ($\r$\n"
  FileWrite $0 "    echo Node.js がインストールされていません。$\r$\n"
  FileWrite $0 "    echo https://nodejs.org/ からダウンロードしてインストールしてください。$\r$\n"
  FileWrite $0 "    echo.$\r$\n"
  FileWrite $0 "    echo 手動でClaude Code設定を行う場合：$\r$\n"
  FileWrite $0 "    echo C:\Users\%USERNAME%\.claude\settings.local.json に以下を追加$\r$\n"
  FileWrite $0 "    echo.$\r$\n"
  FileWrite $0 "    echo $\"hooks$\": {$\r$\n"
  FileWrite $0 "    echo   $\"Stop$\": [{$\"matcher$\": $\"$\", $\"hooks$\": [{$\"type$\": $\"command$\", $\"command$\": $\"python \\$\"$INSTDIR\src\\notify.py\\$\"$\"}]}],$\r$\n"
  FileWrite $0 "    echo   $\"Notification$\": [{$\"matcher$\": $\"$\", $\"hooks$\": [{$\"type$\": $\"command$\", $\"command$\": $\"python \\$\"$INSTDIR\src\\notify.py\\$\"$\"}]}]$\r$\n"
  FileWrite $0 "    echo }$\r$\n"
  FileWrite $0 "    pause$\r$\n"
  FileWrite $0 "    exit /b 1$\r$\n"
  FileWrite $0 ")$\r$\n"
  FileWrite $0 "echo.$\r$\n"
  FileWrite $0 "echo npm依存関係をインストール中...$\r$\n"
  FileWrite $0 "npm install$\r$\n"
  FileWrite $0 "if errorlevel 1 ($\r$\n"
  FileWrite $0 "    echo npm install に失敗しました。$\r$\n"
  FileWrite $0 "    pause$\r$\n"
  FileWrite $0 "    exit /b 1$\r$\n"
  FileWrite $0 ")$\r$\n"
  FileWrite $0 "echo.$\r$\n"
  FileWrite $0 "echo 設定アプリを起動中...$\r$\n"
  FileWrite $0 "npm start$\r$\n"
  FileClose $0
  
  ; 通知テストバッチ
  FileOpen $0 "$INSTDIR\test-notification.bat" w
  FileWrite $0 "@echo off$\r$\n"
  FileWrite $0 "echo Claude Code 通知テスト$\r$\n"
  FileWrite $0 "echo ========================$\r$\n"
  FileWrite $0 "echo.$\r$\n"
  FileWrite $0 "python $\"$INSTDIR\src\notify.py$\"$\r$\n"
  FileWrite $0 "echo.$\r$\n"
  FileWrite $0 "echo 通知が表示されましたか？$\r$\n"
  FileWrite $0 "pause$\r$\n"
  FileClose $0
FunctionEnd

; アンインストール
Section "Uninstall"
  ; ファイル削除
  Delete "$INSTDIR\src\*.*"
  Delete "$INSTDIR\settings-app\renderer\*.*"
  Delete "$INSTDIR\settings-app\*.*"
  Delete "$INSTDIR\*.bat"
  Delete "$INSTDIR\uninstall.exe"
  
  ; ディレクトリ削除
  RMDir "$INSTDIR\src"
  RMDir "$INSTDIR\settings-app\renderer"
  RMDir "$INSTDIR\settings-app"
  RMDir "$INSTDIR"
  
  ; ショートカット削除
  Delete "$SMPROGRAMS\Claude Code 通知システム\*.*"
  RMDir "$SMPROGRAMS\Claude Code 通知システム"
  
  ; レジストリ削除
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClaudeCodeNotifier"
SectionEnd