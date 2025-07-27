// 設定管理アプリ - UIコントローラー
class SettingsApp {
  constructor() {
    this.config = {};
    this.elements = {};
    this.init();
  }

  async init() {
    this.bindElements();
    this.bindEvents();
    await this.loadConfig();
    this.updateUI();
  }

  bindElements() {
    // タブ要素
    this.elements.tabBtns = document.querySelectorAll('.tab-btn');
    this.elements.tabContents = document.querySelectorAll('.tab-content');

    // 通知設定要素
    this.elements.duration = document.getElementById('duration');
    this.elements.durationValue = document.getElementById('duration-value');
    this.elements.soundEnabled = document.getElementById('sound-enabled');
    this.elements.soundType = document.getElementById('sound-type');
    this.elements.soundTypeContainer = document.getElementById('sound-type-container');

    // メッセージ設定要素
    this.elements.stopTitle = document.getElementById('stop-title');
    this.elements.stopTemplate = document.getElementById('stop-template');
    this.elements.notificationTitle = document.getElementById('notification-title');
    this.elements.notificationTemplate = document.getElementById('notification-template');

    // Claude Code連携要素
    this.elements.settingsFilePath = document.getElementById('settings-file-path');
    this.elements.browseSettingsBtn = document.getElementById('browse-settings-btn');
    this.elements.hookStop = document.getElementById('hook-stop');
    this.elements.hookNotification = document.getElementById('hook-notification');
    this.elements.integrationStatus = document.getElementById('integration-status');
    this.elements.integrationDetails = document.getElementById('integration-details');
    this.elements.applyIntegrationBtn = document.getElementById('apply-integration-btn');
    this.elements.testIntegrationBtn = document.getElementById('test-integration-btn');
    this.elements.backupSettingsBtn = document.getElementById('backup-settings-btn');

    // ボタン
    this.elements.testBtn = document.getElementById('test-btn');
    this.elements.resetBtn = document.getElementById('reset-btn');
    this.elements.saveBtn = document.getElementById('save-btn');

    // ステータス
    this.elements.status = document.getElementById('status');
  }

  bindEvents() {
    // タブ切り替え
    this.elements.tabBtns.forEach(btn => {
      btn.addEventListener('click', (e) => {
        const targetTab = e.target.dataset.tab;
        this.switchTab(targetTab);
      });
    });

    // 表示時間スライダー
    this.elements.duration.addEventListener('input', (e) => {
      this.elements.durationValue.textContent = `${e.target.value}秒`;
    });

    // 音ON/OFF切り替え
    this.elements.soundEnabled.addEventListener('change', (e) => {
      const isEnabled = e.target.checked;
      if (isEnabled) {
        this.elements.soundTypeContainer.classList.remove('disabled');
      } else {
        this.elements.soundTypeContainer.classList.add('disabled');
      }
    });

    // Claude Code連携イベント
    this.elements.browseSettingsBtn.addEventListener('click', () => this.browseSettingsFile());
    this.elements.settingsFilePath.addEventListener('input', () => this.onSettingsPathChange());
    this.elements.hookStop.addEventListener('change', () => this.updateIntegrationButtons());
    this.elements.hookNotification.addEventListener('change', () => this.updateIntegrationButtons());
    this.elements.applyIntegrationBtn.addEventListener('click', () => this.applyIntegration());
    this.elements.testIntegrationBtn.addEventListener('click', () => this.testIntegration());
    this.elements.backupSettingsBtn.addEventListener('click', () => this.backupSettings());

    // ボタンイベント
    this.elements.testBtn.addEventListener('click', () => this.testNotification());
    this.elements.resetBtn.addEventListener('click', () => this.resetToDefaults());
    this.elements.saveBtn.addEventListener('click', () => this.saveConfig());

    // フォーム変更イベント監視
    const formElements = [
      this.elements.duration,
      this.elements.soundEnabled,
      this.elements.soundType,
      this.elements.stopTitle,
      this.elements.stopTemplate,
      this.elements.notificationTitle,
      this.elements.notificationTemplate
    ];

    formElements.forEach(element => {
      element.addEventListener('change', () => {
        this.markAsChanged();
      });
    });
  }

  async loadConfig() {
    try {
      this.config = await window.electronAPI.loadConfig();
    } catch (error) {
      console.error('設定読み込みエラー:', error);
      this.showStatus('設定の読み込みに失敗しました', 'error');
    }
  }

