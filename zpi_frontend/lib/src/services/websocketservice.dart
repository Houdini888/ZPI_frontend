import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;


class WebSocketService {
  late WebSocketChannel channel;

  void connect(String username, String groupname) {
    final String url = 'ws://localhost:8080/message?username=$username&groupname=$groupname';
    channel = WebSocketChannel.connect(Uri.parse(url));

    channel.stream.listen((message) {
      print('Received: $message');
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
      channel.sink.close(status.goingAway);
      print('Disconnected from WebSocket');
    }
  }
}
