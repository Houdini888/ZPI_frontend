import 'package:zpi_frontend/src/models/user.dart';

class Group {
  final int groupId;
  final String groupName;
  final List<User> users;

  Group({required this.groupId, required this.groupName, required this.users});

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      groupId: json['groupID'],
      groupName: json['groupname'],
      users: getUserList(json)
    );
  }

  static List<User> getUserList (Map<String, dynamic> json) {
    var userList = json['users'] as List;
    List<User> users = userList.map((userJson) => User.fromJson(userJson)).toList();
    return users;
  }


}