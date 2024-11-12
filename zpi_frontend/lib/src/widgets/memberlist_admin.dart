import 'package:flutter/material.dart';
import 'package:zpi_frontend/src/models/user.dart';
import 'package:zpi_frontend/src/services/apiservice.dart';

class MemberListAdmin extends StatefulWidget {

  final List<User> members;
  final String groupname;
  final Function(User) onRemoveMember;

  MemberListAdmin({required this.members, required this.groupname, required this.onRemoveMember});

  @override
  _MemberListAdminState createState() => _MemberListAdminState();
}

class _MemberListAdminState extends State<MemberListAdmin> {
  List<User> localMembers = [];

  @override
  void initState() {
    super.initState();
    localMembers = widget.members;
  }

  @override
  void didUpdateWidget(MemberListAdmin oldWidget) {
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
              title: Row(
                children: [
                  Text(
                      member.username,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  SizedBox(width: 10,),
                  Text(
                    member.instrument,
                    style: TextStyle(color: Colors.brown),
                  ),
                ],
  ),
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
              onPressed: (){
                fetchStringFromBackend(context);
              }, 
              child: Text("Generuj token")),
          );
        }
      }
    ),
  );
}

Future<void> fetchStringFromBackend(BuildContext context) async {
    try {
      String receivedString = await ApiService.updateAndGetTokenForGroup(widget.groupname, 'test1');
      showStringDialog(context, receivedString);
    } 
    catch (error) {
      // showErrorDialog(context, error.toString());
      print(error);
    }
  }

  void showStringDialog(BuildContext context, String data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Token'),
          content: SelectableText(data), // Show the received string
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }



}



