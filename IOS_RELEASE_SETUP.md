# Windows から iOS アプリをリリースする方法（Codemagic使用）

このガイドでは、WindowsマシンからCodemagicを使用してiOSアプリをApp Storeにリリースする手順を説明します。

## アプリ情報
- **アプリ名**: My First App
- **バンドルID**: com.studio.tae
- **現在のバージョン**: 1.0.0+5

---

## 📋 事前準備

### 1. Apple Developer アカウント
- [ ] Apple Developer Program に登録（年間 $99）
  - https://developer.apple.com/programs/
- [ ] Apple ID と支払い情報を登録

### 2. App Store Connect の設定
- [ ] https://appstoreconnect.apple.com/ にログイン
- [ ] 新しいアプリを作成
  - アプリ名: My First App
  - バンドルID: com.studio.tae
  - SKU: 任意の一意な識別子（例: my-first-app-001）
  - プラットフォーム: iOS

### 3. Codemagic アカウント
- [ ] https://codemagic.io/ でアカウント作成
- [ ] GitHub/GitLab/Bitbucket と連携

---

## 🔧 ステップ1: Gitリポジトリの準備

### 1-1. Gitリポジトリを作成（まだの場合）

```powershell
# プロジェクトディレクトリで実行
cd c:\Users\yumsm\Desktop\my_first_app

# Gitの初期化
git init

# .gitignoreの確認（Flutterプロジェクトには既にあるはず）
# すべてのファイルを追加
git add .

# 初回コミット
git commit -m "Initial commit for iOS release"
```

### 1-2. GitHubにプッシュ

```powershell
# GitHubで新しいリポジトリを作成後
git remote add origin https://github.com/あなたのユーザー名/my_first_app.git
git branch -M main
git push -u origin main
```

---

## 🔑 ステップ2: App Store Connect API キーの作成

### 2-1. APIキーの生成
1. https://appstoreconnect.apple.com/access/api にアクセス
2. 「キー」タブをクリック
3. 「+」ボタンで新しいキーを作成
   - 名前: Codemagic Release
   - アクセス権限: **App Manager** または **Admin**
4. 「生成」をクリック

### 2-2. 重要な情報を保存
ダウンロードしたAPIキーファイルと以下の情報を保存します：
- **Issuer ID**: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
- **Key ID**: `XXXXXXXXXX`
- **APIキーファイル**: `AuthKey_XXXXXXXXXX.p8` （一度しかダウンロードできません！）

⚠️ **重要**: このファイルは一度しかダウンロードできません。安全な場所に保管してください。

---

## 🚀 ステップ3: Codemagic の設定

### 3-1. プロジェクトをCodemagicに追加
1. https://codemagic.io/apps にアクセス
2. 「Add application」をクリック
3. GitHubリポジトリを選択
4. `my_first_app` を選択

### 3-2. iOS Code Signingの設定

1. Codemagicアプリの設定画面で「Code signing identities」を開く
2. 「iOS code signing」セクションで以下を設定：

#### 方法A: 自動署名（推奨・簡単）
- **Distribution type**: App Store
- **Bundle identifier**: `com.studio.tae`
- 「Automatic code signing」を選択
- App Store Connect APIキーを入力：
  - Issuer ID
  - Key ID
  - API key (.p8ファイルの内容)

Codemagicが自動的に証明書とプロビジョニングプロファイルを生成します。

#### 方法B: 手動署名（上級者向け）
Mac環境で事前に証明書とプロビジョニングプロファイルを作成してアップロードします。

### 3-3. 環境変数の設定

Codemagicの環境変数に以下を追加：

1. アプリ設定 → Environment variables
2. 以下の変数を追加：

| 変数名 | 値 | セキュア |
|--------|-----|---------|
| `APP_STORE_CONNECT_ISSUER_ID` | あなたのIssuer ID | ✅ |
| `APP_STORE_CONNECT_KEY_IDENTIFIER` | あなたのKey ID | ✅ |
| `APP_STORE_CONNECT_PRIVATE_KEY` | .p8ファイルの内容全体 | ✅ |
| `BUNDLE_ID` | `com.studio.tae` | ❌ |

### 3-4. codemagic.yaml の確認