  updateUI() {
    // 通知設定
    this.elements.duration.value = this.config.notification?.duration || 10;
    this.elements.durationValue.textContent = `${this.elements.duration.value}秒`;
    
    const soundEnabled = this.config.notification?.sound?.enabled ?? true;
    this.elements.soundEnabled.checked = soundEnabled;
    
    this.elements.soundType.value = this.config.notification?.sound?.file || 'default';

    // 音種類選択の有効/無効状態
    if (soundEnabled) {
      this.elements.soundTypeContainer.classList.remove('disabled');
    } else {
      this.elements.soundTypeContainer.classList.add('disabled');
    }

    // メッセージ設定
    this.elements.stopTitle.value = this.config.messages?.stop?.title || '';
    this.elements.stopTemplate.value = this.config.messages?.stop?.template || '';
    this.elements.notificationTitle.value = this.config.messages?.notification?.title || '';
    this.elements.notificationTemplate.value = this.config.messages?.notification?.template || '';
  }

  collectFormData() {
    return {
      notification: {
        duration: parseInt(this.elements.duration.value),
        sound: {
          enabled: this.elements.soundEnabled.checked,
          file: this.elements.soundType.value,
          volume: this.config.notification?.sound?.volume || 80
        },
        position: this.config.notification?.position || 'bottom-right'
      },
      messages: {
        stop: {
          title: this.elements.stopTitle.value,
          template: this.elements.stopTemplate.value
        },
        notification: {
          title: this.elements.notificationTitle.value,
          template: this.elements.notificationTemplate.value
        }
      },
      advanced: {
        use_emoji: this.config.advanced?.use_emoji ?? true,
        time_format: this.config.advanced?.time_format || '%H:%M:%S',
        language: this.config.advanced?.language || 'ja'
      }
    };
  }

  async saveConfig() {
    try {
      this.elements.saveBtn.disabled = true;
      this.elements.saveBtn.textContent = '保存中...';

      const newConfig = this.collectFormData();
      const result = await window.electronAPI.saveConfig(newConfig);

      if (result.success) {
        this.config = newConfig;
        this.showStatus('設定を保存しました', 'success');
        this.markAsSaved();
      } else {
        throw new Error(result.error || '保存に失敗しました');
      }
    } catch (error) {
      console.error('設定保存エラー:', error);
      this.showStatus('設定の保存に失敗しました', 'error');
    } finally {
      this.elements.saveBtn.disabled = false;
      this.elements.saveBtn.textContent = '保存';
    }
  }

  async testNotification() {
    try {
      this.elements.testBtn.disabled = true;
      this.elements.testBtn.textContent = 'テスト中...';

      const result = await window.electronAPI.testNotification();
      if (result.success) {
        this.showStatus('テスト通知を送信しました', 'success');
      } else {
        throw new Error(result.error || 'テストの実行に失敗しました');
      }
    } catch (error) {
      console.error('テストエラー:', error);
      this.showStatus('テストの実行に失敗しました', 'error');
    } finally {
      this.elements.testBtn.disabled = false;
      this.elements.testBtn.textContent = 'テスト';
    }
  }

  async resetToDefaults() {
    if (!confirm('設定をデフォルトにリセットしますか？')) {
      return;
    }

    // Claude Code連携が設定されているかチェック
    const hasClaudeIntegration = this.elements.settingsFilePath && this.elements.settingsFilePath.value.trim();
    let resetIntegration = false;

    if (hasClaudeIntegration) {
      resetIntegration = confirm(
        'Claude Code連携も一緒にリセットしますか？\n\n' +
        '「はい」: 連携設定も削除し、完全にリセット\n' +
        '「いいえ」: 通知設定のみリセット、連携設定は保持'
      );
    }

    // デフォルト設定
    this.config = {
      notification: {
        duration: 10,
        sound: {
          enabled: true,
          file: 'default',
          volume: 80
        },
        position: 'bottom-right'
      },
      messages: {
        stop: {
          title: 'Claude Code - 作業完了',
          template: '✅ {message}\n📝 {details}\n⏰ {time}'
        },
        notification: {
          title: 'Claude Code - 確認待ち',
          template: '❓ {message}\n📝 {details}\n⏰ {time}'
        }
      },
      advanced: {
        use_emoji: true,
        time_format: '%H:%M:%S',
        language: 'ja'
      }
    };

    this.updateUI();
    this.markAsChanged();

    // Claude Code連携もリセットする場合
    if (resetIntegration) {
      try {
        const filePath = this.elements.settingsFilePath.value.trim();
        const result = await window.electronAPI.applyHooksConfig(filePath, false, false);
        
        if (result.success) {
          // 連携UI状態もリセット
          this.elements.settingsFilePath.value = '';
          this.elements.hookStop.checked = false;
          this.elements.hookNotification.checked = false;
          this.updateIntegrationStatus('not-configured', '未設定', '設定ファイルを選択してください');
          this.updateIntegrationButtons();
          
          this.showStatus('設定と Claude Code連携を完全にリセットしました', 'warning');
          this.updateIntegrationDetails('変更を有効にするには Claude Code の再起動が必要です');
        } else {
          this.showStatus('設定をリセットしましたが、連携解除に失敗しました', 'warning');
        }
      } catch (error) {
        console.error('連携リセットエラー:', error);
        this.showStatus('設定をリセットしましたが、連携解除に失敗しました', 'warning');
      }
    } else {
      this.showStatus('設定をデフォルトにリセットしました', 'warning');
    }
  }

