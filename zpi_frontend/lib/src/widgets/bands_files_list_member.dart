import 'dart:io';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zpi_frontend/src/models/file_data.dart';
import 'package:zpi_frontend/src/models/group.dart';
import 'package:zpi_frontend/src/services/apiservice.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:zpi_frontend/src/services/user_data.dart';

class BandsFilesListMember extends StatefulWidget {
  const BandsFilesListMember({super.key, required this.group});

  final Group group;

  @override
  _BandsFilesListMemberState createState() => _BandsFilesListMemberState();
}


class _BandsFilesListMemberState extends State<BandsFilesListMember> {
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
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error loading files'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No files available'));
            } else {
              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final pdfFile = snapshot.data![index];
                  return Slidable(
                    key: Key(pdfFile.piece),
                    child: buildPdfTile(pdfFile),
                  );
                },
              );
            }
          },
        ),
      ],
    );
  }

  Widget buildPdfTile(FileData doc) => ListTile(
    onTap: () {
      _savePdf(doc.piece,doc.instrument);
    },
    title: Text(doc.piece+' - '+ doc.instrument),
    leading: const Icon(
      Icons.picture_as_pdf,
      color: Colors.red,
      size: 32.0,
    ),
  );

  Future<void> _loadAsync() async {
    user = (await UserPreferences.getUserName())!;
    _pdfFiles = ApiService().fetchAllFiles(user, widget.group.groupName);
    setState(() {}); // Refresh the UI after retrieving the username
  }

  Future<void> _savePdf(String piece, String instrument) async {
    try {
      // Show loading indicator
      setState(() {
        // Trigger any loading indicator here if needed
      });

      // Call downloadFile to get the PDF file
      final file = await ApiService().downloadFile(
        username: user,
        group: widget.group.groupName,
        piece: piece,
        instrument: instrument,
      );

      if (file != null) {
        // Get the application documents directory
        final directory = await getApplicationDocumentsDirectory();

        // Create a subdirectory named after the current user
        final userDirectory = Directory('${directory.path}/$user');
        if (!await userDirectory.exists()) {
          await userDirectory.create(recursive: true); // Create directory if it doesn't exist
        }
        final filePath = '${userDirectory.path}/$piece-$instrument.pdf';

        // Save the file to the device's storage
        final savedFile = await file.copy(filePath);

        print('File saved to: ${savedFile.path}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File saved to: ${savedFile.path}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download file')),
        );
      }
    } catch (e) {
      print('Error saving file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving file: $e')),
      );
    }
  }
}
