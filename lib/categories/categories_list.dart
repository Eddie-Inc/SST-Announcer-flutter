import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sst_announcer/categories/categoriespage.dart';
import 'package:xml/xml.dart' as xml;
import 'package:intl/intl.dart';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({super.key});

  @override
  _CategoryListPageState createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  List<String> categories = [];
  @override
  void initState() {
    fetchCategories();
    super.initState();
  }

  void fetchCategories() async {
    final response = await http.get(
      Uri.parse('http://studentsblog.sst.edu.sg/feeds/posts/default'),
    );
    final document = xml.XmlDocument.parse(response.body);

    final entries = document.findAllElements('entry');
    final List<String> allCategories = [];
    for (var entry in entries) {
      final categories = entry.findAllElements('category');
      for (var category in categories) {
        final categoryName = category.getAttribute('term');
        allCategories.add(categoryName!);
      }
    }

    final uniqueCategories = Set<String>.from(allCategories).toList();
    uniqueCategories.sort();
    setState(() {
      categories = uniqueCategories;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (context, index) => const Divider(),
          itemCount: categories.length,
          shrinkWrap: true,
          itemBuilder: (BuildContext context, int index) {
            return InkWell(
              onTap: () {
                var navigator = Navigator.of(context);
                navigator.push(CupertinoPageRoute(
                  builder: (context) {
                    return CategoryPage(
                      category: categories[index],
                      isCustom: false,
                    );
                  },
                ));
              },
              child: ListTile(
                title: Text(toBeginningOfSentenceCase(categories[index])!),
              ),
            );
          },
        ),
        const SizedBox(
          height: 10,
        ),
      ],
    );
  }
}
