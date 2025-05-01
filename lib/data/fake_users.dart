import '../models/user_model.dart';

class FakeUserDatabase {
  static final List<User> _users = [];

  static List<User> get users => _users;

  static bool isUsernameTaken(String username) {
    return _users.any((user) => user.username == username);
  }

  static bool isEmailTaken(String email) {
    return _users.any((user) => user.email == email);
  }

  static void addUser(User user) {
    _users.add(user);
  }

  static User? authenticate(String email, String password) {
    try {
      return _users.firstWhere(
            (user) => user.email == email && user.password == password,
      );
    } catch (e) {
      return null;
    }
  }
}