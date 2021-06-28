class CrewMember {

  int? id;
  String name;
  
  CrewMember({
    this.id,
    required this.name
  });

  CrewMember.fromMap(Map<String, dynamic> res)
      : id = res["id"],
        name = res["name"];

  Map<String, Object?> toMap() {
    return {'id':id,'name': name};
  }

  @override
  String toString() {
    return 'Crew{id: $id, name: $name}';
  }
}