import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:zpi_frontend/src/services/user_data.dart';



class WebSocket_StatusService {
  late WebSocketChannel _channel;
  final StreamController<Map<String, bool>> _statusController = StreamController.broadcast();

  WebSocket_StatusService({required String username, required String group, required String device}) {


    _channel = WebSocketChannel.connect(
      Uri.parse('ws://192.168.248.177:8080/group/message?username=$username&group=$group&device=$device'),
    );

    _channel.stream.listen((message) {
      print(message);
      final data = jsonDecode(message);
      if (data is Map) {
        _statusController.add({data['Username']: data['Ready']});
      } else if (data is List) {
        for (var user in data) {
          _statusController.add({user['Username']: user['Ready']});
        }
      }
    });
  }

  Stream<Map<String, bool>> get statusStream => _statusController.stream;

  void sendMessage(String message) {
  try {
    _channel.sink.add(message);
  } catch (e) {
    print('Error sending message: $e');
  }
}

  void close() {
    _channel.sink.close();
  }
}
