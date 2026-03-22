enum MainNavigation {
  myBastion,
  basic,
  special,
  hirelings,
  about,
}

extension MainNavigationExtension on MainNavigation {
  String get title {
    switch (this) {
      case MainNavigation.about: return "About";
      case MainNavigation.basic: return "Basic Facilities";
      case MainNavigation.special: return "Special Facilities";
      case MainNavigation.myBastion: return "My Bastion";
      case MainNavigation.hirelings: return "Hirelings";
    }
  }
}