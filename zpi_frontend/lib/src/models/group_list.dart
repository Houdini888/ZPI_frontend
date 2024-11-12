class GroupList {
  final int groupID;
  final String groupName;
  final String owner;
  final String entryCode;

  GroupList({required this.groupID, required this.groupName, required this.owner, required this.entryCode});

  factory GroupList.fromJson(Map<String, dynamic> json) {
    return GroupList(
      groupID: json['groupID'],
      groupName: json['groupName'],
      owner: json['owner'],
      entryCode: json['entryCode'],
    );
  }
}