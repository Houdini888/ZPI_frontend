import 'package:flutter/material.dart';
import 'package:zpi_frontend/src/screens/bandlistscreen.dart';
import 'package:zpi_frontend/src/screens/library_main.dart';
import 'package:zpi_frontend/src/screens/setlists_main.dart';
import 'package:zpi_frontend/src/widgets/app_drawer_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text('Home Page'),
      ),
      drawer: AppDrawer(),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      children: [
        Center(
          child: Card(
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => BandListScreen()));
              },
              child: const SizedBox(
                child: Column(
                  children: [
                    Icon(Icons.groups, size: 150),
                    Text('Bands', style: TextStyle(fontSize: 25)),
                  ],
                ),
              ),
            ),
          ),
        ),
        Center(
          child: Card(
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => LibraryMainPage(title: 'Library')));
              },
              child: const SizedBox(
                child: Column(
                  children: [
                    Icon(Icons.library_music_outlined, size: 150),
                    Text('Library', style: TextStyle(fontSize: 25)),
                  ],
                ),
              ),
            ),
          ),
        ),
        Center(
          child: Card(
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              onTap: () {
                debugPrint('Card tapped.');
              },
              child: const SizedBox(
                child: Column(
                  children: [
                    Icon(Icons.settings, size: 150),
                    Text('Settings', style: TextStyle(fontSize: 25)),
                  ],
                ),
              ),
            ),
          ),
        ),
        Center(
          child: Card(
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => SetlistsMain()));
              },
              child: const SizedBox(
                child: Column(
                  children: [
                    Icon(Icons.list_alt_sharp, size: 150),
                    Text('Setlists', style: TextStyle(fontSize: 25)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
