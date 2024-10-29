import 'package:flutter/material.dart';
import 'package:zpi_frontend/src/services/apiservice.dart';

class MemberList extends StatefulWidget {

  final List<dynamic> members;
  final String groupname;
  final Function(String) onRemoveMember;

  MemberList({required this.members, required this.groupname, required this.onRemoveMember});

  @override
  _MemberListState createState() => _MemberListState();
}

class _MemberListState extends State<MemberList> {
  List<dynamic> localMembers = [];

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

  // Future<void> removeMember(String memberName) async{
  //   print('removing $memberName from ${widget.groupname}');
  //   bool success = await ApiService.removeMemberfromGroup(memberName, widget.groupname);

  //   if(success) {
  //     setState(() {
  //       members = members.where((member) => member['username'] != memberName).toList();
  //     });
  //     print('User $memberName removed successfully');
  //   }else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text('Failed to remove member')),
  //     );
  //   }
  // }

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
              title: Text(member),
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



