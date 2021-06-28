class CrewMemberCrew {

  int? id;
  int crewId;
  int crewMemberId;
  
  CrewMemberCrew({
    this.id,
    required this.crewId,
    required this.crewMemberId,
  });

  CrewMemberCrew.fromMap(Map<String, dynamic> res)
      : id = res["id"],
        crewId = res["crewId"],
        crewMemberId = res["crewMemberId"];

  Map<String, Object?> toMap() {
    return {'id':id,'crewId': crewId, 'crewMemberId': crewMemberId};
  }

  @override
  String toString() {
    return 'Crew{id: $id, crewId: $crewId, crewMemberId: $crewMemberId}';
  }
}