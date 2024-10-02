import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sst_announcer/models/thememodel.dart';
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

  List<String?> RenderingModes = ["Parsed HTML", "Raw Text"];

  Color pickerColor = Color.fromRGBO(100, 230, 30, 1);
  Color currentColor = Color.fromRGBO(100, 230, 30, 1);

  String? selectedRenderMode;

  bool? materialYou = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      getColor();
      pickerColor = currentColor;
    });
  }

  void getSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedRenderMode = prefs.getString("renderMode") ?? "Parsed HTML";
      materialYou = prefs.getBool("materialYou") ?? false;
    });
  }

  void saveSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("renderMode", selectedRenderMode ?? "Parsed HTML");
    prefs.setBool("materialYou", materialYou!);
  }

  void saveColor(int r, int g, int b) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("r", r);
    prefs.setInt("g", g);
    prefs.setInt("b", b);
    print("saved: $r, $g, $b");
  }

  getColor() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final r = prefs.getInt("r") ?? 0;
    final g = prefs.getInt("g") ?? 0;
    final b = prefs.getInt("b") ?? 0;
    setState(() {
      currentColor = Color.fromRGBO(r, g, b, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    getColor();
    getSettings();
    return Consumer<ModelTheme>(
      builder: (context, ModelTheme themeNotifier, child) {
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
              child: Column(
                children: [
                  Row(
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
                          (mode) =>
                              DropdownMenuEntry(value: mode, label: mode!),
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
                  SizedBox(
                    height: 25,
                  ),
                  Row(
                    children: [
                      Text(
                        "Material You theme",
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      Spacer(),
                      Switch(
                        value: materialYou!,
                        onChanged: (value) {
                          setState(() {
                            materialYou = value;
                            themeNotifier.isDynamic = value;
                          });
                          saveSettings();
                        },
                      )
                    ],
                  ),
                  SizedBox(
                    height: 25,
                  ),
                  materialYou == false
                      ? Row(
                          children: [
                            Text(
                              "Theme seed",
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                            Spacer(),
                            ElevatedButton(
                              onPressed: () {
                                getColor();
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      actionsAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      title: Text("Choose seed color"),
                                      content: SingleChildScrollView(
                                        child: ColorPicker(
                                          pickerColor: pickerColor,
                                          onColorChanged: (color) {
                                            pickerColor = color;
                                          },
                                        ),
                                      ),
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text(
                                            "Cancel",
                                            style: TextStyle(
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              currentColor = pickerColor;
                                            });
                                            final r = currentColor.red;
                                            final g = currentColor.green;
                                            final b = currentColor.blue;
                                            saveColor(r, g, b);
                                            themeNotifier.colourSeed =
                                                currentColor;
                                            Navigator.of(context).pop();
                                          },
                                          child: Text(
                                            "Set",
                                            style: TextStyle(fontSize: 18),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  children: [
                                    Text(
                                      "Current color:",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                          color: currentColor,
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .primaryColorLight,
                                            width: 2,
                                          ),
                                          shape: BoxShape.circle),
                                      width: MediaQuery.of(context).size.width /
                                          10,
                                      height:
                                          MediaQuery.of(context).size.width /
                                              10,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        )
                      : SizedBox(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
