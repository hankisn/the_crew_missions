import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:the_crew_missions/model/crew.dart';
import 'package:the_crew_missions/services/database_handler.dart';
import 'package:the_crew_missions/services/dialog_helper.dart';
import 'package:the_crew_missions/widget/component/appbar.dart';
import 'package:the_crew_missions/widget/manage_crew/manage_crew.dart';

class CrewPage extends StatelessWidget {
  const CrewPage({Key? key}) : super(key: key);

  static const String _title = 'Crews';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: _title,
      home: StatefulCrewPage(),
    );
  }
}

/// This is the stateful widget that the main application instantiates.
class StatefulCrewPage extends StatefulWidget {
  const StatefulCrewPage({Key? key}) : super(key: key);

  @override
  State<StatefulCrewPage> createState() => _CrewPageState();
}

/// This is the private State class that goes with MyStatefulWidget.
class _CrewPageState extends State<StatefulCrewPage> {
  late DatabaseHandler handler;
  DialogHelper _dialogHelper = new DialogHelper();

  final _formKeyCrew = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    this.handler = DatabaseHandler();
    this.handler.initializeDB().whenComplete(() async {
      setState(() {});
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.grey[900],
        body: CustomScrollView(
          slivers: <Widget>[
            theCrewAppBar("Crews", context),            
            _futureCrewBuilder(context),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _buildAddCrewMemberBtn(context);
          },
          child: const Icon(Icons.add),
          backgroundColor: Colors.green,
        ),
      )
    );
  }

  Widget _futureCrewBuilder(BuildContext context) {
    return FutureBuilder(
      future: this.handler.retrieveCrew(),
      builder: (BuildContext context, AsyncSnapshot<List<Crew>> snapshot) =>
        snapshot.connectionState == ConnectionState.waiting ? SliverToBoxAdapter(child: LinearProgressIndicator()) :
          snapshot.hasData ? SliverList(delegate: SliverChildBuilderDelegate((_, index) =>
            Dismissible(
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Icon(Icons.delete_forever),
              ),
              key: ValueKey<int>(snapshot.data![index].id!),
              confirmDismiss: (direction) => _dialogHelper.deleteConfirm(context),
              onDismissed: (DismissDirection direction) async {
                String crewDismissed = snapshot.data![index].name.toString();
                await this.handler.deleteCrew(snapshot.data![index].id!);
                setState(() {
                  snapshot.data!.remove(snapshot.data![index]);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Crew " + crewDismissed + ' dismissed'
                    )
                  )
                );
              },
              child: Card(
                child: ListTile(
                  contentPadding: EdgeInsets.all(8.0),
                  title: Text(snapshot.data![index].name),
                  subtitle: Text("Attempts: x, Date: " + formatDate(snapshot.data![index].startDate)),
                  trailing: Ink(
                    decoration: const ShapeDecoration(
                      color: Colors.lightBlue,
                      shape: CircleBorder(),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.mode_edit_outline_rounded),
                      color: Colors.white,
                      onPressed: () async {
                        await Navigator.push(
                          context, new MaterialPageRoute(
                            builder: (context) => new ManageCrew(crew: snapshot.data![index],)
                          )
                        );
                      },
                    ),
                  ),
                )
              ),
            ),
          
            childCount: (snapshot.data as List<Crew>).length)
          ) :
          SliverToBoxAdapter(child: Text('No data found')),
    );
  }

  String formatDate(String iso8601String) {
    DateTime dateTime = DateTime.parse(iso8601String);

    String month = dateTime.month.toString().length==2?dateTime.month.toString():"0"+dateTime.month.toString();
    String day = dateTime.day.toString().length==2?dateTime.day.toString():"0"+dateTime.day.toString();

    return dateTime.year.toString() + "-" + month + "-" + day;
  }

  void _buildAddCrewMemberBtn(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("New Crew"),
          content: Form(
            key: _formKeyCrew,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    icon: Icon(Icons.person),
                    hintText: 'What do people call your crew?',
                    labelText: 'Crew name *',
                  ),
                  onSaved: (String? value) async {
                    print("Saved value: " + value.toString());                    
                    Crew insertCrew = new Crew(name: value.toString(), startDate: DateTime.now().toIso8601String());
                    int result = await this.handler.insertCrew(insertCrew);
                    if (result != 0) {
                      print("All good!");
                      insertCrew.id = result;
                      print("Id: " + result.toString());
                    } else {
                      print("Fcuk!");
                    }
                    // Send user to manage crew
                    await Navigator.push(
                      context, new MaterialPageRoute(
                        //builder: (context) => new ManageCrewPage(crew: insertCrew)
                        builder: (context) => new ManageCrew(crew: insertCrew)
                      )
                    );
                    setState(() {
                      // Redraw the list of crews
                    });
                    Navigator.pop(context, 'Saved value: ' + value.toString());
                  },
                  validator: (String? value) {
                    return (value!.length < 1 || value.contains('@')) ? 'Illegal chars or no name.' : null;
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    if(_formKeyCrew.currentState!.validate()) {
                      print("Valid value, saving");
                      _formKeyCrew.currentState!.save();
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
  }

}
