import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart' as xml;
import 'dart:io';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int cacheSize = 0;
  List<xml.XmlElement> posts = [];
  File? file;

  List<String?> RenderingModes = ["Parsed HTML", "Web View", "Raw Text"];
  String? selectedRenderMode;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) => getSettings);
  }

  void getSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    print("sharedpreferences initialized");
    setState(() {
      selectedRenderMode = prefs.getString("renderMode") ?? "Parsed HTML";
    });
    print(selectedRenderMode);
  }

  void saveSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("renderMode", selectedRenderMode ?? "Parsed HTML");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Render mode",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
              Spacer(),
              DropdownMenu(
                dropdownMenuEntries: RenderingModes.map(
                  (mode) => DropdownMenuEntry(value: mode, label: mode!),
                ).toList(),
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                initialSelection: selectedRenderMode,
                onSelected: (value) {
                  setState(() {
                    selectedRenderMode = value!;
                    saveSettings();
                    getSettings();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
