import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletons/skeletons.dart';
import 'package:sst_announcer/announcement.dart';
import 'package:sst_announcer/categories/categorieslistpage.dart';
import 'package:sst_announcer/categories/categoriespage.dart';
import 'package:sst_announcer/categories/storageinterface.dart';
import 'package:sst_announcer/main.dart';
import 'package:sst_announcer/search.dart';
import 'package:sst_announcer/settings.dart';
import 'package:sst_announcer/themes.dart';
import 'package:xml/xml.dart' as xml;

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<String>? pinnedTitles = [];
  List<String>? pinnedContent = [];
  List<String>? pinnedAuthors = [];

  getSavedValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Return String
    pinnedTitles = prefs.getStringList("titles") ?? ["", "", ""];
    pinnedContent = prefs.getStringList("content") ?? ["", "", ""];
    pinnedAuthors = prefs.getStringList("authors") ?? ["", "", ""];
  }

  int _numPosts = 10;
  List<xml.XmlElement> _posts = [];
  bool _isLoading = true;

  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    getCategoryList().then((categoryList) {
      setState(() {
        customCats = categoryList;
      });
    });
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    String url = 'http://studentsblog.sst.edu.sg/feeds/posts/default';
    final file = await DefaultCacheManager().getSingleFile(url);

    if (await file.exists()) {
      final document = xml.XmlDocument.parse(await file.readAsString());
      final posts = document.findAllElements('entry').toList();
      setState(() {
        _isLoading = false;
        print("loading finished");
        _posts = posts;
      });
    } else {
      final response = await http.get(Uri.parse(url));
      final body = response.body;
      final document = xml.XmlDocument.parse(body);
      final posts = document.findAllElements('entry').toList();
      setState(() {
        _isLoading = false;
        print("loading finished");
        _posts = posts;
      });
      await DefaultCacheManager()
          .putFile(url, Uint8List.fromList(utf8.encode(body)));
    }
  }

  Future<void> _refresh() async {
    final response = await http.get(Uri.parse(
        'http://studentsblog.sst.edu.sg/feeds/posts/default?max-results=$_numPosts'));
    final body = response.body;
    final document = xml.XmlDocument.parse(body);
    final posts = document.findAllElements('entry').toList();
    setState(() {
      _posts = posts;
    });
  }

  final addCatController = TextEditingController();
  bool addCustomCat = false;

  @override
  Widget build(BuildContext context) {
    getSavedValues();

    bool isDarkThemeEnabled(BuildContext context) {
      return Theme.of(context).brightness == Brightness.dark;
    }

    _controller.addListener(() {
      if (_controller.position.atEdge) {
        bool isTop = _controller.position.pixels == 0;
        if (isTop) {
          debugPrint('At the top');
        } else {
          setState(() {
            _numPosts += 10;
            _refresh();
          });
        }
      }
    });

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Ink(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Center(
                    child: const Text(
                      "SST Announcer",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ).animate().fade(duration: 225.ms).scale(),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  ExpansionTile(
                    clipBehavior: Clip.none,
                    title: const Text(
                      "Categories",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ).animate().fade(duration: 225.ms).scale(),
                    children: const [
                      SizedBox(
                        height: 10,
                      ),
                      CategoryListPage(),
                    ],
                  ),
                  Divider(
                    thickness: 0.5,
                    color: isDarkThemeEnabled(context)
                        ? Colors.white
                        : Colors.black,
                  ),
                  ExpansionTile(
                    clipBehavior: Clip.hardEdge,
                    title: const Text(
                      "Tags",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ).animate().fade(duration: 225.ms).scale(),
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            separatorBuilder: (context, index) =>
                                const Divider(),
                            itemCount: customCats.length,
                            shrinkWrap: true,
                            itemBuilder: (BuildContext context, int index) {
                              return customCats.isNotEmpty
                                  ? InkWell(
                                      onTap: () {
                                        var navigator = Navigator.of(context);
                                        navigator.push(CupertinoPageRoute(
                                          builder: (context) {
                                            return CategoryPage(
                                              category: customCats[index],
                                              isCustom: true,
                                            );
                                          },
                                        ));
                                      },
                                      child: ListTile(
                                        title: Text(customCats[index]),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete),
                                          iconSize: 22,
                                          color: isDarkThemeEnabled(context)
                                              ? Colors.white
                                              : Colors.black,
                                          tooltip: "Delete category",
                                          onPressed: () async {
                                            removeCategory(index);
                                            setState(() {
                                              customCats.removeAt(index);
                                            });
                                          },
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink();
                            },
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      addCustomCat == true
                          ? Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(8)),
                                border: Border.all(
                                    width: 0.5, color: Colors.blueGrey),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: addCatController,
                                    decoration: const InputDecoration(
                                      hintText: "Input category title",
                                      hintStyle: TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          if (addCatController.text == "") {
                                            setState(() {
                                              addCustomCat = false;
                                            });
                                            return;
                                          }
                                          setState(() {
                                            customCats
                                                .add(addCatController.text);
                                            addCategory(addCatController.text);
                                            addCatController.text = "";
                                            addCustomCat = false;
                                          });
                                        },
                                        child: const Text("Add category"),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            )
                          : ElevatedButton(
                              style: darkFilledButtonStyle,
                              onPressed: () {
                                setState(() {
                                  addCustomCat = true;
                                });
                              },
                              child: const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text("Add custom category"),
                                  ],
                                ),
                              ),
                            ),
                      const SizedBox(
                        height: 10,
                      )
                    ],
                  ),
                  const Divider(
                    thickness: 0.5,
                  ),
                  TextButton(
                    onPressed: () {
                      var navigator = Navigator.of(context);
                      navigator.push(
                        CupertinoPageRoute(
                          builder: (context) {
                            return const SettingsScreen();
                          },
                        ),
                      );
                    },
                    child: const Text(
                      "Settings",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text(
          "All Announcements",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              var navigator = Navigator.of(context);
              navigator.push(
                CupertinoPageRoute(
                  builder: (context) {
                    return const BlogPage();
                  },
                ),
              );
            },
            icon: const Icon(Icons.search),
          )
        ],
      ),
      body: Container(
        child: _isLoading
            ? SkeletonListView()
            : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.separated(
                  separatorBuilder: (separatorContext, index) =>
                      const Divider(),
                  controller: _controller,
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    if (index < pinnedTitles!.length) {
                      return Dismissible(
                        background: Container(
                          color: Colors.red,
                          child: const Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Icon(Icons.push_pin),
                            ),
                          ),
                        ),
                        key: UniqueKey(),
                        direction: DismissDirection.startToEnd,
                        onDismissed: (direction) async {
                          final SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          await getSavedValues();
                          pinnedTitles?.removeAt(index);
                          pinnedContent?.removeAt(index);
                          pinnedAuthors?.removeAt(index);
                          await prefs.setStringList('titles', pinnedTitles!);
                          await prefs.setStringList('content', pinnedContent!);
                          await prefs.setStringList("authors", pinnedAuthors!);
                          _refresh();
                        },
                        child: pinnedTitles![index] != ""
                            ? Padding(
                                padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                                child: ListTile(
                                  onTap: () {
                                    final navigator = Navigator.of(context);
                                    navigator.push(
                                      CupertinoPageRoute(
                                        builder: (context) {
                                          return AnnouncementPage(
                                            author: pinnedAuthors![index],
                                            title: pinnedTitles![index],
                                            bodyText: pinnedContent![index],
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Pinned",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        pinnedTitles![index],
                                        maxLines: 3,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20),
                                      ),
                                      Text(
                                        pinnedAuthors![index],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w300),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    children: [
                                      Text(
                                        parseFragment(pinnedContent![index])
                                            .text!,
                                        maxLines: 3,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      index == (pinnedTitles!.length - 1)
                                          ? const Divider(
                                              thickness: 3,
                                            )
                                          : Container(),
                                    ],
                                  ),
                                  trailing: const Icon(
                                    Icons.push_pin,
                                    color: Colors.red,
                                  ),
                                ),
                              )
                            : const SizedBox(
                                height: 10,
                              ),
                      );
                    } else {
                      final post = _posts[index - pinnedTitles!.length];
                      final title = post.findElements('title').first.text;
                      final content = post.findElements('content').first.text;
                      final author = post
                          .findElements('author')
                          .first
                          .findElements("name")
                          .first
                          .text;
                      return Dismissible(
                        direction: DismissDirection.startToEnd,
                        confirmDismiss: (direction) async {
                          final SharedPreferences prefs =
                              await SharedPreferences.getInstance();

                          await getSavedValues();

                          pinnedTitles!.insert(0, title);
                          if (pinnedTitles!.length > 3) {
                            pinnedTitles!.removeLast();
                          }

                          // saving pinned content values
                          pinnedContent!.insert(0, content);
                          if (pinnedContent!.length > 3) {
                            pinnedContent!.removeLast();
                          }

                          pinnedAuthors!.insert(0, author);
                          if (pinnedAuthors!.length > 3) {
                            pinnedAuthors!.removeLast();
                          }

                          await prefs.setStringList('titles', pinnedTitles!);
                          await prefs.setStringList('content', pinnedContent!);
                          await prefs.setStringList("authors", pinnedAuthors!);
                          _refresh();
                          return null;
                        },
                        background: Container(
                          color: Colors.green,
                          child: const Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Icon(Icons.push_pin),
                            ),
                          ),
                        ),
                        key: Key(title),
                        child: ListTile(
                          onTap: () {
                            var navigator = Navigator.of(context);
                            navigator.push(
                              CupertinoPageRoute(
                                builder: (context) {
                                  return AnnouncementPage(
                                    author: author,
                                    title: title,
                                    bodyText: content,
                                  );
                                },
                              ),
                            );
                          },
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              Text(
                                author,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w300),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            children: [
                              Text(
                                parseFragment(content).text!,
                                maxLines: 3,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(
                                height: 15,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
      ),
    );
  }
}