  markAsChanged() {
    this.elements.saveBtn.textContent = '保存 *';
    this.elements.saveBtn.classList.add('changed');
  }

  markAsSaved() {
    this.elements.saveBtn.textContent = '保存';
    this.elements.saveBtn.classList.remove('changed');
  }

  showStatus(message, type = 'success') {
    this.elements.status.textContent = message;
    this.elements.status.className = `status ${type} show`;

    // 3秒後に非表示
    setTimeout(() => {
      this.elements.status.classList.remove('show');
      setTimeout(() => {
        this.elements.status.classList.add('hidden');
      }, 300);
    }, 3000);
  }

  // === Claude Code連携メソッド ===

  switchTab(tabName) {
    // すべてのタブボタンとコンテンツを非アクティブに
    this.elements.tabBtns.forEach(btn => btn.classList.remove('active'));
    this.elements.tabContents.forEach(content => content.classList.remove('active'));

    // 指定されたタブをアクティブに
    const targetBtn = document.querySelector(`[data-tab="${tabName}"]`);
    const targetContent = document.getElementById(`${tabName}-tab`);
    
    if (targetBtn && targetContent) {
      targetBtn.classList.add('active');
      targetContent.classList.add('active');
    }
  }

  async browseSettingsFile() {
    try {
      const result = await window.electronAPI.openFileDialog({
        title: 'Claude Code settings.local.json を選択',
        filters: [
          { name: 'JSON files', extensions: ['json'] },
          { name: 'All files', extensions: ['*'] }
        ],
        properties: ['openFile']
      });

      if (result.filePath) {
        this.elements.settingsFilePath.value = result.filePath;
        await this.onSettingsPathChange();
      }
    } catch (error) {
      console.error('ファイル選択エラー:', error);
      this.showStatus('ファイル選択に失敗しました', 'error');
    }
  }

  async onSettingsPathChange() {
    const filePath = this.elements.settingsFilePath.value.trim();
    
    if (!filePath) {
      this.updateIntegrationStatus('not-configured', '未設定', '設定ファイルを選択してください');
      this.updateIntegrationButtons();
      return;
    }

    try {
      const result = await window.electronAPI.checkHooksStatus(filePath);
      
      if (result.success) {
        const status = result.status;
        this.updateIntegrationStatus(status.status, status.message, status.details);
        
        // チェックボックスの状態を更新
        if (status.hooks) {
          this.elements.hookStop.checked = status.hooks.stop || false;
          this.elements.hookNotification.checked = status.hooks.notification || false;
        }
      } else {
        this.updateIntegrationStatus('error', 'エラー', result.error);
      }
    } catch (error) {
      console.error('設定確認エラー:', error);
      this.updateIntegrationStatus('error', 'エラー', error.message);
    }
    
    this.updateIntegrationButtons();
  }

  updateIntegrationStatus(status, message, details) {
    this.elements.integrationStatus.textContent = message;
    this.elements.integrationDetails.textContent = details;

    // ステータスバッジのスタイルを更新
    this.elements.integrationStatus.className = 'status-badge';
    if (status === 'configured' || status === 'partial') {
      this.elements.integrationStatus.style.background = 'rgba(166, 227, 161, 0.2)';
      this.elements.integrationStatus.style.color = 'var(--success)';
    } else if (status === 'error') {
      this.elements.integrationStatus.style.background = 'rgba(243, 139, 168, 0.2)';
      this.elements.integrationStatus.style.color = 'var(--error)';
    } else {
      this.elements.integrationStatus.style.background = 'rgba(243, 139, 168, 0.2)';
      this.elements.integrationStatus.style.color = 'var(--error)';
    }
  }

