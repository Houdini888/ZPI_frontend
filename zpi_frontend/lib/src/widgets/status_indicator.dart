import 'package:flutter/material.dart';
import 'package:zpi_frontend/src/services/websocketservice.dart';

class StatusIndicator extends StatefulWidget {
  final WebSocketService webSocketService;

  const StatusIndicator({Key? key, required this.webSocketService}) : super(key: key);

  @override
  _StatusIndicatorState createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: widget.webSocketService.statusStream,
      builder: (context, snapshot) {
        Color circleColor = Colors.grey; // Default color

        if (snapshot.hasData) {
          switch (snapshot.data) {
            case 'ready':
              circleColor = Colors.green;
              break;
            case 'unready':
              circleColor = Colors.red;
              break;
            case 'status':
              circleColor = Colors.blue;
              break;
            default:
              circleColor = Colors.yellow;
              break;
          }
        }

          return Container(
            width: 50, // Circle size
            height: 50, // Circle size
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
          );
      },
    );
  }
}
