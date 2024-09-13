import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:sst_announcer/homepage.dart';

const feedUrl = 'http://studentsblog.sst.edu.sg/feeds/posts/default?';

const seedcolor = Colors.red;

const simplePeriodicTask = "";

final lightTheme = ThemeData.light(useMaterial3: true);
final darkTheme = ThemeData.dark(useMaterial3: true);

void main() async {
  runApp(const MyApp());
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("856bbc0e-4c79-4d7e-bc8f-1b63ad85ee66");
  OneSignal.Notifications.requestPermission(true);
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
