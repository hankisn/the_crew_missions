import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:the_crew_missions/model/attempts.dart';
import 'package:the_crew_missions/model/crew.dart';
import 'package:the_crew_missions/services/database_handler.dart';

import 'package:flutter_polygon/flutter_polygon.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:the_crew_missions/theme/the_crew_theme.dart';
import 'package:the_crew_missions/widget/manage_crew.dart';

import 'component/appbar.dart';
import 'component/navbar.dart';
import 'crew_page.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ignore: must_be_immutable
class MissionPage extends StatefulWidget {
  Crew crew;

  MissionPage({
    Key? key,
    required this.crew,
  }) : super(key: key);

  @override
  _MissionPageState createState() => _MissionPageState(crew: crew);
}

class _MissionPageState extends State<MissionPage> {
  late Crew crew;
  late DatabaseHandler handler;
  late List<Attempts> attemptsList;
  int _mission = 1;
  int _attempt = 1;

  final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final _formKey = GlobalKey<FormState>();


  _MissionPageState({
    required this.crew,
  });
  
  @override
  void initState() {
    super.initState();
    this.handler = DatabaseHandler();
    this.handler.initializeDB().whenComplete(() async {
      this._mission = await this.handler.getProgression(this.crew.id!);
      this._mission +=1;
      setState(() { });
    });
    this.attemptsList = [];
  }

