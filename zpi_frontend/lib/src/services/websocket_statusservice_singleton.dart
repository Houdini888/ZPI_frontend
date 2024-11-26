import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocket_StatusService {
  // Private constructor
  WebSocket_StatusService._internal();

  // Singleton instance
  static final WebSocket_StatusService _instance = WebSocket_StatusService._internal();

  // Factory constructor
  factory WebSocket_StatusService() {
    return _instance;
  }

  late WebSocketChannel _channel;
  final StreamController<Map<String, bool>> _statusController = StreamController.broadcast();
  Map<String, bool> _statuses = {};
  String? _username;
  String? _group;

  bool _isInitialized = false;

  // Initialize method to set up connection
  void initialize({required String username, required String group}) {
    if (_isInitialized) return; // Prevent re-initialization
    _username = username;
    _group = group;

    _channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:8080/message?username=$_username&group=$_group'),
    );

    requestStatus();

    _channel.stream.listen((message) {
      final data = jsonDecode(message);

      if (data is Map) {
        _statuses[data['Username']] = data['Ready'];
        _statusController.add({..._statuses});
      } else if (data is List) {
        _statuses = _deduplicateStatuses(data);
        print(_statuses);
        _statusController.add({..._statuses});
      }
    }, onError: (error) {
      print('WebSocket Error: $error');
    }, onDone: () {
      print('WebSocket Connection Closed');
      // Optionally, implement reconnection logic here
    });

    _isInitialized = true;
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
    _statusController.close();
  }
}
