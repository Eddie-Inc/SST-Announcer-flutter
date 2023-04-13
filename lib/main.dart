import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sst_announcer/poststream.dart';
import 'package:sst_announcer/search.dart';
import 'package:sst_announcer/settings.dart';
import 'package:sst_announcer/categories/categories_list.dart';
import 'package:sst_announcer/categories/user_categories.dart';

import 'categories/categoriespage.dart';

final postStreamController = StreamController<PostStream>.broadcast();

var seedcolor = Colors.red;

var lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: seedcolor));
var filledButtonStyle = ElevatedButton.styleFrom(
        backgroundColor: lightTheme.colorScheme.primary,
        foregroundColor: lightTheme.colorScheme.onPrimary,
        elevation: 3)
    .copyWith(elevation: MaterialStateProperty.resolveWith((states) {
  if (states.contains(MaterialState.hovered)) {
    return 1;
  }
  return 0;
}));

var darkTheme = ThemeData.dark(useMaterial3: true);
var darkFilledButtonStyle = ElevatedButton.styleFrom(
        backgroundColor: darkTheme.colorScheme.primary,
        foregroundColor: darkTheme.colorScheme.onPrimary)
    .copyWith(elevation: MaterialStateProperty.resolveWith((states) {
  if (states.contains(MaterialState.hovered)) {
    return 1;
  }
  return 0;
}));

void main() {
  runApp(const MyApp());
  WidgetsFlutterBinding.ensureInitialized();
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
      home: HomePage(title: 'All announcements'),
      debugShowCheckedModeBanner: false,
    );
  }
}

List<String> customCats = [];

class HomePage extends StatefulWidget {
  HomePage({super.key, required this.title});
  final String title;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final addCatController = TextEditingController();
  bool addCustomCat = false;

  Future<List<String>> getCategoryList() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('categoryList') ?? [];
  }

  Future<void> addCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final categoryList = await getCategoryList();
    if (!categoryList.contains(category)) {
      categoryList.add(category);
      await prefs.setStringList('categoryList', categoryList);
    }
  }

  Future<void> removeCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final categoryList = await getCategoryList();
    categoryList.remove(category);
    await prefs.setStringList('categoryList', categoryList);
  }

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
    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Ink(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const Center(
                    child: Text(
                      "SST Announcer",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
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
                    ),
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      CategoryListPage(),
                    ],
                  ),
                  const Divider(
                    thickness: 0.5,
                    color: Colors.black,
                  ),
                  ExpansionTile(
                    clipBehavior: Clip.hardEdge,
                    title: const Text(
                      "Tags",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
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
                                          tooltip: "Delete category",
                                          onPressed: () async {
                                            removeCategory(customCats[index]);
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
                              child: Center(
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
                  Divider(
                    thickness: 0.5,
                  ),
                  TextButton(
                    onPressed: () {
                      var navigator = Navigator.of(context);
                      navigator.push(
                        CupertinoPageRoute(
                          builder: (context) {
                            return SettingsScreen();
                          },
                        ),
                      );
                    },
                    child: Text(
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
                    return BlogPage();
                  },
                ),
              );
            },
            icon: const Icon(Icons.search),
          )
        ],
      ),
      body: Ink(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(
                height: 10,
              ),
              Expanded(
                child: FeedPage(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
