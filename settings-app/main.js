const { app, BrowserWindow, ipcMain, dialog } = require('electron');
const path = require('path');
const fs = require('fs');
const { spawn } = require('child_process');
const ClaudeHooksManager = require('./claude-hooks-manager');

let mainWindow;

// 設定ファイルのパス取得
const getConfigPath = () => {
  const appPath = app.getAppPath();
  const isDev = !app.isPackaged;
  
  if (isDev) {
    // 開発時は src/config.json を参照
    return path.join(appPath, '..', 'src', 'config.json');
  } else {
    // 本番時は実行ファイルの隣の config.json を参照
    return path.join(path.dirname(app.getPath('exe')), '..', 'src', 'config.json');
  }
};

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 600,
    height: 800,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false
    },
    icon: path.join(__dirname, 'assets', 'icon.png'),
    autoHideMenuBar: true,
    resizable: false
  });

  mainWindow.loadFile(path.join(__dirname, 'renderer', 'index.html'));

  // 本番環境のためDevToolsを無効化
  // if (!app.isPackaged) {
  //   mainWindow.webContents.openDevTools();
  // }
}

app.whenReady().then(() => {
  createWindow();

  app.on('activate', function () {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', function () {
  if (process.platform !== 'darwin') app.quit();
});

// IPC ハンドラー
// 設定読み込み
ipcMain.handle('load-config', async () => {
  try {
    const configPath = getConfigPath();
    const data = await fs.promises.readFile(configPath, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    console.error('設定読み込みエラー:', error);
    // デフォルト設定を返す
    return {
      notification: {
        duration: 10,
        sound: {
          enabled: true,
          file: "default",
          volume: 80
        }
      },
      messages: {
        stop: {
          title: "Claude Code - 作業完了",
          template: "✅ {message}\n📝 {details}\n⏰ {time}"
        },
        notification: {
          title: "Claude Code - 確認待ち",
          template: "❓ {message}\n📝 {details}\n⏰ {time}"
        }
      }
    };
  }
});

// 設定保存
ipcMain.handle('save-config', async (event, config) => {
  try {
    const configPath = getConfigPath();
    await fs.promises.writeFile(configPath, JSON.stringify(config, null, 2), 'utf8');
    return { success: true };
  } catch (error) {
    console.error('設定保存エラー:', error);
    return { success: false, error: error.message };
  }
});

// テスト通知
ipcMain.handle('test-notification', async () => {
  try {
    const notifyPath = path.join(path.dirname(getConfigPath()), 'notify.py');
    
    // Claude Code hooks方式と同じ独立プロセス実行
    const testData = {
      hook_event_name: "Stop",
      message: "Test completed",
      details: "Test execution from settings tool",
      timestamp: new Date().toISOString()
    };
    
    console.log('Starting independent Python process...');
    console.log('Test data:', testData);
    
    // 完全に独立したPythonプロセスを起動（Claude Code hooks方式）
    const python = spawn('python', [notifyPath], {
      detached: true,
      stdio: ['pipe', 'ignore', 'pipe']
    });
    
    // JSONデータをstdinに送信
    const jsonString = JSON.stringify(testData);
    python.stdin.write(jsonString);
    python.stdin.end();
    
    // エラーログ監視
    python.stderr.on('data', (data) => {
      console.error('Python process error:', data.toString());
    });
    
    // プロセス終了監視
    python.on('close', (code) => {
      console.log(`Python process exited with code: ${code}`);
    });
    
    // プロセスを完全に独立させる
    python.unref();
    
    console.log('Independent Python process started successfully');
    return { success: true };
  } catch (error) {
    console.error('テストエラー:', error);
    return { success: false, error: error.message };
  }
});

// Claude Code連携 IPC処理
let hooksManager = null;

// Claude Hooks Manager初期化
const getHooksManager = () => {
  if (!hooksManager) {
    hooksManager = new ClaudeHooksManager();
  }
  return hooksManager;
};

// ファイル選択ダイアログ
ipcMain.handle('open-file-dialog', async (event, options) => {
  try {
    const result = await dialog.showOpenDialog(mainWindow, options);
    if (!result.canceled && result.filePaths.length > 0) {
      return { success: true, filePath: result.filePaths[0] };
    }
    return { success: false, error: 'ファイルが選択されませんでした' };
  } catch (error) {
    return { success: false, error: error.message };
  }
});

// hooks設定状態確認
ipcMain.handle('check-hooks-status', async (event, settingsPath) => {
  try {
    const manager = getHooksManager();
    const status = await manager.checkHooksStatus(settingsPath);
    return { success: true, status };
  } catch (error) {
    return { success: false, error: error.message };
  }
});

// hooks設定適用
ipcMain.handle('apply-hooks-config', async (event, settingsPath, enableStop, enableNotification) => {
  try {
    const manager = getHooksManager();
    const result = await manager.applyHooksConfig(settingsPath, enableStop, enableNotification);
    return result;
  } catch (error) {
    return { success: false, error: error.message };
  }
});

// 連携テスト
ipcMain.handle('test-integration', async () => {
  try {
    const manager = getHooksManager();
    const result = await manager.testIntegration();
    return result;
  } catch (error) {
    return { success: false, error: error.message };
  }
});

// 設定バックアップ
ipcMain.handle('backup-settings', async (event, settingsPath) => {
  try {
    const manager = getHooksManager();
    const result = await manager.backupSettings(settingsPath);
    return result;
  } catch (error) {
    return { success: false, error: error.message };
  }
});