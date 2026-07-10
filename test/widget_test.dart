import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/test_data/bastion/fake_bastion_data.dart';
import 'package:maura_bastion_system/data/test_data/user/fake_user_data.dart';

void main() {
  test('fake bastions are alphabetized and include the user-owned bastion', () {
    final bastions = getFakeBastions();

    expect(bastions.isNotEmpty, isTrue);
    expect(bastions.first.id, userBastionId);

    final sortedNames = bastions.map((bastion) => bastion.name).toList();
    final expectedSorted = List<String>.from(sortedNames)..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    expect(sortedNames, equals(expectedSorted));
  });

  test('administrator login assigns the user bastion', () {
    final user = findUserByCredentials('admin', 'admin123');

    expect(user, isNotNull);
    expect(user!.bastionId, equals(userBastionId));
  });
}
