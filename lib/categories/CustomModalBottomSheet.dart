import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sst_announcer/main.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../services/poststream.dart';

class AddPostBotttomSheet extends StatefulWidget {
  final String customCategoryName;
  final Map<String, List<xml.XmlElement>> customCatPosts;
  const AddPostBotttomSheet(
      {super.key,
      required this.customCategoryName,
      required this.customCatPosts});

  @override
  State<AddPostBotttomSheet> createState() => _AddPostBotttomSheetState();
}

class _AddPostBotttomSheetState extends State<AddPostBotttomSheet> {
  bool _isLoading = true;
  bool isLoading = false;
  List<xml.XmlElement> _posts = [];
  Future<void> _fetchPosts() async {
    final response = await http.get(
      Uri.parse('http://studentsblog.sst.edu.sg/feeds/posts/default?'),
    );
    final body = response.body;
    final document = xml.XmlDocument.parse(body);
    final posts = document.findAllElements('entry').toList();
    setState(() {
      _posts = posts;
      _isLoading = !_isLoading;
    });
  }

  Future<void> saveCustomCatPosts(
      String category, List<xml.XmlElement> customCatPosts) async {
    final prefs = await SharedPreferences.getInstance();
    final customCatPostsXml =
        customCatPosts.map((e) => e.toXmlString()).toList();

    await prefs.setStringList(category, customCatPostsXml);
  }

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  @override
  void dispose() {
    // Save the current state of custom category posts to persistent storage when the widget is removed from the widget tree
    saveCustomCatPosts(widget.customCategoryName,
        widget.customCatPosts[widget.customCategoryName]!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final controller = ScrollController();
    final navigator = Navigator.of(context);
    return Container(
      height: screenHeight * 0.75,
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
      child: Skeletonizer(
        ignoreContainers: true,
        enabled: _isLoading,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              height: screenHeight * 0.726,
              width: MediaQuery.of(context).size.width,
              child: ListView.separated(
                separatorBuilder: (separatorContext, index) => const Divider(
                  color: Colors.grey,
                  thickness: 0.4,
                  height: 1,
                ),
                controller: controller,
                itemCount: _posts.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  final title = post.findElements('title').first.text;
                  final content =
                      parseFragment(post.findElements('content').first.text)
                          .text;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(6, 15, 6, 10),
                    child: ListTile(
                      title: Text(title),
                      subtitle: Text(
                        content!,
                        maxLines: 3,
                      ),
                      trailing: IconButton(
                        onPressed: () {
                          setState(() {
                            isLoading = true;
                          });
                          widget.customCatPosts[widget.customCategoryName]
                              ?.add(post);
                          saveCustomCatPosts(
                              widget.customCategoryName,
                              widget
                                  .customCatPosts[widget.customCategoryName]!);
                          if (mounted) {
                            postStreamController.add(PostStream.refreshPosts);
                          }
                          navigator.pop();
                        },
                        iconSize: 21.5,
                        icon: isLoading == true
                            ? const CircularProgressIndicator()
                            : const Icon(
                                Icons.add,
                                color: Color.fromARGB(255, 99, 99, 99),
                              ),
                      ),
                    ),
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
