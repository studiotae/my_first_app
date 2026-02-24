import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:device_info_plus/device_info_plus.dart';

// 自作ファイルのインポート
import 'db_helper.dart';
import 'ad_banner.dart';
import 'anime/tae_animation.dart';
import 'gemini_analyzer.dart'; 

// .envファイルから API キーを読み込む
late String _apiKey;

// ---------------------------------------------------------
//  Main & MyApp
// ---------------------------------------------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // .env ファイルを読み込む
  await dotenv.load(fileName: ".env");
  _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  
  await MobileAds.instance.initialize();

  if (_apiKey.isEmpty) {
    debugPrint("【警告】APIキーが設定されていません。.env ファイルを確認してください。");
  } else {
    debugPrint("✅ APIキー設定確認: ${_apiKey.substring(0, 10)}...${_apiKey.substring(_apiKey.length - 5)}");
  }

  // デバッグ: Android パッケージ情報を出力
  if (Platform.isAndroid) {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      debugPrint("========== Android パッケージ情報 ==========");
      debugPrint("パッケージ名: ${androidInfo.id}");
      debugPrint("ビルド: ${androidInfo.brand} ${androidInfo.model}");
      debugPrint("Android: ${androidInfo.version.release} (API: ${androidInfo.version.sdkInt})");
      debugPrint("【重要】Google Cloud Console で以下を確認:");
      debugPrint("  ・API キー > アプリケーションの制限 > Android");
      debugPrint("  ・パッケージ名が 「com.studio.tae」 か確認");
      debugPrint("  ・SHA-1 フィンガープリントが正しいか確認");
      debugPrint("  ・確認方法: keytool -list -v -keystore ~/.android/debug.keystore");
      debugPrint("========================================");
    } catch (e) {
      debugPrint("デバイス情報取得エラー: $e");
    }
  }

  // API キー有効性テスト（デバッグ用）
  if (!_apiKey.isEmpty) {
    debugPrint("\n【デバッグ】API キー有効性をテスト中...");
    final analyzer = GeminiAnalyzer(apiKey: _apiKey);
    await analyzer.testApiKey();
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? _isTosAccepted;

  @override
  void initState() {
    super.initState();
    _checkTosStatus();
  }

  Future<void> _checkTosStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isTosAccepted = prefs.getBool('is_tos_accepted') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.yomogiTextTheme(Theme.of(context).textTheme);

    if (_isTosAccepted == null) {
      return MaterialApp(
        home: const Scaffold(
          backgroundColor: Color(0xFF3E2723), 
          body: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '耐 - TAE',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5D4037),
          primary: const Color(0xFF5D4037),
          secondary: const Color(0xFFFFB74D),
          surface: const Color(0xFF3E2723),
        ),
        scaffoldBackgroundColor: const Color(0xFF3E2723),
        useMaterial3: true,
        textTheme: textTheme,

        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFFFFF8E1),
          titleTextStyle: GoogleFonts.yomogi(
            color: const Color(0xFF3E2723), 
            fontSize: 20, 
            fontWeight: FontWeight.bold
          ),
          contentTextStyle: GoogleFonts.yomogi(
            color: const Color(0xFF3E2723), 
            fontSize: 16
          ),
        ),

        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.yomogi(
            color: Colors.white, 
            fontWeight: FontWeight.bold, 
            fontSize: 22
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
      ),
      home: _isTosAccepted! ? const DashboardScreen() : const TermsOfServicePage(),
    );
  }
}

