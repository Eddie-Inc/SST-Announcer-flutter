import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:sst_announcer/main.dart';
import 'package:sst_announcer/services/notificationservice.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:intl/intl.dart';

class AnnouncementPage extends StatefulWidget {
  final String title;
  String bodyText;
  String author;
  AnnouncementPage(
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
  Future<void> pickDate() async {
    final newDueDate = await DatePicker.showDateTimePicker(
      context,
      showTitleActions: true,
      onChanged: (date) => date,
      onConfirm: (date) {},
    );
    if (newDueDate != null) {
      setState(() {
        dueDate = newDueDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
    final theme = Theme.of(context);
    final originalString = widget.bodyText;
    final parsedString = originalString.replaceAllMapped(
        RegExp(
            r'((?:font-size|color|background-color):\s*(?:rgba\([^)]*\)|[^;]*);?)',
            multiLine: true,
            caseSensitive: false), (match) {
      return '"${match.group(0)}"';
    });
    final formattedDate =
        dueDate == null ? "" : DateFormat("dd/MM/yyyy").format(dueDate);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Set reminder"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: titleController,
                            decoration: const InputDecoration(
                              hintText: "Notification title",
                            ),
                          ),
                          TextField(
                            controller: bodyController,
                            decoration: const InputDecoration(
                                hintText: "Notification description"),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          dueDate == null
                              ? IconButton(
                                  onPressed: pickDate,
                                  iconSize: 26,
                                  icon: const Icon(
                                      Icons.event_available_outlined),
                                )
                              : ActionChip(
                                  label: Text(formattedDate),
                                  onPressed: pickDate,
                                  backgroundColor: theme.brightness ==
                                          Brightness.dark
                                      ? Colors.grey[800]
                                      : const Color.fromRGBO(246, 242, 249, 1),
                                  elevation: 0,
                                )
                        ],
                      ),
                      actions: [
                        Center(
                          child: Row(children: [
                            TextButton(
                              onPressed: () {
                                final navigator = Navigator.of(context);
                                navigator.pop();
                              },
                              child: const Text("Cancel"),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () {
                                final navigator = Navigator.of(context);
                                navigator.pop();
                                if (titleController.text == "" ||
                                    dueDate == null) {
                                  return;
                                } else {
                                  service.scheduleNotification(
                                      title: titleController.text,
                                      body: bodyController.text,
                                      scheduledNotificationDateTime: dueDate);
                                }
                              },
                              style: filledButtonStyle,
                              child: const Text("Confirm"),
                            ),
                          ]),
                        )
                      ],
                      alignment: Alignment.center,
                    );
                  },
                );
              },
              icon: const Icon(Icons.calendar_month))
        ],
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("Announcement"),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Ink(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                        color: backgroundColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(widget.author),
                  const SizedBox(
                    height: 15,
                  ),
                  Html(
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
                      /*"span": Style(
                          fontSize: FontSize.large,
                          color: backgroundColor,
                          textDecorationColor: backgroundColor),*/
                      "p": Style(
                          fontSize: FontSize.large,
                          color: backgroundColor,
                          textDecorationColor: backgroundColor),
                      "a": Style(
                        color: Colors.blue,
                      ),
                    },
                    onLinkTap: (link, _, __, ___) {
                      launch(link!);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
