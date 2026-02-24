# Google Cloud Console API キー設定

## 📋 登録すべき情報

### 【デバッグ用（開発・テスト）】
- **パッケージ名**: `com.studio.tae`
- **SHA-1 フィンガープリント**: `84:D9:62:CE:C7:2B:5D:60:DF:1A:AF:E5:68:8C:1D:AA:C9:C2:C5:5C`
- **キーストア**: `~/.android/debug.keystore`
- **用途**: 開発・テスト時にエミュレータや開発端末で実行

### 【リリース用（本番・Google Play Store）】
- **パッケージ名**: `com.studio.tae`
- **SHA-1 フィンガープリント**: `4E:52:FC:3E:9F:3E:9A:A8:F4:0A:44:5D:2E:07:D8:14:D5:1E:D8:78`
- **キーストア**: `android/app/upload-keystore.jks`
- **用途**: 本番環境・Google Play Store への配布

---

## 🔧 Google Cloud Console での登録手順

1. **Google Cloud Console にアクセス**
   - https://console.cloud.google.com

2. **API キーを選択**
   - 左メニュー → 「認証情報」
   - 対象の API キーをクリック

3. **「アプリケーションの制限」を設定**
   - セクション: 「アプリケーションの制限」
   - ドロップダウン: **「Android アプリ」** を選択
   
4. **Android アプリを2つ登録**
   - ボタン: **「Android アプリを追加」** をクリック（2回）
   
   ① デバッグ用:
      - **パッケージ名**: `com.studio.tae`
      - **SHA-1 フィンガープリント**: `84:D9:62:CE:C7:2B:5D:60:DF:1A:AF:E5:68:8C:1D:AA:C9:C2:C5:5C`
   
   ② リリース用:
      - **パッケージ名**: `com.studio.tae`
      - **SHA-1 フィンガープリント**: `4E:52:FC:3E:9F:3E:9A:A8:F4:0A:44:5D:2E:07:D8:14:D5:1E:D8:78`
   
5. **保存**
   - ページ上部の **「保存」** をクリック

---

## ✅ 設定完了後の確認

設定を保存した後、アプリをリビルドして以下を確認:

```bash
flutter clean
flutter pub get
flutter run
```

エラーが解消されれば、Google Cloud への登録が成功しています。

---

## 📝 注意事項

- **パッケージ名は両方で同じ**: `com.studio.tae`
- **SHA-1 は異なる**: デバッグ用とリリース用で異なります
- 両方のSHA-1を Google Cloud Console に登録する必要があります
- デバッグビルドとリリースビルドで異なるキーストアを使用しているため、SHA-1 も異なります

---

## 🔍 トラブルシューティング

### 「<empty>」エラーが解消されない場合
1. Google Cloud コンソールで設定が保存されているか再確認
2. **両方のSHA-1が登録されているか確認**:
   - ① デバッグ用: `84:D9:62:CE:C7:2B:5D:60:DF:1A:AF:E5:68:8C:1D:AA:C9:C2:C5:5C`
   - ② リリース用: `4E:52:FC:3E:9F:3E:9A:A8:F4:0A:44:5D:2E:07:D8:14:D5:1E:D8:78`
3. 5～10分待つ（キャッシュ反映に時間がかかる場合あり）
4. 設定を保存した後、キャッシュをクリアして再度実行:
   ```bash
   flutter clean
   adb uninstall com.studio.tae
   flutter run
   ```

### 次に確認すること
1. アプリ起動時のログで以下を確認：
   - ✓ API キー有効性テストの結果
   - ✓ パッケージ名: `com.studio.tae` と表示されている
2. Google Cloud Console で以下を確認：
   - ✓ API「Generative Language API」が有効化されている
   - ✓ API キーの「API の制限」に「Generative Language API」が選択されている

