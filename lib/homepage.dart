import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:sst_announcer/feed.dart";
import "package:sst_announcer/folders/folderpage.dart";
import "package:sst_announcer/settings.dart";

List<String> customCats = [];

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final addCatController = TextEditingController();
  bool addCustomCat = false;

  int currentPageIndex = 0;

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

  Future<void> removeCategory(int category) async {
    final prefs = await SharedPreferences.getInstance();
    final categoryList = await getCategoryList();
    categoryList.removeAt(category);
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
    bool isDarkThemeEnabled(BuildContext context) {
      return Theme.of(context).brightness == Brightness.dark;
    }

    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (index) {
          currentPageIndex = index;
          setState(() {});
        },
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
              icon: Icon(Icons.campaign), label: "Announcements"),
          NavigationDestination(icon: Icon(Icons.folder), label: "Saved posts"),
          NavigationDestination(icon: Icon(Icons.settings), label: "Settings")
        ],
      ),
      body: <Widget>[
        BlogPage(),
        const FolderPage(),
        const SettingsScreen(),
      ][currentPageIndex],
    );
  }
}
