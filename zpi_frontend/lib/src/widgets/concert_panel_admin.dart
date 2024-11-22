import 'dart:io';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zpi_frontend/src/models/file_data.dart';
import 'package:zpi_frontend/src/models/group.dart';
import 'package:zpi_frontend/src/services/apiservice.dart';
import 'package:flutter/material.dart';
import 'package:zpi_frontend/src/services/user_data.dart';

import '../models/pdf_document_class.dart';
import '../screens/pdf_preview.dart';
import '../services/websocketservice.dart';

class ConcertPanelAdmin extends StatefulWidget {
  const ConcertPanelAdmin({super.key, required this.group});

  final Group group;

  @override
  _ConcertPanelAdminState createState() => _ConcertPanelAdminState();
}

class _ConcertPanelAdminState extends State<ConcertPanelAdmin> {
  late String user;
  late Future<List<FileData>> _pdfFiles = Future.value([]);

  @override
  void initState() {
    super.initState();
    _loadAsync();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FutureBuilder<List<FileData>?>(
          future: _pdfFiles,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Error loading files'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No files available'));
            } else {
              // Grouping the data by piece name
              final groupedData = _groupByPiece(snapshot.data!);
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groupedData.length,
                itemBuilder: (context, index) {
                  final piece = groupedData[index];
                  return Slidable(
                    key: Key(piece),
                    child: buildPdfTile(piece),
                  );
                },
              );
            }
          },
        ),
      ],
    );
  }

  // Method to group FileData by piece name
  List<String> _groupByPiece(List<FileData> files) {
    return files.map((file) => file.piece).toSet().toList();
  }

  Widget buildPdfTile(String piece) => ListTile(
    onTap: () {
      _sendMessage(piece);
    },
    title: Text(piece),
    leading: const Icon(
      Icons.music_note,
      color: Colors.red,
      size: 32.0,
    ),
  );

  Future<void> _loadAsync() async {
    user = (await UserPreferences.getUserName())!;
    _pdfFiles = ApiService().fetchAllFiles(user, widget.group.groupName);
    setState(() {}); // Refresh the UI after retrieving the username
  }

  Future<void> _sendMessage(String piece) async {
    try {
      // Send the piece name via WebSocket
      WebSocketService().sendMessage(piece);

      // Notify the user that the message has been sent
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sent "$piece" to other band members')),
      );
      await _handleFileForSender(piece);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  Future<void> _handleFileForSender(String piece) async {
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
              builder: (context) => ReaderScreen([doc], doc.name),
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
        await userDirectory.create(recursive: true); // Create directory if it doesn't exist
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

}
