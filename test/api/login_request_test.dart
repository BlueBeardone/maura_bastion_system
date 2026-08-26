import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/api/dto/login_request.dart';

void main() {
  test('LoginRequest serializes username key', () {
    final request = LoginRequest(username: 'admin', password: 'secret');

    expect(
      request.toJson(),
      equals({
        'username': 'admin',
        'password': 'secret',
      }),
    );
  });
}