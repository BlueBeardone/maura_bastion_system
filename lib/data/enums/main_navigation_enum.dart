enum MainNavigation {
  newspaper,
  myBastion,
  facility,
  hirelings,
  about,
}

extension MainNavigationExtension on MainNavigation {
  String get title {
    switch (this) {
      case MainNavigation.newspaper: return "Newspaper";
      case MainNavigation.about: return "About";
      case MainNavigation.facility: return "Facilities";
      case MainNavigation.myBastion: return "My Bastion";
      case MainNavigation.hirelings: return "Hirelings";
    }
  }
}
