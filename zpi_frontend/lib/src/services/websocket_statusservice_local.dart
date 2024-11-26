import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocket_StatusService {
  late WebSocketChannel _channel;
  final StreamController<Map<String, bool>> _statusController = StreamController.broadcast();
  Map<String, bool> _statuses = {};

  WebSocket_StatusService({required String username, required String group}) {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:8080/message?username=$username&group=$group'),
    );

    requestStatus();

    _channel.stream.listen((message) {
      final data = jsonDecode(message);

      if (data is Map) {
        _statuses[data['Username']] = data['Ready'];
        _statusController.add({..._statuses});
      } else if (data is List) {
        _statuses.clear();

        // for (var user in data) {
          _statuses = _deduplicateStatuses(data);
          // _statuses[user['Username']] = user['Ready'];
        // }
        print(_statuses);
        _statusController.add({..._statuses});
      }
    });
  }

  Map<String, bool> _deduplicateStatuses(List<dynamic> statusList) {
    Map<String, bool> latestStatuses = {};
    for (var status in statusList) {
      latestStatuses[status['Username']] = status['Ready'];
    }
    return latestStatuses;
  }

  Stream<Map<String, bool>> get statusStream => _statusController.stream;

  void sendMessage(String message) {
  try {
    _channel.sink.add(message);
  } catch (e) {
    print('Error sending message: $e');
  }
}

 void requestStatus() {
    sendMessage('status');
  }

  void close() {
    _channel.sink.close();
  }
}
