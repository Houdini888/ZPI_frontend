import 'package:flutter/material.dart';
import 'package:zpi_frontend/src/models/member.dart';

class Memberlist extends StatelessWidget {

  late List<dynamic> members;

  Memberlist({required this.members});

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text("Band members"),
      automaticallyImplyLeading: false,
    ),
    body: ListView.builder(
      itemCount: members.length+1,
      itemBuilder: (context, index) {
        if (index < members.length) {
          final member = members[index];
          return Column(
            children: <Widget> [
              ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage('assets/images/prof_dziekan.jpg'),
              ),
              title: Text(members[index]),
              trailing: ElevatedButton(
                onPressed: (){},
                child: Text("Usuń członka")),
              onTap: () {},
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