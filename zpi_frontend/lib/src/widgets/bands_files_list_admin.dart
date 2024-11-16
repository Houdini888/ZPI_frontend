import 'dart:io';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zpi_frontend/src/models/file_data.dart';
import 'package:zpi_frontend/src/models/group.dart';
import 'package:zpi_frontend/src/services/apiservice.dart';
import 'package:file_picker/file_picker.dart';
import 'package:zpi_frontend/src/services/user_data.dart';

class BandsFilesListAdmin extends StatefulWidget {
  const BandsFilesListAdmin({super.key, required this.group});

  final Group group;

  @override
  _BandsFilesListAdminState createState() => _BandsFilesListAdminState();
}

class _BandsFilesListAdminState extends State<BandsFilesListAdmin> {
  late TextEditingController instrumentTextController;
  late TextEditingController pieceTextController;
  late String user;
  File? selectedFile;
  late Future<List<FileData>> _pdfFiles = Future.value([]);
  late Future<List<String>> _instruments = Future.value([]);

  @override
  void initState() {
    super.initState();
    _loadAsync();
    instrumentTextController = TextEditingController();
    pieceTextController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<FileData>>(
        future: _pdfFiles,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading files'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No files available'));
          } else {
            // Grouping the data by piece name with instruments list
            final groupedData = _groupByPiece(snapshot.data!);
            return ListView.builder(
              itemCount: groupedData.length,
              itemBuilder: (context, index) {
                final pieceEntry = groupedData[index];
                return Slidable(
                  key: Key(pieceEntry['piece']),
                  child: buildPdfTile(
                      pieceEntry['piece'], pieceEntry['instruments']),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadFileToServer,
        child: Icon(Icons.add),
        tooltip: 'Add File',
      ),
    );
  }

  // Method to group FileData by piece name, retaining a list of instruments
  List<Map<String, dynamic>> _groupByPiece(List<FileData> files) {
    Map<String, List<String>> groupedMap = {};

    for (var file in files) {
      // Add instrument to the list for each piece
      if (groupedMap.containsKey(file.piece)) {
        groupedMap[file.piece]!.add(file.instrument);
      } else {
        groupedMap[file.piece] = [file.instrument];
      }
    }

    // Convert the map into a list of maps for easy access in the UI
    return groupedMap.entries.map((entry) {
      return {
        'piece': entry.key,
        'instruments': entry.value,
      };
    }).toList();
  }

  // Modified buildPdfTile to show all instruments as children of the expandable tile
  Widget buildPdfTile(String piece, List<String> instruments) {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(piece),
        leading: const Icon(Icons.music_note_outlined,
            color: Colors.red, size: 32.0),
        childrenPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
        // Adjust padding
        children: instruments.map((instrument) {
          return ListTile(
            leading: const Icon(Icons.picture_as_pdf_rounded),
            title: Text(instrument),
            onTap: () {
              _savePdf(piece, instrument);
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _uploadFileToServer() async {
    final result = await openDialog();
    if (result != null && result['file'] != null) {
      final snackBar = SnackBar(content: Text('File being added...'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      final success = await ApiService.uploadFile(
        file: result['file'] as File,
        memberName: user,
        groupName: widget.group.groupName,
        piece: result['piece'] as String,
        instrument: result['instrument'] as String,
        fileType: "pdf",
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (success) {
        print("File uploaded successfully");
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('File added successfully!')));
        await _loadAsync(); // Refresh the list
      } else {
        print("Failed to upload file");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add file. Please try again.')));
      }
    } else {
      print("No file selected for upload");
    }
  }

  Future<Map<String, dynamic>?> openDialog() =>
      showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Upload File:'),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(hintText: "Piece Name"),
                      controller: pieceTextController,
                    ),
                    FutureBuilder(
                        future: _instruments,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Text('Error loading instruments'));
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return TextField(
                              controller: instrumentTextController,
                              decoration: InputDecoration(
                                hintText: "Instrument",
                                border: UnderlineInputBorder(),
                              ),
                            );
                          } else {
                            return Autocomplete<String>(
                              optionsBuilder:
                                  (TextEditingValue textEditingValue) {
                                // Filter options based on entered text
                                return snapshot.data!.where((String option) {
                                  return option.toLowerCase().contains(
                                      textEditingValue.text.toLowerCase());
                                });
                              },
                              fieldViewBuilder: (context, controller, focusNode,
                                  onFieldSubmitted) {
                                // Assign controller to manage custom and dropdown values
                                instrumentTextController = controller;
                                return TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    hintText: "Instrument",
                                    border: UnderlineInputBorder(),
                                  ),
                                );
                              },
                              onSelected: (String selection) {
                                // Update the controller with the selected suggestion
                                instrumentTextController.text = selection;
                              },
                            );
                          }
                        }),
                    ElevatedButton(
                      onPressed: () async {
                        await _pickAndSavePdf(setState);
                      },
                      child: Text('Pick File'),
                    ),
                    if (selectedFile != null)
                      Text(
                          'Selected file: ${selectedFile!.path.split('/').last}',
                          style: TextStyle(color: Colors.grey)),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop({
                  "piece": pieceTextController.text,
                  "instrument": instrumentTextController.text,
                  "file": selectedFile,
                });
              },
              child: Text("Add"),
            ),
          ],
        ),
      );

  Future<void> _loadAsync() async {
    user = (await UserPreferences.getUserName())!;
    _pdfFiles = ApiService().fetchAllFiles(user, widget.group.groupName);
    _instruments =
        ApiService().getAllInstrumentsFromGroup(widget.group.groupName);
    setState(() {}); // Refresh the UI after retrieving the username
  }

  Future<void> _pickAndSavePdf(StateSetter setState) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'], // Allow only PDFs
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _savePdf(String piece, String instrument) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$piece-$instrument.pdf';

      // Check if the file already exists
      final fileExists = await File(filePath).exists();
      if (fileExists) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File already downloaded: $filePath')));
        return;
      }

      final loadingSnackBar = SnackBar(content: Text('Saving file...'));
      ScaffoldMessenger.of(context).showSnackBar(loadingSnackBar);

      final file = await ApiService().downloadFile(
        username: user,
        group: widget.group.groupName,
        piece: piece,
        instrument: instrument,
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (file != null) {
        final savedFile = await file.copy(filePath);

        print('File saved to: ${savedFile.path}');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File saved to ${savedFile.path}')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to download file')));
      }
    } catch (e) {
      print('Error saving file: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error saving file')));
    }
  }
}
