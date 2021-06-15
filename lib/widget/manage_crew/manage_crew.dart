import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:the_crew_missions/model/crew.dart';
import 'package:the_crew_missions/services/database_handler.dart';
import 'package:the_crew_missions/services/dialog_helper.dart';
import 'package:the_crew_missions/widget/component/appbar.dart';

import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';

import 'package:the_crew_missions/widget/crewpage/crew_page.dart';

// ignore: must_be_immutable
class ManageCrew extends StatelessWidget {
  Crew crew;
  static const _actionTitles = ['Delete Crew', 'Finish mission', 'Add crew member'];
  DatabaseHandler _databaseHandler = new DatabaseHandler();
  DialogHelper _dialogHelper = new DialogHelper();

  ManageCrew({Key? key, required this.crew}) : super(key: key);

  void _showAction(BuildContext context, int index, int crewId) {
    showDialog<void>(
      context: context,
      builder: (context) {
        switch(index) {
          case 0: {
            print("Deleting crew id: " + crewId.toString());
          }
          break;
          case 1: {
            print("Finish?");
          }
          break;
          case 2: {
            print("Add crew member?");
          }
          break;
        }
        
        return AlertDialog(
          content: Text(_actionTitles[index]),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ManageCrewPageStateful(
      crew: this.crew,
      distance: 112.0,
      children: [
        ActionButton(
          onPressed: () async {
            int crewId = crew.id!.toInt();
            if(await _dialogHelper.deleteConfirm(context)) {
              print("Deleting crew id: " + crewId.toString());
              await _databaseHandler.deleteCrew(crewId);
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
                builder: (context) => new CrewPage()
              )
            );
          },
          icon: const Icon(Icons.calendar_today_rounded, color: Colors.red,),
        ),
        ActionButton(
          onPressed: () => _showAction(context, 2, crew.id!.toInt()),
          icon: const Icon(Icons.person_add),
        ),
      ],
    );
  }
}

// ignore: must_be_immutable
class ManageCrewPageStateful extends StatefulWidget {
  Crew crew;
  
  ManageCrewPageStateful({
    Key? key,
    this.initialOpen,
    required this.distance,
    required this.children,
    required this.crew,
  }) : super(key: key);

  final bool? initialOpen;
  final double distance;
  final List<Widget> children;

  @override
  _ManageCrewPageState createState() => _ManageCrewPageState(crew: crew);
}

class _ManageCrewPageState extends State<ManageCrewPageStateful> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;

  DateTime selectedDate = DateTime.now();

  final _formKey = GlobalKey<FormState>();
  late Crew crew;
  late DatabaseHandler handler;

  _ManageCrewPageState({
    required this.crew,
  });

  @override
  void initState() {
    super.initState();

    this.handler = DatabaseHandler();
    this.handler.initializeDB().whenComplete(() async {
      //await this.handler.addCrew();
      setState(() {
        print("Jobbe ikke i databaseavdelinga lengre...");
      });
    });

    _open = widget.initialOpen ?? false;
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
              _buildTapToCloseFab(),
              ..._buildExpandingActionButtons(),
              _buildTapToOpenFab(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTapToCloseFab() {
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

  List<Widget> _buildExpandingActionButtons() {
    final children = <Widget>[];
    final count = widget.children.length;
    final step = 90.0 / (count - 1);
    for (var i = 0, angleInDegrees = 0.0;
        i < count;
        i++, angleInDegrees += step) {
      children.add(
        _ExpandingActionButton(
          directionInDegrees: angleInDegrees,
          maxDistance: widget.distance,
          progress: _expandAnimation,
          child: widget.children[i],
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
                  print("Crew name: " + value.toString());
                  crew.name = value.toString();

                  handler.insertCrew(crew);

                  await Navigator.push(
                    context, new MaterialPageRoute(
                      builder: (context) => new CrewPage()
                    )
                  );
                },
              ),
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
              padding: EdgeInsets.all(5.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,                    
                    children: <Widget> [
                      Icon(Icons.calendar_today, color: Colors.deepOrange),
                      Text(
                        "Start date:",
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
                              print('confirm $date');
                              setState(() {
                                selectedDate = date;
                                this.crew.startDate = selectedDate.toIso8601String();
                              });
                            },
                            currentTime: DateTime.parse(this.crew.startDate).toLocal(),
                            locale: LocaleType.no
                          );
                        },
                        child: Text(
                          "${selectedDate.toLocal()}".split(' ')[0],
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ]
                  ),
                ],
              )
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Validate will return true if the form is valid, or false if
                  // the form is invalid.
                  if (_formKey.currentState!.validate()) {
                    // Process data.
                    _formKey.currentState!.save();
                  }
                },
                child: const Text('Save Crew'),
              ),
            )
          ],
        ),
      ),
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

class FakeItem extends StatelessWidget {
  const FakeItem({
    Key? key,
    required this.isBig,
  }) : super(key: key);

  final bool isBig;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
      height: isBig ? 128.0 : 36.0,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        color: Colors.grey.shade300,
      ),
    );
  }
}