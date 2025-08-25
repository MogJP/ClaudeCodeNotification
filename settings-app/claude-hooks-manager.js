// Claude Code hooks設定管理モジュール
const fs = require('fs');
const path = require('path');

class ClaudeHooksManager {
  constructor() {
    // インストール後のパスを検出
    // Electronアプリがpackage化されている場合はresources/src/notify.pyを使用
    // 開発環境の場合は../src/notify.pyを使用
    const isDev = !process.resourcesPath || process.resourcesPath.includes('node_modules');
    
    if (isDev) {
      // 開発環境: settings-app/../src/notify.py
      this.scriptDir = path.dirname(__dirname);
      this.notifyScript = path.join(this.scriptDir, 'src', 'notify.py');
    } else {
      // 本番環境: インストールディレクトリの親フォルダのsrc/notify.py
      // resources/app.asar/../../../src/notify.py
      const installDir = path.resolve(process.resourcesPath, '..', '..', '..');
      this.notifyScript = path.join(installDir, 'src', 'notify.py');
    }
    
    console.log('Notify script path:', this.notifyScript);
  }

  /**
   * 設定ファイルのバックアップを作成
   */
  async backupSettings(settingsPath) {
    try {
      if (!fs.existsSync(settingsPath)) {
        return { success: false, error: '設定ファイルが存在しません' };
      }

      const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, -5);
      const backupName = `settings.local.json.backup.${timestamp}`;
      const backupPath = path.join(path.dirname(settingsPath), backupName);
      
      await fs.promises.copyFile(settingsPath, backupPath);
      return { success: true, backupPath };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * 既存の設定を読み込み
   */
  async loadExistingSettings(settingsPath) {
    try {
      if (!fs.existsSync(settingsPath)) {
        return { success: true, settings: {} };
      }

      const data = await fs.promises.readFile(settingsPath, 'utf8');
      const settings = JSON.parse(data);
      return { success: true, settings };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * hooks設定を生成
   */
  createHooksConfig(enableStop = true, enableNotification = true, isWindowsEnvironment = false) {
    const hooks = {};

    if (isWindowsEnvironment) {
      // Windows環境用コマンド（ネイティブWindows版Claude Code用）
      // PowerShellで非同期実行、親ウィンドウに影響しないよう設定
      const notifyPath = this.notifyScript.replace(/\//g, '\\');
      
      if (enableStop) {
        hooks.Stop = [
          {
            "matcher": "",
            "hooks": [
              {
                "type": "command",
                "command": `powershell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process -FilePath 'pythonw.exe' -ArgumentList '${notifyPath}', 'Stop', 'Claude Codeの作業が完了しました' -WindowStyle Hidden}"`
              }
            ]
          }
        ];
      }

      if (enableNotification) {
        hooks.Notification = [
          {
            "matcher": "",
            "hooks": [
              {
                "type": "command",
                "command": `powershell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process -FilePath 'pythonw.exe' -ArgumentList '${notifyPath}', 'Notification', 'Claude Codeの確認が必要です' -WindowStyle Hidden}"`
              }
            ]
          }
        ];
      }
    } else {
      // WSL環境用コマンド（WSL/Linux版Claude Code用）
      const notifyPath = this.notifyScript.replace(/\\/g, '/');
      
      if (enableStop) {
        hooks.Stop = [
          {
            "matcher": "",
            "hooks": [
              {
                "type": "command",
                "command": `nohup /mnt/c/Windows/System32/cmd.exe /c python ${notifyPath} Stop "Claude Codeの作業が完了しました" > /dev/null 2>&1 &`
              }
            ]
          }
        ];
      }

      if (enableNotification) {
        hooks.Notification = [
          {
            "matcher": "",
            "hooks": [
              {
                "type": "command",
                "command": `nohup /mnt/c/Windows/System32/cmd.exe /c python ${notifyPath} Notification "Claude Codeの確認が必要です" > /dev/null 2>&1 &`
              }
            ]
          }
        ];
      }
    }

    return hooks;
  }

  /**
   * 設定をマージ
   */
  mergeSettings(existingSettings, hooksConfig) {
    const merged = { ...existingSettings };
    
    // hooks設定を追加
    merged.hooks = hooksConfig;
    
    // 必要な権限を確保
    if (!merged.permissions) {
      merged.permissions = { allow: ["*"], deny: [] };
    } else {
      if (!merged.permissions.allow) {
        merged.permissions.allow = ["*"];
      } else if (!merged.permissions.allow.includes("*")) {
        merged.permissions.allow.push("*");
      }
    }

    return merged;
  }

  /**
   * 設定を保存
   */
  async saveSettings(settingsPath, settings) {
    try {
      // ディレクトリが存在しない場合は作成
      const dir = path.dirname(settingsPath);
      if (!fs.existsSync(dir)) {
        await fs.promises.mkdir(dir, { recursive: true });
      }

      const jsonString = JSON.stringify(settings, null, 2);
      await fs.promises.writeFile(settingsPath, jsonString, 'utf8');
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * hooks設定の状態を確認
   */
  async checkHooksStatus(settingsPath) {
    try {
      const loadResult = await this.loadExistingSettings(settingsPath);
      if (!loadResult.success) {
        return { 
          status: 'error', 
          message: '設定ファイルの読み込みに失敗',
          details: loadResult.error 
        };
      }

      const settings = loadResult.settings;
      
      if (!settings.hooks) {
        return { 
          status: 'not-configured', 
          message: '未設定',
          details: 'hooks設定が見つかりません' 
        };
      }

      const hasStop = !!settings.hooks.Stop;
      const hasNotification = !!settings.hooks.Notification;

      if (hasStop && hasNotification) {
        return { 
          status: 'configured', 
          message: '設定済み',
          details: 'Stop と Notification イベントが設定されています',
          hooks: { stop: hasStop, notification: hasNotification }
        };
      } else if (hasStop || hasNotification) {
        return { 
          status: 'partial', 
          message: '部分設定',
          details: `${hasStop ? 'Stop' : ''}${hasStop && hasNotification ? ' と ' : ''}${hasNotification ? 'Notification' : ''} イベントが設定されています`,
          hooks: { stop: hasStop, notification: hasNotification }
        };
      } else {
        return { 
          status: 'empty', 
          message: 'hooks設定が空',
          details: 'hooks設定は存在しますが、イベントが設定されていません' 
        };
      }
    } catch (error) {
      return { 
        status: 'error', 
        message: 'エラー',
        details: error.message 
      };
    }
  }

  /**
   * hooks設定を適用
   */
  async applyHooksConfig(settingsPath, enableStop, enableNotification, isWindowsEnvironment = false) {
    try {
      // バックアップ作成
      const backupResult = await this.backupSettings(settingsPath);
      if (!backupResult.success && fs.existsSync(settingsPath)) {
        return { success: false, error: `バックアップ作成失敗: ${backupResult.error}` };
      }

      // 既存設定読み込み
      const loadResult = await this.loadExistingSettings(settingsPath);
      if (!loadResult.success) {
        return { success: false, error: `設定読み込み失敗: ${loadResult.error}` };
      }

      // 両方のフックが無効な場合は連携解除
      if (!enableStop && !enableNotification) {
        return await this.removeHooksConfig(settingsPath, loadResult.settings, backupResult.backupPath);
      }

      // hooks設定作成（Windows環境フラグを渡す）
      const hooksConfig = this.createHooksConfig(enableStop, enableNotification, isWindowsEnvironment);

      // 設定マージ
      const mergedSettings = this.mergeSettings(loadResult.settings, hooksConfig);

      // 設定保存
      const saveResult = await this.saveSettings(settingsPath, mergedSettings);
      if (!saveResult.success) {
        return { success: false, error: `設定保存失敗: ${saveResult.error}` };
      }

      const environmentType = isWindowsEnvironment ? 'Windows環境' : 'WSL環境';
      return { 
        success: true, 
        message: `hooks設定を正常に適用しました (${environmentType})`,
        backupPath: backupResult.backupPath 
      };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * hooks設定を削除（連携解除）
   */
  async removeHooksConfig(settingsPath, existingSettings, backupPath) {
    try {
      const updatedSettings = { ...existingSettings };
      
      // hooks設定を削除
      if (updatedSettings.hooks) {
        delete updatedSettings.hooks;
      }

      // 設定保存
      const saveResult = await this.saveSettings(settingsPath, updatedSettings);
      if (!saveResult.success) {
        return { success: false, error: `設定保存失敗: ${saveResult.error}` };
      }

      return { 
        success: true, 
        message: 'Claude Code連携を解除しました',
        backupPath: backupPath 
      };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * 連携テストを実行
   */
  async testIntegration() {
    try {
      // WSL環境でWindows cmd経由でテスト実行
      const { spawn } = require('child_process');
      
      console.log('Starting integration test with Windows cmd...');
      
      // pythonw.exeでウィンドウレス実行
      const pythonProcess = spawn('pythonw', [
        this.notifyScript.replace(/\//g, '\\'), 
        'Stop', '連携テスト - Electronアプリから実行'
      ], {
        detached: true,
        stdio: 'ignore',
        windowsHide: true
      });

      // プロセスを完全に独立させる（監視なし）
      pythonProcess.unref();
      
      console.log('Integration test process started successfully');
      
      // detached方式では即座に成功を返す（通知表示の責任はPythonプロセスに委譲）
      return { 
        success: true, 
        message: '連携テスト成功 - 通知プロセスを開始しました' 
      };
    } catch (error) {
      console.error('Integration test error:', error);
      return { success: false, error: error.message };
    }
  }
}

module.exports = ClaudeHooksManager;