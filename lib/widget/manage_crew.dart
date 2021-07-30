import 'package:flutter/material.dart';
import 'package:the_crew_missions/model/crew.dart';
import 'package:the_crew_missions/model/crew_member.dart';
import 'package:the_crew_missions/services/database_handler.dart';
import 'package:the_crew_missions/theme/the_crew_theme.dart';
import 'package:the_crew_missions/widget/component/appbar.dart';

import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:the_crew_missions/widget/component/navbar.dart';

import 'package:the_crew_missions/widget/crew_page.dart';
import 'package:the_crew_missions/widget/mission_page.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  final _formKey = GlobalKey<FormState>();
  final _formKeyCrewMember = GlobalKey<FormState>();
  late Crew crew;
  late DatabaseHandler handler;
  late int _attempts;
  late int _mission;
  late List<String> _autoCompleteOptions = [];
  late List<CrewMember> _allCrewMembers = [];

  final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  _ManageCrewPageState({
    required this.crew,
  });

  @override
  void initState()  {
    super.initState();
    this.handler = DatabaseHandler();
    this.handler.initializeDB().whenComplete(() {
      setState(() {
        _findAllCrew();
      });
    });

    this._attempts = -1;
    this._mission = -1;
  }

  @override
  void dispose() {
    super.dispose();
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
      theme: TheCrewTheme.standardTheme,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      home: Scaffold(
        body: CustomScrollView(
          slivers: <Widget>[
            theCrewAppBar("Manage Crew", context),
            new SliverList(delegate: SliverChildListDelegate([
              _buildManageCrewPage(context),
            ]))
          ],
        ),
        floatingActionButton: FloatingActionButton(
        onPressed: () {
          _buildAddCrewMemberBtn(context);
        },
        child: const Icon(Icons.person_add),
      ),
        bottomNavigationBar: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            homeMenuItem(),
            helpMenuItem(),
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
              default:
                break;
            }
          },
        ),
      ),
    );
  }

  void _buildAddCrewMemberBtn(BuildContext context) {
    if (this.crew.crewMembers == null) {
      this.crew.crewMembers = [];
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("New Crew member"),
          content: this.crew.crewMembers!.length<=4?Form(
            key: _formKeyCrewMember,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _showAutocompleteField(),
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

  Future<void> _findAllCrew() async {
    List<String> _options = [];
    List<CrewMember> _crewmembers = await this.handler.retrieveCrewMembers();

    if (_crewmembers.isNotEmpty) {
      for (int i = 0; i < _crewmembers.length; i++) {
        _options.add(_crewmembers[i].name);
      }

      setState(() {
        this._autoCompleteOptions = _options;
        this._allCrewMembers = _crewmembers;
      });
    }
  }

  Widget _showAutocompleteField() {
    List<String> _options = this._autoCompleteOptions;
    return RawAutocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        return this._autoCompleteOptions.where((String option) {
          return option.contains(textEditingValue.text);
        });
      },
      onSelected: (String selection) {
        setState(() {
        });
      },
      fieldViewBuilder: (BuildContext context,
          TextEditingController textEditingController,
          FocusNode focusNode,
          VoidCallback onFieldSubmitted) {
        return TextFormField(
          controller: textEditingController,
          decoration: const InputDecoration(
            hintText: 'Crew member name',
          ),
          focusNode: focusNode,
          onFieldSubmitted: (String value) {
            onFieldSubmitted();
          },
          validator: (String? value) {
            if (!_options.contains(value)) {
              print("New Crewmember");
            }

            return (value!.length < 1 || value.contains('@')) ? 'Illegal chars or no name.' : null;
          },
          onSaved: (String? value) async {
            List<CrewMember> _selectedCrew = _allCrewMembers.where((e) => e.name == value).toList();
            CrewMember insertCrewMember;
            if (_selectedCrew.isNotEmpty && _selectedCrew.length == 1) {
              print("Crewmember already exists, not creating new one.");
              insertCrewMember = _selectedCrew[0];
            } else {
              print("Creating new crewmember: " + value.toString());
              insertCrewMember = new CrewMember(name: value.toString());
            }

            if (this.crew.crewMembers!.where((e) => e.id == insertCrewMember.id).toList().isNotEmpty) {
              print("Crewmember is already part of the crew!");
              _snackBarMessage("Crewmember " + insertCrewMember.name + " is already part of the crew!", Colors.red[800]!, 3);
            } else {
              int crewMemberId = await handler.insertCrewMember(insertCrewMember, this.crew.id!);
              List<CrewMember> _crewMembers = this.crew.crewMembers!;
              insertCrewMember.id = crewMemberId;
              _crewMembers.add(insertCrewMember);
              this.crew.crewMembers = _crewMembers;

              setState(() {
                // Redraw the list of crews
              });
              _snackBarMessage(value.toString() + ' added to ' + this.crew.name.toString());
            }

            Navigator.pop(context, 'Saved value: ' + value.toString());
          },
        );
      },
      optionsViewBuilder: (BuildContext context,
          AutocompleteOnSelected<String> onSelected,
          Iterable<String> options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: SizedBox(
              height: 200.0,
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return GestureDetector(
                    onTap: () {
                      onSelected(option);
                    },
                    child: ListTile(
                      title: Text(option),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildManageCrewPage(BuildContext context) {
    return Form(
      key: _formKey,
      child: Card(
        child: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  FaIcon(FontAwesomeIcons.users),
                  Flexible(
                    flex: 3,
                    child: Container(
                      padding: EdgeInsets.all(5),
                      child: TextFormField(
                        initialValue: this.crew.name,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.all(10.0),
                          border:  OutlineInputBorder(),
                          hintText: 'Enter name of the crew',
                          labelText: 'Name your crew',
                        ),
                        validator: (String? value) {
                          return (value == null || value.contains('@')) ? 'No chars or illegal chars.' : null;
                        },
                        onSaved: (value) async {
                          this.crew.name = value.toString();
                          handler.insertCrew(crew);
                          _snackBarMessage("Crew updated!");
                        },
                      ),
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
                        child: Text('Save Name'),
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
                            _snackBarMessage("Start date is after finish date...", TheCrewTheme.error, 3);
                          }
                        },
                        currentTime: DateTime.parse(this.crew.startDate).toLocal(),
                        locale: LocaleType.no //-------------------------------------------//
                      );
                    },
                    child: Column(
                      children: <Widget>[
                        FaIcon(FontAwesomeIcons.calendarPlus),
                        Text("Start date", style: TheCrewTheme.standardTheme.textTheme.headline6,),
                        Text(
                          "${DateTime.parse(this.crew.startDate).toLocal()}".split(' ')[0],
                          style: TheCrewTheme.standardTheme.textTheme.subtitle1,
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      if (this._mission < 50) {
                        print("Campaign not finished yet: " + this._mission.toString());
                        _snackBarMessage("Campaign is not finished yet, can't set finish date until all missions are completed.");
                      } else {
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
                              _snackBarMessage("Finish date is before start date...", TheCrewTheme.error, 3);
                            }
                          },
                          currentTime: this.crew.finishDate!=null?DateTime.parse(this.crew.finishDate.toString()).toLocal():DateTime.now().toLocal(),
                          locale: LocaleType.no
                        );
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        FaIcon(FontAwesomeIcons.calendarCheck),
                        Text("Finish date", style: TheCrewTheme.standardTheme.textTheme.headline6,),
                        this.crew.finishDate==null?Text("Add Finish Date", style: TheCrewTheme.standardTheme.textTheme.subtitle2,): 
                        Text(
                          "${DateTime.parse(this.crew.finishDate!).toLocal()}".split(' ')[0],
                          style: TheCrewTheme.standardTheme.textTheme.subtitle1,
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context, new MaterialPageRoute(
                          builder: (context) => new MissionPage(crew: this.crew)
                        )
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        FaIcon(FontAwesomeIcons.award),
                        Text(
                          "Attempts",
                          style: TheCrewTheme.standardTheme.textTheme.headline6,
                        ),
                        Row(
                          children: [
                            FaIcon(FontAwesomeIcons.rocket, size: 15,),
                            Text(" " + this._attempts.toString() + " "),
                            FaIcon(FontAwesomeIcons.grav, size: 15,),
                            Text(" " + this._mission.toString()),
                          ],
                        ),
                      ]
                    ),
                  ),
                ],
              )
            ),
            Container(
              padding: EdgeInsets.only(top: 12.0),
              child: Text("The Crewmembers",
                style: TheCrewTheme.standardTheme.textTheme.headline5,
              ),
            ),
            Container(
              child: Column(
                children: <Widget>[
                  this.crew.crewMembers!=null? (this.crew.crewMembers!.isNotEmpty?_crewMembersList(context): Text("No Crew Members", style: TheCrewTheme.standardTheme.textTheme.subtitle2,)): Text("No Crew Members", style: TheCrewTheme.standardTheme.textTheme.subtitle2,),
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
            padding: EdgeInsets.all(10),
            itemCount: snapshot.data!.length,
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemBuilder: (BuildContext context, index) {
              return Dismissible(
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: Icon(Icons.delete_forever),
                  margin: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
                  decoration: new BoxDecoration(
                    borderRadius: BorderRadius.circular(5.0),
                    color: Theme.of(context).errorColor,
                  ),
                ),
                key: ValueKey<int>(snapshot.data![index].id!),
                confirmDismiss: (direction) async {
                  return showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Confirm"),
                        content: Text("Are you sure you want to delete this attempt?"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(true);
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
                    },
                  );
                },
                onDismissed: (DismissDirection direction) async {
                  String crewMemberDismissed = snapshot.data![index].name.toString();
                  await this.handler.dismissCrewMemberFromCrew(this.crew.id!, snapshot.data![index].id!);
                  setState(() {
                    snapshot.data!.remove(snapshot.data![index]);
                    this.crew.crewMembers!.removeAt(index);
                  });
                  _snackBarMessage(crewMemberDismissed + " dismissed");
                },
                child: Card(
                  color: TheCrewTheme.cardOnCards,
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