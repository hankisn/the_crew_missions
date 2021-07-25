import 'package:flutter/material.dart';

BottomNavigationBar navBarCrewPage() {
  return BottomNavigationBar(
    items: <BottomNavigationBarItem>[
      homeMenuItem(),
      helpMenuItem(),
    ],
  );
}

BottomNavigationBar navBarManageCrew() {
  return BottomNavigationBar(
    items: <BottomNavigationBarItem>[
      homeMenuItem(),
      helpMenuItem(),
    ],
  );
}

// ----------------------- Helpers ----------------------- //

BottomNavigationBarItem homeMenuItem() {
  return BottomNavigationBarItem(
    icon: Icon(Icons.home),
    label: 'Home',
  );
}

BottomNavigationBarItem helpMenuItem() {
  return BottomNavigationBarItem(
    icon: Icon(Icons.help),
    label: 'Help',
  );
}