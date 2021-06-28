class Attempts {

  int? id;
  int crewId;
  int mission;
  int attempts;

  Attempts({
    this.id,
    required this.crewId,
    required this.mission,
    required this.attempts,
  });

  Attempts.fromMap(Map<String, dynamic> res)
      : id = res["id"],
        crewId = res["crewId"],
        mission = res["mission"],
        attempts = res["attempts"];

  Map<String, Object?> toMap() {
    return {'id':id, 'crewId': crewId, 'mission': mission, 'attempts': attempts};
  }

  @override
  String toString() {
    return 'Crew{id: $id, crewId: $crewId, mission: $mission, attempts: $attempts}';
  }
}