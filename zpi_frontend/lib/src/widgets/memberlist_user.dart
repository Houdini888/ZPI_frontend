import 'dart:io';

import 'package:flutter/material.dart';
import 'package:zpi_frontend/src/models/user.dart';
import 'package:zpi_frontend/src/services/apiservice.dart';
import 'package:zpi_frontend/src/services/user_data.dart';
import 'package:zpi_frontend/src/services/websocketservice.dart';
import 'package:zpi_frontend/src/widgets/instrument_dropdown.dart';
import 'package:zpi_frontend/src/widgets/statuscircle.dart';

class MemberListUser extends StatefulWidget {

  final List<User> members;
  final String groupname;
  final String admin;
  final Function(User) onRemoveMember;

  MemberListUser({required this.members, required this.groupname, required this.onRemoveMember, required this.admin});

  @override
  _MemberListUserState createState() => _MemberListUserState();
}

class _MemberListUserState extends State<MemberListUser> {
  List<User> localMembers = [];
  late String user = '';
  late WebSocketService _webSocketService;

  Future<void> _loadAsync() async {
    user = (await UserPreferences.getUserName())!;
    setState(() {});
  }

  @override
  void initState(){
    super.initState();
    _loadAsync();
    localMembers = widget.members;
    _webSocketService = WebSocketService(
      username: 'test1',
      group: widget.groupname,
    );
  }

  @override
  void didUpdateWidget(MemberListUser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.members != widget.members) {
      setState(() {
        localMembers = widget.members; // Update local list if parent list changes
      });
    }
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text("Band members"),
      automaticallyImplyLeading: false,
    ),
    body: ListView.builder(
      itemCount: localMembers.length,
      itemBuilder: (context, index) {
          final member = localMembers[index];
          return Column(
            children: <Widget> [
              ListTile(
              leading: StatusCircle(username: member.username, webSocketService: _webSocketService, loggedInUsername: user,),
              title: Row(
                children: [
                  Text(
                      member.username,
                    style: member.username == widget.admin?TextStyle(fontWeight: FontWeight.bold, color: Colors.amber): TextStyle(fontWeight: FontWeight.bold),
                    ),
                  SizedBox(width: 10,),
                  Text(
                    member.instrument,
                  )

                ],
              ),
              onTap: () {}
            ),
            Divider(),
            ],
          );
      }
    ),
  );
}


}



