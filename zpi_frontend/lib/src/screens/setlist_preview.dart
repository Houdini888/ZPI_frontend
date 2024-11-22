import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zpi_frontend/src/screens/pdf_preview.dart';

import '../models/pdf_document_class.dart';
import '../services/user_data.dart';
import '../widgets/app_drawer_menu.dart';

class SetlistPreview extends StatefulWidget {
  final String setlist;

  const SetlistPreview(this.setlist, {super.key});

  @override
  SetlistPreviewState createState() => SetlistPreviewState();
}

class SetlistPreviewState extends State<SetlistPreview> {
  List<PdfNotesFile> docsList = [];
  List<PdfNotesFile> fullFileList = [];
  late String user;

  final Future<SharedPreferencesWithCache> _prefs =
      SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
              // This cache will only accept the key 'counter'.
              ));
  late Future<List<String>> _lists;
  // List<String> _externalList = [];
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

  Future<void> _changeOrderOfPdfs(List<String> setlist) async {
    final SharedPreferencesWithCache prefs = await _prefs;
    List<String> list = (prefs.getStringList(widget.setlist) ?? []);

    list = setlist;

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
    final directory = await getApplicationDocumentsDirectory();
    user = (await UserPreferences.getUserName())!;

    // Create a subdirectory named after the current user
    final userDirectory = Directory('${directory.path}/$user');
    if (!await userDirectory.exists()) {
      await userDirectory.create(recursive: true); // Create directory if it doesn't exist
    }
    final List<FileSystemEntity> files = userDirectory.listSync(); // List all files

    final SharedPreferencesWithCache prefs = await _prefs;
    final List<String> list = (prefs.getStringList(widget.setlist) ?? []);

    final List<PdfNotesFile> loadedPdfs = [];
    final List<PdfNotesFile> fullPdfs = [];

    for (FileSystemEntity entity in files) {
      if (entity is File) {
        PdfNotesFile pdfFile = PdfNotesFile(entity);
        fullPdfs.add(pdfFile);
        if (!list.contains(pdfFile.name)) {
          loadedPdfs.add(pdfFile);
        }
      }
    }
    final pdfsList =
        loadedPdfs.where((string) => string.filePath.endsWith(".pdf")).toList();
    final fullPdfsList =
        fullPdfs.where((string) => string.filePath.endsWith(".pdf")).toList();

    pdfsList.sort();

    setState(() {
      docsList = pdfsList;
      fullFileList = fullPdfsList;
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

  Future<void> previewSetlist(String startPdfName) async {
    final SharedPreferencesWithCache prefs = await _prefs;
    List<String> list = (prefs.getStringList(widget.setlist) ?? []);

    List<PdfNotesFile> setlistToPreview = [];
    int first = 0;
    for (int i = 0; i < list.length; i++) {
      PdfNotesFile pdf =
          fullFileList.where((item) => item.name == list[i]).first;
      setlistToPreview.add(pdf);
      if (list[i] == startPdfName) {
        first = i;
      }
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ReaderScreen(setlistToPreview, widget.setlist,
                startPdfIndex: first)));
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
                    padding:
                        EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
                    child: ReorderableListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final setlistPosition = snapshot.data![index];
                        return Slidable(
                          key: Key(setlistPosition),
                          startActionPane: ActionPane(
                              motion: const StretchMotion(),
                              children: [
                                SlidableAction(
                                  backgroundColor: Colors.red,
                                  icon: Icons.delete,
                                  label: 'Delete',
                                  onPressed: (context) => _onDismissed(index),
                                )
                              ]),
                          child: buildPdfTile(setlistPosition),
                        );
                      },
                      onReorder: (int oldIndex, int newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final items = snapshot.data!.removeAt(oldIndex);
                          snapshot.data!.insert(newIndex, items);
                          _changeOrderOfPdfs(snapshot.data!);
                        });
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
            title: Text('Choose track to add:'),
            content: SingleChildScrollView(
                child: Column(
              children: docsList
                  .map((doc) => ListTile(
                        onTap: () {
                          Navigator.of(context).pop(doc.name);
                        },
                        onLongPress: () {},
                        title: Text(doc.name),
                        leading: Icon(
                          Icons.picture_as_pdf,
                          color: Colors.red,
                          size: 32.0,
                        ),
                      ))
                  .toList(),
            )),
          ));

  Widget buildPdfTile(String setlistPosition) => ListTile(
        key: Key(setlistPosition),
        onTap: () {
          previewSetlist(setlistPosition);
        },
        title: Text(setlistPosition),
        leading: Icon(
          Icons.picture_as_pdf,
          color: Colors.red,
          size: 32.0,
        ),
      );

  Future<void> _onDismissed(int index) async {
    final SharedPreferencesWithCache prefs = await _prefs;
    List<String> list = (prefs.getStringList(widget.setlist) ?? []);

    docsList.add(fullFileList.where((item) => item.name == list[index]).first);
    docsList.sort();
    list.removeAt(index);

    setState(() {
      _lists = prefs.setStringList(widget.setlist, list).then((_) {
        return list;
      });
    });
  }
}
