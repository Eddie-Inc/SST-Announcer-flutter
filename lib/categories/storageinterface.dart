import 'package:shared_preferences/shared_preferences.dart';

Future<List<String>> getCategoryList() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getStringList('categoryList') ?? [];
}

Future<void> addCategory(String category) async {
  final prefs = await SharedPreferences.getInstance();
  final categoryList = await getCategoryList();
  if (!categoryList.contains(category)) {
    categoryList.add(category);
    await prefs.setStringList('categoryList', categoryList);
  }
}

Future<void> removeCategory(int category) async {
  final prefs = await SharedPreferences.getInstance();
  final categoryList = await getCategoryList();
  categoryList.removeAt(category);
  await prefs.setStringList('categoryList', categoryList);
}
