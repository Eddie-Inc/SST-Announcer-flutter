import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sst_announcer/folders/foldercontents.dart';
import 'package:sst_announcer/folders/storagecontroller.dart';

class FolderPage extends StatefulWidget {
  const FolderPage({super.key});

  @override
  State<FolderPage> createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage> {
  List<String> dummyFolders = ["Important", "Prelims", "Events"];

  final FolderStorage folderStorage = FolderStorage();
  final TextEditingController _folderNameController = TextEditingController();
  List<String> _folders = [];
  Map<String, int> _folderItemCounts =
      {}; // To store the number of items in each folder

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  // Load all folder names and their respective item counts
  Future<void> _loadFolders() async {
    await folderStorage.init(); // Initialize shared preferences
    List<String> folders = folderStorage.getAllFolders();
    Map<String, int> folderItemCounts = {};

    for (String folderName in folders) {
      List<MapEntry<String, String>> items =
          folderStorage.getStringsFromFolder(folderName);
      folderItemCounts[folderName] =
          items.length; // Store the number of items in each folder
    }

    setState(() {
      _folders = folders;
      _folderItemCounts = folderItemCounts;
    });
  }

  // Create a new folder
  Future<void> _createFolder() async {
    String folderName = _folderNameController.text.trim();
    if (folderName.isNotEmpty) {
      await folderStorage.createFolder(folderName);
      _folderNameController.clear();
      _loadFolders(); // Reload the folders after creating a new one
    }
  }

  // Delete a folder
  Future<void> _deleteFolder(String folderName) async {
    await folderStorage.deleteFolder(folderName);
    _loadFolders(); // Reload the folders after deletion
  }

  // Navigate to another screen to display folder contents
  void _viewFolderContents(String folderName) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => FolderContentsScreen(folderName: folderName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    folderStorage.init();
    _loadFolders();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Saved posts",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              "New folder",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: TextField(
              controller: _folderNameController,
              decoration: InputDecoration(
                labelText: "Enter folder name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _folderNameController.text = "";
                  });
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  _createFolder();
                  Navigator.pop(context);
                  setState(() {
                    _folderNameController.text = "";
                  });
                },
                child: const Text(
                  'Create',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
        child: Icon(Icons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            children: [
              Expanded(
                child: _folders.isEmpty
                    ? Center(child: Text('No folders found'))
                    : ListView.separated(
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                        ),
                        itemCount: _folders.length,
                        itemBuilder: (context, index) {
                          String folderName = _folders[index];
                          int itemCount = _folderItemCounts[folderName] ??
                              0; // Get the number of items in the folder
                          return ListTile(
                            title: Text(
                              folderName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                                '$itemCount item(s)'), // Show the item count as subtitle
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteFolder(folderName),
                            ),
                            onTap: () => _viewFolderContents(folderName),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
