import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sst_announcer/homepage.dart';
import 'package:sst_announcer/services/poststream.dart';
import 'services/notificationservice.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

final postStreamController = StreamController<PostStream>.broadcast();
final NotificationService service = NotificationService();
const feedUrl = 'http://studentsblog.sst.edu.sg/feeds/posts/default?';

Future<void> checkForNewPosts() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  DateTime lastCheckTime = prefs.containsKey('lastCheckTime')
      ? DateTime.parse(prefs.getString('lastCheckTime')!)
      : DateTime.now();

  // Check for new posts in the RSS feed
  bool newPostsAvailable =
      await checkForNewBlogspotPosts(feedUrl, lastCheckTime);

  if (newPostsAvailable) {
    // Fetch the latest posts
    List<Map<String, String>> latestPosts =
        await fetchLatestBlogspotPosts(feedUrl);

    // Update the last check time
    await prefs.setString('lastCheckTime', latestPosts.first['pubDate']!);
    service.showNotification(
        "New announcement", "There is a new post in SST Announcer");
  } else {
    return;
  }
}

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

final lightTheme = ThemeData.light(useMaterial3: true);
final filledButtonStyle = ElevatedButton.styleFrom(
        backgroundColor: lightTheme.colorScheme.primary,
        foregroundColor: lightTheme.colorScheme.onPrimary,
        elevation: 3)
    .copyWith(elevation: MaterialStateProperty.resolveWith((states) {
  if (states.contains(MaterialState.hovered)) {
    return 1;
  }
  return 0;
}));

final darkTheme = ThemeData.dark(useMaterial3: true);
final darkFilledButtonStyle = ElevatedButton.styleFrom(
        backgroundColor: darkTheme.colorScheme.primary,
        foregroundColor: darkTheme.colorScheme.onPrimary)
    .copyWith(elevation: MaterialStateProperty.resolveWith((states) {
  if (states.contains(MaterialState.hovered)) {
    return 1;
  }
  return 0;
}));

void main() async {
  runApp(const MyApp());
  WidgetsFlutterBinding.ensureInitialized();
  // await AndroidAlarmManager.initialize();
  // await AndroidAlarmManager.periodic(
  //     const Duration(minutes: 20), 1, checkForNewPosts);
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
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
