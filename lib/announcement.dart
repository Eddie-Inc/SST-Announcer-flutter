import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sst_announcer/main.dart';
import 'package:sst_announcer/services/notificationservice.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AnnouncementPage extends StatefulWidget {
  final String title;
  final String bodyText;
  final String author;
  const AnnouncementPage(
      {super.key,
      required this.title,
      required this.bodyText,
      required this.author});
  @override
  State<AnnouncementPage> createState() => _AnnouncementPageState();
}

String selectedCat = "";

class _AnnouncementPageState extends State<AnnouncementPage> {
  final NotificationService service = NotificationService();
  void choiceDropdownCallback(String? selectedValue) {
    if (selectedValue != null) {
      selectedCat = selectedValue;
    }
  }

  final bodyController = TextEditingController();
  bool categoried = false;
  DateTime? dueDate;

  String? renderMode;

  void getPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    renderMode = prefs.getString("renderMode") ?? "Parsed HTML";
    print(renderMode);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  // Future<void> pickDate() async {
  //   final newDueDate = await DatePicker.showDateTimePicker(
  //     context,
  //     showTitleActions: true,
  //     onChanged: (date) => date,
  //     onConfirm: (date) {},
  //   );
  //   if (newDueDate != null) {
  //     setState(() {
  //       dueDate = newDueDate;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    getPreferences();

    final titleController = TextEditingController(text: widget.title);
    Color backgroundColor = Colors.white;

    bool isDarkMode =
        (MediaQuery.of(context).platformBrightness == Brightness.dark);
    if (isDarkMode) {
      backgroundColor = Colors.white;
    } else {
      backgroundColor = Colors.black;
    }

    DateTime? dueDate;
    final originalString = widget.bodyText;

    final parsedString = originalString.replaceAllMapped(
        RegExp(
            r'((?:font-size|color|background-color):\s*(?:rgba\([^)]*\)|[^;]*);?)',
            multiLine: true,
            caseSensitive: false), (match) {
      return '"${match.group(0)}"';
    });

    // final formattedDate =
    //     dueDate == null ? "" : DateFormat("dd/MM/yyyy").format(dueDate);

    WebViewController htmlViewController = WebViewController()
      ..loadHtmlString(originalString)
      ..enableZoom(true);

    return Scaffold(
      appBar: AppBar(
        actions: [
          // IconButton(
          //   onPressed: () {
          //     showDialog(
          //       context: context,
          //       builder: (BuildContext context) {
          //         return AlertDialog(
          //           title: const Text("Set reminder"),
          //           content: Column(
          //             mainAxisSize: MainAxisSize.min,
          //             crossAxisAlignment: CrossAxisAlignment.start,
          //             children: [
          //               TextField(
          //                 controller: titleController,
          //                 decoration: const InputDecoration(
          //                   hintText: "Notification title",
          //                 ),
          //               ),
          //               TextField(
          //                 controller: bodyController,
          //                 decoration: const InputDecoration(
          //                     hintText: "Notification description"),
          //               ),
          //               const SizedBox(
          //                 height: 10,
          //               ),
          //               dueDate == null
          //                   ? IconButton(
          //                       onPressed: () {},
          //                       iconSize: 26,
          //                       icon:
          //                           const Icon(Icons.event_available_outlined),
          //                     )
          //                   : ActionChip(
          //                       label: Text(formattedDate),
          //                       onPressed: () {},
          //                       backgroundColor: theme.brightness ==
          //                               Brightness.dark
          //                           ? Colors.grey[800]
          //                           : const Color.fromRGBO(246, 242, 249, 1),
          //                       elevation: 0,
          //                     )
          //             ],
          //           ),
          //           actions: [
          //             Center(
          //               child: Row(children: [
          //                 TextButton(
          //                   onPressed: () {
          //                     final navigator = Navigator.of(context);
          //                     navigator.pop();
          //                   },
          //                   child: const Text("Cancel"),
          //                 ),
          //                 const Spacer(),
          //                 ElevatedButton(
          //                   onPressed: () {
          //                     final navigator = Navigator.of(context);
          //                     navigator.pop();
          //                     if (titleController.text == "" ||
          //                         dueDate == null) {
          //                       return;
          //                     } else {
          //                       service.scheduleNotification(
          //                           title: titleController.text,
          //                           body: bodyController.text,
          //                           scheduledNotificationDateTime: dueDate);
          //                     }
          //                   },
          //                   style: filledButtonStyle,
          //                   child: const Text("Confirm"),
          //                 ),
          //               ]),
          //             )
          //           ],
          //           alignment: Alignment.center,
          //         );
          //       },
          //     );
          //   },
          //   icon: const Icon(Icons.calendar_month),
          // ),
        ],
        // title: Row(
        //   mainAxisAlignment: MainAxisAlignment.start,
        //   children: [
        //     Text("Announcement"),
        //   ],
        // ),
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
                  widget.author,
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
                    child: renderMode == "Parsed HTML"
                        ? Html(
                            data: parsedString,
                            style: {
                              "body": Style(
                                  fontFamily: DefaultTextStyle.of(context)
                                      .style
                                      .fontFamily,
                                  fontSize: FontSize.large,
                                  color: backgroundColor,
                                  textDecorationColor: backgroundColor),
                              "content": Style(
                                  fontFamily: DefaultTextStyle.of(context)
                                      .style
                                      .fontFamily,
                                  fontSize: FontSize.large,
                                  color: backgroundColor,
                                  textDecorationColor: backgroundColor),
                              "div": Style(
                                  fontFamily: DefaultTextStyle.of(context)
                                      .style
                                      .fontFamily,
                                  fontSize: FontSize.large,
                                  color: backgroundColor,
                                  textDecorationColor: backgroundColor),
                              /*"span": Style(
                            fontSize: FontSize.large,
                            color: backgroundColor,
                            textDecorationColor: backgroundColor),*/
                              "p": Style(
                                  fontFamily: DefaultTextStyle.of(context)
                                      .style
                                      .fontFamily,
                                  fontSize: FontSize.large,
                                  color: backgroundColor,
                                  textDecorationColor: backgroundColor),
                              "a": Style(
                                  textDecoration: TextDecoration.none,
                                  fontFamily: DefaultTextStyle.of(context)
                                      .style
                                      .fontFamily,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold),
                            },
                            onLinkTap: (link, _, ___) {
                              launch(link!);
                            },
                          )
                        : (renderMode == "Web View"
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
