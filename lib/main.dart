import 'dart:async';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:sst_announcer/bottomnavigation.dart';
import 'package:sst_announcer/categories/storageinterface.dart';
import 'package:sst_announcer/services/poststream.dart';
import 'package:sst_announcer/themes.dart';
import 'package:xml/xml.dart' as xml;

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

const kSeedColor = Colors.red;

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
    return Scaffold(
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
