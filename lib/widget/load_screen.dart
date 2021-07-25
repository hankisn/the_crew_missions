import 'package:flutter/material.dart';
import 'package:the_crew_missions/theme/the_crew_theme.dart';
import 'package:the_crew_missions/widget/crew_page.dart';

class LoadScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LoadScreenState();
}

class _LoadScreenState extends State<LoadScreen> {

  @override
  void initState() {
    print('Initializing....');
    super.initState();
    init();
  }
  
  void init() async {
    print('Doing hard work...... promise!');
    await Future.delayed(Duration(seconds: 1), () {
      print('All spent, all done........ promise!');
    });

    await Navigator.push(
      context, new MaterialPageRoute(
        builder: (context) => new CrewPage(),
      )
    );
/*
    Navigator.pushReplacementNamed(
      context,
      '/crew',
    );
*/
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: TheCrewTheme.standardTheme,
      home: Scaffold(
        body: Center(
          child: Column(
            children: [
              SizedBox(height: 75),
              Text("The Crew Missions",
                  style: TheCrewTheme.standardTheme.textTheme.headline1,), //TextStyle(color: Colors.white, fontSize: 36)),
              SizedBox(height: 50),
              Image.asset('assets/images/logo.jpg'),
              SizedBox(height: 75),
              Text("Versjon 0.0.1",
                  style: TextStyle(color: Colors.white, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }  
}