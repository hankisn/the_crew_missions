import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:the_crew_missions/model/attempts.dart';
import 'package:the_crew_missions/model/crew.dart';
import 'package:the_crew_missions/model/crew_member.dart';
import 'package:the_crew_missions/model/crew_member_crew.dart';

const String CREW_TABLE = 'crewTable';
const String CREWMEMBER_CREW_TABLE = 'crewMemberCrewTable';
const String CREWMEMBER_TABLE = 'crewMemberTable';
const String ATTEMPTS_TABLE = 'attemptsTable';
const String DATABASE = 'the_crew.db';

class DatabaseHandler {
  Future<Database> initializeDB() async {
    WidgetsFlutterBinding.ensureInitialized();

    String path = await getDatabasesPath();
    return openDatabase(
      join(path, DATABASE),
      onCreate: (database, version) async {
        await database.execute(
          "CREATE TABLE $CREW_TABLE(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, startDate TEXT NOT NULL, finishDate TEXT)",
        );
        await database.execute(
          "CREATE TABLE $CREWMEMBER_CREW_TABLE(id INTEGER PRIMARY KEY AUTOINCREMENT, crewId INTEGER NOT NULL, crewMemberId INTEGER NOT NULL)",
        );
        await database.execute(
          "CREATE TABLE $CREWMEMBER_TABLE(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE)",
        );
        await database.execute(
          "CREATE TABLE $ATTEMPTS_TABLE(id INTEGER PRIMARY KEY AUTOINCREMENT, crewId INTEGER NOT NULL, mission INTEGER NOT NULL, attempts INTEGER NOT NULL)",
        );
      },
      version: 1,
    );
  }

  Future<int> insertCrewMember(CrewMember crewMember, int crewId) async {
    int crewMemberResult = 0;
    int crewMemberCrewResult = 0;

    final Database db = await initializeDB();
    crewMemberResult = await db.insert(CREWMEMBER_TABLE, crewMember.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    CrewMemberCrew crewMemberCrew = new CrewMemberCrew(crewId: crewId, crewMemberId: crewMemberResult);

    crewMemberCrewResult = await db.insert(CREWMEMBER_CREW_TABLE, crewMemberCrew.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

    if (crewMemberResult != 0 && crewMemberCrewResult != 0) {
      return crewMemberResult;
    } else {
      return 0;
    }
  }

  Future<int> insertCrew(Crew crew) async {
    int result = 0;
    final Database db = await initializeDB();

    result = await db.insert(CREW_TABLE, crew.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    if (result == 0) return 0;

    return result;
  }

  Future<List<Crew>> retrieveCrew() async {
    final Database db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.query(CREW_TABLE);

    List<Crew> allCrew = queryResult.map((e) => Crew.fromMap(e)).toList();

    for (int i = 0; allCrew.length > i; i++) {
      allCrew[i].crewMembers = await retrieveCrewMembersInCrew(allCrew[i].id!);
    }

    return allCrew;
  }
  
  Future<List<CrewMember>> retrieveCrewMembers() async {
    final Database db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.query(CREWMEMBER_TABLE);
    return queryResult.map((e) => CrewMember.fromMap(e)).toList();
  }

  Future<List<CrewMember>> retrieveCrewMembersInCrew(int crewId) async {
    List<int> crewMemberIds = [];
    final Database db = await initializeDB();
    final List<Map<String, Object?>> crewMemberCrewResult = await db.query(
      CREWMEMBER_CREW_TABLE,
      where: "crewId = ?",
      whereArgs: [crewId],);

    List<CrewMemberCrew> crewMemberCrew = crewMemberCrewResult.map((e) => CrewMemberCrew.fromMap(e)).toList();

    
    for (int i = 0; crewMemberCrew.length > i; i++) {
      crewMemberIds.add(crewMemberCrew[i].crewMemberId);
    }

    String queryParamIds = "";
    for (int j = 0; crewMemberIds.length > j; j++) {
      if (j != 0) queryParamIds += ",";
      queryParamIds += crewMemberIds[j].toString();
    }

    final List<Map<String, Object?>> crewMemberResult = await db.rawQuery(
      "SELECT * FROM $CREWMEMBER_TABLE WHERE id IN($queryParamIds)");

    return crewMemberResult.map((e) => CrewMember.fromMap(e)).toList();
  }

  Future<void> deleteCrew(int id) async {
    final db = await initializeDB();
    await db.delete(
      CREW_TABLE,
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<void> dismissCrewMemberFromCrew(int crewId, int crewMemberId) async {
    print("Deleting crewMember: $crewMemberId");
    final db = await initializeDB();

    final List<Map<String, Object?>> crewMemberCrewResult = await db.query(
      CREWMEMBER_CREW_TABLE,
      where: "crewId = ? AND crewMemberId = ?",
      whereArgs: [crewId, crewMemberId],);
    
    List<CrewMemberCrew> crewMemberCrew = crewMemberCrewResult.map((e) => CrewMemberCrew.fromMap(e)).toList();

    print(crewMemberCrew.toString());
    
    if (crewMemberCrew.length == 1) {
      await db.delete(
        CREWMEMBER_CREW_TABLE,
        where: "id = ?",
        whereArgs: [crewMemberCrew[0].id],
      );
    }
  }

  Future<void> deleteLastAttempt(int attemptId) async {
    print("Deleting attempt: $attemptId");

    final db = await initializeDB();
    
    await db.delete(
      ATTEMPTS_TABLE,
      where: "id = ?",
      whereArgs: [attemptId],
    );
  }

  Future<int> addAttempts(int crewId, int mission, int attempts) async {
    print("Adding $attempts attempts to mission $mission on crew $crewId");
    final db = await initializeDB();
    Attempts attempt = new Attempts(crewId: crewId, mission: mission, attempts: attempts);

    final List<Map<String, Object?>> crewAttemptsResults = await db.query(
      ATTEMPTS_TABLE,
      where: "crewId = ? AND mission = ?",
      whereArgs: [crewId, mission]
    );

    List<Attempts> attemptsList = crewAttemptsResults.map((e) => Attempts.fromMap(e)).toList();

    print("Lengden er: " + attemptsList.length.toString());

    if(attemptsList.length == 1) {
      attempt.id = attemptsList[0].id;
    } else if (attemptsList.length > 1) {
      print("Shitfaced, her gikk vi dunken...");
      return Future<int>.value(0);
    }

    return await db.insert(
      ATTEMPTS_TABLE, 
      attempt.toMap(), 
      conflictAlgorithm: ConflictAlgorithm.replace
    );        
  }

  Future<List<Attempts>> findAttempts(int crewId) async {
    print("Searching for missions for crew: $crewId");
    final db = await initializeDB();

    final List<Map<String, Object?>> crewAttemptsResults = await db.query(
      ATTEMPTS_TABLE,
      where: "crewId = ?",
      whereArgs: [crewId],
      orderBy: "mission"
    );

    return crewAttemptsResults.map((e) => Attempts.fromMap(e)).toList();
  }

  Future<int> getProgression(int crewId) async {
    final db = await initializeDB();

    int? numberOfAttempts =  Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(attempts) FROM $ATTEMPTS_TABLE WHERE crewId = $crewId"));

    return numberOfAttempts == null?0:numberOfAttempts;
  }

  Future<int> getTotalAttempts(int crewId) async {
    final db = await initializeDB();

    int? numberOfAttempts =  Sqflite.firstIntValue(await db.rawQuery("SELECT SUM(attempts) FROM $ATTEMPTS_TABLE WHERE crewId = $crewId"));

    return numberOfAttempts == null?0:numberOfAttempts;
  }
}
