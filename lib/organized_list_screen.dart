import 'dart:io';
import 'package:flutter/material.dart';
import 'db_helper.dart'; 
import 'ad_banner.dart'; 

class OrganizedListScreen extends StatefulWidget {
  const OrganizedListScreen({super.key});

  @override
  State<OrganizedListScreen> createState() => _OrganizedListScreenState();
}

class _OrganizedListScreenState extends State<OrganizedListScreen> {
  // フォルダ分けしたデータ
  Map<String, List<Map<String, dynamic>>> _folders = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  // データを読み込んでフォルダ分けする
  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    final data = await DBHelper.instance.queryAllRows();

    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var doc in data) {
      // データベースには'title'カラムは存在しない。'subject'（科目名）でグループ化
      String title = doc['subject'] ?? '未分類';
      if (!grouped.containsKey(title)) {
        grouped[title] = [];
      }
      grouped[title]!.add(doc);
    }

    setState(() {
      _folders = grouped;
      _isLoading = false;
    });
  }

  void _showFolderMenu(BuildContext context, String folderName) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text('「$folderName」の操作'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _showRenameDialog(context, folderName);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue),
                    SizedBox(width: 10),
                    Text('フォルダ名を変更'),
                  ],
                ),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _confirmDeleteFolder(context, folderName);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 10),
                    Text('フォルダを削除'),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, String currentName) {
    final TextEditingController _controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('フォルダ名を変更'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: "新しい名前を入力"),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = _controller.text.trim();
                if (newName.isNotEmpty && newName != currentName) {
                  await DBHelper.instance.renameFolder(currentName, newName);
                  _loadDocuments();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('「$currentName」を「$newName」に変更しました')),
                    );
                  }
                }
              },
              child: const Text('変更'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteFolder(BuildContext context, String folderName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('フォルダを削除'),
          content: Text('「$folderName」とその中のプリントをすべて削除しますか？\nこの操作は元に戻せません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await DBHelper.instance.deleteFolder(folderName);
                _loadDocuments();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('「$folderName」を削除しました')),
                  );
                }
              },
              child: const Text('削除する', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('過去問フォルダ一覧', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _folders.isEmpty
                    ? const Center(child: Text("データがありません"))
                    : ListView.builder(
                        itemCount: _folders.keys.length,
                        itemBuilder: (context, index) {
                          String folderName = _folders.keys.elementAt(index);
                          List<Map<String, dynamic>> files = _folders[folderName]!;

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: ListTile(
                              leading: const Icon(Icons.folder, color: Colors.amber, size: 50),
                              title: Text(folderName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("${files.length} 枚のプリント"),
                              trailing: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                              
                              onLongPress: () {
                                _showFolderMenu(context, folderName);
                              },

                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FolderContentsScreen(
                                      currentFolderName: folderName,
                                      files: files,
                                      allFolderNames: _folders.keys.toList(),
                                    ),
                                  ),
                                );
                                _loadDocuments();
                              },
                            ),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 5),
          const SimpleBannerAd(),
          const SizedBox(height: 5),
        ],
      ),
    );
  }
}

// --- 以下、中身の画面などは変更ないのでそのまま置いておきます ---

class FolderContentsScreen extends StatelessWidget {
  final String currentFolderName;
  final List<Map<String, dynamic>> files;
  final List<String> allFolderNames;

  const FolderContentsScreen({
    super.key,
    required this.currentFolderName,
    required this.files,
    required this.allFolderNames,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentFolderName, style: const TextStyle(fontSize: 16, color: Colors.white)),
        backgroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                final doc = files[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  child: ListTile(
                    leading: const Icon(Icons.description, color: Colors.blueGrey),
                    title: Text(
                      "日付: ${doc['date'].toString().substring(5, 16)}",
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: const Text("長押しで移動", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    trailing: const Icon(Icons.touch_app, color: Colors.orange),
                    
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DocumentDetailScreen(
                            title: doc['title'],
                            content: doc['content'],
                            imagePath: doc['image_path'],
                          ),
                        ),
                      );
                    },

                    onLongPress: () {
                      _showMoveDialog(context, doc);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showMoveDialog(BuildContext context, Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("フォルダを移動"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allFolderNames.length,
              itemBuilder: (context, index) {
                String targetFolder = allFolderNames[index];
                if (targetFolder == currentFolderName) return const SizedBox.shrink();

                return ListTile(
                  leading: const Icon(Icons.folder_open, color: Colors.amber),
                  title: Text(targetFolder),
                  onTap: () async {
                    Map<String, dynamic> updatedRow = Map.from(doc);
                    updatedRow['title'] = targetFolder; 
                    
                    await DBHelper.instance.update(updatedRow);

                    Navigator.pop(context);
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("「$targetFolder」に移動しました")),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("キャンセル"),
            ),
          ],
        );
      },
    );
  }
}

class DocumentDetailScreen extends StatelessWidget {
  final String title;
  final String content;
  final String? imagePath;

  const DocumentDetailScreen({
    super.key,
    required this.title,
    required this.content,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("詳細データ", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (imagePath != null && File(imagePath!).existsSync())
                Image.file(File(imagePath!))
              else
                const Icon(Icons.broken_image, size: 100, color: Colors.grey),
              const SizedBox(height: 20),
              SelectableText(content),
            ],
          ),
        ),
      ),
    );
  }
}