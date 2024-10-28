class Group {
  final int groupId;
  final String groupName;
  final List<dynamic> users;

  Group({required this.groupId, required this.groupName, required this.users});

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      groupId: json['groupID'],
      groupName: json['groupname'],
      users: json['users']
    );
  }
}