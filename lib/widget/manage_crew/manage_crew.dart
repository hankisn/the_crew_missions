import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:the_crew_missions/model/crew.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:the_crew_missions/services/database_handler.dart';
import 'package:the_crew_missions/widget/component/appbar.dart';
import 'package:the_crew_missions/widget/crewpage/crew_page.dart';



class ManageCrewPage extends StatefulWidget {

  final Crew crew;

  ManageCrewPage({Key? key, required this.crew}) : super(key: key);
  
  @override
  State<ManageCrewPage> createState() => _ManageCrewPageState(crew: crew);
}

class _ManageCrewPageState extends State<ManageCrewPage> {
  DateTime selectedDate = DateTime.now();

  final _formKey = GlobalKey<FormState>();
  //final _formKeyCrewMembers = GlobalKey<FormState>();

  Crew crew;

  _ManageCrewPageState({required this.crew}) {
    print("Manage Crew: " + this.crew.name);
  }

  late DatabaseHandler handler;

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
  }


  final textController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    textController.dispose();
    super.dispose();
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
        //drawer: MainMenu(),
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

                  handler.insertUser(crew);

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
            //if(this.crew.crewMembers != null || this.crew.crewMembers!.isNotEmpty) _buildCrewMemberList(context),
            //if(this.crew.crewMembers!.length < 5) _buildAddCrewMemberBtn(context),
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
                    /*
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(content: Text("Saved..."));
                      }
                    );
                    */
                  }
                },
                child: const Text('Submit'),
              ),
            )
          ],
        ),
      ),
    );
  }
/*
  Widget _buildAddCrewMemberBtn(BuildContext context) {
    return InkWell(
      onTap: () {
        print("Adding new crewmember...");
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Add new crewmember"),
              content: Form(
                key: _formKeyCrewMembers,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        icon: Icon(Icons.person),
                        hintText: 'What do people call you?',
                        labelText: 'Name *',
                      ),
                      onSaved: (String? value) {
                        if(this.crew.crewMembers!.isEmpty) {
                          print("Empty roster!!");
                        }
                        print("Saved value: " + value.toString());
                        this.crew.crewMembers!.add(new CrewMember(crewMemberName: value.toString()));
                        Navigator.pop(context, 'Saved value: ' + value.toString());
                        setState(() {
                          print("Oppdatering?");
                        });
                      },
                      validator: (String? value) {
                        return (value == null || value.contains('@')) ? 'No chars or illegal chars.' : null;
                      },
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if(_formKeyCrewMembers.currentState!.validate()) {
                          print("Valid value, saving");
                          _formKeyCrewMembers.currentState!.save();
                        }
                      }, 
                      child: Text("Save"),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
      child: Text("Add Crewmember", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue[900])),
    );
  }
*/
/*
  Widget _buildCrewMemberList(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: this.crew.crewMembers!.length.toInt(),
      itemBuilder: (BuildContext context, int i) {
        return ListTile(
          title: _createCrewMemberRows(i),
        );
      }
    );
  }
*/
/*
  void deleteCrewMemberFromCrew(int crewMemberId) {
    setState(() {
      print("Sletting...");

      this.crew.crewMembers!.removeWhere((e) => e.crewMemberId == crewMemberId);
    });
  }
*/
/*
  Widget _createCrewMemberRows(int crewMemberSequenceId) {    
    return Row(
      children: <Widget>[
        Expanded(
          flex: 6,
          child: Text(
            this.crew.crewMembers![crewMemberSequenceId].crewMemberName.toString(),
            style: const TextStyle(
              fontSize: 16,
              fontFamily: "Arial",
              color: Colors.blue,
            ),
          ),
        ),
        Expanded(
          child: IconButton(
            icon: Icon(Icons.delete),
            color: Colors.red[800],
            onPressed: () {
              print("Deleting the following crewmember: \'" + this.crew.crewMembers![crewMemberSequenceId].crewMemberName.toString() + "\' => id: " + this.crew.crewMembers![crewMemberSequenceId].crewMemberId.toString());
              deleteCrewMemberFromCrew(this.crew.crewMembers![crewMemberSequenceId].crewMemberId!.toInt());
            }
          )
        ),
      ],
    );
  }
  */
}
