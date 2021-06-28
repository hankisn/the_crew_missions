import 'package:the_crew_missions/model/crew_member.dart';

class Crew {
  int? id;
  String name;
  String startDate;
  String? finishDate;
  List<CrewMember>? crewMembers; 

  Crew({
    this.id,
    required this.name,
    required this.startDate,
    this.finishDate,
    this.crewMembers
  });

  Crew.fromMap(Map<String, dynamic> res)
      : id = res["id"],
        name = res["name"],
        startDate = res["startDate"],
        finishDate = res["finishDate"];

  Map<String, Object?> toMap() {
    return {'id':id,'name': name, 'startDate': startDate, 'finishDate': finishDate};
  }

  @override
  String toString() {
    return 'Crew{id: $id, name: $name, startDate: $startDate, finishDate: $finishDate, crew: $crewMembers}';
  }
}