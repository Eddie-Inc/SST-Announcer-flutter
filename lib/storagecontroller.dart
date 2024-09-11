import 'package:shared_preferences/shared_preferences.dart';

class FolderStorage {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Add key-value pair to a specific folder
  Future<void> addStringToFolder(
      String folderName, String key, String value) async {
    String folderKey = 'folder_$folderName\_$key';
    await _prefs.setString(folderKey, value);
  }

  // Get all key-value pairs from a folder
  List<MapEntry<String, String>> getStringsFromFolder(String folderName) {
    String folderPrefix = 'folder_$folderName\_';
    List<MapEntry<String, String>> folderContents = _prefs
        .getKeys()
        .where((key) => key.startsWith(folderPrefix))
        .map((key) {
      String value = _prefs.getString(key) ?? '';
      String extractedKey = key.replaceFirst(folderPrefix, '');
      return MapEntry(extractedKey, value);
    }).toList();
    return folderContents;
  }

  // Delete a key-value pair from the folder (removes the key entirely)
  Future<void> deleteKeyFromFolder(String folderName, String key) async {
    String folderKey = 'folder_$folderName\_$key';
    await _prefs.remove(folderKey);
  }

  // Delete a folder and all its key-value pairs
  Future<void> deleteFolder(String folderName) async {
    String folderPrefix = 'folder_$folderName\_';
    final keysToDelete =
        _prefs.getKeys().where((key) => key.startsWith(folderPrefix)).toList();

    for (String key in keysToDelete) {
      await _prefs.remove(key);
    }
  }

  // Extract unique folder names from shared preferences keys
  List<String> getAllFolders() {
    Set<String> folders = {};

    for (String key in _prefs.getKeys()) {
      if (key.startsWith('folder_')) {
        // Extract the folder name from the key
        String folderName = key.split(
            '_')[1]; // Assuming the format is 'folder_{folderName}_{key}'
        folders.add(folderName);
      }
    }

    return folders.toList();
  }

  // Create a new folder by adding an initial key-value pair
  Future<void> createFolder(String folderName) async {
    // Add an empty item to signify folder creation
    await addStringToFolder(folderName, 'initial', 'empty');
  }
}
