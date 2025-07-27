@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

echo ===============================================
echo Claude Code 通知システム - 簡単セットアップ
echo ===============================================
echo.
echo このスクリプトは自動で以下を実行します：
echo 1. Python環境の確認・インストール
echo 2. 必要なライブラリのインストール
echo 3. Electronアプリの起動
echo 4. Claude Code設定の案内
echo.

:: 管理者権限確認
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo 注意: 管理者権限での実行を推奨します
    echo 続行しますか？ ^(Y/N^)
    set /p confirm=
    if /i not "%confirm%"=="y" exit /b 0
)

echo [ステップ1/4] Python環境の確認...
echo.

:: Python 3.xの確認
python --version >nul 2>&1
if errorlevel 1 (
    echo Python 3.xがインストールされていません。
    echo.
    echo Python公式サイトからダウンロードしてインストールしてください：
    echo https://www.python.org/downloads/
    echo.
    echo インストール時の注意：
    echo - "Add Python to PATH"にチェックを入れてください
    echo - "pip"もインストールしてください
    echo.
    pause
    echo.
    echo Python をインストールしましたか？ ^(Y/N^)
    set /p installed=
    if /i not "%installed%"=="y" (
        echo セットアップを中止します。
        pause
        exit /b 1
    )
    
    :: 再度確認
    python --version >nul 2>&1
    if errorlevel 1 (
        echo Pythonが正しくインストールされていないようです。
        echo PATH設定を確認して、コマンドプロンプトを再起動してください。
        pause
        exit /b 1
    )
)

echo Python が見つかりました:
python --version
echo.

echo [ステップ2/4] Pythonライブラリのインストール...
echo.

:: win10toast-clickのインストール
echo win10toast-click をインストール中...
python -m pip install win10toast-click
if errorlevel 1 (
    echo ライブラリのインストールに失敗しました。
    echo インターネット接続を確認してください。
    pause
    exit /b 1
)

echo ライブラリのインストール完了！
echo.

echo [ステップ3/4] 通知テスト...
echo.

:: 通知テスト実行
echo 通知テストを実行します...
cd /d "%~dp0"
python src\notify.py "Claude Code セットアップ" "通知システムが正常に動作しています！"
if errorlevel 1 (
    echo 通知テストに失敗しました。
    echo エラーの詳細を確認してください。
) else (
    echo 通知テスト成功！（デスクトップ右下に通知が表示されたはずです）
)
echo.

echo [ステップ4/4] Electron設定アプリの起動...
echo.

:: Electronアプリが存在するかチェック
if exist "settings-app\dist\win-unpacked\Claude通知設定.exe" (
    echo Electron設定アプリを起動します...
    start "" "settings-app\dist\win-unpacked\Claude通知設定.exe"
    echo.
    echo 設定アプリを起動しました！
    echo.
    echo 【次に行うこと】
    echo 1. 開いた設定アプリの「Claude Code連携」タブをクリック
    echo 2. 「ファイルを選択」ボタンをクリック
    echo 3. Claude Codeの設定ファイルを選択:
    echo    C:\Users\%USERNAME%\.claude\settings.local.json
    echo 4. 「設定を適用」ボタンをクリック
    echo 5. Claude Codeを再起動
    echo.
    echo これでClaude Codeの作業完了時に通知が表示されます！
) else (
    echo 設定アプリが見つかりません。
    echo 以下のコマンドでElectronアプリをビルドしてください：
    echo.
    echo cd settings-app
    echo npm install
    echo npm run build
    echo.
    echo または、手動でClaude Code設定を行ってください：
    echo.
    echo 【手動設定方法】
    echo 1. C:\Users\%USERNAME%\.claude\settings.local.json を開く
    echo 2. 以下の内容を追加:
    echo.
    echo {
    echo   "hooks": {
    echo     "Stop": [{
    echo       "matcher": "",
    echo       "hooks": [{
    echo         "type": "command",
    echo         "command": "python \"%~dp0src\\notify.py\""
    echo       }]
    echo     }],
    echo     "Notification": [{
    echo       "matcher": "",
    echo       "hooks": [{
    echo         "type": "command", 
    echo         "command": "python \"%~dp0src\\notify.py\""
    echo       }]
    echo     }]
    echo   }
    echo }
)

echo.
echo ===============================================
echo セットアップ完了！
echo ===============================================
echo.
echo Claude Codeを使用する際、作業完了時や確認待ち時に
echo Windows通知が表示されるようになりました。
echo.
pause