// ---------------------------------------------------------
//  利用規約画面
// ---------------------------------------------------------
class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  Future<void> _acceptTos(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_tos_accepted', true);

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const String tosText = """
利用規約

この利用規約（以下「本規約」といいます。）は、本アプリ『耐』（以下「本アプリ」といいます。）の提供者（以下「運営者」といいます。）が提供するサービスの利用条件を定めるものです。ユーザーの皆さま（以下「ユーザー」といいます。）には、本規約に従って、本アプリをご利用いただきます。本アプリを利用し、「同意して利用を開始する」ボタン（または規約変更時の同意ボタン）を押した時点で、本規約に同意したものとみなされます。

第1条（本アプリの目的と性質）
1. 個人利用の原則
本アプリは、ユーザー自身が所有する学習資料（ノート、配布プリント等）を、AI技術を用いて整理・管理するための個人利用専用ツールです。
2. 共有機能の不存在
本アプリは、第三者へのファイル共有機能や、不特定多数への公開機能を意図して提供するものではありません。

第2条（定義）
1. 「コンテンツ」とは、本アプリを通じてユーザーが保存、管理する一切の情報（画像、テキスト、タグ情報等）をいいます。
2. 「AI解析」とは、本アプリに搭載された人工知能技術を用いて、画像内の文字情報を認識し、分類・タグ付けを行う機能をいいます。

第3条（禁止事項）
ユーザーは、本アプリの利用にあたり、以下の行為を行ってはなりません。
1. 著作権法に違反する行為
第三者の著作物（試験問題、教科書、出版物等）を、権利者の許諾なく、著作権法で認められた「私的使用のための複製」の範囲を超えて利用する行為。
2. 教育機関の規則に違反する行為
ユーザーが所属する学校、大学、その他教育機関が定める規則（学則、試験規定、シラバス等）に違反する行為。特に、試験問題の持ち出し禁止ルール、撮影禁止ルールに違反する行為、およびカンニング等の不正行為を固く禁じます。
3. 不正な共有および公衆送信
本アプリでスキャンまたは保存したデータを、権利者の許諾なく第三者に譲渡、貸与、配布、またはSNS、掲示板、共有ドライブ等を通じて公衆が閲覧可能な状態にする行為。
4. 運営妨害および不正利用
本アプリのプログラムの解析、改変、またはサーバーに過度な負荷をかける行為。

第4条（利用制限および登録抹消）
1. 運営者は、ユーザーが以下のいずれかに該当する場合には、事前の通知なく、ユーザーに対して本アプリの全部もしくは一部の利用を制限し、またはユーザーとしての登録を抹消することができるものとします。
(1) 本規約のいずれかの条項に違反した場合
(2) その他、運営者が本アプリの利用を適当でないと判断した場合
2. 運営者は、本条に基づき運営者が行った行為によりユーザーに生じた損害について、一切の責任を負いません。

第5条（本サービスの提供の停止等）
1. 運営者は、以下のいずれかの事由があると判断した場合、ユーザーに事前に通知することなく本サービスの全部または一部の提供を停止または中断することができるものとします。
(1) 本サービスにかかるコンピュータシステムの保守点検または更新を行う場合
(2) 地震、落雷、火災、停電または天災などの不可抗力により、本サービスの提供が困難となった場合
(3) 外部サービス（API提供元、クラウドサーバー等）のトラブル、サービス停止、または仕様変更が生じた場合
(4) その他、運営者が本サービスの提供が困難と判断した場合
2. 運営者は、本サービスの提供の停止または中断により、ユーザーまたは第三者が被ったいかなる不利益または損害についても、一切の責任を負わないものとします。

第6条（サービス内容の変更等および終了）
運営者は、ユーザーに通知することなく、本サービスの内容を変更し、または本サービスの提供を中止することができるものとし、これによってユーザーに生じた損害について一切の責任を負いません。

第7条（コンテンツの取扱いと権利）
1. 権利の帰属
ユーザーが本アプリにアップロードしたコンテンツの著作権は、当該ユーザーまたは当該コンテンツの正当な権利者に留保されます。運営者がコンテンツの著作権を取得することはありません。
2. 利用許諾
ユーザーは、運営者に対し、本サービスを提供および維持・改善するために必要な範囲（AIによる解析処理、データの変換、一時的な保存、サムネイル表示、バックアップ等を含みますがこれらに限りません）において、コンテンツを使用、複製、翻案、および公衆送信するための、非独占的かつ無償の権利を許諾するものとします。
3. 権利の保証
ユーザーは、アップロードするコンテンツについて、自らが投稿その他送信することについての適法な権利を有していること、および第三者の権利（著作権、肖像権、プライバシー権等）を侵害していないことを保証するものとします。
4. AI解析データの精度
運営者は、AIによる解析結果（科目名、作成者名等の認識精度）の完全性、正確性を保証しません。また、外部AIサービスの仕様変更により、解析機能が利用できなくなる可能性があることをユーザーは承諾するものとします。
5. データの統計的利用
運営者は、ユーザーのプライバシーを侵害しない範囲で、本アプリの利用状況（科目ごとの登録数等の数値データ）を統計的に処理し、本アプリの改良やマーケティングのために利用できるものとします。

第8条（免責事項）
1. 法的責任の所在
ユーザーが本アプリを利用して保存・管理したコンテンツに関して生じた著作権法違反、プライバシー侵害、その他一切の法的トラブルについて、運営者は一切の責任を負いません。すべての責任は当該行為を行ったユーザー本人に帰属します。
2. 教育機関による処分への免責
本アプリの利用が原因で、ユーザーが所属する教育機関から懲戒処分（停学、退学、訓告等）や、成績上の不利益（単位認定の取り消し等）を受けた場合であっても、運営者は一切の責任を負わず、いかなる補償も行いません。ユーザーは、自身の責任において、所属機関のルールを遵守した上で本アプリを利用するものとします。
3. データ消失
端末の故障、アプリの削除、OSのアップデート、サーバー障害等によりデータが消失した場合でも、運営者はその復旧や損害賠償の責任を負いません。

第9条（利用規約の変更）
1. 運営者は、必要と判断した場合には、本規約を変更することができるものとします。
2. 本規約を変更する場合、運営者は本アプリ上での表示その他適切な方法により、変更後の本規約の内容および効力発生日を周知するものとします。
3. 前項の効力発生日以降にユーザーが本アプリを利用した場合、または本アプリ上で変更への同意ボタンを押下した場合、ユーザーは変更後の規約に同意したものとみなされます。

第10条（準拠法・裁判管轄）
本規約の解釈にあたっては、日本法を準拠法とします。本アプリに関して紛争が生じた場合には、運営者の居住地を管轄する地方裁判所を専属的合意管轄とします。

以上
""";

    return Scaffold(
      appBar: AppBar(title: const Text('利用規約')),
      backgroundColor: const Color(0xFFFFF8E1), 
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.brown.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SingleChildScrollView(
                child: Text(tosText, style: TextStyle(color: Colors.black87)), 
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Color(0xFF5D4037),
              boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black12)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "上記規約を読み、理解した上で利用を開始します。",
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _acceptTos(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, 
                      foregroundColor: const Color(0xFF5D4037),
                    ),
                    child: const Text('同意して始める', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
//  Helper
// ---------------------------------------------------------
String _getDisplaySubject(String raw) {
  if (raw == "不明" || raw == "Unknown" || raw == "null") return "未仕分けボックス";
  return raw;
}
String _getDisplayTag(String raw) {
  if (raw == "不明" || raw == "Unknown" || raw == "タグなし" || raw == "null") return "一般・未分類";
  return raw;
}
String _getDisplayDate(String raw) {
  if (raw == "不明" || raw == "Unknown" || raw == "日付なし" || raw == "null") return "日付未定";
  return raw;
}

// ---------------------------------------------------------
//  階層1：科目一覧画面
// ---------------------------------------------------------
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;
  File? _processingImage;
  String _statusMessage = "";
  int _progressCurrent = 0;
  int _progressTotal = 0;
  
  Map<String, int> _subjectFolders = {};
  
  final GlobalKey _scanButtonKey = GlobalKey();
  final GlobalKey _importButtonKey = GlobalKey();
  final GlobalKey _tvButtonKey = GlobalKey();
  final GlobalKey _fabKey = GlobalKey(); // ＋ボタン用キー

  @override
  void initState() { 
    super.initState(); 
    _refreshFolders();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTutorial());
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    bool isTutorialShown = prefs.getBool('is_tutorial_shown_v3') ?? false;

    if (!isTutorialShown) {
      if (mounted) _showTutorial();
      await prefs.setBool('is_tutorial_shown_v3', true);
    }
  }

  void _showTutorial() {
    TutorialCoachMark(
      targets: [
        TargetFocus(
          identify: "scan_button",
          keyTarget: _scanButtonKey, 
          color: Colors.black, 
          contents: [
            TargetContent(
              align: ContentAlign.top, 
              builder: (context, controller) {
                return _buildOwlMessage("① カメラでスキャン", "ここを押して資料を撮影してね。\nAIが自動で分類するよ！");
              },
            ),
          ],
        ),
        TargetFocus(
          identify: "import_button",
          keyTarget: _importButtonKey, 
          color: Colors.black, 
          contents: [
            TargetContent(
              align: ContentAlign.top, 
              builder: (context, controller) {
                return _buildOwlMessage("② ライブラリから追加", "スマホに入っている画像も\nここからまとめて追加できるよ。");
              },
            ),
          ],
        ),
        TargetFocus(
          identify: "tv_button",
          keyTarget: _tvButtonKey, 
          color: Colors.black, 
          contents: [
            TargetContent(
              align: ContentAlign.bottom, 
              builder: (context, controller) {
                return _buildOwlMessage("③ ユーザー辞書", "キーワードを設定しておくと\nAIが優先的に振り分けてくれるよ！");
              },
            ),
          ],
        ),
        TargetFocus(
          identify: "fab_button",
          keyTarget: _fabKey, 
          color: Colors.black, 
          contents: [
            TargetContent(
              align: ContentAlign.top, 
              builder: (context, controller) {
                return _buildOwlMessage("④ フォルダ作成・編集", "ここから手動でフォルダを作れるよ！\n\n【重要】\nフォルダを「長押し」すると\n名前の変更や削除ができるよ。");
              },
            ),
          ],
        ),
      ],
      textSkip: "スキップ", 
      textStyleSkip: GoogleFonts.yomogi(color: Colors.white, fontWeight: FontWeight.bold),
      paddingFocus: 10,
      opacityShadow: 0.8, 
    ).show(context: context);
  }

  // フクロウのメッセージビルダー
  Widget _buildOwlMessage(String title, String message) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Image.asset('assets/start.png', height: 80), 
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                    const SizedBox(height: 4),
                    Text(message, style: const TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _refreshFolders() async {
    final data = await DBHelper.instance.queryAllRows();
    Map<String, int> map = {};
    for (var item in data) {
      String fullTitle = item['title'] ?? "不明 / 不明 / 不明 / 不明";
      List<String> parts = fullTitle.split(" / ");
      String subject = (parts.length >= 2) ? parts[1] : "不明";
      map[subject] = (map[subject] ?? 0) + 1;
    }
    setState(() { 
      _subjectFolders = map;
    });
  }

  Future<void> _renameSubject(String oldName, String newName) async {
    final allRows = await DBHelper.instance.queryAllRows();
    for (var row in allRows) {
      String currentSubject = row[DBHelper.columnSubject] ?? "";
      if (currentSubject == oldName) {
        Map<String, dynamic> updatedRow = Map.from(row);
        updatedRow[DBHelper.columnSubject] = newName;
        await DBHelper.instance.update(updatedRow);
      }
    }
    _refreshFolders();
  }

  Future<void> _deleteSubject(String subjectName) async {
    final allRows = await DBHelper.instance.queryAllRows();
    for (var row in allRows) {
       String fullTitle = row['title'] ?? "";
       List<String> parts = fullTitle.split(" / ");
       String subject = (parts.length >= 2) ? parts[1] : "不明";
       if (subject == subjectName) {
         await DBHelper.instance.delete(row[DBHelper.columnId]);
       }
    }
    _refreshFolders();
  }

  // 新規科目フォルダ作成
  Future<void> _addNewSubject(String newName) async {
    await DBHelper.instance.insertDocument(
      docType: "新規作成",
      subject: newName,
      tag: "未設定",
      period: "未設定",
      content: "空フォルダ",
      imagePath: "",
      fileHash: "manual_${DateTime.now().millisecondsSinceEpoch}",
    );
    _refreshFolders();
  }

  void _showFolderMenu(String subjectRaw, String subjectDisplay) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFF8E1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "「$subjectDisplay」のメニュー",
                  style: GoogleFonts.yomogi(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF3E2723)),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: Text("名前を変更", style: GoogleFonts.yomogi(fontSize: 18, color: Colors.black87)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRenameDialog(subjectRaw, subjectDisplay);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text("削除", style: GoogleFonts.yomogi(fontSize: 18, color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteConfirmDialog(subjectRaw, subjectDisplay);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showRenameDialog(String oldName, String oldDisplay) {
    final controller = TextEditingController(text: oldName == "不明" ? "" : oldName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("名前を変更", style: TextStyle(color: const Color(0xFF3E2723))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("「$oldDisplay」の新しい名前を入力してね。", style: TextStyle(fontSize: 14)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "新しい科目名",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("キャンセル"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _renameSubject(oldName, controller.text);
                if (mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D4037), foregroundColor: Colors.white),
            child: const Text("変更"),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("新しい科目を作る", style: TextStyle(color: Color(0xFF3E2723))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("作成する科目の名前を入力してね。", style: TextStyle(fontSize: 14)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: "例：数学、英語", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("キャンセル")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _addNewSubject(controller.text);
                if (mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D4037), foregroundColor: Colors.white),
            child: const Text("作成"),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(String subjectRaw, String subjectDisplay) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("「$subjectDisplay」を削除"),
        content: const Text("含まれる全てのドキュメントが削除されます。\n本当によろしいですか？"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("キャンセル"),
          ),
          TextButton(
            onPressed: () async {
              await _deleteSubject(subjectRaw);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("削除", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _startAnalysis(List<File> files) async {
    if (_isLoading) return;
    if (_apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("APIキーエラー")));
      return;
    }

    setState(() { _isLoading = true; _progressTotal = files.length; });
    
    final analyzer = GeminiAnalyzer(apiKey: _apiKey);
    String? lastResult; 

    for (int i = 0; i < files.length; i++) {
      setState(() { _processingImage = files[i]; _progressCurrent = i + 1; _statusMessage = "AI解析中..."; });
      
      String result = await analyzer.processSingleImage(files[i], previousResult: lastResult);
      
      if (!result.contains("エラー") && !result.contains("スキップ") && !result.contains("不明")) {
        lastResult = result;
      }
      
      _statusMessage = "完了"; 
      await Future.delayed(const Duration(seconds: 1));
    }
    setState(() { _isLoading = false; _processingImage = null; });
    _refreshFolders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景画像
          Positioned.fill(
            child: Image.asset(
              'assets/wall.png',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.4),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          
          Column(
            children: [
              // AppBar
              AppBar(
                title: const Text("ドキュメント管理"),
                actions: [
                  GestureDetector(
                    key: _tvButtonKey, 
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 1500),
                          reverseTransitionDuration: const Duration(milliseconds: 1500),
                          pageBuilder: (_, __, ___) => const TvDictionaryScreen(),
                          transitionsBuilder: (_, animation, __, child) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                        ),
                      );
                    },
                    child: Hero(
                      tag: 'tv_hero',
                      child: Container(
                        margin: const EdgeInsets.only(right: 16),
                        width: 60,
                        child: Image.asset('assets/tv.png'),
                      ),
                    ),
                  ),
                ],
              ),

              // フォルダ一覧エリア
              Expanded(
                child: _subjectFolders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Opacity(
                               opacity: 0.5,
                               child: Image.asset('assets/start.png', width: 100)
                            ),
                            const SizedBox(height: 16),
                            const Text("下のカメラから資料を追加してね", style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, 
                          childAspectRatio: 1.3, 
                          mainAxisSpacing: 16, 
                          crossAxisSpacing: 16
                        ),
                        itemCount: _subjectFolders.length,
                        itemBuilder: (ctx, i) {
                          String subjectRaw = _subjectFolders.keys.elementAt(i);
                          String subjectDisplay = _getDisplaySubject(subjectRaw);
                          if (subjectDisplay == "未仕分けボックス") subjectDisplay = "未整理";
                          int count = _subjectFolders[subjectRaw]!;

                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (_) => TagListScreen(subjectName: subjectRaw))
                            ).then((_) => _refreshFolders()),
                            onLongPress: () {
                              _showFolderMenu(subjectRaw, subjectDisplay);
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.asset('assets/clipboard.png', fit: BoxFit.contain),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 18), 
                                      SizedBox(
                                        height: 45,
                                        child: Center(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              subjectDisplay,
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.yomogi(
                                                color: const Color(0xFF3E2723),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.clip,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text("$count items", style: GoogleFonts.yomogi(color: Colors.brown.shade600, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              
              // 下部操作エリア
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                decoration: BoxDecoration(
                  color: const Color(0xFF3E2723), 
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      key: _scanButtonKey, 
                      child: _buildImageButton(
                        assetName: 'assets/camera.png',
                        label: "スキャン",
                        onTap: _isLoading ? () {} : () async {
                          try {
                            List<String>? paths = await CunningDocumentScanner.getPictures();
                            if (paths != null) await _startAnalysis(paths.map((e) => File(e)).toList());
                          } catch (e) {
                            debugPrint("スキャンエラー: $e");
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      key: _importButtonKey,
                      child: _buildImageButton(
                        assetName: 'assets/lamp.png',
                        label: "インポート",
                        onTap: _isLoading ? () {} : () async {
                          try {
                            final picked = await ImagePicker().pickMultiImage();
                            if (picked.isNotEmpty) await _startAnalysis(picked.map((e) => File(e.path)).toList());
                          } catch (e) {
                             debugPrint("インポートエラー: $e");
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SimpleBannerAd(),
            ],
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.9),
              width: double.infinity,
              height: double.infinity,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    if (_processingImage != null)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.file(_processingImage!, height: 220, fit: BoxFit.contain),
                      ),
                    const SizedBox(height: 20),
                    const TaeRandomLoadingAnimation(width: 180, height: 180),
                    const SizedBox(height: 20),
                    Text(_statusMessage, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("$_progressCurrent / $_progressTotal", style: const TextStyle(color: Colors.grey, fontSize: 24)),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120.0),
        child: FloatingActionButton(
          key: _fabKey,
          onPressed: _showAddDialog,
          backgroundColor: Colors.orange,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildImageButton({required String assetName, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(assetName, height: 70), 
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.yomogi(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
//  階層2：詳細タグ一覧画面
// ---------------------------------------------------------
class TagListScreen extends StatefulWidget {
  final String subjectName;
  const TagListScreen({super.key, required this.subjectName});
  @override
  State<TagListScreen> createState() => _TagListScreenState();
}

class _TagListScreenState extends State<TagListScreen> {
  Map<String, int> _tagFolders = {};
  @override
  void initState() { super.initState(); _loadTags(); }
  
  Future<void> _loadTags() async {
    final allRows = await DBHelper.instance.queryAllRows();
    Map<String, int> map = {};
    for (var row in allRows) {
      String fullTitle = row['title'] ?? "";
      List<String> parts = fullTitle.split(" / ");
      String subject = (parts.length >= 2) ? parts[1] : "不明";
      String tag = (parts.length >= 3) ? parts[2] : "不明";
      if (subject == widget.subjectName) map[tag] = (map[tag] ?? 0) + 1;
    }
    setState(() => _tagFolders = map);
  }

  Future<void> _renameTag(String oldTag, String newTag) async {
    final allRows = await DBHelper.instance.queryAllRows();
    for (var row in allRows) {
      String currentSubject = row[DBHelper.columnSubject] ?? "";
      String currentTag = row[DBHelper.columnTag] ?? "";
      
      if (currentSubject == widget.subjectName && currentTag == oldTag) {
        Map<String, dynamic> updatedRow = Map.from(row);
        updatedRow[DBHelper.columnTag] = newTag;
        await DBHelper.instance.update(updatedRow);
      }
    }
    _loadTags();
  }

  Future<void> _deleteTag(String tagRaw) async {
    final allRows = await DBHelper.instance.queryAllRows();
    for (var row in allRows) {
       String fullTitle = row['title'] ?? "";
       List<String> parts = fullTitle.split(" / ");
       String subject = (parts.length >= 2) ? parts[1] : "不明";
       String tag = (parts.length >= 3) ? parts[2] : "不明";
       
       if (subject == widget.subjectName && tag == tagRaw) {
         await DBHelper.instance.delete(row[DBHelper.columnId]);
       }
    }
    _loadTags();
  }

  Future<void> _addNewTag(String newTag) async {
    await DBHelper.instance.insertDocument(
      docType: "新規作成",
      subject: widget.subjectName,
      tag: newTag,
      period: "未設定",
      content: "空フォルダ",
      imagePath: "",
      fileHash: "manual_tag_${DateTime.now().millisecondsSinceEpoch}",
    );
    _loadTags();
  }

  void _showFolderMenu(String tagRaw, String tagDisplay) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFF8E1),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("「$tagDisplay」のメニュー", style: GoogleFonts.yomogi(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF3E2723))),
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: Text("名前を変更", style: GoogleFonts.yomogi(fontSize: 18, color: Colors.black87)),
                onTap: () { Navigator.pop(ctx); _showRenameDialog(tagRaw, tagDisplay); },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text("削除", style: GoogleFonts.yomogi(fontSize: 18, color: Colors.red)),
                onTap: () { Navigator.pop(ctx); _showDeleteConfirmDialog(tagRaw, tagDisplay); },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showRenameDialog(String oldName, String oldDisplay) {
    final controller = TextEditingController(text: oldName == "不明" ? "" : oldName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("名前を変更", style: TextStyle(color: Color(0xFF3E2723))),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "新しい分類名", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("キャンセル")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _renameTag(oldName, controller.text);
                if (mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D4037), foregroundColor: Colors.white),
            child: const Text("変更"),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(String tagRaw, String tagDisplay) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("「$tagDisplay」を削除"),
        content: const Text("このフォルダ内のデータがすべて消えます。\nよろしいですか？"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("キャンセル")),
          TextButton(
            onPressed: () async {
              await _deleteTag(tagRaw);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("削除", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("新しい分類を作る", style: TextStyle(color: Color(0xFF3E2723))),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "例：中間テスト、プリント", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("キャンセル")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _addNewTag(controller.text);
                if (mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D4037), foregroundColor: Colors.white),
            child: const Text("作成"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String titleDisplay = _getDisplaySubject(widget.subjectName);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/wall.png', fit: BoxFit.cover, color: Colors.black.withOpacity(0.4), colorBlendMode: BlendMode.darken)),
          Column(
            children: [
              AppBar(title: Text("$titleDisplay の分類")),
              Expanded(
                child: _tagFolders.isEmpty 
                  ? const Center(child: Text("フォルダがありません\n＋ボタンで作成できます", style: TextStyle(color: Colors.white)))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.3, mainAxisSpacing: 10, crossAxisSpacing: 10),
                      itemCount: _tagFolders.length,
                      itemBuilder: (ctx, i) {
                        String tagRaw = _tagFolders.keys.elementAt(i);
                        String tagDisplay = _getDisplayTag(tagRaw);
                        int count = _tagFolders[tagRaw]!;
                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => DateListScreen(subjectName: widget.subjectName, tagName: tagRaw)
                          )).then((_) => _loadTags()),
                          onLongPress: () {
                            _showFolderMenu(tagRaw, tagDisplay);
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset('assets/clipboard.png', fit: BoxFit.contain),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 12),
                                  Text(tagDisplay, style: GoogleFonts.yomogi(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF3E2723))),
                                  Text("$count items", style: GoogleFonts.yomogi(color: Colors.brown)),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ---------------------------------------------------------
//  階層3：時期一覧画面
// ---------------------------------------------------------
class DateListScreen extends StatefulWidget {
  final String subjectName;
  final String tagName;
  const DateListScreen({super.key, required this.subjectName, required this.tagName});
  @override
  State<DateListScreen> createState() => _DateListScreenState();
}

class _DateListScreenState extends State<DateListScreen> {
  Map<String, int> _dateFolders = {};
  @override
  void initState() { super.initState(); _loadDates(); }
  
  Future<void> _loadDates() async {
    final allRows = await DBHelper.instance.queryAllRows();
    Map<String, int> map = {};
    for (var row in allRows) {
      String fullTitle = row['title'] ?? "";
      List<String> parts = fullTitle.split(" / ");
      String subject = (parts.length >= 2) ? parts[1] : "不明";
      String tag = (parts.length >= 3) ? parts[2] : "不明";
      String date = (parts.length >= 4) ? parts[3] : "不明";
      if (subject == widget.subjectName && tag == widget.tagName) map[date] = (map[date] ?? 0) + 1;
    }
    setState(() => _dateFolders = map);
  }

  Future<void> _renameDate(String oldDate, String newDate) async {
    final allRows = await DBHelper.instance.queryAllRows();
    for (var row in allRows) {
      String currentSubject = row[DBHelper.columnSubject] ?? "";
      String currentTag = row[DBHelper.columnTag] ?? "";
      String currentDate = row[DBHelper.columnPeriod] ?? "";
      
      if (currentSubject == widget.subjectName && currentTag == widget.tagName && currentDate == oldDate) {
        Map<String, dynamic> updatedRow = Map.from(row);
        updatedRow[DBHelper.columnPeriod] = newDate;
        await DBHelper.instance.update(updatedRow);
      }
    }
    _loadDates();
  }

  Future<void> _deleteDate(String dateRaw) async {
    final allRows = await DBHelper.instance.queryAllRows();
    for (var row in allRows) {
       String fullTitle = row['title'] ?? "";
       List<String> parts = fullTitle.split(" / ");
       String subject = (parts.length >= 2) ? parts[1] : "不明";
       String tag = (parts.length >= 3) ? parts[2] : "不明";
       String date = (parts.length >= 4) ? parts[3] : "不明";
       
       if (subject == widget.subjectName && tag == widget.tagName && date == dateRaw) {
         await DBHelper.instance.delete(row[DBHelper.columnId]);
       }
    }
    _loadDates();
  }

  Future<void> _addNewDate(String newDate) async {
    await DBHelper.instance.insertDocument(
      docType: "新規作成",
      subject: widget.subjectName,
      tag: widget.tagName,
      period: newDate,
      content: "空フォルダ",
      imagePath: "",
      fileHash: "manual_date_${DateTime.now().millisecondsSinceEpoch}",
    );
    _loadDates();
  }

  void _showFolderMenu(String dateRaw, String dateDisplay) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFF8E1),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("「$dateDisplay」のメニュー", style: GoogleFonts.yomogi(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF3E2723))),
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: Text("名前を変更", style: GoogleFonts.yomogi(fontSize: 18, color: Colors.black87)),
                onTap: () { Navigator.pop(ctx); _showRenameDialog(dateRaw, dateDisplay); },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text("削除", style: GoogleFonts.yomogi(fontSize: 18, color: Colors.red)),
                onTap: () { Navigator.pop(ctx); _showDeleteConfirmDialog(dateRaw, dateDisplay); },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showRenameDialog(String oldName, String oldDisplay) {
    final controller = TextEditingController(text: oldName == "不明" ? "" : oldName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("名前を変更", style: TextStyle(color: Color(0xFF3E2723))),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "新しい日程名", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("キャンセル")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _renameDate(oldName, controller.text);
                if (mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D4037), foregroundColor: Colors.white),
            child: const Text("変更"),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(String dateRaw, String dateDisplay) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("「$dateDisplay」を削除"),
        content: const Text("フォルダ内の画像がすべて消えます。\nよろしいですか？"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("キャンセル")),
          TextButton(
            onPressed: () async {
              await _deleteDate(dateRaw);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("削除", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("新しい日程を作る", style: TextStyle(color: Color(0xFF3E2723))),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "例：2026年度、5月1日", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("キャンセル")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _addNewDate(controller.text);
                if (mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D4037), foregroundColor: Colors.white),
            child: const Text("作成"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String tagDisplay = _getDisplayTag(widget.tagName);
    return Scaffold(
      body: Stack(
        children: [
           Positioned.fill(child: Image.asset('assets/wall.png', fit: BoxFit.cover, color: Colors.black.withOpacity(0.4), colorBlendMode: BlendMode.darken)),
          Column(
            children: [
              AppBar(title: Text("$tagDisplay - 時期別")),
              Expanded(
                child: _dateFolders.isEmpty 
                  ? const Center(child: Text("データがありません\n＋ボタンで作成できます", style: TextStyle(color: Colors.white)))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.3, mainAxisSpacing: 10, crossAxisSpacing: 10),
                      itemCount: _dateFolders.length,
                      itemBuilder: (ctx, i) {
                        String dateRaw = _dateFolders.keys.elementAt(i);
                        String dateDisplay = _getDisplayDate(dateRaw);
                        int count = _dateFolders[dateRaw]!;
                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => FinalGalleryScreen(subjectName: widget.subjectName, tagName: widget.tagName, dateInfo: dateRaw)
                          )).then((_) => _loadDates()),
                          onLongPress: () {
                            _showFolderMenu(dateRaw, dateDisplay);
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset('assets/clipboard.png', fit: BoxFit.contain),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 12),
                                  Text(dateDisplay, style: GoogleFonts.yomogi(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF3E2723))),
                                  Text("$count items", style: GoogleFonts.yomogi(color: Colors.brown)),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ---------------------------------------------------------
//  階層4：画像一覧画面
// ---------------------------------------------------------
class FinalGalleryScreen extends StatefulWidget {
  final String subjectName;
  final String tagName;
  final String dateInfo;
  const FinalGalleryScreen({super.key, required this.subjectName, required this.tagName, required this.dateInfo});
  @override
  State<FinalGalleryScreen> createState() => _FinalGalleryScreenState();
}

class _FinalGalleryScreenState extends State<FinalGalleryScreen> {
  List<Map<String, dynamic>> _images = [];
  @override
  void initState() { super.initState(); _loadImages(); }
  Future<void> _loadImages() async {
    final all = await DBHelper.instance.queryAllRows();
    if (!mounted) return;
    setState(() { 
      _images = all.where((e) {
        String fullTitle = e['title'] ?? "";
        List<String> parts = fullTitle.split(" / ");
        String s = (parts.length >= 2) ? parts[1] : "不明";
        String t = (parts.length >= 3) ? parts[2] : "不明";
        String d = (parts.length >= 4) ? parts[3] : "不明";
        return s == widget.subjectName && t == widget.tagName && d == widget.dateInfo;
      }).toList(); 
    });
  }

  Future<void> _addManualImage() async {
    showModalBottomSheet(context: context, builder: (ctx) {
      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("カメラで撮影して追加"),
              onTap: () async { Navigator.pop(ctx); _pickAndSave(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("アルバムから追加"),
              onTap: () async { Navigator.pop(ctx); _pickAndSave(ImageSource.gallery); },
            ),
          ],
        ),
      );
    });
  }

  Future<void> _pickAndSave(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile == null) return;
    final bytes = await pickedFile.readAsBytes();
    final hash = md5.convert(bytes).toString();
    await DBHelper.instance.insertDocument(
      docType: "手動追加",
      subject: widget.subjectName,
      tag: widget.tagName,
      period: widget.dateInfo,
      content: "手動追加",
      imagePath: pickedFile.path,
      fileHash: hash,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("追加しました")));
    _loadImages(); 
  }

  @override
  Widget build(BuildContext context) {
    String dateDisplay = _getDisplayDate(widget.dateInfo);
    return Scaffold(
      body: Stack(
        children: [
           Positioned.fill(child: Image.asset('assets/wall.png', fit: BoxFit.cover, color: Colors.black.withOpacity(0.4), colorBlendMode: BlendMode.darken)),
          Column(
            children: [
              AppBar(title: Text(dateDisplay)),
              Expanded(
                child: _images.isEmpty 
                    ? const Center(child: Text("画像がありません\n＋ボタンで追加できます", style: TextStyle(color: Colors.white)))
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8),
                        itemCount: _images.length,
                        itemBuilder: (ctx, i) {
                          return GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenViewer(initialIndex: i, images: _images))).then((_) => _loadImages()),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(2, 2))],
                              ),
                              child: Image.file(
                                File(_images[i]['image_path']), 
                                fit: BoxFit.cover,
                                cacheWidth: 300,
                                errorBuilder: (c, o, s) => Container(
                                  color: Colors.black12,
                                  child: const Center(child: Icon(Icons.folder_open, color: Colors.white70, size: 40)),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addManualImage,
        backgroundColor: const Color(0xFF5D4037),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}

// ---------------------------------------------------------
//  画像拡大ビューア
// ---------------------------------------------------------
class FullScreenViewer extends StatefulWidget {
  final int initialIndex;
  final List<Map<String, dynamic>> images;
  const FullScreenViewer({super.key, required this.initialIndex, required this.images});
  @override
  State<FullScreenViewer> createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends State<FullScreenViewer> {
  late PageController _controller;
  late List<Map<String, dynamic>> _currentImages;
  int _currentIndex = 0;
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _currentImages = List.from(widget.images);
    _controller = PageController(initialPage: widget.initialIndex);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.delete), onPressed: () async {
            await DBHelper.instance.delete(_currentImages[_currentIndex][DBHelper.columnId]);
            setState(() {
              _currentImages.removeAt(_currentIndex);
              if (_currentImages.isEmpty) Navigator.pop(context);
            });
          }),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: _currentImages.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (ctx, i) => Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.file(File(_currentImages[i]['image_path']), fit: BoxFit.contain, cacheWidth: 1200, errorBuilder: (c,o,s) => const Icon(Icons.broken_image, color: Colors.white, size: 50)),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
//  辞書設定画面（テレビ UI）
// ---------------------------------------------------------
class TvDictionaryScreen extends StatefulWidget {
  const TvDictionaryScreen({super.key});
  @override
  State<TvDictionaryScreen> createState() => _TvDictionaryScreenState();
}

class _TvDictionaryScreenState extends State<TvDictionaryScreen> {
  List<Map<String, dynamic>> _rules = [];
  final _keywordController = TextEditingController();
  final _subjectController = TextEditingController();
  bool _isAddingMode = false;
  final Color _retroGreen = const Color(0xFF4CAF50); 
  final Color _retroText = const Color(0xFF69F0AE);

  TextStyle get _glowingTextStyle {
    return TextStyle(
      color: _retroText, fontSize: 16, fontWeight: FontWeight.bold,
      shadows: [Shadow(blurRadius: 10.0, color: _retroText.withOpacity(0.8), offset: const Offset(0, 0))],
    );
  }

  @override
  void initState() { super.initState(); _loadRules(); }
  Future<void> _loadRules() async {
    final data = await DBHelper.instance.getAllKeywordRules();
    setState(() => _rules = data);
  }
  Future<void> _addRule() async {
    if (_keywordController.text.isEmpty || _subjectController.text.isEmpty) return;
    await DBHelper.instance.addKeywordRule(_keywordController.text, _subjectController.text);
    _keywordController.clear(); _subjectController.clear(); _loadRules();
    setState(() => _isAddingMode = false);
    if (mounted) FocusScope.of(context).unfocus();
  }
  Future<void> _deleteRule(int id) async { await DBHelper.instance.deleteKeywordRule(id); _loadRules(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false, 
      body: Stack(
        children: [
          Positioned.fill(child: Hero(tag: 'tv_hero', child: Image.asset('assets/tv.png', fit: BoxFit.cover, color: Colors.black.withOpacity(0.3), colorBlendMode: BlendMode.darken))),
          Positioned.fill(child: Container(decoration: BoxDecoration(gradient: RadialGradient(center: Alignment.center, radius: 1.0, colors: [Colors.transparent, Colors.black.withOpacity(0.6)], stops: const [0.6, 1.0])))),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: Icon(Icons.arrow_back, color: _retroText), onPressed: () => Navigator.pop(context)),
                      Text("マイルール辞書", style: _glowingTextStyle.copyWith(fontSize: 22, letterSpacing: 2)),
                      IconButton(icon: Icon(_isAddingMode ? Icons.close : Icons.edit, color: _retroText), onPressed: () => setState(() => _isAddingMode = !_isAddingMode)),
                    ],
                  ),
                  Divider(color: _retroText, thickness: 2),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 50),
                      children: [
                        const SizedBox(height: 10),
                        if (_isAddingMode) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), border: Border.all(color: _retroText, width: 1), borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(">> 新しいルールを入力...", style: _glowingTextStyle),
                                const SizedBox(height: 15),
                                _buildRetroTextField(controller: _keywordController, label: "キーワード（例：テスト）"),
                                const SizedBox(height: 15),
                                _buildRetroTextField(controller: _subjectController, label: "科目名（例：数学）"),
                                const SizedBox(height: 20),
                                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _addRule, style: ElevatedButton.styleFrom(backgroundColor: _retroGreen, foregroundColor: Colors.black), child: const Text("登 録 す る", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (_rules.isEmpty && !_isAddingMode)
                          Padding(padding: const EdgeInsets.only(top: 100), child: Center(child: Text("データがありません。\n右上のペンボタンで\nルールを追加してください。", textAlign: TextAlign.center, style: _glowingTextStyle.copyWith(height: 1.5)))),
                        ..._rules.map((rule) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _retroText.withOpacity(0.3)))),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              title: Text("『${rule['keyword']}』があれば", style: _glowingTextStyle.copyWith(fontSize: 18)),
                              subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(" → 科目【${rule['subject']}】に入れる", style: TextStyle(color: _retroText.withOpacity(0.8), fontSize: 14))),
                              trailing: IconButton(icon: Icon(Icons.delete_outline, color: _retroText), onPressed: () => _deleteRule(rule['_id'])),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(child: IgnorePointer(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.1)], stops: const [0.5, 1.0], tileMode: TileMode.repeated))))),
        ],
      ),
    );
  }
  Widget _buildRetroTextField({required TextEditingController controller, required String label}) {
    return TextField(
      controller: controller, style: _glowingTextStyle, cursorColor: _retroText,
      decoration: InputDecoration(
        labelText: label, labelStyle: TextStyle(color: _retroText.withOpacity(0.6)),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _retroText)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _retroText, width: 2)),
        isDense: true, prefixIcon: Icon(Icons.arrow_right, color: _retroText),
      ),
    );
  }
}