import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:the_crew_missions/model/attempts.dart';
import 'package:the_crew_missions/model/crew.dart';
import 'package:the_crew_missions/services/database_handler.dart';

import 'package:numberpicker/numberpicker.dart';
import 'package:the_crew_missions/services/dialog_helper.dart';

import 'component/appbar.dart';

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
  DialogHelper _dialogHelper = new DialogHelper();


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
            if (this.attemptsList.isNotEmpty) _deleteLastBtn(),
          ],
        ),
      ),
    );
  }

  Widget _deleteLastBtn() {
    return SliverPadding(
      padding: EdgeInsets.all(20),
      sliver: Container(
        child: new SliverList(delegate: SliverChildListDelegate([
          ElevatedButton(
            onPressed: () async => await _dialogHelper.deleteConfirm(context, "attempt")?_deleteLastAttempt(this.attemptsList.last.id!):print("No delete"),
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
      sliver: SliverGrid.count(
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        crossAxisCount: 4,
        childAspectRatio: 2.3,
        children: <Widget>[
          for (int i = 0; this.attemptsList.length > i; i++) _missionAttempts(i),
        ]
      ),
    );
  }

  Widget _missionAttempts(int index) {
    return Container(
      padding: const EdgeInsets.all(2.0),
      color: Colors.yellow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text("Mission " + (index + 1).toString()),
          Text("Attempts: " + this.attemptsList[index].attempts.toString()),
        ],
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
                      child: Text("Choose mission:"),
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
                      child: Text("Choose attempts:"),
                    ),
                    Container(
                      child: NumberPicker(
                        value: this._attempt,
                        minValue: 1,
                        maxValue: 200,
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

  Future<void> saveAttempt(int mission, int attempt) async {
    print("Mission: $_mission, attempts: $_attempt");
    int result = await this.handler.addAttempts(this.crew.id!, _mission, _attempt);
    if (result != 0) {
      updateAttemptListView();
    }
    setState(() { });
    _snackBarMessage("Added $attempt attempts to mission $mission", Colors.green);
  }

  void _deleteLastAttempt(int attemptId) {
    print("Trying to delete attempt #$attemptId");
    print("This attempt is mission #" + this.attemptsList.last.mission.toString());
    this.handler.deleteLastAttempt(attemptId);
    updateAttemptListView();
    setState(() { });
    _snackBarMessage("Deleted all attempts on mission " + this.attemptsList.last.mission.toString(), Colors.green);
  }

  void _snackBarMessage(String message, Color color, [int duration = 2]) {
    rootScaffoldMessengerKey.currentState!.showSnackBar(
      SnackBar(
        backgroundColor: color,
        duration: Duration(seconds: duration),
        content: Text(message),
      ),
    );

  }

}

/**
 * 
 * 
 * TODO Få til en commit til GitHub snart...
 */