プロジェクトルートに `codemagic.yaml` が作成されています。
メールアドレスを更新してください：

```yaml
publishing:
  email:
    recipients:
      - your-email@example.com  # ← あなたのメールアドレスに変更
```

変更後、Gitにコミット：

```powershell
git add codemagic.yaml
git commit -m "Add Codemagic configuration"
git push
```

---

## 📱 ステップ4: アプリアイコンの設定

App Store では必ずアプリアイコンが必要です。

### 現在のアイコン状態を確認
`ios/Runner/Assets.xcassets/AppIcon.appiconset/` を確認

### アイコンがない場合の設定方法

1. **アイコン画像を用意**（1024x1024 PNG、透過なし）

2. **flutter_launcher_icons を使用**（すでにpubspec.yamlに含まれています）

`pubspec.yaml` を編集して以下を追加：

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon.png"  # アイコン画像のパス
```

3. **アイコンを生成**

```powershell
# アイコン画像を assets/icon.png に配置
flutter pub get
flutter pub run flutter_launcher_icons
```

4. **変更をコミット**

```powershell
git add ios/Runner/Assets.xcassets/
git commit -m "Add app icon"
git push
```

---

## 🎯 ステップ5: リリースビルドの実行

### 5-1. リリースブランチを作成

```powershell
# リリースブランチを作成
git checkout -b release/1.0.0

