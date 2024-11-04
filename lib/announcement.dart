import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:photo_view/photo_view.dart';
import 'package:sst_announcer/folders/storagecontroller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AnnouncementPage extends StatefulWidget {
  final String renderMode;
  final String title;
  final String bodyText;
  final String author;
  final String parent;
  const AnnouncementPage(
      {super.key,
      required this.parent,
      required this.renderMode,
      required this.title,
      required this.bodyText,
      required this.author});
  @override
  State<AnnouncementPage> createState() => _AnnouncementPageState();
}

String selectedCat = "";

class _AnnouncementPageState extends State<AnnouncementPage> {
  var originalString = "";
  final TextEditingController _folderNameController = TextEditingController();

  void choiceDropdownCallback(String? selectedValue) {
    if (selectedValue != null) {
      selectedCat = selectedValue;
    }
  }

  final FolderStorage folderStorage = FolderStorage();
  List<String> _folders = [];
  Map<String, int> _folderItemCounts = {};

  Future<void> _loadFolders() async {
    await folderStorage.init(); // Initialize shared preferences
    List<String> folders = folderStorage.getAllFolders();
    Map<String, int> folderItemCounts = {};

    for (String folderName in folders) {
      List<MapEntry<String, String>> items =
          folderStorage.getStringsFromFolder(folderName);
      folderItemCounts[folderName] =
          items.length; // Store the number of items in each folder
    }

    setState(() {
      _folders = folders;
      _folderItemCounts = folderItemCounts;
    });
  }

  Future<void> _addKeyValue(String key, String value, String folderName) async {
    if (key.isNotEmpty && value.isNotEmpty) {
      await folderStorage.addStringToFolder(folderName, key, value);
      _loadFolders();
    }
  }

  // Create a new folder
  Future<void> _createFolder() async {
    String folderName = _folderNameController.text.trim();
    if (folderName.isNotEmpty) {
      await folderStorage.createFolder(folderName);
      _folderNameController.clear();
      _loadFolders(); // Reload the folders after creating a new one
    }
  }

  final bodyController = TextEditingController();
  bool categoried = false;
  DateTime? dueDate;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadFolders();
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Colors.white;

    bool isDarkMode =
        (MediaQuery.of(context).platformBrightness == Brightness.dark);
    if (isDarkMode) {
      backgroundColor = Colors.white;
    } else {
      backgroundColor = Colors.black;
    }

    originalString = widget.bodyText;

    var cleanedHtml = originalString.replaceAll(
        RegExp(r'\s*height="[^"]*"', caseSensitive: false), "");

    final parsedString = cleanedHtml.replaceAllMapped(
        RegExp(
            r'((?:font-size|color|background-color):\s*(?:rgba\([^)]*\)|[^;]*);?)',
            multiLine: true,
            caseSensitive: false), (match) {
      return '"${match.group(0)}"';
    });

    WebViewController htmlViewController = WebViewController()
      ..loadHtmlString(originalString)
      ..enableZoom(true);

    _loadFolders();

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Container(
                    height: MediaQuery.of(context).size.height * 0.8,
                    width: MediaQuery.of(context).size.width,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Add post to folder",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          _folders.length > 0
                              ? Expanded(
                                  child: ListView.builder(
                                    itemCount: _folders.length,
                                    itemBuilder: (context, index) {
                                      String folderName = _folders[index];
                                      int itemCount = _folderItemCounts[
                                              folderName] ??
                                          0; // Get the number of items in the folder
                                      return ListTile(
                                        title: Text(
                                          folderName,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                            '$itemCount item(s)'), // Show the item count as subtitle
                                        onTap: () {
                                          _addKeyValue(
                                              widget.title,
                                              "${widget.bodyText}|${widget.author}",
                                              folderName);
                                          setState(() {});
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: Text(
                                                    "Post added to folder $folderName"),
                                                actions: [
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      Navigator.pop(context);
                                                    },
                                                    child: Text("OK"),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                )
                              : Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "No folders created",
                                        style: TextStyle(fontSize: 18),
                                      ),
                                      SizedBox(
                                        height: 5,
                                      ),
                                      ElevatedButton(
                                        onPressed: () => showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(
                                              "New folder",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            content: TextField(
                                              controller: _folderNameController,
                                              decoration: InputDecoration(
                                                labelText: "Enter folder name",
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20.0),
                                                ),
                                              ),
                                            ),
                                            actions: [
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  setState(() {
                                                    _folderNameController.text =
                                                        "";
                                                  });
                                                },
                                                child: const Text(
                                                  'Cancel',
                                                  style:
                                                      TextStyle(fontSize: 16),
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  _createFolder();
                                                  Navigator.pop(context);
                                                  setState(() {
                                                    _folderNameController.text =
                                                        "";
                                                  });
                                                },
                                                child: const Text(
                                                  'Create',
                                                  style:
                                                      TextStyle(fontSize: 16),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        child: Text(
                                          "Create folder",
                                          style: TextStyle(
                                            fontSize: 16,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                        ],
                      ),
                    ),
                  );
                },
                isScrollControlled: true,
              );
            },
            icon: Icon(Icons.folder_copy),
            iconSize: 30,
          ),
          SizedBox(
            width: 15,
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.5),
          child: Ink(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                      color: backgroundColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 5,
                ),
                Text(
                  widget.parent == "folderview"
                      ? originalString.split("|").last
                      : widget.author,
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(
                  height: 15,
                ),
                Divider(
                  height: 1,
                ),
                SizedBox(
                  height: 10,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: widget.renderMode == "Parsed HTML"
                        ? Html(
                            data: parsedString,
                            style: {
                              "body": Style(
                                  fontSize: FontSize.large,
                                  color: backgroundColor,
                                  textDecorationColor: backgroundColor),
                              "content": Style(
                                  fontSize: FontSize.large,
                                  color: backgroundColor,
                                  textDecorationColor: backgroundColor),
                              "div": Style(
                                  fontSize: FontSize.large,
                                  color: backgroundColor,
                                  textDecorationColor: backgroundColor),
                              "span": Style(
                                  fontSize: FontSize.large,
                                  color: backgroundColor,
                                  textDecorationColor: backgroundColor),
                              "p": Style(
                                  fontSize: FontSize.large,
                                  color: backgroundColor,
                                  textDecorationColor: backgroundColor),
                              "a": Style(
                                  textDecoration: TextDecoration.none,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold),
                              "img": Style(
                                width: Width(
                                  MediaQuery.of(context).size.width - 20,
                                ),
                              ),
                            },
                            onLinkTap: (link, _, ___) {
                              launchUrl(Uri.parse(link!),
                                  mode: LaunchMode.externalApplication);
                            },
                            // extensions: [
                            //   OnImageTapExtension(
                            //       onImageTap: (src, imgAttributes, element) {
                            //     Navigator.of(context).push(
                            //       CupertinoPageRoute(builder: (context) {
                            //         return Scaffold(
                            //           body: SafeArea(
                            //             child: Center(
                            //               child: PhotoView(
                            //                 imageProvider:
                            //                     Image.network(src!).image,
                            //               ),
                            //             ),
                            //           ),
                            //         );
                            //       }),
                            //     );
                            //   })
                            // ],
                          )
                        : (widget.renderMode == "Web View"
                            ? SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.6,
                                child: WebViewWidget(
                                    controller: htmlViewController),
                              )
                            : SelectableText(originalString)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
