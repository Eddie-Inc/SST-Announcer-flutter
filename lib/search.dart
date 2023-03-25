import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

class BlogPage extends StatefulWidget {
  @override
  _BlogPageState createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  final url = 'http://studentsblog.sst.edu.sg/feeds/posts/default';
  List<xml.XmlElement> _posts = [];
  List<String?> _categories = [];
  String? _selectedCategory;
  String? _searchTerm;

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
        title: Text('Blog'),
      ),
      body: Column(
        children: [
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Category'),
              value: _selectedCategory,
              items: _categories
                  .map(
                    (category) => DropdownMenuItem<String>(
                      value: category!,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextFormField(
              decoration: InputDecoration(labelText: 'Search'),
              onChanged: (value) => setState(() => _searchTerm = value),
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: filteredPosts.length,
              itemBuilder: (context, index) {
                final post = filteredPosts[index];
                final title = post.findElements('title').first.text;
                final content =
                    parseFragment(post.findElements('content').first.text).text;
                return ListTile(
                  title: Text(title),
                  subtitle: Text(
                    content!,
                    maxLines: 3,
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
