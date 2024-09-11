import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:sst_announcer/categories/categoriespage.dart";
import "package:sst_announcer/feed.dart";
import "package:sst_announcer/folderpage.dart";
import "package:sst_announcer/main.dart";
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
          print("Selected page: $currentPageIndex");
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
      // drawer: Drawer(
      //   child: SafeArea(
      //     child: Padding(
      //       padding: const EdgeInsets.all(10),
      //       child: Ink(
      //         child: ListView(
      //           padding: EdgeInsets.zero,
      //           children: [
      //             Center(
      //               child: const Text(
      //                 "SST Announcer",
      //                 style:
      //                     TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      //               ).animate().fade(duration: 225.ms).scale(),
      //             ),
      //             const SizedBox(
      //               height: 10,
      //             ),
      //             ExpansionTile(
      //               clipBehavior: Clip.hardEdge,
      //               title: const Text(
      //                 "Tags",
      //                 style:
      //                     TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      //               ).animate().fade(duration: 225.ms).scale(),
      //               children: [
      //                 Column(
      //                   mainAxisAlignment: MainAxisAlignment.start,
      //                   crossAxisAlignment: CrossAxisAlignment.start,
      //                   children: [
      //                     ListView.separated(
      //                       physics: const NeverScrollableScrollPhysics(),
      //                       separatorBuilder: (context, index) =>
      //                           const Divider(),
      //                       itemCount: customCats.length,
      //                       shrinkWrap: true,
      //                       itemBuilder: (BuildContext context, int index) {
      //                         return customCats.isNotEmpty
      //                             ? InkWell(
      //                                 onTap: () {
      //                                   var navigator = Navigator.of(context);
      //                                   navigator.push(CupertinoPageRoute(
      //                                     builder: (context) {
      //                                       return CategoryPage(
      //                                         category: customCats[index],
      //                                         isCustom: true,
      //                                       );
      //                                     },
      //                                   ));
      //                                 },
      //                                 child: ListTile(
      //                                   title: Text(customCats[index]),
      //                                   trailing: IconButton(
      //                                     icon: const Icon(Icons.delete),
      //                                     iconSize: 22,
      //                                     color: isDarkThemeEnabled(context)
      //                                         ? Colors.white
      //                                         : Colors.black,
      //                                     tooltip: "Delete category",
      //                                     onPressed: () async {
      //                                       removeCategory(index);
      //                                       setState(() {
      //                                         customCats.removeAt(index);
      //                                       });
      //                                     },
      //                                   ),
      //                                 ),
      //                               )
      //                             : const SizedBox.shrink();
      //                       },
      //                     ),
      //                     const SizedBox(
      //                       height: 10,
      //                     ),
      //                   ],
      //                 ),
      //                 const SizedBox(
      //                   height: 15,
      //                 ),
      //                 addCustomCat == true
      //                     ? Container(
      //                         padding: const EdgeInsets.all(8),
      //                         decoration: BoxDecoration(
      //                           shape: BoxShape.rectangle,
      //                           borderRadius:
      //                               const BorderRadius.all(Radius.circular(8)),
      //                           border: Border.all(
      //                               width: 0.5, color: Colors.blueGrey),
      //                         ),
      //                         child: Column(
      //                           mainAxisAlignment: MainAxisAlignment.start,
      //                           crossAxisAlignment: CrossAxisAlignment.start,
      //                           children: [
      //                             TextField(
      //                               controller: addCatController,
      //                               decoration: const InputDecoration(
      //                                 hintText: "Input category title",
      //                                 hintStyle: TextStyle(
      //                                     fontWeight: FontWeight.w400,
      //                                     fontSize: 13),
      //                               ),
      //                             ),
      //                             const SizedBox(
      //                               height: 5,
      //                             ),
      //                             Row(
      //                               mainAxisAlignment: MainAxisAlignment.end,
      //                               children: [
      //                                 TextButton(
      //                                   onPressed: () {
      //                                     if (addCatController.text == "") {
      //                                       setState(() {
      //                                         addCustomCat = false;
      //                                       });
      //                                       return;
      //                                     }
      //                                     setState(() {
      //                                       customCats
      //                                           .add(addCatController.text);
      //                                       addCategory(addCatController.text);
      //                                       addCatController.text = "";
      //                                       addCustomCat = false;
      //                                     });
      //                                   },
      //                                   child: const Text("Add category"),
      //                                 )
      //                               ],
      //                             )
      //                           ],
      //                         ),
      //                       )
      //                     : ElevatedButton(
      //                         style: darkFilledButtonStyle,
      //                         onPressed: () {
      //                           setState(() {
      //                             addCustomCat = true;
      //                           });
      //                         },
      //                         child: Center(
      //                           child: Row(
      //                             mainAxisAlignment: MainAxisAlignment.center,
      //                             children: [
      //                               Icon(Icons.add),
      //                               SizedBox(
      //                                 width: 10,
      //                               ),
      //                               Text("Add custom category"),
      //                             ],
      //                           ),
      //                         ),
      //                       ),
      //                 const SizedBox(
      //                   height: 10,
      //                 )
      //               ],
      //             ),
      //             const Divider(
      //               thickness: 0.5,
      //             ),
      //           ],
      //         ),
      //       ),
      //     ),
      //   ),
      // ),
      body: <Widget>[
        BlogPage(),
        const FolderPage(),
        const SettingsScreen(),
      ][currentPageIndex],
    );
  }
}
