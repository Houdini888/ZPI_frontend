import 'dart:io';

import 'package:flutter/material.dart';
import 'package:zpi_frontend/src/models/user.dart';
import 'package:zpi_frontend/src/services/apiservice.dart';
import 'package:zpi_frontend/src/widgets/instrument_dropdown.dart';

class MemberListUser extends StatefulWidget {

  final List<User> members;
  final String groupname;
  final Function(User) onRemoveMember;

  MemberListUser({required this.members, required this.groupname, required this.onRemoveMember});

  @override
  _MemberListUserState createState() => _MemberListUserState();
}

class _MemberListUserState extends State<MemberListUser> {
  List<User> localMembers = [];

  

  @override
  void initState(){
    super.initState();
    localMembers = widget.members;
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
              leading: CircleAvatar(
                backgroundImage: AssetImage('assets/images/prof_dziekan.jpg'),
              ),
              title: Row(
                children: [
                  Text(
                      member.username,
                      style: TextStyle(fontWeight: FontWeight.bold),
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



