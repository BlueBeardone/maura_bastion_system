import 'package:maura_bastion_system/data/models/user/user.dart';

class UserCredentials {
  final String username;
  final String password;
  final User user;

  const UserCredentials({
    required this.username,
    required this.password,
    required this.user,
  });
}

List<UserCredentials> fakeUserCredentials = [
  UserCredentials(
    username: 'admin',
    password: 'admin123',
    user: User(
      id: '1',
      displayName: 'Administrator',
      ),
  ),
  UserCredentials(
    username: 'user',
    password: 'password',
    user: User(id: '2', displayName: 'Standard User'),
  ),
  UserCredentials(
    username: 'tester',
    password: 'test123',
    user: User(id: '3', displayName: 'Test User'),
  ),
];

User? findUserByCredentials(String username, String password) {
  for (final credential in fakeUserCredentials) {
    if (credential.username.toLowerCase() == username.toLowerCase() &&
        credential.password == password) {
      return credential.user;
    }
  }

  return null;
}
