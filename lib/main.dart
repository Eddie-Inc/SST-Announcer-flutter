import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sst_announcer/homepage.dart';

const feedUrl = 'http://studentsblog.sst.edu.sg/feeds/posts/default?';

const seedcolor = Colors.red;

const simplePeriodicTask = "";

ThemeData? lightTheme;
ThemeData? darkTheme;

void main() async {
  runApp(const MyApp());
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("856bbc0e-4c79-4d7e-bc8f-1b63ad85ee66");
  OneSignal.Notifications.requestPermission(true);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool materialYou = false;
  Color seed = Color(0x000000);

  void getThemeData() async {
    final prefs = await SharedPreferences.getInstance();
    materialYou = prefs.getBool("materialYou") ?? false;
    print(materialYou);
  }

  void getColor() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final r = prefs.getInt("r") ?? 0;
    final g = prefs.getInt("g") ?? 0;
    final b = prefs.getInt("b") ?? 0;
    seed = Color.fromRGBO(r, g, b, 1);
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    getColor();
    getThemeData();
    if (materialYou == false) {
      lightTheme = ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(seedColor: seed));
      darkTheme = ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
              seedColor: seed, brightness: Brightness.dark));
    } else {
      lightTheme = ThemeData.light(useMaterial3: true);
      darkTheme = ThemeData.dark(useMaterial3: true);
    }

    return DynamicColorBuilder(builder: (lightColorScheme, darkColorScheme) {
      return MaterialApp(
        title: 'SST Announcer',
        theme:
            materialYou ? ThemeData(colorScheme: lightColorScheme) : lightTheme,
        darkTheme:
            materialYou ? ThemeData(colorScheme: darkColorScheme) : darkTheme,
        home: HomePage(),
        debugShowCheckedModeBanner: false,
      );
    });
  }
}
