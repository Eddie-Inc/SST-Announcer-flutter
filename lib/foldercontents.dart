import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sst_announcer/announcement.dart';
import 'storagecontroller.dart'; // The FolderStorage class
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

class FolderContentsScreen extends StatefulWidget {
  final String folderName;

  FolderContentsScreen({required this.folderName});

  @override
  _FolderContentsScreenState createState() => _FolderContentsScreenState();
}

class _FolderContentsScreenState extends State<FolderContentsScreen> {
  final FolderStorage folderStorage = FolderStorage();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  List<MapEntry<String, String>> _folderContents = [];

  @override
  void initState() {
    super.initState();
    _loadFolderContents();
    _isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getPosts();
    });
  }

  // Load all key-value pairs from the folder
  Future<void> _loadFolderContents() async {
    await folderStorage.init(); // Initialize shared preferences
    List<MapEntry<String, String>> items =
        folderStorage.getStringsFromFolder(widget.folderName);
    setState(() {
      _folderContents = items;
    });
  }

  // Add a key-value pair to the folder
  Future<void> _addKeyValue(String key, String value) async {
    if (key.isNotEmpty && value.isNotEmpty) {
      await folderStorage.addStringToFolder(widget.folderName, key, value);
      _keyController.clear();
      _valueController.clear();
      _loadFolderContents(); // Refresh the contents after adding
    }
  }

  // Delete a specific key-value pair
  Future<void> _deleteKeyValue(String key) async {
    await folderStorage.deleteKeyFromFolder(widget.folderName, key);
    _loadFolderContents(); // Refresh the contents after deletion
  }

  final _scrollController = ScrollController();
  String? renderMode;
  int _numPosts = 100;

  bool _isLoading = true;
  bool loadingMorePosts = false;

  List<xml.XmlElement> _posts = [];
  String? _selectedCategory;
  String? _searchTerm;

  void getPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    renderMode = prefs.getString("renderMode") ?? "Parsed HTML";
  }

  void _getPosts() async {
    final url =
        'http://studentsblog.sst.edu.sg/feeds/posts/default?max-results=$_numPosts';

    setState(() {
      _isLoading = true;
    });
    final response = await http.get(Uri.parse(url));
    final feed = xml.XmlDocument.parse(response.body);
    final posts = feed.findAllElements('entry').toList();
    setState(() {
      _posts = posts;
      _isLoading = !_isLoading;
    });
  }

  Future<void> _refresh() async {
    final response = await http.get(Uri.parse(
        'http://studentsblog.sst.edu.sg/feeds/posts/default?max-results=$_numPosts'));
    final body = response.body;
    final document = xml.XmlDocument.parse(body);
    final posts = document.findAllElements('entry').toList();
    setState(() {
      _posts = posts;
      loadingMorePosts = false;
    });
  }

  List<xml.XmlElement> get filteredPosts {
    if (_selectedCategory == null && _searchTerm == null) {
      return _posts;
    }

    var filteredPosts = _posts;
    if (_selectedCategory != null) {
      filteredPosts = filteredPosts
          .where((post) => post.findElements('category').any(
                (category) =>
                    category.getAttribute('term') == _selectedCategory,
              ))
          .toList();
    }

    if (_searchTerm != null) {
      filteredPosts = filteredPosts
          .where((post) =>
              post
                  .findElements('title')
                  .first
                  .text
                  .toLowerCase()
                  .contains(_searchTerm!.toLowerCase()) ||
              post
                  .findElements('content')
                  .first
                  .text
                  .toLowerCase()
                  .contains(_searchTerm!.toLowerCase()))
          .toList();
    } else {
      filteredPosts = filteredPosts;
    }
    return filteredPosts;
  }

  @override
  Widget build(BuildContext context) {
    getPreferences();

    _scrollController.addListener(() {
      if (_scrollController.position.atEdge) {
        bool isTop = _scrollController.position.pixels == 0;
        if (isTop) {
        } else {
          setState(() {
            _numPosts += 20;
            loadingMorePosts = true;
            _refresh();
          });
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Posts in ${widget.folderName}',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                isScrollControlled: true,
                context: context,
                builder: (context) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          "Add posts",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        height: MediaQuery.of(context).size.height * 0.75,
                        child: RefreshIndicator(
                            onRefresh: _refresh,
                            child: ListView.separated(
                              controller: _scrollController,
                              separatorBuilder: (separatorContext, index) =>
                                  SizedBox(height: 5),
                              itemCount: filteredPosts.length,
                              itemBuilder: (context, index) {
                                final post = filteredPosts[index];
                                final title =
                                    post.findElements('title').first.text;
                                final content =
                                    post.findElements('content').first.text;
                                final author = post
                                    .findElements("author")
                                    .first
                                    .findElements("name")
                                    .first
                                    .text;
                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                        color: Theme.of(context)
                                            .primaryColorLight),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ListTile(
                                      onTap: () {
                                        _addKeyValue(title, "$content|$author");
                                        Navigator.of(context).pop();
                                        print(
                                          "$content|$author".split("|").last,
                                        );
                                      },
                                      title: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 20),
                                          ),
                                          SizedBox(
                                            height: 5,
                                          )
                                        ],
                                      ),
                                      subtitle: Column(
                                        children: [
                                          Text(
                                            parseFragment(content).text!,
                                            maxLines: 3,
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )),
                      ),
                    ],
                  );
                },
              );
            },
            icon: Icon(Icons.add),
            iconSize: 30,
          ),
          SizedBox(
            width: 20,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Text fields to enter key-value pairs
            // Display the folder contents in a ListView
            Expanded(
              child: _folderContents.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child:
                              Text('No contents found in ${widget.folderName}'),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          child: Text(
                            "Add posts",
                            style: TextStyle(fontSize: 18),
                          ),
                        )
                      ],
                    )
                  : ListView.builder(
                      itemCount: _folderContents.length,
                      itemBuilder: (context, index) {
                        MapEntry<String, String> entry = _folderContents[index];
                        return ListTile(
                          title: Text(entry.key,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 20)),
                          subtitle: Text(
                            parseFragment(entry.value).text!,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 3,
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteKeyValue(entry.key),
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(builder: (context) {
                                print(entry.value.split("|").last);
                                return AnnouncementPage(
                                    parent: "folderview",
                                    renderMode: "Parsed HTML",
                                    title: entry.key,
                                    bodyText: entry.value,
                                    author: "");
                              }),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
