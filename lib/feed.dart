import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sst_announcer/announcement.dart';
import 'package:xml/xml.dart' as xml;

class BlogPage extends StatefulWidget {
  const BlogPage({super.key});

  @override
  _BlogPageState createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  int _numPosts = 20;

  bool _isLoading = true;
  bool loadingMorePosts = false;

  bool searchTileOpen = false;

  List<xml.XmlElement> _posts = [];
  List<String?> _categories = [];
  String? _selectedCategory;
  String? _searchTerm;

  String? renderMode;

  final _scrollController = ScrollController();

  TextEditingController categoryController = TextEditingController();

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
    final categories = posts
        .map((post) => post
            .findElements('category')
            .map((category) => category.getAttribute('term'))
            .toList())
        .expand((categoryList) => categoryList)
        .toSet()
        .toList();
    setState(() {
      _posts = posts;
      _categories = categories;
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
  void initState() {
    super.initState();
    _isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getPosts();
    });
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
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
          "All announcements",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              child: ExpansionTile(
                collapsedShape: RoundedRectangleBorder(
                  side: BorderSide.none,
                ),
                onExpansionChanged: (isOpen) {
                  if (isOpen) {
                    searchTileOpen = true;
                  } else {
                    searchTileOpen = false;
                  }
                  setState(() {});
                },
                shape: RoundedRectangleBorder(),
                tilePadding: EdgeInsets.symmetric(horizontal: 7.5),
                title: TextField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Search',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0)),
                  ),
                  onChanged: (value) => setState(() => _searchTerm = value),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Category",
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Expanded(
                          child: DropdownMenu(
                            controller: categoryController,
                            menuHeight: MediaQuery.of(context).size.height / 2,
                            inputDecorationTheme: InputDecorationTheme(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            initialSelection: _selectedCategory,
                            dropdownMenuEntries: _categories
                                .map(
                                  (category) => DropdownMenuEntry(
                                    value: category!,
                                    label: category.capitalize(),
                                  ),
                                )
                                .toList(),
                            onSelected: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            categoryController.text = "";
                            _selectedCategory = null;
                          });
                        },
                        child: Text(
                          "Reset filters",
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: !_isLoading
                    ? RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.separated(
                          controller: _scrollController,
                          separatorBuilder: (separatorContext, index) =>
                              SizedBox(
                            height: 5,
                          ),
                          itemCount: filteredPosts.length,
                          itemBuilder: (context, index) {
                            final post = filteredPosts[index];
                            final title = post.findElements('title').first.text;
                            final content =
                                post.findElements('content').first.text;
                            final author = post
                                .findElements("author")
                                .first
                                .findElements("name")
                                .first
                                .text;
                            final publishedDate = post
                                .findElements("published")
                                .first
                                .text
                                .split("T")
                                .first;
                            final postcategory =
                                post.findAllElements("category").isNotEmpty
                                    ? post.findAllElements("category").first
                                    : null;
                            final categoryelement = postcategory == null
                                ? ""
                                : postcategory.getAttribute("term");

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                    color: Theme.of(context).primaryColorLight),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: ListTile(
                                  onTap: () {
                                    var navigator = Navigator.of(context);
                                    navigator.push(
                                      CupertinoPageRoute(
                                        builder: (context) {
                                          return AnnouncementPage(
                                            parent: "",
                                            renderMode: renderMode!,
                                            author: author,
                                            title: title,
                                            bodyText: content,
                                          );
                                        },
                                      ),
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
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.schedule,
                                            size: 15,
                                          ),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Text(
                                            publishedDate,
                                            style: TextStyle(fontSize: 15),
                                          ),
                                          Spacer(),
                                          postcategory != null
                                              ? Text(
                                                  "Category: ${categoryelement.toString().capitalize()}")
                                              : SizedBox(),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ))
                    : Skeletonizer(
                        child: ListView.separated(
                          separatorBuilder: (separatorContext, index) =>
                              SizedBox(
                            height: 5,
                          ),
                          itemCount: 6,
                          itemBuilder: (context, index) {
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                    color: Theme.of(context).primaryColorLight),
                              ),
                              child: const Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ListTile(
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Lorem Ipsum is simply dummy text of the printing and typesetting industry.",
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
                                        "Lorem Ipsum is simply dummy text of the printing and typesetting industry.",
                                        maxLines: 3,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ),
          ),
          loadingMorePosts
              ? Column(
                  children: [
                    SizedBox(
                      height: 15,
                    ),
                    Text(
                      "Loading more posts...",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                  ],
                )
              : Container(),
        ],
      ),
    );
  }
}

extension StringExtensions on String {
  String capitalize() {
    if (this.isNotEmpty) {
      return "${this[0].toUpperCase()}${this.substring(1)}";
    } else {
      return "";
    }
  }
}