  void updateAttemptListView() {
    Future<List<Attempts>> attemptsList = this.handler.findAttempts(this.crew.id!);
    attemptsList.then((attemptsList) {
      setState(() {
        this.attemptsList = attemptsList;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (this.attemptsList.isEmpty) {
      updateAttemptListView();
    }
    return MaterialApp(
      theme: TheCrewTheme.standardTheme,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      home: Scaffold(
        backgroundColor: Colors.grey[800],
        body: CustomScrollView(
          slivers: <Widget>[
            theCrewAppBar("Register Missions", context),
            new SliverList(delegate: SliverChildListDelegate([
              _missionControls(),
            ])),
            if (this.attemptsList.isNotEmpty) _attemptsList(),
            if (this.attemptsList.isNotEmpty) _deleteLastBtn(context),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            homeMenuItem(),
            helpMenuItem(),
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.users),
              label: 'Back to Crew',
              backgroundColor: Colors.red,
            ),
          ],
          onTap: (index) {
            switch(index) {
              case 0:
                Navigator.push(
                  context, new MaterialPageRoute(
                    builder: (context) => new CrewPage(),
                  )
                );
                break;
              case 1:
                print("Get help!");
                break;
              case 2:
                Navigator.push(
                  context, new MaterialPageRoute(
                    builder: (context) => new ManageCrew(crew: this.crew)
                  )
                );
                break;
              default:
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _deleteLastBtn(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.all(20),
      sliver: Container(
        child: new SliverList(delegate: SliverChildListDelegate([
          ElevatedButton(
            onPressed: () {
              _showDialogDeleteAttempt(context, this.attemptsList.last.id!);
            },

            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete),
                Padding(padding: EdgeInsets.fromLTRB(5.0, 0, 5.0, 0)),
                Text("Delete last attempt"),
              ],
            )
          ),
        ])),
      ),
    );
  }

  Widget _attemptsList() {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverGrid.extent(
        maxCrossAxisExtent: 110,
        mainAxisSpacing: 10.0,
        crossAxisSpacing: 10.0,
        childAspectRatio: 2.0,
        children: [
          for (int i = 0; this.attemptsList.length > i; i++) _missionAttempts(i),
        ],
      ),
    );
  }

  Widget _missionAttempts(int index) {
    return Container(
      padding: const EdgeInsets.all(2.0),
      color: Colors.blueGrey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ClipPolygon(
            sides: 5,
            borderRadius: 5.0,
            boxShadows: [
              PolygonBoxShadow(color: Colors.black, elevation: 1.0),
              PolygonBoxShadow(color: Colors.grey, elevation: 5.0),
            ],
            child: Container(
              padding: EdgeInsets.all(5.0),
              color: Colors.black,
              child: Align(
                alignment: Alignment.center,
                child: Text((index + 1).toString(), style: TheCrewTheme.standardTheme.textTheme.button,),
              ),
            ),
          ),
          Spacer(),
          ClipPolygon(
            sides: 4,
            borderRadius: 1.0,
            rotate: 45,
            boxShadows: [
              PolygonBoxShadow(color: Colors.black, elevation: 1.0),
              PolygonBoxShadow(color: Colors.grey, elevation: 5.0),
            ],
            child: Container(
              padding: EdgeInsets.all(5.0),
              child: Align(
                alignment: Alignment.center,
                child: Text(this.attemptsList[index].attempts.toString(), style: TheCrewTheme.standardTheme.textTheme.button,),
              ),
              color: Colors.black,
            ),
          ),
        ]
      ),
    );
  }

  Widget _missionControls() {
    return Form(
      key: _formKey,
      child: Container(
        color: Colors.blueGrey[200],
        padding: EdgeInsets.all(10.0),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Container(
                      child: Text("Missions:", style: TheCrewTheme.standardTheme.textTheme.headline6,),
                    ),
                    Container(
                      child: NumberPicker(
                        value: this._mission,
                        minValue: 1,
                        maxValue: 50,
                        onChanged: (value) => setState(() => _mission = value),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Container(
                      child: Text("Attempts:", style: TheCrewTheme.standardTheme.textTheme.headline6,),
                    ),
                    Container(
                      child: NumberPicker(
                        value: this._attempt,
                        minValue: 1,
                        maxValue: 99,
                        onChanged: (value) => setState(() => _attempt = value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.all(5.0),
              child: ElevatedButton(
                onPressed: () async {
                  if (this.attemptsList.isEmpty) {
                    if (_mission != 1) {
                      print("Error, the first mission has to be mission 1.");
                      _snackBarMessage("First mission must be mission 1", Colors.red, 4);
                    } else if (_mission == 1) {
                      saveAttempt(_mission, _attempt);
                    }
                  } else {
                    if (_mission.toInt() > (this.attemptsList.last.mission.toInt() + 1)) {
                      print("Error, mission registered is not in sequence. mission: $_mission,  last: " + this.attemptsList.last.mission.toInt().toString());
                      _snackBarMessage("Cannot add attempts to mission $_mission, you need to add all previous missions first", Colors.red, 4);
                    } else {
                      print("Vi gjør ting rett...");
                      print("Mission: " + _mission.toInt().toString() + ", last:" + this.attemptsList.last.mission.toInt().toString());
                      saveAttempt(_mission, _attempt);
                    }
                  }
                },
                child: const Text('Register attempts'),
              ),
            ),
          ]
        ),
      ),
    );
  }

  _showDialogDeleteAttempt(BuildContext context, int attempt) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm"),
          content: const Text("Are you sure you want to delete this attempt?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                _deleteLastAttempt(attempt);
              },
              child: const Text("DELETE"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                print("No delete");
              },
              child: const Text("CANCEL"),
            ),
          ],
        );
      }
    );
  }

  Future<void> saveAttempt(int mission, int attempt) async {
    print("Mission: $_mission, attempts: $_attempt");
    int result = await this.handler.addAttempts(this.crew.id!, _mission, _attempt);
    if (result != 0) {
      updateAttemptListView();
    }
    setState(() { });
    _snackBarMessage("Added $attempt attempts to mission $mission");
  }

  void _deleteLastAttempt(int attemptId) {
    print("Trying to delete attempt #$attemptId");
    print("This attempt is mission #" + this.attemptsList.last.mission.toString());
    this.handler.deleteLastAttempt(attemptId);
    updateAttemptListView();
    setState(() { });
    _snackBarMessage("Deleted attempts on mission " + this.attemptsList.last.mission.toString());
  }

  void _snackBarMessage(String message, [Color color = Colors.white, int duration = 2]) {
    if(color == Colors.white) {
      color = TheCrewTheme.standardTheme.snackBarTheme.backgroundColor!;
    }
    rootScaffoldMessengerKey.currentState!.showSnackBar(
      SnackBar(
        backgroundColor: color,
        duration: Duration(seconds: duration),
        content: Text(message),
      ),
    );

  }

}
