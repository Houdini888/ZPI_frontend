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

import '../models/pdf_document_class.dart';
import '../screens/pdf_preview.dart';
import '../services/websocketservice.dart';

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
  late String? activeGroup;
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
            return Center(child: Text('Sooo empty here...'));
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
                    pieceEntry['piece'],
                    pieceEntry['instruments'],
                    pieceEntry['bpm'],
                  ),
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
    Map<String, Map<String, dynamic>> groupedMap = {};

    for (var file in files) {
      // Check if the piece is already in the map
      if (groupedMap.containsKey(file.piece)) {
        // Add instrument to the list of instruments for this piece
        groupedMap[file.piece]!['instruments'].add(file.instrument);
      } else {
        // Initialize the map for this piece with instruments and bpm
        groupedMap[file.piece] = {
          'instruments': [file.instrument],
          'bpm': file.bpm, // Assign the bpm from the first file encountered
        };
      }
    }

    // Convert the map into a list of maps for easy access in the UI
    return groupedMap.entries.map((entry) {
      return {
        'piece': entry.key,
        'instruments': entry.value['instruments'],
        'bpm': entry.value['bpm'],
      };
    }).toList();
  }

  Widget buildPdfTile(String piece, List<String> instruments, String bpm) {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(piece),
        leading: const Icon(Icons.music_note_outlined, color: Colors.red, size: 32.0),
        trailing: ElevatedButton.icon(
          onPressed: () {
            if (widget.group.groupName == activeGroup) {
              _sendMessage(piece,bpm); // Send the piece name to the WebSocket
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('To start playing a piece, you need to have this group as the active group.')),
              );
            }
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
          ),
        ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Instrument Files:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...instruments.map((instrument) {
            return ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded),
              title: Text(instrument),
              onTap: () {
                _savePdf(piece, instrument);
              },
            );
          }).toList(),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Metronome:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.timer, color: Colors.blue),
            title: Text('Current BPM: $bpm', style: const TextStyle(fontSize: 16)),
            trailing: ElevatedButton(
              onPressed: () async {
                double selectedBpm = double.tryParse(bpm) ?? 0.0;
                await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Set Metronome BPM'),
                      content: StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Slider(
                                value: selectedBpm,
                                min: 0,
                                max: 250,
                                divisions: 250,
                                label: selectedBpm.round().toString(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedBpm = value;
                                  });
                                },
                              ),
                              Text(
                                'Selected BPM: ${selectedBpm.round()}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          );
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog without action
                          },
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop(); // Close the dialog
                            try {
                              bool success = await ApiService().updateBpm(
                                widget.group.groupName,
                                piece,
                                selectedBpm.round().toString(),
                              );
                              if (success) {
                                setState(() {
                                  _pdfFiles = ApiService().fetchAllFiles(user, widget.group.groupName);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Metronome BPM updated successfully!')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to update Metronome BPM.')),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },
                          child: const Text('Set BPM'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('Set Metronome'),
            ),
          ),
        ],
      ),
    );
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
      await _handleFileForSender(piece, bpm);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  Future<void> _handleFileForSender(String piece, String bpm) async {
    // Retrieve the active group and user's instrument
    final String? instrument = await UserPreferences.getActiveGroupInstrument();
    if (instrument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active group instrument found.')),
      );
      return;
    }

    // Show a loading dialog while the file is being processed
    _showLoadingDialog(context, 'Checking file...');

    try {
      // Check for the file or download it
      final file = await _downloadAndSavePdf(piece, instrument);

      // Close the loading dialog
      if (mounted) Navigator.of(context).pop();

      // Open the file if it exists
      if (file != null && await file.exists()) {
        PdfNotesFile doc = PdfNotesFile(file);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReaderScreen([doc], doc.name,bpm: bpm != ''? int.parse(bpm):0,isAdmin: true,),
            ),
          );
        }
      } else {
        throw Exception('File does not exist after download.');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close the loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error handling file: $e')),
        );
      }
    }
  }

  Future<File?> _downloadAndSavePdf(String piece, String instrument) async {
    try {
      final directory = await getApplicationDocumentsDirectory();

      // Create a subdirectory named after the current user
      final userDirectory = Directory('${directory.path}/$user');
      if (!await userDirectory.exists()) {
        await userDirectory.create(
            recursive: true); // Create directory if it doesn't exist
      }

      // Define the file path within the user directory
      final filePath = '${userDirectory.path}/$piece-$instrument.pdf';

      // Return the file if it already exists
      if (await File(filePath).exists()) {
        return File(filePath);
      }

      // Fetch the active group name
      final String groupName = widget.group.groupName;

      // Download the file using the ApiService
      final file = await ApiService().downloadFile(
        username: user,
        group: groupName,
        piece: piece,
        instrument: instrument,
      );

      if (file != null) {
        // Save the downloaded file to the user-specific directory
        final savedFile = await file.copy(filePath);
        return savedFile;
      } else {
        throw Exception('Failed to download file.');
      }
    } catch (e) {
      throw Exception('Error downloading file: $e');
    }
  }

  Future<void> _showLoadingDialog(BuildContext context, String message) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(child: Text(message)),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadFileToServer() async {
    final result = await openDialog();
    if (result != null && result['file'] != null) {
      const snackBar = SnackBar(content: Text('File being added...'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      final success = await ApiService.uploadFile(
          file: result['file'] as File,
          memberName: user,
          groupName: widget.group.groupName,
          piece: result['piece'] as String,
          instrument: result['instrument'] as String,
          fileType: "pdf",
          bmp: '0');

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
                            return Center(
                                child: Text('Error loading instruments'));
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
    activeGroup = await UserPreferences.getActiveGroup();
    _pdfFiles = ApiService().fetchAllFiles(user, widget.group.groupName);
    _instruments =
        ApiService().getAllInstrumentsFromGroup(widget.group.groupName, user);
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

      // Create a subdirectory named after the current user
      final userDirectory = Directory('${directory.path}/$user');
      if (!await userDirectory.exists()) {
        await userDirectory.create(
            recursive: true); // Create directory if it doesn't exist
      }
      final filePath = '${userDirectory.path}/$piece-$instrument.pdf';

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
