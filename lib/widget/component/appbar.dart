import 'package:flutter/material.dart';
import 'package:the_crew_missions/widget/crew_page.dart';

SliverAppBar theCrewAppBar(String title, BuildContext context) {
  return SliverAppBar(
    expandedHeight: 70.0,
    flexibleSpace: FlexibleSpaceBar(
      title: Text(title),
    ),
    pinned: true,
    snap: false,
    floating: true,
    leading: Builder(
      builder: (BuildContext context) {
        if (title == "Crews") {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            tooltip: 'Hey meny!!',
          );
        } else {
          return IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await Navigator.push(
                context, new MaterialPageRoute(
                  builder: (context) => new CrewPage()
                )
              );
            },
            tooltip: 'Hey meny!!',
          );
        }
      },
    ),
  );
}