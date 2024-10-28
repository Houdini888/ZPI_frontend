import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zpi_frontend/src/screens/setlist_preview.dart';

import '../widgets/app_drawer_menu.dart';

class SetlistsMain extends StatefulWidget {
  const SetlistsMain({super.key});

  @override
  SharedPreferencesDemoState createState() => SharedPreferencesDemoState();
}

class SharedPreferencesDemoState extends State<SetlistsMain> {
  final Future<SharedPreferencesWithCache> _prefs =
      SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
              // This cache will only accept the key 'counter'.
              ));
  late Future<List<String>> _lists;
  List<String> _externalList = [];
  late TextEditingController textController;

  Future<void> _addSetList() async {
    final String? listName = await openDialog();
    if (listName == null || listName.isEmpty) return;
    final SharedPreferencesWithCache prefs = await _prefs;
    final List<String> list = (prefs.getStringList('setlists') ?? []);
    if(list.contains(listName)) {
      
    }
    else {
      list.add(listName);
    }

    setState(() {
      _lists = prefs.setStringList('setlists', list).then((_) {
        return list;
      });
    });
  }

  // Future<void> _getExternalList() async {
  //   final SharedPreferencesAsync prefs = SharedPreferencesAsync();
  //   setState(() async {
  //     _externalList = (await prefs.getStringList('externalCounter')) ?? [];
  //   });
  // }

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
    _lists = _prefs.then((SharedPreferencesWithCache prefs) {
      return prefs.getStringList('setlists') ?? [];
    });
    // _getExternalList();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
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
        title: const Text('Setlists'),
      ),
      drawer: AppDrawer(),
      body: FutureBuilder<List<String>>(
          future: _lists,
          builder:
              (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
              case ConnectionState.waiting:
                return const CircularProgressIndicator();
              case ConnectionState.active:
              case ConnectionState.done:
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 18.0, horizontal: 16.0),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: snapshot.data!
                                  .map((set) => ListTile(
                                        key: Key(set),
                                        onTap: () {Navigator.push(context, MaterialPageRoute(builder: (context)=> SetlistPreview(set)));},
                                        title: Text(set),
                                        leading: Icon(
                                          Icons.label,
                                          color: Colors.red,
                                          size: 32.0,
                                        ),
                                      ))
                                  .toList(),
                            )
                          ],
                        ),
                      ));
                }
            }
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSetList,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<String?> openDialog() => showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
            title: Text("Wpisz nazwe setlisty:"),
            content: TextField(
              autofocus: true,
              decoration: InputDecoration(hintText: "Wpisz nazwe"),
              controller: textController,
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(textController.text);
                  },
                  child: Text("Create"))
            ],
          ));
}
