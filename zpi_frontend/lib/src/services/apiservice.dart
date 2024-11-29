import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zpi_frontend/src/models/user.dart';
import 'package:zpi_frontend/src/models/group.dart';
import 'package:zpi_frontend/src/services/user_data.dart';
import '../models/file_data.dart';
import '../models/group_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://192.168.248.177:8080";
  static const String authUrl = "http://192.168.224.177:8081";

  Future<String> _getDeviceCode() async {
    return await UserPreferences.getSessionCode() ?? '';
  }

  Future<Group> fetchGroupByName(String groupName, String username) async {
    final device = await _getDeviceCode();
    final response = await http.get(
      Uri.parse('$baseUrl/group/getGroup?group=$groupName&username=$username&device=$device'),
    );
    if (response.statusCode == 200) {
      return Group.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load group');
    }
  }

  Future<bool> joinGroup({
    required String username,
    required String token,
  }) async {
    final device = await _getDeviceCode();
    final response = await http.post(
      Uri.parse('$baseUrl/user/joinGroup?username=$username&token=$token&device=$device'),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      print("Failed to join group: ${response.statusCode} - ${response.body}");
      return false;
    }
  }

  Future<List<GroupList>> fetchAllGroups(String username) async {
    final device = await _getDeviceCode();
    final response = await http.get(
      Uri.parse('$baseUrl/user/getAllGroups?username=$username&device=$device'),
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((group) => GroupList.fromJson(group)).toList();
    } else {
      throw Exception('Failed to load groups');
    }
  }

  Future<List<FileData>> fetchAllFiles(String username, String group) async {
    final device = await _getDeviceCode();
    final response = await http.get(
      Uri.parse('$baseUrl/group/getAllFiles?username=$username&group=$group&device=$device'),
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((file) => FileData.fromJson(file)).toList();
    } else {
      throw Exception('Failed to load files');
    }
  }


  Future<bool> updateBpm(String group, String piece, String bpm) async {

    try {

      final device = await _getDeviceCode();
      final response = await http.post(
          Uri.parse('$baseUrl/groupOwner/updateBpm?group=$group&piece=$piece&bpm=$bpm&device=$device'),
      );

      if (response.statusCode == 200) {
        print('BPM updated successfully');
        return true;
      } else {
        print('Failed to update BPM: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error in updateBpm: $e');
      return false;
    }
  }

  Future<bool> createUser(String username, String password) async {
    final device = await _getDeviceCode();
    final response = await http.post(
      Uri.parse('$baseUrl/guest/createUser?username=$username&password=$password&device=$device'),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      print("Failed to create user: ${response.statusCode} - ${response.body}");
      return false;
    }
  }

  Future<bool> removeMemberFromGroup({
    required String username,
    required String groupName,
  }) async {
    final device = await _getDeviceCode();
    final response = await http.post(
      Uri.parse('$baseUrl/group/removeFromGroup?username=$username&group=$groupName&device=$device'),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      print("Failed to remove member: ${response.reasonPhrase}");
      return false;
    }
  }

  Future<bool> createGroup({
    required String group,
    required String owner,
  }) async {
    final device = await _getDeviceCode();
    final response = await http.post(
      Uri.parse('$baseUrl/user/createGroup?group=$group&owner=$owner&device=$device'),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      print("Failed to create group: ${response.reasonPhrase}");
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
    required String bmp,
  }) async {
    try {
      final device = await UserPreferences.getSessionCode() ?? '';
      final uri = Uri.parse('$baseUrl/groupOwner/upload?device=$device');

      final request = http.MultipartRequest('POST', uri)
        ..fields['username'] = memberName
        ..fields['group'] = groupName
        ..fields['piece'] = piece
        ..fields['instrument'] = instrument
        ..fields['filetype'] = fileType
        ..fields['bmp'] = bmp;

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: basename(file.path),
      ));

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

  Future<File?> downloadFile({
    required String username,
    required String group,
    required String piece,
    required String instrument,
  }) async {
    final device = await _getDeviceCode();
    final url = Uri.parse(
      '$baseUrl/group/download?username=$username&group=$group&piece=$piece&instrument=$instrument&device=$device',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$piece-$instrument.pdf';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      print('File downloaded to: $filePath');
      return file;
    } else {
      print('Failed to download file: ${response.reasonPhrase}');
      return null;
    }
  }

  Future<bool> removeUser(String username) async {
    final device = await _getDeviceCode();
    final response = await http.post(
      Uri.parse('$baseUrl/user/removeUser?username=$username&device=$device'),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      print("Failed to remove user: ${response.reasonPhrase}");
      return false;
    }
  }

  Future<bool> updateUserInstrument(
      String username, String group, String musician, String instrument) async {
    final device = await _getDeviceCode();
    final response = await http.post(
      Uri.parse(
          '$baseUrl/group/updateUserInstrument?username=$username&group=$group&musician=$musician&instrument=$instrument&device=$device'),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      print("Failed to update instrument: ${response.reasonPhrase}");
      return false;
    }
  }

  Future<bool> removeFromGroupByInstrument({
    required String username,
    required String group,
    required String instrument,
  }) async {
    final device = await _getDeviceCode();
    final response = await http.post(
      Uri.parse(
          '$baseUrl/group/removeFromGroupByInstrument?username=$username&group=$group&instrument=$instrument&device=$device'),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      print("Failed to remove user by instrument: ${response.reasonPhrase}");
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    final device = await _getDeviceCode();
    final response = await http.post(
      Uri.parse('$baseUrl/login/me?username=$username&password=$password&device=$device'),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      print("Failed to log in: ${response.reasonPhrase}");
      return false;
    }
  }

  Future<List<String>> getAllInstrumentsFromGroup(String groupName, String username) async {
    final device = await _getDeviceCode();
    final response = await http.get(
      Uri.parse('$baseUrl/group/getAllInstruments?group=$groupName&username=$username&device=$device'),
    );
    if (response.statusCode == 200) {
      return List<String>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load list of instruments in group');
    }
  }

  Future<String> updateToken({
    required String group,
    required String owner,
  }) async {
    final device = await _getDeviceCode();
    final response = await http.get(
      Uri.parse('$baseUrl/groupOwner/updateToken?group=$group&username=$owner&device=$device'),
    );
    if (response.statusCode == 200) {
      return response.body; // Assuming the response body contains the token as a string
    } else {
      print("Failed to update token: ${response.reasonPhrase}");
      throw Exception('Failed to update token');
    }
  }

  Future<bool> removeToken({
    required String group,
    required String owner,
  }) async {
    final device = await _getDeviceCode();
    final response = await http.post(
      Uri.parse('$baseUrl/groupOwner/removeToken?group=$group&username=$owner&device=$device'),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      print("Failed to remove token: ${response.reasonPhrase}");
      return false;
    }
  }

  Future<List<String>> getUserInstrument({
    required String group,
    required String username,
  }) async {
    final device = await _getDeviceCode();
    final response = await http.get(
      Uri.parse('$baseUrl/group/getInstrument?group=$group&username=$username&device=$device'),
    );
    if (response.statusCode == 200) {
      return List<String>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to retrieve instruments for user');
    }
  }

  Future<File?> downloadGroup({
    required String group,
    required String owner,
  }) async {
    final device = await _getDeviceCode();
    final response = await http.get(
      Uri.parse('$baseUrl/groupOwner/downloadGroup?group=$group&username=$owner&device=$device'),
    );
    if (response.statusCode == 200) {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$group.zip';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      print('Group file downloaded to: $filePath');
      return file;
    } else {
      print('Failed to download group: ${response.reasonPhrase}');
      return null;
    }
  }
}
