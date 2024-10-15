import 'package:flutter/material.dart';
import 'package:zpi_frontend/src/models/member.dart';

class Memberlist extends StatelessWidget {

  final List<Member> members = [
    Member(name: "Big", surname: "Dziekan", imageUrl: 'images/prof_dziekan.jpg'),
    Member(name: "Yung", surname: "Dean", imageUrl: 'images/prof_dziekan.jpg'),
    Member(name: "P.", surname: "Deanny", imageUrl: 'images/prof_dziekan.jpg')
  ];

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
                backgroundImage: AssetImage(member.imageUrl),
              ),
              title: Text('${member.name} ${member.surname}'),
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