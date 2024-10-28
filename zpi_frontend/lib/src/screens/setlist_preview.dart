import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pdf_document_class.dart';
import '../widgets/app_drawer_menu.dart';

class SetlistPreview extends StatefulWidget {
  final String setlist;

  const SetlistPreview(this.setlist, {super.key});

  @override
  SetlistPreviewState createState() => SetlistPreviewState();
}

class SetlistPreviewState extends State<SetlistPreview> {
  List<PdfNotesFile> docsList=[];

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
    final List<String> list = (prefs.getStringList(widget.setlist) ?? []);
    
    docsList.removeWhere((item) => item.name == listName);
    
    list.add(listName);

    setState(() {
      _lists = prefs.setStringList(widget.setlist, list).then((_) {
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

  Future _initPdfs() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = appDir.listSync();  // List all files

    final SharedPreferencesWithCache prefs = await _prefs;
    final List<String> list = (prefs.getStringList(widget.setlist) ?? []);

    final List<PdfNotesFile> loadedPdfs = [];
    for (FileSystemEntity entity in files) {
      if (entity is File) {
        PdfNotesFile pdfFile = PdfNotesFile(entity);
        if(!list.contains(pdfFile.name)) {
          loadedPdfs.add(pdfFile);
        }
      }
    }
    final pdfsList = loadedPdfs.where((string) =>
        string.filePath.endsWith(".pdf")).toList();
    setState(() {
      docsList = pdfsList;
    });
  }

  @override
  void initState() {
    super.initState();
    _initPdfs();
    textController = TextEditingController();
    _lists = _prefs.then((SharedPreferencesWithCache prefs) {
      return prefs.getStringList(widget.setlist) ?? [];
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
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
        leading: Builder(
          builder: (context) =>
              IconButton(
                icon: new Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        title: Text(widget.setlist),
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
                                  .map((set) =>
                                  ListTile(
                                    key: Key(set),
                                    onTap: () {},
                                    title: Text(set),
                                    leading: Icon(
                                      Icons.picture_as_pdf,
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

  Future<String?> openDialog() => showDialog<String>
  (
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Wpisz nazwe setlisty:'),
      content:
      Column(children: docsList.map((doc) => ListTile(
        onTap: (){
          Navigator.of(context).pop(doc.name);
        },
        onLongPress: (){

        },
        title: Text(doc.name),
        leading: Icon(Icons.picture_as_pdf,
          color: Colors.red,
          size: 32.0,),
      )).toList(),)
  ),
  );
}
