import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zpi_frontend/src/models/user.dart';
import 'package:zpi_frontend/src/models/group.dart';

class ApiService {
  final String baseUrl = "http://localhost:8080";
  // for testing purposes only
  final String testGroup = 'testGroup';

  //later version
  // Future<Group> fetchGroupByName(String groupName) async {
  //   final response = await http.get(Uri.parse('$baseUrl/getGroups?group=$groupName'));
  //   if (response.statusCode == 200) {
  //     return Group.fromJson(json.decode(response.body));
  //   } else {
  //     throw Exception('Failed to load groups');
  //   }
  // }

    Future<Group> fetchGroupByName() async {
    final response = await http.get(Uri.parse('http://localhost:8080/getGroup?group=testGroup'));
    if (response.statusCode == 200) {
      return Group.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load groups');
    }
  }

  Future<List<User>> fetchUsersInGroup(int groupId) async {
    final response = await http.get(Uri.parse('$baseUrl/getUsersInGroup?groupId=$groupId'));
    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((user) => User.fromJson(user)).toList();
    } else {
      throw Exception('Failed to load users for group');
    }
  }
}
