import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sst_announcer/announcement.dart';
import 'package:xml/xml.dart' as xml;
import 'package:intl/intl.dart';

class BlogPage extends StatefulWidget {
  const BlogPage({super.key});

  @override
  _BlogPageState createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  bool _isLoading = true;

  final url = 'http://studentsblog.sst.edu.sg/feeds/posts/default';
  List<xml.XmlElement> _posts = [];
  List<String?> _categories = [];
  String? _selectedCategory;
  String? _searchTerm;

  TextEditingController categoryController = TextEditingController();

  void _getPosts() async {
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.symmetric(horizontal: 10),
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
                                  borderRadius: BorderRadius.circular(20))),
                          initialSelection: _selectedCategory,
                          dropdownMenuEntries: _categories
                              .map(
                                (category) => DropdownMenuEntry(
                                  value: category!,
                                  label: toBeginningOfSentenceCase(category)!,
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
          SizedBox(
            height: 10,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5),
              child: !_isLoading
                  ? ListView.separated(
                      separatorBuilder: (separatorContext, index) => SizedBox(
                        height: 5,
                      ),
                      itemCount: filteredPosts.length,
                      itemBuilder: (context, index) {
                        final post = filteredPosts[index];
                        final title = post.findElements('title').first.text;
                        final content = post.findElements('content').first.text;
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
                                color: Theme.of(context).primaryColorLight),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
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
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : Skeletonizer(
                      child: ListView.separated(
                        separatorBuilder: (separatorContext, index) => SizedBox(
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
        ],
      ),
    );
  }
}
