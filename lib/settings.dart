import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
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

  @override
  void initState() {
    super.initState();
    getCache();
  }

  void getCache() async {
    file = await DefaultCacheManager().getSingleFile(
        'http://studentsblog.sst.edu.sg/feeds/posts/default?max-results=100');
    final document = xml.XmlDocument.parse(await file!.readAsString());
    setState(() {
      posts = document.findAllElements('entry').toList();
      cacheSize = _getSize(file!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              "Cache size: $cacheSize bytes",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(
              height: 10,
            ),
            const Divider(
              height: 1,
            ),
            const SizedBox(
              height: 10,
            ),
            ExpansionTile(
              title: const Text("Show full cache string"),
              children: [
                SingleChildScrollView(
                  child: Text(posts.toString()),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
              onPressed: () async {
                DefaultCacheManager().emptyCache();
                print("emptied");
                print(cacheSize);
                initState();
              },
              child: const Text("Clear cache"),
            )
          ],
        ),
      ),
    );
  }
}
