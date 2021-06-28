import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:the_crew_missions/model/crew.dart';
import 'package:the_crew_missions/model/crew_member.dart';
import 'package:the_crew_missions/services/database_handler.dart';
import 'package:the_crew_missions/services/dialog_helper.dart';
import 'package:the_crew_missions/widget/component/appbar.dart';

import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';

import 'package:the_crew_missions/widget/crew_page.dart';
import 'package:the_crew_missions/widget/mission_page.dart';

// ignore: must_be_immutable
class ManageCrew extends StatefulWidget {
  Crew crew;
  
  ManageCrew({
    Key? key,
    required this.crew,
  }) : super(key: key);

  final double distance = 112.0;

  @override
  _ManageCrewPageState createState() => _ManageCrewPageState(crew: crew);
}

class _ManageCrewPageState extends State<ManageCrew> with SingleTickerProviderStateMixin {
  final bool? initialOpen;

  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;

  final _formKey = GlobalKey<FormState>();
  final _formKeyCrewMember = GlobalKey<FormState>();
  late Crew crew;
  late DatabaseHandler handler;
  late int _attempts;
  late int _mission;

  DialogHelper _dialogHelper = new DialogHelper();

  final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  _ManageCrewPageState({
    this.initialOpen,
    required this.crew,
  });

