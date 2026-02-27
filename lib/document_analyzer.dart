import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'db_helper.dart';

class DocumentAnalyzer {
  final String apiKey;

  DocumentAnalyzer({required this.apiKey});

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
          "画像内に以下の語句がある場合は、指定の科目名に分類してください。\n";
      for (var rule in rules) {
        dictText +=
            "・「${rule[DBHelper.columnKeyword]}」→ 科目：「${rule[DBHelper.columnRuleSubject]}」\n";
      }
    }

    String contextText = "";
    if (previousResult != null && !previousResult.contains("不明")) {
      contextText =
          "\n直前の解析結果: 『$previousResult』\nもし今回の画像に詳細がなく、直前の画像の続きと思われる場合は、以下の判断基準で直前の情報を引き継いでください。\n1. 連番の推理\n2. 画像の雰囲気\n";
    }

    final model =
        GenerativeModel(model: 'gemini-3-flash-preview', apiKey: apiKey);
    final prompt = TextPart(
      "この画像は学習用ドキュメントです。ファイリングのために以下の情報を抽出してください。\n\n"
      "出力形式:\n"
      "必ず以下の順序で出力してください。\n"
      "『ドキュメント種別 / 科目名 / 詳細タグ / 時期情報』\n"
      "（例: 試験用紙 / 熱力学 / 佐藤教授 / 2024年度）\n\n"
      "抽出内容:\n"
      "1. ドキュメント種別(試験用紙/手書きノート/レポート/配布プリント)\n"
      "2. 科目名(不明な場合は『不明』)\n"
      "3. 詳細タグ(作成者優先、なければイベント名)\n"
      "4. 時期情報(年度や日付)\n\n"
      "$dictText\n$contextText\n",
    );

    try {
      final response = await model.generateContent(
        [Content.multi([prompt, DataPart('image/jpeg', bytes)])],
      );

      String result = response.text?.trim() ?? "不明 / 不明 / 不明 / 不明";
      result = result.replaceAll("\n", " ");

      _parseAndSaveResult(result, file.path, hash);

      return result;
    } catch (e) {
      return "解析エラー";
    }
  }

  /// 解析結果をパースしてDBに保存
  Future<void> _parseAndSaveResult(
    String result,
    String imagePath,
    String fileHash,
  ) async {
    List<String> parts = result.split(" / ");
    
    String docType = parts.isNotEmpty ? parts[0].trim() : "不明";
    String subject = parts.length > 1 ? parts[1].trim() : "不明";
    String tag = parts.length > 2 ? parts[2].trim() : "不明";
    String period = parts.length > 3 ? parts[3].trim() : "未設定";

    await DBHelper.instance.insertDocument(
      docType: docType,
      subject: subject,
      tag: tag,
      period: period,
      content: "解析済み",
      imagePath: imagePath,
      fileHash: fileHash,
    );
  }
}
