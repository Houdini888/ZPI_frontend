import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zpi_frontend/src/screens/setlist_preview_band.dart';


class Setlists extends StatefulWidget {
  const Setlists({super.key, required this.band});

  final String band;
  @override
  SharedPreferencesDemoState createState() => SharedPreferencesDemoState();
}

class SharedPreferencesDemoState extends State<Setlists> {
  final Future<SharedPreferencesWithCache> _prefs =
  SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        // This cache will only accept the key 'counter'.
      ));
  late Future<List<String>> _lists;
  late TextEditingController textController;


  Future<void> _addSetList() async {
    final String? listName = await openDialog();
    if (listName == null || listName.isEmpty || listName.contains('setlists')) return;
    final SharedPreferencesWithCache prefs = await _prefs;
    final List<String> list = (prefs.getStringList('setlists-${widget.band}') ?? []);
    if (list.contains(listName)) {
    } else {
      list.add(listName);
    }

    setState(() {
      _lists = prefs.setStringList('setlists-${widget.band}', list).then((_) {
        return list;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
    _lists = _prefs.then((SharedPreferencesWithCache prefs) {
      return prefs.getStringList('setlists-${widget.band}') ?? [];
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
                    child: ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final setlistName = snapshot.data![index];
                        return Slidable(
                          key: Key(setlistName),
                          startActionPane: ActionPane(
                              motion: const StretchMotion(),
                              children: [
                                SlidableAction(
                                  backgroundColor: Colors.red,
                                  icon: Icons.delete,
                                  label: 'Delete',
                                  onPressed: (context) =>
                                      _onDismissed(index),
                                )
                              ]),
                          child: buildSetlistTile(setlistName),
                        );
                      },
                    ),
                  );
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
        title: Text("Write setlist name:"),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(hintText: "Setlist name"),
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

  Widget buildSetlistTile(String setlistName) => ListTile(
    key: Key(setlistName),
    onTap: () {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => SetlistPreview(setlistName, widget.band)));
    },
    title: Text(setlistName),
    leading: Icon(
      Icons.label,
      color: Colors.red,
      size: 32.0,
    ),
  );

  Future<void> _onDismissed(int index) async {
    final SharedPreferencesWithCache prefs = await _prefs;
    List<String> list = (prefs.getStringList('setlists-${widget.band}') ?? []);

    String setlistName = list[index];

    list.removeAt(index);
    prefs.remove(setlistName);

    setState(() {
      _lists = prefs.setStringList('setlists-${widget.band}', list).then((_) {
        return list;
      });
    });
  }
}
