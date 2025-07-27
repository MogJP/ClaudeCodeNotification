@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

echo ===============================================
echo Claude Code 通知システム - ポータブル版作成
echo ===============================================
echo.

:: 作業ディレクトリに移動
cd /d "%~dp0"

echo [1/4] パッケージディレクトリの準備...

:: 古いパッケージディレクトリを削除
if exist "ClaudeCodeNotifier-Portable" rmdir /s /q "ClaudeCodeNotifier-Portable"

:: パッケージディレクトリ作成
mkdir "ClaudeCodeNotifier-Portable"
mkdir "ClaudeCodeNotifier-Portable\src"
mkdir "ClaudeCodeNotifier-Portable\settings-app"

echo [2/4] Files copying...

:: Python notification system copy
copy "src\notify.py" "ClaudeCodeNotifier-Portable\src\"
copy "src\config.json" "ClaudeCodeNotifier-Portable\src\"
copy "src\settings_template.json" "ClaudeCodeNotifier-Portable\src\"

:: Electron app source copy
copy "settings-app\main.js" "ClaudeCodeNotifier-Portable\settings-app\"
copy "settings-app\preload.js" "ClaudeCodeNotifier-Portable\settings-app\"
copy "settings-app\claude-hooks-manager.js" "ClaudeCodeNotifier-Portable\settings-app\"
copy "settings-app\package.json" "ClaudeCodeNotifier-Portable\settings-app\"
xcopy /E /Y "settings-app\renderer" "ClaudeCodeNotifier-Portable\settings-app\renderer\"

:: node_modulesをコピー（巨大なのでスキップ）
echo.
echo Electronアプリの実行ファイルが必要です。
echo 以下の方法でElectronアプリを含めることができます：
echo.
echo 1. 手動でnode_modulesをコピー（時間がかかります）
echo 2. ユーザー側でnpm installを実行
echo.
choice /M "node_modulesをコピーしますか"
if errorlevel 2 goto :skip_node_modules
if errorlevel 1 goto :copy_node_modules

:copy_node_modules
echo node_modulesをコピー中... （時間がかかります）
xcopy /E /Y "settings-app\node_modules" "ClaudeCodeNotifier-Portable\settings-app\node_modules\"
goto :continue

:skip_node_modules
echo node_modulesはスキップしました。

:continue

echo [3/4] セットアップスクリプトの作成...

:: ポータブル版専用のセットアップスクリプトを作成
(
echo @echo off
echo chcp 65001 ^>nul
echo echo ===============================================
echo echo Claude Code 通知システム - ポータブル版セットアップ
echo echo ===============================================
echo echo.
echo.
echo echo [1/3] Python環境の確認...
echo python --version ^>nul 2^>^&1
echo if errorlevel 1 ^(
echo     echo Python 3.x がインストールされていません。
echo     echo https://www.python.org/downloads/ からダウンロードしてください。
echo     pause
echo     exit /b 1
echo ^)
echo echo Python が見つかりました
echo python --version
echo echo.
echo.
echo echo [2/3] Python ライブラリのインストール...
echo python -m pip install win10toast-click
echo if errorlevel 1 ^(
echo     echo ライブラリのインストールに失敗しました。
echo     pause
echo     exit /b 1
echo ^)
echo echo.
echo.
echo echo [3/3] 通知テスト...
echo python src\notify.py
echo echo.
echo.
echo echo ===============================================
echo echo セットアップ完了！
echo echo ===============================================
echo echo.
echo echo 次に設定アプリを起動するには：
echo echo 1. Node.js がインストールされている場合：
echo echo    cd settings-app ^&^& npm install ^&^& npm start
echo echo.
echo echo 2. 手動でClaude Code設定する場合：
echo echo    C:\Users\%%USERNAME%%\.claude\settings.local.json に以下を追加：
echo echo.
echo echo    "hooks": {
echo echo      "Stop": [{"matcher": "", "hooks": [{"type": "command", "command": "python \"%~dp0src\\\\notify.py\""}]}],
echo echo      "Notification": [{"matcher": "", "hooks": [{"type": "command", "command": "python \"%~dp0src\\\\notify.py\""}]}]
echo echo    }
echo echo.
echo pause
) > "ClaudeCodeNotifier-Portable\setup.bat"

echo [4/4] READMEファイルの作成...

:: README作成
(
echo # Claude Code 通知システム - ポータブル版
echo.
echo ## セットアップ手順
echo.
echo 1. setup.bat を実行してPython環境をセットアップ
echo 2. settings-app/ でElectronアプリを起動（Node.js必要）
echo 3. Claude Code設定ファイルを編集してhooksを追加
echo.
echo ## 必要な環境
echo.
echo - Python 3.9以上
echo - Node.js （設定アプリ使用時）
echo.
echo ## 手動設定
echo.
echo C:\Users\[ユーザー名]\.claude\settings.local.json に以下を追加：
echo.
echo ```json
echo {
echo   "hooks": {
echo     "Stop": [{
echo       "matcher": "",
echo       "hooks": [{
echo         "type": "command",
echo         "command": "python \"[このフォルダのパス]\\src\\notify.py\""
echo       }]
echo     }],
echo     "Notification": [{
echo       "matcher": "",
echo       "hooks": [{
echo         "type": "command", 
echo         "command": "python \"[このフォルダのパス]\\src\\notify.py\""
echo       }]
echo     }]
echo   }
echo }
echo ```
) > "ClaudeCodeNotifier-Portable\README.md"

echo ===============================================
echo ポータブル版作成完了！
echo ===============================================
echo.
echo フォルダ: ClaudeCodeNotifier-Portable
echo.
echo 配布方法：
echo 1. ClaudeCodeNotifier-Portable フォルダをZIP化
echo 2. ユーザーは任意の場所に展開
echo 3. setup.bat を実行してセットアップ
echo.
pause