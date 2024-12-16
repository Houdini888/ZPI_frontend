import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocket_IconService {
  late WebSocketChannel _channel;
  final StreamController<String?> _symbolController = StreamController.broadcast();
  String? _currentSymbol;

  WebSocket_IconService({required String username, required String group, required String device}) {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://4.207.13.58:8080/group/message?username=$username&group=$group&device=$device'),
    );

    _channel.stream.listen((message) {
      final data = jsonDecode(message);
      // We expect data of the form: {"type":"music_symbol","symbol":"ds"} or {"type":"music_symbol","symbol":"koda"}
      if (data is Map && data['type'] == 'music_symbol') {
        _currentSymbol = data['symbol'];
        _symbolController.add(_currentSymbol);
      }
    });
  }

  Stream<String?> get symbolStream => _symbolController.stream;

  void sendSymbol(String symbol) {
    final symbolMessage = jsonEncode({
      'type': 'music_symbol',
      'symbol': symbol
    });
    try {
      _channel.sink.add(symbolMessage);
    } catch (e) {
      print('Error sending symbol: $e');
    }
  }

  void close() {
    _channel.sink.close();
    _symbolController.close();
  }
}
