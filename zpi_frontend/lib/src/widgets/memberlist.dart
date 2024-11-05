import 'package:flutter/material.dart';
import 'package:zpi_frontend/src/models/user.dart';
import 'package:zpi_frontend/src/services/apiservice.dart';

class MemberList extends StatefulWidget {

  final List<User> members;
  final String groupname;
  final Function(User) onRemoveMember;

  MemberList({required this.members, required this.groupname, required this.onRemoveMember});

  @override
  _MemberListState createState() => _MemberListState();
}

class _MemberListState extends State<MemberList> {
  List<User> localMembers = [];

  @override
  void initState() {
    super.initState();
    localMembers = widget.members;
  }

  @override
  void didUpdateWidget(MemberList oldWidget) {
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
      itemCount: localMembers.length+1,
      itemBuilder: (context, index) {
        if (index < localMembers.length) {
          final member = localMembers[index];
          return Column(
            children: <Widget> [
              ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage('assets/images/prof_dziekan.jpg'),
              ),
              title: Text(member.username),
              trailing: ElevatedButton(
                onPressed: () => widget.onRemoveMember(localMembers[index]),
                child: Text("Usuń członka")
                ),
              onTap: () {}
            ),
            Divider(),
            ],
          );
        } else {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              //TODO: Adding members
              onPressed: (){}, 
              child: Text("Dodaj członków")),
          );
        }
      }
    ),
  );
}
}



