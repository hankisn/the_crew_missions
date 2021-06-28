import 'package:flutter/material.dart';

BottomNavigationBar theCrewNavBar() {
  return BottomNavigationBar(
    items: const <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
        backgroundColor: Colors.red,
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.home_max),
        label: 'Home2',
        backgroundColor: Colors.red,
      ),
    ],
  );
}