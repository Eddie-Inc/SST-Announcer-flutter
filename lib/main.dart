import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sst_announcer/homepage.dart';
import 'package:sst_announcer/models/thememodel.dart';

const feedUrl = 'http://studentsblog.sst.edu.sg/feeds/posts/default?';

const seedcolor = Colors.red;

const simplePeriodicTask = "";

ThemeData? lightTheme;
ThemeData? darkTheme;

void main() async {
  runApp(const MyApp());
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  OneSignal.initialize("eed6fbe1-6be5-431e-8b67-0b4478d68586");
  print("initialized with id: eed6fbe1-6be5-431e-8b67-0b4478d68586");
  OneSignal.Notifications.requestPermission(true);
  OneSignal.Notifications.addClickListener((event) {
    print("notification clicked with event: $event");
    print(
        "notification: ${event.notification.title}, ${event.notification.body}");
  });
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
    print("color: $r, $g, $b");
    seed = Color.fromRGBO(r, g, b, 1);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getColor();
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

    return ChangeNotifierProvider(
      create: (_) => ModelTheme(),
      child: Consumer<ModelTheme>(
          builder: (context, ModelTheme themeNotifier, child) {
        return DynamicColorBuilder(
            builder: (lightColorScheme, darkColorScheme) {
          return MaterialApp(
            title: 'SST Announcer',
            theme: themeNotifier.isDynamic
                ? ThemeData(colorScheme: lightColorScheme)
                : ThemeData(
                    useMaterial3: true,
                    brightness: Brightness.light,
                    colorScheme: ColorScheme.fromSeed(
                        seedColor: themeNotifier.seedColour)),
            darkTheme: themeNotifier.isDynamic
                ? ThemeData(
                    colorScheme: darkColorScheme, brightness: Brightness.dark)
                : ThemeData(
                    useMaterial3: true,
                    brightness: Brightness.dark,
                    colorScheme: ColorScheme.fromSeed(
                        seedColor: themeNotifier.seedColour,
                        brightness: Brightness.dark)),
            debugShowCheckedModeBanner: false,
            home: const HomePage(),
          );
        });
      }),
    );
  }
}
