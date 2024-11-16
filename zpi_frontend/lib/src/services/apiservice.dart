import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zpi_frontend/src/models/user.dart';
import 'package:zpi_frontend/src/models/group.dart';

import '../models/file_data.dart';
import '../models/group_list.dart';

class ApiService {
  static const String baseUrl = "http://localhost:8080";
  static const String secUrl = "https://localhost:8443";

  // for testing purposes only
  final String testGroup = 'testGroup';

  Future<Group> fetchGroupByName(String groupName) async {
    final response =
        await http.get(Uri.parse('$baseUrl/getGroup?group=$groupName'));
    if (response.statusCode == 200) {
      return Group.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load group');
    }
  }

  Future<bool> joinGroup({
    required String username,
    required String token,
    required String instrument,
  }) async {
    final response = await http.post(Uri.parse('$baseUrl/joinGroup?username=$username&token=$token&instrument=$instrument'));

    if (response.statusCode == 200) {
      // Successfully joined the group
      return true;
    } else {
      // Print the error for debugging
      print("Failed to join group: ${response.statusCode} - ${response.body}");
      return false;
    }
  }

  Future<List<GroupList>> fetchAllGroups(String username) async {
    final url = Uri.parse('$baseUrl/getAllGroups?username=$username');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((group) => GroupList.fromJson(group)).toList();
    } else {
      throw Exception('Failed to load groups');
    }
  }

  Future<List<FileData>> fetchAllFiles(String username, String group) async {
    final url =
        Uri.parse('$baseUrl/getAllFiles?username=$username&group=$group');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((file) => FileData.fromJson(file)).toList();
    } else {
      throw Exception('Failed to load files');
    }
  }

  Future<List<User>> fetchUsersInGroup(int groupId) async {
    final response =
        await http.post(Uri.parse('$baseUrl/getUsersInGroup?groupId=$groupId'));
    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((user) => User.fromJson(user)).toList();
    } else {
      throw Exception('Failed to load users for group');
    }
  }

  Future<bool> createGroup(
      {required String group, required String owner}) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/createGroup?group=$group&owner=$owner'));

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Failed to create group: ${response.reasonPhrase}");
        return false;
      }
    } catch (e) {
      print("Error creating group: $e");
      return false;
    }
  }

  static Future<bool> removeMemberfromGroup(
      String memberName, String groupName) async {
    final response = await http.post(Uri.parse(
        '$baseUrl/removeFromGroup?group=$groupName&username=$memberName'));

    if (response.statusCode == 200) {
      return true;
    } else {
      print("Failed to remove member: ${response.reasonPhrase}");
      return false;
    }
  }

  static Future<bool> uploadFile({
    required File file,
    required String memberName,
    required String groupName,
    required String piece,
    required String instrument,
    required String fileType,
  }) async {
    try {
      // Construct URI
      final uri = Uri.parse('$baseUrl/upload');

      // Create a multipart request
      final request = http.MultipartRequest('POST', uri)
        ..fields['username'] = memberName
        ..fields['group'] = groupName
        ..fields['piece'] = piece
        ..fields['instrument'] = instrument
        ..fields['filetype'] = fileType;

      // Add the file to the request
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: basename(file.path),
      ));

      // Send the request
      final response = await request.send();

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Failed to upload file: ${response.reasonPhrase}");
        return false;
      }
    } catch (e) {
      print("Error uploading file: $e");
      return false;
    }
  }

  static Future<String> updateAndGetTokenForGroup(
      String groupname, String username) async {
    final response = await http.post(
        Uri.parse('$baseUrl/updateToken?group=$groupname&username=$username'));

    if (response.statusCode == 200) {
      return response.body;
    } else {
      print("Failed to receive token: ${response.reasonPhrase}");
      return "";
    }
  }

  Future<File?> downloadFile({
    required String username,
    required String group,
    required String piece,
    required String instrument,
  }) async {
    try {
      // Construct the URI with the required parameters
      final url = Uri.parse(
        '$baseUrl/download?username=$username&group=$group&piece=$piece&instrument=$instrument',
      );

      // Send the GET request
      final response = await http.get(url);

      // Check for successful response
      if (response.statusCode == 200) {
        // Retrieve the temporary directory of the device to save the file
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/$piece-$instrument.pdf';

        // Write the response body to a file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        print('File downloaded to: $filePath');
        return file;
      } else {
        print('Failed to download file: ${response.reasonPhrase}');
        return null;
      }
    } catch (e) {
      print('Error downloading file: $e');
      return null;
    }
  }

  Future<List<String>> getAllInstrumentsFromGroup(String groupname) async {
    final response =
        await http.post(Uri.parse('$baseUrl/getAllInstruments?group=$groupname'));
    if (response.statusCode == 200) {
      List<String> jsonResponse = List<String>.from(json.decode(response.body));
      return jsonResponse;
    } else {
      throw Exception('Failed to load list of instruments in group');
    }
  }

  static Future<bool> updateUserInstrument(String admin, String groupname, String member, String instrument) async {
    final response =
        await http.post(Uri.parse('$baseUrl/updateUserInstrument?username=$admin&group=$groupname&musician=$member&instrument=$instrument'));
    if (response.statusCode == 200) {
      return true;
    } else {
      print("Failed to update instrument: ${response.reasonPhrase}");
      return false;
    }
  }

// static Future<bool> addMemberToGroup(String username, String groupname, String instrument) async{
//   final response = await http.post(Uri.parse('$baseUrl/addToGroup?username=$username&group=$groupname&instrument=$instrument'));

//   if (response.statusCode == 200) {
//     return true;
//   }else {
//     print("Failed to add member: ${response.reasonPhrase}");
//     return false;
//   }

// }
}
