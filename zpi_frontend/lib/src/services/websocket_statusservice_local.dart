import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:zpi_frontend/src/services/user_data.dart';

class WebSocket_StatusService {
  late WebSocketChannel _channel;
  final StreamController<Map<String, bool>> _statusController = StreamController.broadcast();
  Map<String, bool> _statuses = {};
  // final String username;

  WebSocket_StatusService({required String username, required String group, required String device}) {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://4.207.13.58:8080/group/message?username=$username&group=$group&device=$device'),
    );

    requestStatus();

    _channel.stream.listen((message) {
      final data = jsonDecode(message);

      if (data is Map) {
        _statuses[data['Username']] = data['Ready'];
        _statusController.add({..._statuses});
      } else if (data is List) {

          Map<String, bool> receivedStatuses = _deduplicateStatuses(data);
          print(username);
          receivedStatuses.remove(username);
           _statuses.addAll(receivedStatuses);
          _statusController.add({..._statuses});
      }
    });
  }

  Future<void> initialize() async {
    bool? storedStatus = await UserPreferences.getUserStatus();
    if (storedStatus != null) {
      String message = storedStatus ? 'ready' : 'unready';
      sendMessage(message);
    }

    requestStatus();
  }

  Map<String, bool> _deduplicateStatuses(List<dynamic> statusList) {
    Map<String, bool> latestStatuses = {};
    for (var status in statusList) {
      latestStatuses[status['Username']] = status['Ready'];
    }
    print('before decoupling: $statusList');
    print('after decoupling: $latestStatuses');
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

  void setReadyStatus(bool isReady) {
    String message = isReady ? 'ready' : 'unready';
    sendMessage(message);
  }

  void close() {
    _channel.sink.close();
    _statusController.close();
  }
}
