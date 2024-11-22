import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();

  WebSocketChannel? channel; // Make channel nullable
  final StreamController<String> _messageController = StreamController<String>.broadcast();
  final StreamController<String> _statusController = StreamController<String>.broadcast();

  WebSocketService._internal();

  factory WebSocketService() => _instance;

  // Streams for listening to messages and status updates
  Stream<String> get messageStream => _messageController.stream;

  Stream<String> get statusStream => _statusController.stream;

  void connect(String username, String groupname) {
    final String url = 'ws://192.168.224.177:8080/message?username=$username&group=$groupname';

    // Close any existing connection
    disconnect();

    try {
      channel = WebSocketChannel.connect(Uri.parse(url));
      print('Connected to WebSocket at $url');

      // Listen for messages
      channel!.stream.listen(
            (data) {
          print('Received: $data');

          if (data is String &&
              !data.contains('status') &&
              !data.contains('Unready') &&
              !data.contains('Ready') &&
              data != '200') {
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
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      _statusController.add('error: $e');
      _reconnect(username, groupname);
    }
  }

  void sendMessage(String message) {
    if (channel != null) {
      try {
        channel!.sink.add(message);
        print('Sent: $message');
      } catch (e) {
        print('Error sending message: $e');
        _statusController.add('error sending message: $e');
      }
    } else {
      print('WebSocket is not connected.');
    }
  }

  void disconnect() {
    if (channel != null) {
      channel!.sink.close(status.normalClosure);
      channel = null; // Nullify the channel
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
