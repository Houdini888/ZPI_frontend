import 'package:flutter/material.dart';
import 'package:zpi_frontend/src/models/group.dart';
import 'package:zpi_frontend/src/screens/banddetailsscreen.dart';
import 'package:zpi_frontend/src/services/apiservice.dart';


class BandListScreen extends StatefulWidget {
  @override
  _BandListScreenState createState() => _BandListScreenState();
}

class _BandListScreenState extends State<BandListScreen> {
late Future<Group> _group;

@override
void initState() {
  super.initState();
  _group = ApiService().fetchGroupByName();
}

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bands List'),
      ),
      body: FutureBuilder(
        future: _group, 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('Group not found.'));
          } else {
            final group = snapshot.data!;
            return ListTile(
              title: Text(group.groupName),
              onTap: (){
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => GroupDetailsScreen(group: group)
                    ) 
                  );
              }
            );
          };
        }
        )
    );
  }

}