import 'package:flutter/material.dart';
import 'model/crew.dart';
import 'widget/crew_page.dart';
import 'widget/manage_crew.dart';
import 'widget/mission_page.dart';

void main() async => runApp(MaterialApp(
  theme: ThemeData(
    primarySwatch: Colors.blue,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  ),
  routes: {
    '/': (context) => CrewPage(),
    '/crew': (context) => CrewPage(),
    '/manageCrew': (context) => ManageCrew(crew: new Crew(name: "New Crew", startDate: DateTime.now().toIso8601String())),
    '/missions': (context) => MissionPage(crew: new Crew(name: "New Crew", startDate: DateTime.now().toIso8601String())),
  },
));
