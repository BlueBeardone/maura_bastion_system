enum MainNavigation {
  myBastion,
  facility,
  hirelings,
  about,
}

extension MainNavigationExtension on MainNavigation {
  String get title {
    switch (this) {
      case MainNavigation.about: return "About";
      case MainNavigation.facility: return "Facilities";
      case MainNavigation.myBastion: return "Bastions";
      case MainNavigation.hirelings: return "Hirelings";
    }
  }
}