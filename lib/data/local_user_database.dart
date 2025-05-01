import '../models/user_model.dart';
import 'local_file_storage.dart';

class LocalUserDatabase {
  static Future<List<User>> getUsers() async {
    return await LocalFileStorage.loadUsers();
  }

  static Future<bool> isUsernameTaken(String username) async {
    final users = await getUsers();
    return users.any((user) => user.username == username);
  }

  static Future<bool> isEmailTaken(String email) async {
    final users = await getUsers();
    return users.any((user) => user.email == email);
  }

  static Future<void> addUser(User user) async {
    await LocalFileStorage.saveUser(user);
  }

  static Future<User?> authenticate(String email, String password) async {
    final users = await getUsers();
    try {
      return users.firstWhere(
            (user) => user.email == email && user.password == password,
      );
    } catch (e) {
      return null;
    }
  }
}