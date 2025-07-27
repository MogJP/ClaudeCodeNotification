#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Claude Code 通知スクリプト
Claude Codeのhooksから呼び出され、Windows通知を表示する
"""

import sys
import json
import os
from datetime import datetime
from pathlib import Path

try:
    from win10toast_click import ToastNotifier
except ImportError:
    print("エラー: win10toast-click がインストールされていません。")
    print("pip install win10toast-click を実行してください。")
    sys.exit(1)


class ClaudeNotifier:
    def __init__(self):
        self.toaster = ToastNotifier()
        self.config_path = self._get_config_path()
        self.config = self._load_config()
        
    def _get_config_path(self):
        """設定ファイルのパスを取得"""
        # 実行ファイルと同じディレクトリのconfig.json
        script_dir = Path(__file__).parent
        return script_dir / "config.json"
    
    def _load_config(self):
        """設定ファイルを読み込む"""
        default_config = {
            "notification": {
                "duration": 10,
                "sound": {
                    "enabled": True,
                    "file": "default",
                    "volume": 80
                },
                "position": "bottom-right"
            },
            "messages": {
                "stop": {
                    "title": "Claude Code - 作業完了",
                    "template": "✅ {message}\n📝 {details}\n⏰ {time}"
                },
                "notification": {
                    "title": "Claude Code - 確認が必要",
                    "template": "❗ {message}\n📝 {details}\n⏰ {time}"
                }
            },
            "advanced": {
                "use_emoji": True,
                "time_format": "%H:%M:%S",
                "language": "ja"
            }
        }
        
        if self.config_path.exists():
            try:
                with open(self.config_path, 'r', encoding='utf-8') as f:
                    loaded_config = json.load(f)
                # デフォルト設定とマージ
                return self._merge_config(default_config, loaded_config)
            except Exception as e:
                print(f"設定ファイル読み込みエラー: {e}")
                return default_config
        return default_config
    
    def _merge_config(self, default, loaded):
        """設定を再帰的にマージ"""
        result = default.copy()
        for key, value in loaded.items():
            if key in result and isinstance(result[key], dict) and isinstance(value, dict):
                result[key] = self._merge_config(result[key], value)
            else:
                result[key] = value
        return result
    
    def _parse_hook_input(self):
        """Claude Codeからのstdin入力をパース"""
        try:
            # stdinが利用可能かチェック
            if not sys.stdin.isatty():
                # stdinからJSON読み取り
                stdin_data = sys.stdin.read().strip()
                if stdin_data:
                    input_data = json.loads(stdin_data)
                    print(f"Parsed stdin data: {input_data}")
                    return input_data
            return None
        except Exception as e:
            print(f"stdin parse error: {e}")
            return None
    
    def _get_message_details(self, hook_data):
        """フック情報から詳細メッセージを生成"""
        if not hook_data:
            return "手動実行", ""
        
        event_type = hook_data.get('hook_event_name', 'Unknown')
        
        # Notificationイベントの場合
        if event_type == 'Notification':
            message = hook_data.get('message', 'Claude Codeからの通知')
            return message, "ユーザーの確認が必要です"
        
        # Stopイベントの場合
        elif event_type == 'Stop':
            # transcript_pathから最新の作業内容を取得（将来的な拡張用）
            return "作業が完了しました", "Claude Codeがタスクを完了しました"
        
        return event_type, ""
    
    def show_notification(self, title=None, message=None, custom_duration=None):
        """通知を表示"""
        # フック入力を取得
        hook_data = self._parse_hook_input()
        
        # イベントタイプを判定
        if hook_data:
            event_type = hook_data.get('hook_event_name', 'stop').lower()
            config_key = event_type if event_type in self.config['messages'] else 'stop'
        else:
            # コマンドライン引数から判定
            if len(sys.argv) > 1:
                event_type = sys.argv[1].lower()
                config_key = event_type if event_type in self.config['messages'] else 'stop'
            else:
                config_key = 'stop'
        
        # メッセージ設定を取得
        msg_config = self.config['messages'][config_key]
        
        # タイトルは常に設定ファイルから取得
        if not title:
            title = msg_config['title']
        
        # 詳細情報を取得
        main_message, details = self._get_message_details(hook_data)
        
        # テンプレートを使用してメッセージを生成
        current_time = datetime.now().strftime(self.config['advanced']['time_format'])
        
        if not message:
            # コマンドライン引数がある場合は、テンプレートに引数を適用
            if len(sys.argv) > 2:
                main_message = sys.argv[2]  # コマンドライン引数をメインメッセージに設定
                if len(sys.argv) > 3:
                    details = sys.argv[3]  # 3番目の引数があれば詳細に設定
                else:
                    details = "手動テスト実行"  # デフォルトの詳細
            
            # テンプレートを使用
            template = msg_config['template']
            message = template.format(
                message=main_message,
                details=details,
                time=current_time
            )
        
        # 表示時間
        duration = custom_duration or self.config['notification']['duration']
        
        # 通知を表示
        try:
            # threadedモードで通知を開始
            self.toaster.show_toast(
                title,
                message,
                duration=duration,
                threaded=True,  # バックグラウンドで実行
                # アイコンは将来的に追加可能
            )
            print("通知を開始しました")
            
            # 通知開始後、即座にプロセス終了（hooks実行時間短縮）
            print("=== Python notify.py finished ===")
            sys.exit(0)
            
        except Exception as e:
            print(f"通知表示エラー: {e}")
            # エラーでもプロセス終了
            print("=== Python notify.py finished (with error) ===")
            sys.exit(0)


def main():
    """メイン処理"""
    print("=== Python notify.py started ===")
    print(f"Start time: {datetime.now().strftime('%H:%M:%S.%f')}")
    print(f"Raw arguments: {sys.argv}")
    
    notifier = ClaudeNotifier()
    
    # コマンドライン引数をチェック
    if len(sys.argv) > 1:
        # 引数の意味：
        # sys.argv[1] = イベントタイプ（Stop/Notification）
        # sys.argv[2] = カスタムメッセージ
        # titleとmessageはshow_notification内で設定ファイルから生成
        
        print(f"Event type: {sys.argv[1] if len(sys.argv) > 1 else 'None'}")
        print(f"Custom message: {sys.argv[2] if len(sys.argv) > 2 else 'None'}")
        
        # titleとmessageは設定ファイルとテンプレートから生成するためNone
        title = None
        message = None
        
        print(f"Processed title: {title}")
        print(f"Processed message: {message}")
        print(f"Showing notification with title: {title}, message: {message}")
        notifier.show_notification(title, message)
        print("=== Notification call completed ===")
    else:
        # 引数がない場合はフック入力を処理
        print("No arguments, processing hook input")
        notifier.show_notification()
    
    print("=== Python notify.py finished ===")


if __name__ == "__main__":
    main()