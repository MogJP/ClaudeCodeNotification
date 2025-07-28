# Claude Code 通知システム

🔔 Claude Code用Windows通知システム - 作業完了時・確認待ち時にWindows通知を表示

![License](https://img.shields.io/badge/license-非商用・再配布制限-blue)
![Platform](https://img.shields.io/badge/platform-Windows%2010%2F11-lightgrey)
![Python](https://img.shields.io/badge/python-3.9%2B-green)

---

### ☕ このプロジェクトを気に入っていただけましたか？

**[☕ Buy me a coffee](https://buymeacoffee.com/mog_jp)** でサポートしていただけると嬉しいです！

開発の継続・機能追加のモチベーションになります 🙏

---

## ✨ 主な機能

- 🔔 **自動通知**: Claude Codeの作業完了時・確認待ち時に自動でWindows通知
- 🇯🇵 **日本語完全対応**: 設定画面・通知メッセージすべて日本語
- ⚙️ **簡単設定**: Electron製GUIで直感的な設定・Claude Code連携
- 🎨 **カスタマイズ**: 通知時間・音・メッセージテンプレートを自由に調整
- 🔗 **ワンクリック連携**: Claude Codeのhooks設定を自動適用・解除

## 🚀 かんたんインストール

### 📥 ダウンロード

**[📦 最新版ダウンロード](../../releases/latest)**

`ClaudeCodeNotifier-Setup.exe` (約170MB) をダウンロード

> ⚠️ **注意**: Setup.exeには必要なファイルがすべて含まれています。  
> **リポジトリのクローンやNode.js環境は不要**です！

### 💻 インストール手順

1. **Setup.exeをダウンロード** → 上のリンクから最新版を取得  
2. **Setup.exeを実行** → **管理者権限**で実行してください  
3. **画面の指示に従って完了** → Python環境もすべて自動セットアップ  
4. **スタートメニューから設定** → `Claude Code 通知システム` → `Claude通知設定`

### ⚡ 3分で完了！

1. インストール（1分）
2. 設定アプリでClaude Code連携（1分）  
3. Claude Code再起動（30秒）

**これだけで作業完了時に通知が届きます！**

## 🔧 動作環境

### 🎯 エンドユーザー（Setup.exe使用）
- **OS**: Windows 10/11
- **Claude Code**: 最新版
- **その他**: Setup.exeが自動でPython環境をセットアップ

### 👨‍💻 開発者（ソースからビルド）
- **OS**: Windows 10/11  
- **Python**: 3.9以上
- **Node.js**: 18以上
- **Claude Code**: 最新版

## 📖 使い方

### 🎯 設定方法

1. **スタートメニュー** → `Claude Code 通知システム` → `Claude通知設定` を起動
2. **Claude Code連携** タブをクリック
3. **ファイルを選択** → `C:\Users\[ユーザー名]\.claude\settings.local.json` を選択
4. **設定を適用** をクリック
5. **Claude Codeを再起動**

### 🔔 通知の種類

- 🎉 **作業完了通知**: Claude Codeがタスクを完了した時
- ❓ **確認待ち通知**: Claude Codeがユーザーの確認を待っている時

### ⚙️ カスタマイズ

**通知設定**
- 表示時間：3〜60秒で調整可能
- 音：ON/OFF切り替え
- 位置：Windows通知の表示位置

**メッセージ設定**  
- タイトル：通知のタイトルをカスタマイズ
- テンプレート：`{message}` `{details}` `{time}` 変数を使用可能

**Claude Code連携**
- ワンクリックで設定適用・解除
- 自動バックアップ・復元機能

## 📝 メッセージテンプレート

以下の変数が使用できます：

- `{message}`: Claudeからのメッセージ
- `{details}`: 詳細情報
- `{time}`: 時刻

例：
```
✅ {message}
📝 {details}
⏰ {time}
```

## ⚙️ 設定ファイル

`src/config.json` で詳細設定が可能です：

```json
{
  "notification": {
    "duration": 10,
    "sound": {
      "enabled": true,
      "file": "default",
      "volume": 80
    },
    "position": "bottom-right"
  },
  "messages": {
    "stop": {
      "title": "Claude Code - 作業完了",
      "template": "✅ {message}\\n📝 {details}\\n⏰ {time}"
    },
    "notification": {
      "title": "Claude Code - 確認待ち", 
      "template": "❓ {message}\\n📝 {details}\\n⏰ {time}"
    }
  },
  "advanced": {
    "use_emoji": true,
    "time_format": "%H:%M:%S",
    "language": "ja"
  }
}
```

## 📁 プロジェクト構成

```
ClaudeCodeNotification/
├── src/                        # 通知システム
│   ├── notify.py              # メイン通知スクリプト
│   ├── config.json            # 設定ファイル
│   └── settings_template.json # Claude Code設定テンプレート
├── settings-app/              # Electron設定アプリ
│   ├── main.js               # メインプロセス
│   ├── preload.js            # プリロードスクリプト
│   ├── claude-hooks-manager.js # Claude Code連携管理
│   ├── renderer/             # レンダラープロセス
│   └── dist/win-unpacked/    # ビルド済み実行ファイル
├── installer/                 # インストーラー
│   ├── ClaudeCodeNotifier-Simple.nsi
│   └── build-installer.bat
├── quick-setup.bat           # 簡単セットアップスクリプト
├── create-portable-package.bat # ポータブル版作成
└── AIDocuments/             # 技術ドキュメント
```

## 🆘 困った時は

### 💡 よくある質問

**Q: 通知が表示されない**
- Python環境を確認：`python --version` でPython 3.9以上がインストールされているか
- Claude Codeを再起動してみてください
- 設定アプリで「通知テスト」ボタンを押して動作確認

**Q: 設定アプリが起動しない**  
- 管理者権限でSetup.exeを実行し直してください
- Windows Defenderなどでブロックされていないか確認

**Q: Claude Code連携がうまくいかない**
- `C:\Users\[ユーザー名]\.claude\settings.local.json` ファイルが存在するか確認
- 設定適用後にClaude Codeを必ず再起動してください

### 🔧 手動設定（上級者向け）

設定アプリが使えない場合、手動で設定可能：

```json
// C:\Users\[ユーザー名]\.claude\settings.local.json に追加
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "nohup /mnt/c/Windows/System32/cmd.exe /c python C:/Program Files (x86)/ClaudeCodeNotifier/settings-app/dist/win-unpacked/resources/src/notify.py Stop \"Claude Codeの作業が完了しました\" > /dev/null 2>&1 &"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "nohup /mnt/c/Windows/System32/cmd.exe /c python C:/Program Files (x86)/ClaudeCodeNotifier/settings-app/dist/win-unpacked/resources/src/notify.py Notification \"Claude Codeの確認が必要です\" > /dev/null 2>&1 &"
          }
        ]
      }
    ]
  }
}
```

---


## 📄 ライセンス

**非商用・再配布制限ライセンス** - 詳細は [LICENSE](LICENSE) ファイルを参照

- ✅ 個人・非商用利用: 自由に使用可能
- ❌ 商用利用: 禁止
- ❌ 再配布: 事前許可が必要

商用利用や再配布をご希望の場合は [GitHub Issues](../../issues) でお問い合わせください。

## 🆘 サポート

- **バグ報告**: [GitHub Issues](../../issues)
- **機能要望**: [GitHub Issues](../../issues)
- **質問**: [GitHub Issues](../../issues)

---

Claude Codeでの開発をより快適に！ 🎉
