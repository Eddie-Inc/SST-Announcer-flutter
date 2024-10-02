import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyThemePreferences {
  static const THEME_KEY = "theme_key";

  setTheme(bool value) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setBool(THEME_KEY, value);
  }

  getTheme() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getBool(THEME_KEY) ?? false;
  }
}

class ThemeColourPreferences {
  static const r = 0;
  static const g = 0;
  static const b = 0;

  setSeed(int r, int g, int b) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setInt("r", r);
    sharedPreferences.setInt("g", g);
    sharedPreferences.setInt("b", b);
  }

  getSeed() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    int r = sharedPreferences.getInt("r") ?? 0;
    int g = sharedPreferences.getInt("g") ?? 0;
    int b = sharedPreferences.getInt("b") ?? 0;
    return Color.fromRGBO(r, g, b, 1);
  }
}

class SeedTheme extends ChangeNotifier {
  late Color color;

  late ThemeColourPreferences _preferences;

  Color get seedColour => color;

  SeedTheme() {
    color = Colors.black;
    _preferences = ThemeColourPreferences();
  }

  set colourSeed(Color seed) {
    color = seed;
    _preferences.setSeed(seed.red, seed.green, seed.blue);
    notifyListeners();
  }

  getColourValues() async {
    color = await _preferences.getSeed();
    notifyListeners();
  }
}

class ModelTheme extends ChangeNotifier {
  late bool _isDynamic;
  late MyThemePreferences _preferences;
  bool get isDynamic => _isDynamic;

  late Color color;
  late ThemeColourPreferences _preferences2;
  Color get seedColour => color;

  ModelTheme() {
    _isDynamic = false;
    _preferences = MyThemePreferences();
    _preferences2 = ThemeColourPreferences();
    color = Colors.black;
    setup();
    getPreferences();
  }
//Switching the themes
  set isDynamic(bool value) {
    _isDynamic = value;
    _preferences.setTheme(value);
    notifyListeners();
  }

  set colourSeed(Color seed) {
    color = seed;
    _preferences2.setSeed(seed.red, seed.green, seed.blue);
    notifyListeners();
  }

  getColourValues() async {
    color = await _preferences2.getSeed();
    notifyListeners();
  }

  getPreferences() async {
    _isDynamic = await _preferences.getTheme();
    notifyListeners();
  }

  void setup() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final r = prefs.getInt("r") ?? 0;
    final g = prefs.getInt("g") ?? 0;
    final b = prefs.getInt("b") ?? 0;
    color = Color.fromRGBO(r, g, b, 1);
    notifyListeners();
  }
}
