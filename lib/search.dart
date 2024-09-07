import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:sst_announcer/announcement.dart';
import 'package:xml/xml.dart' as xml;
import 'package:intl/intl.dart';

class BlogPage extends StatefulWidget {
  const BlogPage({super.key});

  @override
  _BlogPageState createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  final url = 'http://studentsblog.sst.edu.sg/feeds/posts/default';
  List<xml.XmlElement> _posts = [];
  List<String?> _categories = [];
  String? _selectedCategory;
  String? _searchTerm;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getPosts();
  }

  void _getPosts() async {
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
    }
    return filteredPosts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Category'),
              value: _selectedCategory,
              items: _categories
                  .map(
                    (category) => DropdownMenuItem<String>(
                      value: category!,
                      child: Text(toBeginningOfSentenceCase(category)!),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextFormField(
              decoration: const InputDecoration(labelText: 'Search'),
              onChanged: (value) => setState(() => _searchTerm = value),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading == true
                ? Placeholder()
                : ListView.separated(
                    separatorBuilder: (separatorContext, index) =>
                        const Divider(
                      color: Colors.grey,
                      thickness: 0.4,
                      height: 1,
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
                      return Ink(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
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
                          title: Text(title),
                          subtitle: Text(
                            parseFragment(content).text!,
                            maxLines: 3,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
