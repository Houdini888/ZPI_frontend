import 'package:flutter/material.dart';
import 'package:zpi_frontend/src/screens/bandlistscreen.dart';
import 'package:zpi_frontend/src/screens/library_main.dart';
import 'package:zpi_frontend/src/widgets/app_drawer_menu.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Little Conductor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
        title: Text(widget.title),
      ),
      drawer: AppDrawer(),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      // Generate 100 widgets that display their index in the List.
      children: [
        Center(
          child: Card(
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=> BandListScreen()));
              },
              child: const SizedBox(
                child: Column(
                    children: [
                      Icon(Icons.groups, size: 150,),
                      Text('Bands',
                        style: TextStyle(fontSize: 25),)
                    ]
                )
              ),
            ),
          ),
        ),
        Center(
          child: Card(
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=> LibraryMainPage(title: 'Library',)));
              },
              child: const SizedBox(
                child: Column(
                    children: [
                      Icon(Icons.library_music_outlined, size: 150,),
                      Text('Library',
                        style: TextStyle(fontSize: 25),)
                    ]
                )
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
                      Icon(Icons.settings, size: 150,),
                      Text('Settings',
                        style: TextStyle(fontSize: 25),)
                    ]
                )
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
                child:
                  Column(
                    children: [
                      Icon(Icons.list_alt_sharp, size: 150,),
                      Text('Setlists',
                      style: TextStyle(fontSize: 25),)
                    ]
                  )
              ),
            ),
          ),
        ),
      ],
    );
  }
}
