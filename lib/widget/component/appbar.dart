import 'package:flutter/material.dart';

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
        return IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
          tooltip: 'Hey meny!!',
        );
      },
    ),
  );
}