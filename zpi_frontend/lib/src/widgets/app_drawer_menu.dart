import 'package:flutter/material.dart';
import 'package:zpi_frontend/src/screens/library_main.dart';
import 'package:zpi_frontend/src/screens/bandlistscreen.dart';
import 'package:zpi_frontend/src/screens/setlists_main.dart';
import 'package:zpi_frontend/src/services/user_data.dart';

import '../../login.dart';

class AppDrawer extends StatefulWidget {
  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Drawer Header
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme
                  .of(context)
                  .colorScheme
                  .inversePrimary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 40,
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 10),
                FutureBuilder<String?>(
                  future: UserPreferences.getUserName(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text(
                        "Loading...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    } else if (snapshot.hasData && snapshot.data != null) {
                      return Text(
                        snapshot.data!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    } else {
                      return Text(
                        "No username",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // List of menu items
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () {
              Navigator.popUntil(context, (route) => route.isFirst);
              // Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.library_music_outlined),
            title: Text('Library'),
            onTap: () {
              Navigator.popUntil(context, (route) => route.isFirst); // Close the drawer
              Navigator.push(context, MaterialPageRoute(builder: (context)=> LibraryMainPage(title: 'Library',)));
            },
          ),
          ListTile(
            leading: Icon(Icons.groups),
            title: Text('Bands'),
            onTap: () {
              Navigator.popUntil(context, (route) => route.isFirst);
              Navigator.push(context, MaterialPageRoute(builder: (context)=> BandListScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
          ListTile(
            leading: Icon(Icons.list_alt_sharp),
            title: Text('Setlists'),
            onTap: () {
              Navigator.popUntil(context, (route) => route.isFirst);
              Navigator.push(context, MaterialPageRoute(builder: (context)=> SetlistsMain()));
            },
          ),
          Divider(), // Add a horizontal divider

          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () async {
              await UserPreferences.clearUserName(); // Clear the stored username
              await UserPreferences.clearActiveGroup(); // Clear the stored username
              await UserPreferences.clearActiveGroupInstrument(); // Clear the stored username
              Navigator.popUntil(context, (route) => route.isFirst); // Close the drawer
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen())); // Go to login
            },
          ),
        ],
      ),
    );
  }
}
