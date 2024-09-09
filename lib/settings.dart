import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart' as xml;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

Future<int> getCacheSize() async {
  Directory tempDir = await getTemporaryDirectory();
  int tempDirSize = _getSize(tempDir);
  return tempDirSize;
}

int _getSize(FileSystemEntity file) {
  if (file is File) {
    return file.lengthSync();
  } else if (file is Directory) {
    int sum = 0;
    List<FileSystemEntity> children = file.listSync();
    for (FileSystemEntity child in children) {
      sum += _getSize(child);
    }
    return sum;
  }
  return 0;
}

class _SettingsScreenState extends State<SettingsScreen> {
  int cacheSize = 0;
  List<xml.XmlElement> posts = [];
  File? file;

  List<String?> RenderingModes = ["Parsed HTML", "Web View", "Raw Text"];
  String? selectedRenderMode = "Parsed HTML";

  @override
  void initState() {
    super.initState();
    getCache();
    getSettings();
  }

  void getSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    selectedRenderMode = prefs.getString("renderMode") ?? "Parsed HTML";
  }

  void saveSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("renderMode", selectedRenderMode ?? "Parsed HTML");
    print(prefs.getString("renderMode"));
  }

  void getCache() async {
    file = await DefaultCacheManager().getSingleFile(
        'http://studentsblog.sst.edu.sg/feeds/posts/default?max-results=100');
    final document = xml.XmlDocument.parse(await file!.readAsString());
    setState(() {
      posts = document.findAllElements('entry').toList();
      cacheSize = _getSize(file!);
      print(cacheSize);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Expanded(
          child: Padding(
            padding: EdgeInsets.all(15),
            child: ListView(
              children: [
                Text(
                  "Cache size: $cacheSize bytes",
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(
                  height: 15,
                ),
                Divider(
                  height: 1,
                ),
                SizedBox(
                  height: 15,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Render mode",
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                    Spacer(),
                    DropdownMenu(
                      dropdownMenuEntries: RenderingModes.map(
                        (mode) => DropdownMenuEntry(value: mode, label: mode!),
                      ).toList(),
                      inputDecorationTheme: InputDecorationTheme(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      initialSelection: selectedRenderMode,
                      onSelected: (value) {
                        setState(() {
                          selectedRenderMode = value!;
                          saveSettings();
                        });
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
