import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();

  late WebSocketChannel channel;
  final StreamController<String> _messageController = StreamController<String>.broadcast();
  final StreamController<String> _statusController = StreamController<String>.broadcast();


  WebSocketService._internal();

  factory WebSocketService() => _instance;

  // Streams for listening to messages and status updates
  Stream<String> get messageStream => _messageController.stream;
  Stream<String> get statusStream => _statusController.stream;

  void connect(String username, String groupname) {
    final String url = 'ws://192.168.224.177:8080/message?username=$username&group=$groupname';
    channel = WebSocketChannel.connect(Uri.parse(url));

    print('Connected to WebSocket at $url');

    // Listen for messages
    channel.stream.listen(
          (data) {
        print('Received: $data');

        if (data is String && !data.contains('status') && data != '200') { // Example filter
          _messageController.add(data); // Add the message to the stream
        }
      },
      onDone: () {
        print('WebSocket connection closed');
        _statusController.add('disconnected');
        _reconnect(username, groupname);
      },
      onError: (error) {
        print('Error: $error');
        _statusController.add('error: $error');
        _reconnect(username, groupname);
      },
    );
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
  }

  void _reconnect(String username, String groupname) {
    Future.delayed(const Duration(seconds: 5), () {
      print('Reconnecting...');
      connect(username, groupname);
    });
  }

}
