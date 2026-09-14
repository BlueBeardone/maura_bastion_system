import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/main_navigation_enum.dart';

void main() {
  test('newspaper is the first navigation item', () {
    expect(MainNavigation.values.first, MainNavigation.newspaper);
  });

  test('newspaper title is "Newspaper"', () {
    expect(MainNavigation.newspaper.title, 'Newspaper');
  });
}