  @override
  void initState()  {
    super.initState();
    this.handler = DatabaseHandler();
    this.handler.initializeDB().whenComplete(() async {
      setState(() { });
    });

    this._attempts = -1;
    this._mission = -1;

    _open = this.initialOpen ?? false;
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void getAttempts() {
    Future<int> _attemptsNum = this.handler.getTotalAttempts(this.crew.id!);
    _attemptsNum.then((value) {
      setState(() {
        this._attempts = value;
      });
    });

    Future<int> _missionProgress = this.handler.getProgression(this.crew.id!);
    _missionProgress.then((value) {
      setState(() {
        this._mission = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (this._attempts == -1 || this._mission == -1) {
      getAttempts();
    }
    return MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      home: Scaffold(
        backgroundColor: Colors.grey[900],
        body: CustomScrollView(
          slivers: <Widget>[
            theCrewAppBar("Manage Crew", context),
            new SliverList(delegate: SliverChildListDelegate([
              _buildManageCrewPage(context),
            ]))
          ],
        ),
        floatingActionButton: SizedBox.expand(
          child: Stack(
            alignment: Alignment.bottomRight,
            clipBehavior: Clip.none,
            children: [
              _buildTapToCloseFab(context),
              ..._buildExpandingActionButtons(context),
              _buildTapToOpenFab(),
            ],
          ),
        ),
      ),
    );
  }

  void _buildAddCrewMemberBtn(BuildContext context) {
    _toggle();
    if (this.crew.crewMembers == null) {
      this.crew.crewMembers = [];
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("New Crew member: "),
          content: this.crew.crewMembers!.length<=4?Form(
            key: _formKeyCrewMember,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    icon: Icon(Icons.person),
                    hintText: 'Crew member name',
                    labelText: 'Name *',
                  ),
                  onSaved: (String? value) async {
                    print("Saved value: " + value.toString());                    
                    CrewMember insertCrewMember = new CrewMember(name: value.toString());
                    int crewMemberId = await handler.insertCrewMember(insertCrewMember, this.crew.id!);
                    List<CrewMember> _crewMembers = this.crew.crewMembers!;
                    insertCrewMember.id = crewMemberId;
                    _crewMembers.add(insertCrewMember);
                    this.crew.crewMembers = _crewMembers;
                    
                    setState(() {
                      // Redraw the list of crews
                    });
                    Navigator.pop(context, 'Saved value: ' + value.toString());
                    rootScaffoldMessengerKey.currentState!.showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 3),
                        content: Text(
                          "Crewmember " + value.toString() + ' added to ' + this.crew.name.toString(),
                        ),
                      ),
                    );
                  },
                  validator: (String? value) {
                    return (value!.length < 1 || value.contains('@')) ? 'Illegal chars or no name.' : null;
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    if(_formKeyCrewMember.currentState!.validate()) {
                      print("Valid value, saving");
                      _formKeyCrewMember.currentState!.save();
                    }
                  }, 
                  child: Text("Save"),
                ),
              ],
            ),
          ):Text("Full squad"),
        );
      }
    );
  }

  List<Widget> _listActions(BuildContext context) {
    return [
    ActionButton(
      onPressed: () async {
        int crewId = crew.id!.toInt();
        if(await this._dialogHelper.deleteConfirm(context, "crew")) {
          print("Deleting crew id: " + crewId.toString());
          await this.handler.deleteCrew(crewId);
          await Navigator.push(
            context, new MaterialPageRoute(
              builder: (context) => new CrewPage()
            )
          );
        } else {
          print("Delete cancelled");
        }
      },
      icon: const Icon(Icons.delete, color: Colors.red,),
    ),
    ActionButton(
      onPressed: () async {
        await Navigator.push(
          context, new MaterialPageRoute(
            builder: (context) => new MissionPage(crew: this.crew)
          )
        );
      },
      icon: Icon(Icons.airplane_ticket_outlined,),
    ),
    ActionButton(
      onPressed: () => _buildAddCrewMemberBtn(context),
      icon: const Icon(Icons.person_add),
    )];
  }
  
  Widget _buildTapToCloseFab(BuildContext context) {
    return SizedBox(
      width: 56.0,
      height: 56.0,
      child: Center(
        child: Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 4.0,
          child: InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.close,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildExpandingActionButtons(BuildContext context) {
    final children = <Widget>[];
    final count = _listActions(context).length;
    final step = 90.0 / (count - 1);
    for (var i = 0, angleInDegrees = 0.0;
        i < count;
        i++, angleInDegrees += step) {
      children.add(
        _ExpandingActionButton(
          directionInDegrees: angleInDegrees,
          maxDistance: widget.distance,
          progress: _expandAnimation,
          child: _listActions(context)[i],
        ),
      );
    }
    return children;
  }

  Widget _buildTapToOpenFab() {
    return IgnorePointer(
      ignoring: _open,
      child: AnimatedContainer(
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          _open ? 0.7 : 1.0,
          _open ? 0.7 : 1.0,
          1.0,
        ),
        duration: const Duration(milliseconds: 250),
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        child: AnimatedOpacity(
          opacity: _open ? 0.0 : 1.0,
          curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
          duration: const Duration(milliseconds: 250),
          child: FloatingActionButton(
            onPressed: _toggle,
            child: const Icon(Icons.create),
          ),
        ),
      ),
    );
  }

  Widget _buildManageCrewPage(BuildContext context) {
    return Form(
      key: _formKey,
      child: Container(
        color: Colors.blueGrey[100],
        padding: EdgeInsets.all(10.0),
        child: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Flexible(
                    flex: 3,
                    child: TextFormField(
                      initialValue: this.crew.name,
                      style: TextStyle(color: Colors.blue),
                      decoration: const InputDecoration(
                        border:  OutlineInputBorder(),
                        icon: Icon(Icons.people, color: Colors.blue),
                        hintText: 'Enter name of the crew',
                        hintStyle: const TextStyle(color: Colors.white),
                        labelText: 'Name your crew',
                      ),
                      validator: (String? value) {
                        return (value == null || value.contains('@')) ? 'No chars or illegal chars.' : null;
                      },
                      onSaved: (value) async {
                        this.crew.name = value.toString();
                        handler.insertCrew(crew);
                        rootScaffoldMessengerKey.currentState!.showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 3),
                            content: const Text(
                              "Crew updated!",
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Flexible(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.all(5.0),
                      child: ElevatedButton(
                        onPressed: () {
                          // Validate will return true if the form is valid, or false if
                          // the form is invalid.
                          if (_formKey.currentState!.validate()) {
                            // Process data.
                            _formKey.currentState!.save();
                          }
                        },
                        child: const Text('Save Name'),
                      ),
                    ),
                  ),
                ]
              ),
            ),
            Container(
              padding: EdgeInsets.all(5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Icon(Icons.event, color: Colors.green),
                      Text(
                        "Start date",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      InkWell(
                        onTap: () {
                          DatePicker.showDatePicker(context,
                            showTitleActions: true,
                            minTime: DateTime(2021, 1, 1),
                            maxTime: DateTime(2050, 12, 12),
                            onChanged: (date) {
                              print('change $date');
                            },
                            onConfirm: (date) {
                              if (this.crew.finishDate == null || (DateTime.parse(this.crew.finishDate!).toLocal()).isAfter(date)) {
                                setState(() {
                                  this.crew.startDate = date.toIso8601String();
                                });
                                if (_formKey.currentState!.validate()) {
                                  // Process data.
                                  _formKey.currentState!.save();
                                }
                              } else {
                                rootScaffoldMessengerKey.currentState!.showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 3),
                                    content: const Text(
                                      "Start date is after finish date...",
                                    ),
                                  ),
                                );
                              }
                            },
                            currentTime: DateTime.parse(this.crew.startDate).toLocal(),
                            locale: LocaleType.no
                          );
                        },
                        child: Text(
                          "${DateTime.parse(this.crew.startDate).toLocal()}".split(' ')[0],
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Icon(Icons.event_note, color: Colors.red),
                      Text(
                        "Finish date",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      InkWell(
                        onTap: () {
                          DatePicker.showDatePicker(context,
                            showTitleActions: true,
                            minTime: DateTime(2021, 1, 1),
                            maxTime: DateTime(2050, 12, 12),
                            onChanged: (date) {
                              print('change $date');
                            },
                            onConfirm: (date) {
                              if (DateTime.parse(this.crew.startDate).toLocal().isBefore(date)) {
                                setState(() {
                                  this.crew.finishDate = date.toIso8601String();
                                });
                                if (_formKey.currentState!.validate()) {
                                  // Process data.
                                  _formKey.currentState!.save();
                                }
                              } else {
                                print("Problem with date");
                                rootScaffoldMessengerKey.currentState!.showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 3),
                                    content: const Text(
                                      "Finish date is before start date...",
                                    ),
                                  ),
                                );
                              }
                            },
                            currentTime: this.crew.finishDate!=null?DateTime.parse(this.crew.finishDate.toString()).toLocal():DateTime.now().toLocal(),
                            locale: LocaleType.no
                          );
                        },
                        child: this.crew.finishDate==null?Text("Add Finish Date"): Text(
                          "${DateTime.parse(this.crew.finishDate!).toLocal()}".split(' ')[0],
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Icon(Icons.emoji_events, color: Colors.blue[900]),
                      Text(
                        "Attempts",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(this._attempts.toString() + "(" + this._mission.toString() + ")"),
                    ]
                  ),
                ],
              )
            ),
            Container(
              padding: EdgeInsets.only(top: 10.0),
              child: Text("The Crewmembers",
                style: const TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(10.0, 0, 10.0, 2.0),
              child: Column(
                children: <Widget>[
                  this.crew.crewMembers!=null? (this.crew.crewMembers!.isNotEmpty?_crewMembersList(context): Text("No Crew Members")): Text("No Crew Members"),
                ]
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _crewMembersList(BuildContext context) {
    return FutureBuilder(
      future: this.handler.retrieveCrewMembersInCrew(this.crew.id!),
      builder: (BuildContext context, AsyncSnapshot<List<CrewMember>> snapshot) =>
        snapshot.hasData ? Container(           
          child: ListView.builder(
            itemCount: snapshot.data!.length,
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemBuilder: (BuildContext context, index) {
              return Dismissible(
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: Icon(Icons.delete_forever),
                ),
                key: ValueKey<int>(snapshot.data![index].id!),
                confirmDismiss: (direction) => _dialogHelper.deleteConfirm(context, "crewmember"),
                onDismissed: (DismissDirection direction) async {
                  String crewMemberDismissed = snapshot.data![index].name.toString();
                  await this.handler.dismissCrewMemberFromCrew(this.crew.id!, snapshot.data![index].id!);
                  setState(() {
                    snapshot.data!.remove(snapshot.data![index]);
                    this.crew.crewMembers!.removeAt(index);
                  });
                  rootScaffoldMessengerKey.currentState!.showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                      content: Text(
                        "Crewmember " + crewMemberDismissed + " dismissed",
                      ),
                    ),
                  );
                },
                child: Card(
                  color: Colors.white70,
                  child: ListTile(
                    leading: Icon(Icons.person_sharp),
                    title: Text(snapshot.data![index].name),
                  ),
                ),
              );
            },
          )
        )
        : Text("No crewmembers"),
    );
  }
}

class _ExpandingActionButton extends StatelessWidget {
  _ExpandingActionButton({
    Key? key,
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
  }) : super(key: key);

  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final offset = Offset.fromDirection(
          directionInDegrees * (math.pi / 180.0),
          progress.value * maxDistance,
        );
        return Positioned(
          right: 4.0 + offset.dx,
          bottom: 4.0 + offset.dy,
          child: Transform.rotate(
            angle: (1.0 - progress.value) * math.pi / 2,
            child: child!,
          ),
        );
      },
      child: FadeTransition(
        opacity: progress,
        child: child,
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  const ActionButton({
    Key? key,
    this.onPressed,
    required this.icon,
  }) : super(key: key);

  final VoidCallback? onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      color: theme.accentColor,
      elevation: 4.0,
      child: IconTheme.merge(
        data: theme.accentIconTheme,
        child: IconButton(
          onPressed: onPressed,
          icon: icon,
        ),
      ),
    );
  }
}
