import 'package:get_storage/get_storage.dart';

class UserStorage {
  static final GetStorage _storage = GetStorage();

  static void saveUser({required String uid, required String email, String? fullName}) {
    _storage.write('user', {
      'uid': uid,
      'email': email,
      if (fullName != null) 'full_name': fullName,
    });
  }

  static Map<String, dynamic>? getUser() {
    return _storage.read('user');
  }

  static void clearUser() {
    _storage.remove('user');
  }
}
