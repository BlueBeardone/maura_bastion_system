enum MainNavigation {
  newspaper,
  bastions,
  facility,
  hirelings,
  about,
}

extension MainNavigationExtension on MainNavigation {
  String get title {
    switch (this) {
      case MainNavigation.newspaper: return "Newspaper";
      case MainNavigation.about: return "About";
      case MainNavigation.facility: return "Overview";
      case MainNavigation.bastions: return "Bastions";
      case MainNavigation.hirelings: return "Hirelings";
    }
  }
}
