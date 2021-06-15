class Crew {
  // final int? id;
  // final String name;
  // final String startDate;
  // final String? endDate;

  int? id;
  String name;
  String startDate;
  String? finishDate;

  Crew(
      { this.id,
      required this.name,
      required this.startDate,
      this.finishDate});

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
    return 'Crew{id: $id, name: $name, startDate: $startDate}'; //, crewStartDate: $crewStartDate, crewEndDate: $crewEndDate}';
  }
}