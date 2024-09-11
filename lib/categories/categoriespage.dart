import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:sst_announcer/announcement.dart';
import 'package:sst_announcer/homepage.dart';
import 'package:sst_announcer/main.dart';
import 'package:webfeed/webfeed.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../services/poststream.dart';
import 'CustomModalBottomSheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryPage extends StatefulWidget {
  final String category;
  final bool isCustom;

  const CategoryPage(
      {super.key, required this.category, required this.isCustom});

  @override
  _CategoryPageState createState() => _CategoryPageState();
}

Future<AtomFeed> fetchAtomFeed() async {
  final response = await http
      .get(Uri.parse('http://studentsblog.sst.edu.sg/feeds/posts/default'));
  return AtomFeed.parse(response.body);
}

class _CategoryPageState extends State<CategoryPage> {
  Map<String, List<xml.XmlElement>> customCatPosts = {
    for (var item in customCats) item: []
  };

  late Future<AtomFeed> _futureAtomFeed;
  void postStreamControllerListener(PostStream value) {
    switch (value) {
      case PostStream.refreshPosts:
        setState(() {});
        break;
      default:
    }
  }

  Future<List<xml.XmlElement>> getCustomCatPosts(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final customCatPostsXml = prefs.getStringList(category);

    if (customCatPostsXml == null) {
      return [];
    }

    final customCatPosts = customCatPostsXml
        .map((xmlString) => xml.XmlDocument.parse(xmlString).rootElement)
        .toList();

    return customCatPosts;
  }

  @override
  void initState() {
    postStreamController.stream.listen(postStreamControllerListener);
    super.initState();
    getCustomCatPosts(
      widget.category,
    ).then((customCatPosts) {
      // Update the customCatPosts map with the loaded data
      setState(() {
        this.customCatPosts[widget.category] = customCatPosts;
      });
    });

    _futureAtomFeed = fetchAtomFeed();
  }

  void showAddPostBottomSheet() {
    showModalBottomSheet(
        context: context,
        builder: (bottomSheetContext) => AddPostBotttomSheet(
              customCategoryName: widget.category,
              customCatPosts: customCatPosts,
            ),
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final navigator = Navigator.of(context);
            navigator.pop(context);
          },
        ),
      ),
      floatingActionButton: widget.isCustom == true
          ? FloatingActionButton.extended(
              onPressed: showAddPostBottomSheet,
              label: const Text("Add posts"),
              icon: const Icon(Icons.post_add),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: widget.isCustom == true
          ? SafeArea(
              child: Column(
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                      child: ListView.separated(
                        separatorBuilder: (separatorContext, index) =>
                            const Divider(
                          color: Colors.grey,
                          thickness: 0.4,
                          height: 1,
                        ),
                        shrinkWrap: true,
                        itemCount: customCatPosts[widget.category]?.length ?? 0,
                        itemBuilder: (context, index) {
                          final customCatPost =
                              customCatPosts[widget.category]![index];
                          final title =
                              customCatPost.findElements('title').first.text;
                          final content =
                              customCatPost.findElements('content').first.text;
                          final author = customCatPost
                              .findElements("author")
                              .first
                              .findElements("name")
                              .first
                              .text;
                          return ListTile(
                            onTap: () {
                              var navigator = Navigator.of(context);
                              // navigator.push(
                              //   CupertinoPageRoute(
                              //     builder: (context) {
                              //       return AnnouncementPage(
                              //         author: author,
                              //         title: title,
                              //         bodyText: content,
                              //       );
                              //     },
                              //   ),
                              // );
                            },
                            title: Text(title),
                            subtitle: Text(
                              parseFragment(content).text!,
                              maxLines: 2,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  Expanded(
                    child: FutureBuilder<AtomFeed>(
                      future: _futureAtomFeed,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final items = snapshot.data!.items!
                              .where((item) => item.categories!.any(
                                  (category) =>
                                      category.term == widget.category))
                              .toList();
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                            child: ListView.separated(
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return ListTile(
                                  onTap: () {
                                    var navigator = Navigator.of(context);
                                    // navigator.push(
                                    //   CupertinoPageRoute(
                                    //     builder: (context) {
                                    //       return AnnouncementPage(
                                    //         author: "",
                                    //         title: item.title!,
                                    //         bodyText: item.content!,
                                    //       );
                                    //     },
                                    //   ),
                                    // );
                                  },
                                  title: Text(item.title ?? ''),
                                  subtitle: Text(
                                    parseFragment(item.content).text!,
                                    maxLines: 2,
                                  ),
                                );
                              },
                              separatorBuilder: (separatorContext, index) =>
                                  const Divider(
                                color: Colors.grey,
                                thickness: 0.4,
                                height: 1,
                              ),
                              shrinkWrap: true,
                              itemCount: items.length,
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Text('${snapshot.error}');
                        } else {}
                        return const Center(
                          child: CircularProgressIndicator(),
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
