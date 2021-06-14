import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:the_crew_missions/model/crew.dart';

const String CREW_TABLE = 'crewTable';
const String CREWMEMBER_CREW_TABLE = 'crewMemberCrewTable';
const String CREWMEMBER_TABLE = 'crewMemberTable';
const String DATABASE = 'the_crew.db';

class DatabaseHandler {
  Future<Database> initializeDB() async {
    WidgetsFlutterBinding.ensureInitialized();

    String path = await getDatabasesPath();
    return openDatabase(
      join(path, DATABASE),
      onCreate: (database, version) async {
        await database.execute(
          "CREATE TABLE $CREW_TABLE(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, attempts INTEGER NOT NULL, startDate TEXT NOT NULL, endDate TEXT)",
        );
      },
      version: 1,
    );
  }

  Future<int> insertUser(Crew crew) async {
    int result = 0;
    final Database db = await initializeDB();
    result = await db.insert(CREW_TABLE, crew.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return result;
  }

  Future<List<Crew>> retrieveUsers() async {
    final Database db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.query(CREW_TABLE);
    return queryResult.map((e) => Crew.fromMap(e)).toList();
  }

  Future<void> deleteUser(int id) async {
    final db = await initializeDB();
    await db.delete(
      CREW_TABLE,
      where: "id = ?",
      whereArgs: [id],
    );
  }



}
