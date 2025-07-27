const { contextBridge, ipcRenderer } = require('electron');

// レンダラープロセス用API定義
contextBridge.exposeInMainWorld('electronAPI', {
  // 通知設定API
  loadConfig: () => ipcRenderer.invoke('load-config'),
  saveConfig: (config) => ipcRenderer.invoke('save-config', config),
  testNotification: () => ipcRenderer.invoke('test-notification'),
  
  // Claude Code連携API
  openFileDialog: (options) => ipcRenderer.invoke('open-file-dialog', options),
  checkHooksStatus: (settingsPath) => ipcRenderer.invoke('check-hooks-status', settingsPath),
  applyHooksConfig: (settingsPath, enableStop, enableNotification) => 
    ipcRenderer.invoke('apply-hooks-config', settingsPath, enableStop, enableNotification),
  testIntegration: () => ipcRenderer.invoke('test-integration'),
  backupSettings: (settingsPath) => ipcRenderer.invoke('backup-settings', settingsPath)
});