  updateIntegrationDetails(details) {
    this.elements.integrationDetails.textContent = details;
  }

  updateIntegrationButtons() {
    const hasPath = !!this.elements.settingsFilePath.value.trim();
    const hasHooks = this.elements.hookStop.checked || this.elements.hookNotification.checked;

    // パスが設定されていれば連携適用（設定/解除）が可能
    this.elements.applyIntegrationBtn.disabled = !hasPath;
    this.elements.testIntegrationBtn.disabled = !hasPath;
    this.elements.backupSettingsBtn.disabled = !hasPath;

    // ボタンテキストを動的に変更
    if (hasPath) {
      if (hasHooks) {
        this.elements.applyIntegrationBtn.textContent = '🔧 連携設定を適用';
      } else {
        this.elements.applyIntegrationBtn.textContent = '🔓 連携を解除';
      }
    } else {
      this.elements.applyIntegrationBtn.textContent = '🔧 連携設定を適用';
    }
  }

  async applyIntegration() {
    try {
      const filePath = this.elements.settingsFilePath.value.trim();
      const enableStop = this.elements.hookStop.checked;
      const enableNotification = this.elements.hookNotification.checked;
      const isRemoving = !enableStop && !enableNotification;

      // 連携解除の場合は確認ダイアログを表示
      if (isRemoving) {
        if (!confirm('Claude Code連携を解除しますか？\n\nsettings.local.json からhooks設定が削除されます。')) {
          return;
        }
      }

      this.elements.applyIntegrationBtn.disabled = true;
      this.elements.applyIntegrationBtn.textContent = isRemoving ? '解除中...' : '設定中...';

      const result = await window.electronAPI.applyHooksConfig(filePath, enableStop, enableNotification);

      if (result.success) {
        if (isRemoving) {
          this.showStatus('Claude Code連携を解除しました', 'success');
        } else {
          this.showStatus('Claude Code連携設定を適用しました', 'success');
        }
        await this.onSettingsPathChange(); // ステータス更新
        
        // 連携設定時のみ再起動リマインダーを表示
        if (!isRemoving) {
          this.updateIntegrationDetails('設定を有効にするには Claude Code の再起動が必要です');
        }
      } else {
        throw new Error(result.error || (isRemoving ? '連携解除に失敗しました' : '連携設定の適用に失敗しました'));
      }
    } catch (error) {
      console.error('連携設定エラー:', error);
      const isRemoving = !this.elements.hookStop.checked && !this.elements.hookNotification.checked;
      this.showStatus(isRemoving ? '連携解除に失敗しました' : '連携設定の適用に失敗しました', 'error');
    } finally {
      this.elements.applyIntegrationBtn.disabled = false;
      this.updateIntegrationButtons(); // ボタンテキストを正しく復元
    }
  }

  async testIntegration() {
    try {
      this.elements.testIntegrationBtn.disabled = true;
      this.elements.testIntegrationBtn.textContent = 'テスト中...';

      const result = await window.electronAPI.testIntegration();

      if (result.success) {
        this.showStatus('連携テストが成功しました', 'success');
      } else {
        throw new Error(result.error || '連携テストに失敗しました');
      }
    } catch (error) {
      console.error('連携テストエラー:', error);
      this.showStatus('連携テストに失敗しました', 'error');
    } finally {
      this.elements.testIntegrationBtn.disabled = false;
      this.elements.testIntegrationBtn.textContent = '🧪 連携テスト';
    }
  }

  async backupSettings() {
    try {
      this.elements.backupSettingsBtn.disabled = true;
      this.elements.backupSettingsBtn.textContent = 'バックアップ中...';

      const filePath = this.elements.settingsFilePath.value.trim();
      const result = await window.electronAPI.backupSettings(filePath);

      if (result.success) {
        this.showStatus(`設定をバックアップしました: ${result.backupPath}`, 'success');
      } else {
        throw new Error(result.error || 'バックアップに失敗しました');
      }
    } catch (error) {
      console.error('バックアップエラー:', error);
      this.showStatus('バックアップに失敗しました', 'error');
    } finally {
      this.elements.backupSettingsBtn.disabled = false;
      this.elements.backupSettingsBtn.textContent = '💾 設定をバックアップ';
    }
  }
}

// アプリ初期化
document.addEventListener('DOMContentLoaded', () => {
  new SettingsApp();
});