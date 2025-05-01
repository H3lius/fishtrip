import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/user_model.dart';

class LocalFileStorage {
  static Future<File> _getUserFile() async {
    final dir = await getApplicationDocumentsDirectory(); // gauna apps'o leidžiamą direktoriją
    final path = '${dir.path}/users.txt'; // sukuriam users.txt tame kataloge
    final file = File(path);

    if (!(await file.exists())) {
      await file.create();
    }

    return file;
  }

  static Future<void> saveUser(User user) async {
    final file = await _getUserFile();
    final line = '${user.username}|${user.email}|${user.password}\n';
    await file.writeAsString(line, mode: FileMode.append); // prideda vartotoją į failą
  }

  static Future<List<User>> loadUsers() async {
    final file = await _getUserFile();
    if (!await file.exists()) return [];

    final lines = await file.readAsLines();
    return lines.map((line) {
      final parts = line.split('|');
      return User(
        username: parts[0],
        email: parts[1],
        password: parts[2],
      );
    }).toList();
  }
}