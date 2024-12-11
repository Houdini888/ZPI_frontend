import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zpi_frontend/src/screens/pdf_preview_band.dart';

import '../models/file_data.dart';
import '../models/pdf_document_class.dart';
import '../models/piece.dart';
import '../services/apiservice.dart';
import '../services/user_data.dart';
import '../services/websocketservice.dart';
import '../widgets/app_drawer_menu.dart';

class SetlistPreview extends StatefulWidget {
  final String setlist;
  final String band;

  const SetlistPreview(this.setlist, this.band, {super.key});

  @override
  SetlistPreviewState createState() => SetlistPreviewState();
}

class SetlistPreviewState extends State<SetlistPreview> {
  List<String> docsList = [];
  List<Piece> fullFileList = [];

  final Future<SharedPreferencesWithCache> _prefs =
      SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
              // This cache will only accept the key 'counter'.
              ));
  late Future<List<String>> _lists;
  late TextEditingController textController;

  Future<void> _addSetList() async {
    final String? listName = await openDialog();
    if (listName == null || listName.isEmpty) return;
    final SharedPreferencesWithCache prefs = await _prefs;
    final List<String> list =
        (prefs.getStringList('${widget.setlist}-${widget.band}') ?? []);

    docsList.removeWhere((item) => item == listName);

    list.add(listName);

    setState(() {
      _lists = prefs
          .setStringList('${widget.setlist}-${widget.band}', list)
          .then((_) {
        return list;
      });
    });
  }

  Future<void> _changeOrderOfPdfs(List<String> setlist) async {
    final SharedPreferencesWithCache prefs = await _prefs;
    List<String> list =
        (prefs.getStringList('${widget.setlist}-${widget.band}') ?? []);

    list = setlist;

    setState(() {
      _lists = prefs.setStringList(widget.setlist, list).then((_) {
        return list;
      });
    });
  }

  Future _initPieces() async {
    final SharedPreferencesWithCache prefs = await _prefs;
    final List<String> pdfsList =
        (prefs.getStringList('${widget.setlist}-${widget.band}') ?? []);

    String? username = await UserPreferences.getUserName();

    List<FileData> pdfFiles =
        await ApiService().fetchAllFiles(username!, widget.band);

    final List<String> loadedPdfs = [];
    final List<Piece> fullPdfs = [];

    for (FileData entity in pdfFiles) {
      Piece piece = Piece(name: entity.piece, bpm: entity.bpm);
      fullPdfs.add(piece);
      if (!pdfsList.contains(piece.name) && !loadedPdfs.contains(piece.name)) {
        loadedPdfs.add(piece.name);
      }
    }

    loadedPdfs.sort();

    setState(() {
      docsList = loadedPdfs;
      fullFileList = fullPdfs;
    });
  }

  @override
  void initState() {
    super.initState();
    _initPieces();

    textController = TextEditingController();
    _lists = _prefs.then((SharedPreferencesWithCache prefs) {
      return prefs.getStringList('${widget.setlist}-${widget.band}') ?? [];
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
        // leading: Builder(
        //   builder: (context) => IconButton(
        //     icon: new Icon(Icons.menu),
        //     onPressed: () => Scaffold.of(context).openDrawer(),
        //   ),
        // ),
        title: Text(widget.setlist),
      ),
      // drawer: AppDrawer(),
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
                          Navigator.of(context).pop(doc);
                        },
                        onLongPress: () {},
                        title: Text(doc),
                        leading: const Icon(
                          Icons.music_note_outlined,
                          color: Colors.black54,
                          size: 32.0,
                        ),
                      ))
                  .toList(),
            )),
          ));

  Widget buildPdfTile(String setlistPosition) => ListTile(
        key: Key(setlistPosition),
        title: Text(setlistPosition),
        onTap: () {
          previewSetlist(setlistPosition);
        },
        leading: const Icon(
          Icons.music_note_outlined,
          color: Colors.black54,
          size: 32.0,
        ),
      );

  Future<void> _onDismissed(int index) async {
    final SharedPreferencesWithCache prefs = await _prefs;
    List<String> list =
        (prefs.getStringList('${widget.setlist}-${widget.band}') ?? []);

    docsList
        .add(fullFileList.where((item) => item.name == list[index]).first.name);
    docsList.sort();
    list.removeAt(index);

    setState(() {
      _lists = prefs
          .setStringList('${widget.setlist}-${widget.band}', list)
          .then((_) {
        return list;
      });
    });
  }

  Future<void> previewSetlist(String startPdfName) async {
    final SharedPreferencesWithCache prefs = await _prefs;
    List<String> list =
    (prefs.getStringList('${widget.setlist}-${widget.band}') ?? []);

    print(fullFileList);
    print(list);
    List<Piece> setlistToPreview = [];
    int first = 0;
    for (int i = 0; i < list.length; i++) {
      Piece piece =
          fullFileList.where((item) => item.name == list[i]).first;
      setlistToPreview.add(piece);
      if (list[i] == startPdfName) {
        first = i;
      }
    }
    print(setlistToPreview);
    _sendMessage(setlistToPreview[first].name, setlistToPreview[first].bpm);

    final directory = await getApplicationDocumentsDirectory();
    String username = (await UserPreferences.getUserName())!;
    Directory userDirectory = Directory('${directory.path}/$username');
    String instrument = (await UserPreferences.getActiveGroupInstrument())!;
    String startPdfPath = '${userDirectory.path}/$startPdfName-$instrument.pdf';

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ReaderScreen(setlistToPreview, widget.setlist,widget.band,startPdfPath,
                startPdfIndex: first, bpm: setlistToPreview[first].bpm != '' ? int.parse(setlistToPreview[first].bpm):0,)));
  }
  Future<void> _sendMessage(String piece, String bpm) async {
    try {
      String message = "piece:$piece,bpm:$bpm";
      // Send the piece name via WebSocket
      WebSocketService().sendMessage(message);

      // Notify the user that the message has been sent
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sent "$piece" to other band members')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }
}
