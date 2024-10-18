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
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return Column(
          children: <Widget> [
            ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage(member.imageUrl),
            ),
            title: Text('${member.name} ${member.surname}'),
            onTap: () {
              // TODO
              // Navigate to the MemberDetailsScreen when tapped
            },
          ),
          Divider(),
          ],
        );
      }
      ),
  );
}
}