@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

echo ===============================================
echo Claude Code Notifier インストーラー作成
echo ===============================================
echo.

:: 環境確認
echo [1/4] 環境確認中...

:: NSIS の確認
set "NSIS_PATH=C:\Program Files (x86)\NSIS\makensis.exe"
if not exist "%NSIS_PATH%" (
    echo エラー: NSIS が見つかりません
    echo NSIS をインストールしてください: https://nsis.sourceforge.io/
    pause
    exit /b 1
)

:: プロジェクトルートに移動
cd /d "%~dp0"
cd ..

echo [2/4] buildsフォルダ作成...

:: buildsフォルダ作成
if not exist "builds" mkdir "builds"

echo [3/6] ファイル確認...

:: 必要なファイルの確認
if not exist "src\notify.py" (
    echo エラー: src\notify.py が見つかりません
    pause
    exit /b 1
)

echo [4/6] Node.js環境確認...

:: Node.js環境の確認
where node >nul 2>&1
if errorlevel 1 (
    echo エラー: Node.js が見つかりません
    echo Node.js をインストールしてください: https://nodejs.org/
    pause
    exit /b 1
)

echo Node.js が見つかりました
node --version

echo [5/6] Electronアプリの確認・ビルド...

:: Electronアプリの存在確認
if not exist "settings-app\dist\win-unpacked\Claude通知設定.exe" (
    echo Electronアプリが見つかりません。自動でビルドします...
    
    :: settings-appディレクトリに移動
    cd settings-app
    
    echo npm依存関係を確認中...
    if not exist "node_modules" (
        echo npm install を実行中...
        npm install
        if errorlevel 1 (
            echo エラー: npm install に失敗しました
            cd ..
            pause
            exit /b 1
        )
    )
    
    echo Electronアプリをビルド中... (数分かかります)
    npm run build
    if errorlevel 1 (
        echo エラー: Electronアプリのビルドに失敗しました
        cd ..
        pause
        exit /b 1
    )
    
    :: 元のディレクトリに戻る
    cd ..
    
    echo Electronアプリのビルドが完了しました！
) else (
    echo Electronアプリが見つかりました
)

echo [6/6] インストーラー作成中...

:: インストーラーをビルド
cd installer
"%NSIS_PATH%" ClaudeCodeNotifier-Simple.nsi
if errorlevel 1 (
    echo エラー: インストーラーの作成に失敗しました
    pause
    exit /b 1
)

cd ..

echo 完了!

:: 作成されたインストーラーのファイル情報表示
if exist "builds\ClaudeCodeNotifier-Setup.exe" (
    for %%A in ("builds\ClaudeCodeNotifier-Setup.exe") do (
        set /a size=%%~zA/1024/1024
        echo.
        echo ===============================================
        echo インストーラーが正常に作成されました
        echo ===============================================
        echo ファイル: ClaudeCodeNotifier-Setup.exe
        echo ファイルサイズ: !size! MB
        echo 場所: %CD%\builds\ClaudeCodeNotifier-Setup.exe
        echo ===============================================
    )
) else (
    echo エラー: インストーラーファイルが見つかりません
    pause
    exit /b 1
)

echo.
echo 配布準備完了！
echo このSetup.exeを配布すれば、他のユーザーはリポジトリなしでインストールできます。
echo.
pause