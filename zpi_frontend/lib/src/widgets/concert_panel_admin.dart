import 'dart:io';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zpi_frontend/src/models/file_data.dart';
import 'package:zpi_frontend/src/models/group.dart';
import 'package:zpi_frontend/src/services/apiservice.dart';
import 'package:flutter/material.dart';
import 'package:zpi_frontend/src/services/user_data.dart';

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
      WebSocketService().sendMessage(piece); // Send the piece name via WebSocket
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sent "$piece" to WebSocket')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }
}
