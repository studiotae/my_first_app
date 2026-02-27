import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'db_helper.dart';

class GeminiAnalyzer {
  final String apiKey;

  GeminiAnalyzer({required this.apiKey});

  /// API キーの有効性をテスト（デバッグ用）
  Future<void> testApiKey() async {
    print("========== API キー有効性テスト開始 ==========");
    print("【APIキー】${apiKey.substring(0, 10)}...${apiKey.substring(apiKey.length - 5)}");
    
    try {
      final model = GenerativeModel(model: 'gemini-3-flash-preview', apiKey: apiKey);
      
      // シンプルなテストリクエスト（画像なし）
      print("【テスト】テキストのみでリクエスト送信...");
      final response = await model.generateContent(
        [Content.multi([TextPart("Hello, this is a simple test.")])],
      );
      
      print("✓ API キーは有効です");
      print("【レスポンス】${response.text?.substring(0, 50) ?? 'null'}...");
      
    } on FormatException catch (e) {
      print("✗ API キーのフォーマットが無効です");
      print("【エラー】$e");
    } catch (e) {
      print("✗ エラーが発生しました");
      print("【エラータイプ】${e.runtimeType}");
      print("【エラーメッセージ】$e");
    }
    
    print("========== テスト終了 ==========");
  }

  /// 単一のドキュメント画像を解析
  /// 
  /// - [file]: 解析対象の画像ファイル
  /// - [previousResult]: 直前の解析結果（文脈学習用）
  /// 
  /// 戻り値: 「ドキュメント種別 / 科目名 / 詳細タグ / 時期情報」の形式
  Future<String> processSingleImage(
    File file, {
    String? previousResult,
  }) async {
    final bytes = await file.readAsBytes();
    final hash = md5.convert(bytes).toString();

    // 重複チェック
    if (await DBHelper.instance.isDuplicate(hash)) {
      return "重複スキップ";
    }

    // キーワードルールを取得
    final rules = await DBHelper.instance.getAllKeywordRules();
    String dictText = "";
    if (rules.isNotEmpty) {
      dictText =
          "【重要：キーワード優先ルール】\n画像内に以下の語句がある場合は、指定の科目名に分類してください。\n";
      for (var rule in rules) {
        dictText +=
            "・「${rule[DBHelper.columnKeyword]}」→ 科目：「${rule[DBHelper.columnRuleSubject]}」\n";
      }
    }

    // 文脈情報を追加
    String contextText = "";
    if (previousResult != null && !previousResult.contains("不明")) {
      contextText =
          "\n【重要：文脈と推論機能】\n直前の解析結果: 『$previousResult』\nもし今回の画像に詳細がなく、直前の画像の続きと思われる場合は、以下の判断基準で直前の情報を引き継いでください。\n1. 連番の推理\n2. 画像の雰囲気\n";
    }

    final model =
        GenerativeModel(model: 'gemini-3-flash-preview', apiKey: apiKey);
    final prompt = TextPart(
      "この画像は学習用ドキュメントです。ファイリングのために以下の情報を抽出してください。\n\n"
      "【出力フォーマット】\n"
      "必ず以下の順序で、スラッシュ区切りで出力してください。\n"
      "『ドキュメント種別 / 科目名 / 詳細タグ / 時期情報』\n"
      "（例: 試験用紙 / 熱力学 / 佐藤教授 / 2024年度）\n\n"
      "【抽出ルール】\n"
      "1. ドキュメント種別(試験用紙/手書きノート/レポート/配布プリント)\n"
      "2. 科目名(不明な場合は『不明』)\n"
      "3. 詳細タグ(作成者優先、なければイベント名)\n"
      "4. 時期情報(年度や日付)\n\n"
      "$dictText\n$contextText\n"
      "回答は指定フォーマットの1行のみで出力してください。",
    );

    try {
      print("[Gemini] 解析リクエスト送信中...");
      print("[Debug] ファイル: ${file.path}");
      print("[Debug] ファイルサイズ: ${bytes.length} bytes");
      print("[Debug] APIキー: ${apiKey.substring(0, 10)}...${apiKey.substring(apiKey.length - 5)}");
      
      final response = await model.generateContent(
        [Content.multi([prompt, DataPart('image/jpeg', bytes)])],
      );

      print("========== Gemini レスポンス詳細 ==========");
      print("[Response] text: ${response.text}");
      print("[Response] candidates: ${response.candidates?.length ?? 0}");
      if (response.candidates != null && response.candidates!.isNotEmpty) {
        print("[Response] first candidate: ${response.candidates!.first}");
      }
      print("==========================================");

      String result = response.text?.trim() ?? "不明 / 不明 / 不明 / 不明";
      result = result.replaceAll("\n", " ");
      print("[Gemini] 判定結果（処理後）: $result");

      // 正規化されたDBに保存
      _parseAndSaveResult(result, file.path, hash);

      return result;
    } catch (e) {
      print("========== Gemini Error ==========");
      print("【エラータイプ】${e.runtimeType}");
      print("【エラーメッセージ】$e");
      print("【ファイル】${file.path}");
      print("【ファイルサイズ】${bytes.length} bytes");
      print("【APIキー設定】${apiKey.isNotEmpty ? '✓ 設定済み' : '✗ 未設定'}");
      
      // スタックトレースも出力
      if (e is Exception) {
        print("【例外情報】${e.toString()}");
      }
      
      print("========== エラー詳細ここまで ==========");
      return "解析エラー";
    }
  }

  /// 解析結果をパースしてDBに保存
  Future<void> _parseAndSaveResult(
    String result,
    String imagePath,
    String fileHash,
  ) async {
    print("========== パース処理開始 ==========");
    print("[Parse] 元の文字列: $result");
    
    List<String> parts = result.split(" / ");
    print("[Parse] 分割結果: $parts");
    print("[Parse] パート数: ${parts.length}");
    
    String docType = parts.isNotEmpty ? parts[0].trim() : "不明";
    String subject = parts.length > 1 ? parts[1].trim() : "不明";
    String tag = parts.length > 2 ? parts[2].trim() : "不明";
    String period = parts.length > 3 ? parts[3].trim() : "未設定";

    print("[Parse] docType: $docType");
    print("[Parse] subject: $subject");
    print("[Parse] tag: $tag");
    print("[Parse] period: $period");
    print("========================================");

    await DBHelper.instance.insertDocument(
      docType: docType,
      subject: subject,
      tag: tag,
      period: period,
      content: "AI解析済み",
      imagePath: imagePath,
      fileHash: fileHash,
    );
    
    print("[DB] 保存完了");
  }
}
