import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sst_announcer/bottomnavigation.dart';
import 'package:sst_announcer/categories/storageinterface.dart';
import 'package:sst_announcer/services/poststream.dart';
import 'package:sst_announcer/search.dart';
import 'package:sst_announcer/settings.dart';
import 'package:sst_announcer/categories/categorieslistpage.dart';
import 'package:sst_announcer/themes.dart';
import 'categories/categoriespage.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

final postStreamController = StreamController<PostStream>.broadcast();
const feedUrl = 'http://studentsblog.sst.edu.sg/feeds/posts/default?';

Future<bool> checkForNewBlogspotPosts(
    String rssFeedUrl, DateTime lastCheckTime) async {
  final response = await http.get(Uri.parse(rssFeedUrl));
  if (response.statusCode == 200) {
    final document = xml.XmlDocument.parse(response.body);
    final latestPostPubDate =
        document.getElement("feed")!.getElement("updated")!.text;
    final latestPostPubDateTime = DateTime.parse(latestPostPubDate);

    // Check if the latest post is newer than the last check time
    return latestPostPubDateTime.isAfter(lastCheckTime);
  } else {
    throw Exception('Failed to load latest posts');
  }
}

Future<List<Map<String, String>>> fetchLatestBlogspotPosts(
    String rssFeedUrl) async {
  final response = await http.get(Uri.parse(rssFeedUrl));

  if (response.statusCode == 200) {
    final document = xml.XmlDocument.parse(response.body);
    final items = document
        .findAllElements('channel')
        .single
        .findAllElements('item')
        .map((item) {
      final title = item.getElement('title')!.text;
      final link = item.getElement('link')!.text;
      final pubDate = item.getElement('pubDate')!.text;

      return {
        'title': title,
        'link': link,
        'pubDate': pubDate,
      };
    }).toList();

    return items;
  } else {
    throw Exception('Failed to load latest posts');
  }
}

const seedcolor = Colors.red;

void main() async {
  runApp(const MyApp());
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SST Announcer',
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const HomePage(title: 'All announcements')
          .animate()
          .shimmer(delay: 10.ms, duration: 450.ms),
      debugShowCheckedModeBanner: false,
    );
  }
}

List<String> customCats = [];

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final addCatController = TextEditingController();
  bool addCustomCat = false;

  @override
  void initState() {
    super.initState();
    getCategoryList().then((categoryList) {
      setState(() {
        customCats = categoryList;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkThemeEnabled(BuildContext context) {
      return Theme.of(context).brightness == Brightness.dark;
    }

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
        title: Text(
          widget.title,
          style: const TextStyle(
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
      body: Ink(
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                height: 10,
              ),
              Expanded(
                child: NavigationExample(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
