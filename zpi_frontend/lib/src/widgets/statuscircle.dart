import 'package:flutter/material.dart';
import 'package:zpi_frontend/src/services/websocketservice.dart';

class StatusCircle extends StatefulWidget {
  final String username;
  final WebSocketService webSocketService;
  final String loggedInUsername; // Add the logged-in username as a parameter.

  const StatusCircle({
    required this.username,
    required this.webSocketService,
    required this.loggedInUsername,
    Key? key,
  }) : super(key: key);

  @override
  _StatusCircleState createState() => _StatusCircleState();
}

class _StatusCircleState extends State<StatusCircle> {
  bool _isReady = false;

  @override
  void initState() {
    super.initState();

    widget.webSocketService.statusStream.listen((statuses) {
      if (statuses.containsKey(widget.username)) {
        setState(() {
          _isReady = statuses[widget.username]!;
        });
      }
    });
  }

  void _toggleStatus(bool newStatus) {
    if (widget.username != widget.loggedInUsername) {
      return;
    }

    // Send plain text "ready" or "unready" to the server.
    String message = newStatus ? 'ready' : 'unready';
    widget.webSocketService.sendMessage(message);

    setState(() {
      _isReady = newStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    Color circleColor = _isReady ? Colors.green : Colors.yellow;

    return GestureDetector(
      onTap: widget.username == widget.loggedInUsername
          ? () async {
              bool? selected = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Change Status'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: Icon(Icons.check, color: Colors.green),
                          title: Text('Ready'),
                          onTap: () => Navigator.pop(context, true),
                        ),
                        ListTile(
                          leading: Icon(Icons.close, color: Colors.yellow),
                          title: Text('Unready'),
                          onTap: () => Navigator.pop(context, false),
                        ),
                      ],
                    ),
                  );
                },
              );

              if (selected != null) {
                _toggleStatus(selected);
              }
            }
          : null, // Disable interaction if not the logged-in user.
      child: Container(
        width: 20.0,
        height: 20.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: circleColor,
        ),
      ),
    );
  }
}
