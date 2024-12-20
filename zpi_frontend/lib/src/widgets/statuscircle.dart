import 'package:flutter/material.dart';
import 'package:zpi_frontend/src/services/user_data.dart';
import 'package:zpi_frontend/src/services/websocket_statusservice_local.dart';

class StatusCircle extends StatefulWidget {
  final String username;
  final WebSocket_StatusService ws_StatusService;
  final String loggedInUsername;

  const StatusCircle({
    required this.username,
    required this.ws_StatusService,
    required this.loggedInUsername,
    Key? key,
  }) : super(key: key);

  @override
  _StatusCircleState createState() => _StatusCircleState();
}

class _StatusCircleState extends State<StatusCircle> {
  bool? _isReady = false;
  // late bool? _isCurrentUserReady;

  @override
  void initState() {
    super.initState();


    if (widget.username == widget.loggedInUsername) {
      _loadStoredStatus();
    }

      widget.ws_StatusService.statusStream.listen((statuses) {
      if (statuses.containsKey(widget.username)) {
        setState(() {
          _isReady = statuses[widget.username]!;
        });
      }
    });

  }

  void _loadStoredStatus() async {
    bool? storedStatus = await UserPreferences.getUserStatus();
    print('stored status: $storedStatus');
    if (storedStatus != null && storedStatus == true) {

      // widget.ws_StatusService.sendMessage('ready');

      if (storedStatus != null){
          setState(() {
          _isReady = storedStatus;
      });
      }

    }
  }

  void _toggleStatus(bool newStatus) async {
    if (widget.username != widget.loggedInUsername) {
      return;
    }

    String message = newStatus ? 'ready' : 'unready';
    widget.ws_StatusService.sendMessage(message);

    await UserPreferences.setUserStatus(newStatus);

    setState(() {
      _isReady = newStatus;

    });
  }

  @override
  Widget build(BuildContext context) {
    Color circleColor;
    if (_isReady == null) {
      circleColor = Colors.grey; // Unknown or loading state
    } else if (_isReady == true) {
      circleColor = Colors.green; // Ready
    } else {
      circleColor = Colors.yellow; // Unready
    }

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
        width: 30.0,
        height: 30.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: circleColor,
        ),
      ),
    );
  }
}
