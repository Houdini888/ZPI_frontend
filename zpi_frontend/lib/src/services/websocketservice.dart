import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:async';


class WebSocketService {
  late WebSocketChannel channel;
  final StreamController<String> _statusController = StreamController<String>.broadcast();

  Stream<String> get statusStream => _statusController.stream;

  void connect(String username, String groupname) {
    final String url = 'ws://localhost:8080/message?username=$username&group=$groupname';
    channel = WebSocketChannel.connect(Uri.parse(url));

  channel.stream.listen((message) {
    print('Received: $message');
    _statusController.add(message);
  }, onDone: () {
    print('WebSocket connection closed');
  }, onError: (error) {
    print('Error: $error');
  });
  }

  void sendMessage(String message) {
    if (channel != null) {
      channel.sink.add(message);
      print('Sent: $message');
    }
  }

  void disconnect() {
    if (channel != null) {
      channel.sink.close(status.normalClosure);
      print('Disconnected from WebSocket');
    }
    _statusController.close();
  }
}
