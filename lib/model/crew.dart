class Crew {
  // final int? id;
  // final String name;
  // final int attempts;
  // final String startDate;
  // final String? endDate;

  int? id;
  String name;
  int attempts;
  String startDate;
  String? endDate;

  Crew(
      { this.id,
      required this.name,
      required this.attempts,
      required this.startDate,
      this.endDate});

  Crew.fromMap(Map<String, dynamic> res)
      : id = res["id"],
        name = res["name"],
        attempts = res["attempts"],
        startDate = res["startDate"],
        endDate = res["endDate"];

  Map<String, Object?> toMap() {
    return {'id':id,'name': name, 'attempts': attempts, 'startDate': startDate, 'endDate': endDate};
  }

  @override
  String toString() {
    return 'Crew{id: $id, name: $name, attempts: $attempts, startDate: $startDate}'; //, crewStartDate: $crewStartDate, crewEndDate: $crewEndDate}';
  }
}