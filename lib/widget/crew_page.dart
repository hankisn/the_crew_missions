import 'package:flutter/material.dart';
import 'package:the_crew_missions/model/crew.dart';
import 'package:the_crew_missions/services/database_handler.dart';
import 'package:the_crew_missions/theme/the_crew_theme.dart';
import 'package:the_crew_missions/widget/component/appbar.dart';
import 'package:the_crew_missions/widget/manage_crew.dart';
import 'package:the_crew_missions/widget/component/navbar.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CrewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String title = "Crews";    

    return MaterialApp(
      theme: TheCrewTheme.standardTheme,
      home: _StatefullCrewPage(title: title,),
    );
  }
}

class _StatefullCrewPage extends StatefulWidget {
  final String title;

  _StatefullCrewPage({
    Key? key, required this.title
  }) : super(key: key);

  @override
  _CrewPageState createState() => _CrewPageState();

  
}

class _CrewPageState extends State<_StatefullCrewPage> {
  final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  late DatabaseHandler handler;

  final _formKeyCrew = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    this.handler = DatabaseHandler();
    this.handler.initializeDB().whenComplete(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          theCrewAppBar('Crews', context),
          _futureCrewBuilder(context),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _buildAddCrewBtn(context);
        },
        child: const Icon(Icons.add),
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
                      content: const Text("Are you sure you want to delete this crew?"),
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
                child: InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context, new MaterialPageRoute(
                        builder: (context) => new ManageCrew(crew: snapshot.data![index],)
                      )
                    );
                  },
                  child: ListTile(
                    contentPadding: EdgeInsets.all(8.0),
                    title: Text(snapshot.data![index].name, style: Theme.of(context).textTheme.headline4),
                    subtitle: Container(
                      child: DefaultTextStyle(
                        style: Theme.of(context).textTheme.subtitle1!,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Started: " + formatDate(snapshot.data![index].startDate)),
                            if (snapshot.data![index].crewMembers != null) Text(snapshot.data![index].crewMembers!.length.toString() + " crewmembers"),
                          ],
                        ),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const FaIcon(FontAwesomeIcons.edit),
                      color: Theme.of(context).primaryIconTheme.color,
                      onPressed: () async {
                        await Navigator.push(
                          context, new MaterialPageRoute(
                            builder: (context) => new ManageCrew(crew: snapshot.data![index],)
                          )
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          
            childCount: (snapshot.data as List<Crew>).length)
          ) :
          SliverToBoxAdapter(child: Text('No data found')),
    );
  }

  String formatDate(String iso8601String, {style}) {
    DateTime dateTime = DateTime.parse(iso8601String);

    String month = dateTime.month.toString().length==2?dateTime.month.toString():"0"+dateTime.month.toString();
    String day = dateTime.day.toString().length==2?dateTime.day.toString():"0"+dateTime.day.toString();

    return dateTime.year.toString() + "-" + month + "-" + day;
  }

  void _buildAddCrewBtn(BuildContext context) {
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
                    } else {
                      print("Fcuk!");
                    }
                    // Send user to manage crew
                    await Navigator.push(
                      context, new MaterialPageRoute(
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
