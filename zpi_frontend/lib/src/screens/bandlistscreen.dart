import 'package:flutter/material.dart';
import 'package:zpi_frontend/src/models/group.dart';
import 'package:zpi_frontend/src/screens/banddetailsscreen_in_work.dart';
import 'package:zpi_frontend/src/services/apiservice.dart';

import '../widgets/app_drawer_menu.dart';

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
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: Builder(
            builder: (context) => IconButton(
              icon: new Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),

          ),
          title: Text('Bands List'),
        ),
        drawer: AppDrawer(),
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
                return Card(
                  color: Colors.grey,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  GroupDetailsScreen(group: group)));
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/band_pf.jpg',
                          fit: BoxFit.fill,
                        ),
                        Text(
                          group.groupName,
                          style: const TextStyle(fontSize: 30),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }));
  }
}