# プッシュ
git push -u origin release/1.0.0
```

### 5-2. Codemagicで自動ビルド開始

`release/*` ブランチにプッシュすると自動的にビルドが開始されます。

Codemagicダッシュボード（https://codemagic.io/apps）で進捗を確認できます。

### 5-3. ビルド完了を待つ

- ビルド時間: 約15-30分
- 成功すると、自動的にTestFlightにアップロードされます
- メールで通知が届きます

---

## 📦 ステップ6: TestFlight でのテスト

### 6-1. TestFlightの設定

1. https://appstoreconnect.apple.com/ にログイン
2. 「マイApp」から「My First App」を選択
3. 「TestFlight」タブを開く
4. アップロードされたビルドが表示されます（処理に数分かかる場合があります）

### 6-2. テスターを追加

1. 「内部テスト」または「外部テスト」グループを作成
2. テスターのメールアドレスを追加
3. テスターにTestFlightアプリのインストールを依頼

### 6-3. テスト

- テスターがiPhoneでTestFlightアプリから「My First App」をインストール
- 動作確認を実施

---

## 🏪 ステップ7: App Store への申請

### 7-1. App Store Connect での情報入力

https://appstoreconnect.apple.com/ で以下を設定：

#### アプリ情報
- [ ] アプリ名: My First App
- [ ] サブタイトル（30文字以内）
- [ ] カテゴリ（教育、ユーティリティなど）
- [ ] 年齢制限

#### スクリーンショット
- [ ] 6.7インチディスプレイ（iPhone 15 Pro Max等）: 最低3枚
- [ ] 6.5インチディスプレイ（iPhone 14 Plus等）: 最低3枚
- [ ] サイズ: 1290x2796 または 1284x2778

💡 **スクリーンショットの作成方法**:
- iPhoneシミュレーターで撮影（Macが必要）
- オンラインツール: https://www.screenshot.rocks/
- テスターにiPhoneで撮影してもらう

#### アプリのプレビューとスクリーンショット
- [ ] 説明文（4000文字以内）
- [ ] キーワード（100文字以内、カンマ区切り）
- [ ] サポートURL
- [ ] マーケティングURL（任意）

#### 価格と配信可能状況
- [ ] 価格: 無料 または 有料
- [ ] 配信国: 日本、または全世界

### 7-2. プライバシーポリシー

App Storeの要件として、プライバシーポリシーが必須です。

使用している機能から判断すると、以下の許可が必要：
- カメラ（document scanner用）
- 広告ID（google_mobile_ads用）
- データ収集の詳細

プライバシーポリシーのURLを用意してください。

### 7-3. App Store 審査用情報
- [ ] 連絡先情報
- [ ] デモアカウント（ログインが必要な場合）
- [ ] 注記（審査員へのメッセージ）

### 7-4. ビルドを選択

1. 「ビルド」セクションで TestFlight でテスト済みのビルドを選択
2. 「審査に提出」ボタンをクリック

---

## ⏱️ ステップ8: 審査待ちと承認

### 審査プロセス
1. **審査待ち**: 通常1-3日
2. **審査中**: 通常1-2日
3. **承認** または **リジェクト**

### 承認後
- アプリが自動的にApp Storeで公開されます
- または、手動リリースを選択して任意のタイミングで公開できます

---

## 🔄 バージョンアップデート手順

次回以降のリリース手順：

### 1. バージョンを更新

`pubspec.yaml`:
```yaml
version: 1.0.1+6  # バージョン番号とビルド番号を増やす
```

### 2. 変更をコミット

```powershell
git add pubspec.yaml
git commit -m "Bump version to 1.0.1"
git push
```

### 3. リリースブランチを作成

```powershell
git checkout -b release/1.0.1
git push -u origin release/1.0.1
```

### 4. Codemagicで自動ビルド

自動的にビルドされ、TestFlightにアップロードされます。

### 5. App Store Connect で新バージョンを作成

前回と同様の手順で審査に提出します。

---

## 🛠️ トラブルシューティング

### ビルドが失敗する場合

#### エラー: Code signing failed
→ Codemagicの Code signing identities を再確認
→ App Store Connect APIキーが正しいか確認

#### エラー: Pod install failed
→ `ios/Podfile.lock` を削除して再試行
→ CocoaPodsのバージョン問題の可能性

#### エラー: Flutter build failed
→ ローカルでビルドを確認: `flutter build ios --release`
→ エラーログを確認

### TestFlightにアップロードされない

→ `codemagic.yaml` の `submit_to_testflight: true` を確認
→ App Store Connect APIキーの権限を確認（App Manager以上）

### アプリが審査でリジェクトされる

一般的な理由：
- **メタデータ不足**: スクリーンショット、説明文が不十分
- **機能の問題**: アプリがクラッシュする、主要機能が動作しない
- **プライバシー**: プライバシーポリシーが不明確
- **デザインガイドライン違反**: Appleのヒューマンインターフェースガイドラインに準拠していない

リジェクト時は理由が通知されるので、修正して再提出します。

---

## 📊 コスト概算

| 項目 | 費用 |
|------|------|
| Apple Developer Program | $99/年 |
| Codemagic 無料枠 | $0（月500分まで） |
| Codemagic 有料プラン | $0.038/分（無料枠超過時） |

**例**: 月に5回リリース（各30分）= 150分 → 無料枠内

---

## ✅ チェックリスト

リリース前の最終確認：

- [ ] Apple Developer アカウント登録完了
- [ ] App Store Connect でアプリ作成完了
- [ ] App Store Connect APIキー取得
- [ ] GitHubリポジトリ作成・プッシュ完了
- [ ] Codemagicアカウント作成・リポジトリ連携
- [ ] Codemagic Code signing 設定完了
- [ ] 環境変数設定完了
- [ ] アプリアイコン設定完了
- [ ] codemagic.yaml メールアドレス更新
- [ ] TestFlightでテスト完了
- [ ] スクリーンショット準備完了
- [ ] アプリ説明文作成完了
- [ ] プライバシーポリシーURL準備
- [ ] App Store Connect 情報入力完了

---

## 📚 参考リンク

- [Codemagic Documentation](https://docs.codemagic.io/flutter-code-signing/ios-code-signing/)
- [App Store Connect ヘルプ](https://help.apple.com/app-store-connect/)
- [Flutter iOS デプロイメント](https://docs.flutter.dev/deployment/ios)
- [Apple Developer](https://developer.apple.com/)
- [TestFlight](https://developer.apple.com/testflight/)

---

## 💡 次のステップ

1. まず **Apple Developer アカウント**を登録
2. **App Store Connect** でアプリを作成
3. **APIキー**を取得
4. **GitHub** にコードをプッシュ
5. **Codemagic** でセットアップ
6. **最初のビルド**を実行！

質問があれば、このドキュメントを参照するか、Codemagicのサポートに問い合わせてください。

Good luck with your iOS release! 🚀
