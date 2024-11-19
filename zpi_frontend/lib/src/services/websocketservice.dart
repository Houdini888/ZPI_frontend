import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  late WebSocketChannel _channel;
  final StreamController<Map<String, bool>> _statusController = StreamController.broadcast();

  WebSocketService({required String username, required String group}) {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:8080/message?username=$username&group=$group'),
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
