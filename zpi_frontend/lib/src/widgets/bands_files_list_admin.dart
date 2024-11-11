import 'dart:io';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zpi_frontend/src/models/file_data.dart';
import 'package:zpi_frontend/src/models/group.dart';
import 'package:zpi_frontend/src/services/apiservice.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:zpi_frontend/src/services/user_data.dart';
import 'package:zpi_frontend/src/services/apiservice.dart';

class BandsFilesListAdmin extends StatefulWidget {
  const BandsFilesListAdmin({super.key, required this.group});

  final Group group;

  @override
  _BandsFilesListAdminState createState() => _BandsFilesListAdminState();
}

class MenuItem {
  final int id;
  final String label;
  final IconData icon;

  MenuItem(this.id, this.label, this.icon);
}

class _BandsFilesListAdminState extends State<BandsFilesListAdmin> {
  late TextEditingController instrumentTextController;
  late TextEditingController pieceTextController;
  late String user;
  final TextEditingController menuController = TextEditingController();
  MenuItem? selectedMenu;
  File? selectedFile;
  late Future<List<FileData>> _pdfFiles = Future.value([]);



  List<MenuItem> menuItems = [
  MenuItem(1, 'Home', Icons.home),
  MenuItem(2, 'Profile', Icons.person),
  MenuItem(3, 'Settings', Icons.settings),
  MenuItem(4, 'Favorites', Icons.favorite),
  MenuItem(5, 'Notifications', Icons.notifications),
  MenuItem(6, 'Messages', Icons.message),
  MenuItem(7, 'Explore', Icons.explore),
  MenuItem(8, 'Search', Icons.search),
  MenuItem(9, 'Chat', Icons.chat),
  MenuItem(10, 'Calendar', Icons.calendar_today),
  ];

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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Your existing FutureBuilder and other widgets here
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadFileToServer,
        child: Icon(Icons.add), // Use an icon or text
        tooltip: 'Add File', // Optional tooltip for accessibility
      ),
    );
  }

  Widget buildPdfTile(FileData doc) => ListTile(
    onTap: () {
      _savePdf(doc.piece, doc.instrument);
    },
    title: Text(doc.piece),
    leading: const Icon(
      Icons.picture_as_pdf,
      color: Colors.red,
      size: 32.0,
    ),
  );

  Future<void> _uploadFileToServer() async {
    final result = await openDialog();
    if (result != null) {
      if (result['file'] != null) {
        // Show Snackbar indicating file upload has started
        final snackBar = SnackBar(content: Text('File being added...'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);

        // Upload the file
        final success = await ApiService.uploadFile(
          file: result['file'] as File,
          memberName: user,
          groupName: widget.group.groupName,
          piece: result['piece'] as String,
          instrument: result['instrument'] as String,
          fileType: "pdf",
        );

        // Dismiss the Snackbar after a response
        ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide the current Snackbar

        if (success) {
          print("File uploaded successfully");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File added successfully!')),
          );
          // Reload the list of files after successful upload
          await _loadAsync(); // Refresh the list
        } else {
          print("Failed to upload file");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add file. Please try again.')),
          );
        }
      } else {
        print("No file selected for upload");
      }
    }
  }

  Future<Map<String, dynamic>?> openDialog() => showDialog<Map<String, dynamic>>(
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
                TextField(
                  autofocus: true,
                  decoration: InputDecoration(hintText: "Instrument"),
                  controller: instrumentTextController,
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _pickAndSavePdf(setState);
                  },
                  child: Text('Pick File'),
                ),
                if (selectedFile != null)
                  Text(
                    'Selected file: ${selectedFile!.path.split('/').last}',
                    style: TextStyle(color: Colors.grey),
                  ),
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
    setState(() {}); // Refresh the UI after retrieving the username
  }

  Future<void> _pickAndSavePdf(StateSetter setState) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'], // Allow only PDFs
    );

    if (result != null && result.files.single.path != null) {
      // Update the selected file and trigger dialog UI rebuild
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
          SnackBar(content: Text('File already downloaded: $filePath')),
        );
        return; // Exit if the file already exists
      }

      // Show loading indicator
      final loadingSnackBar = SnackBar(content: Text('Saving file...'));
      ScaffoldMessenger.of(context).showSnackBar(loadingSnackBar);

      // Call downloadFile to get the PDF file
      final file = await ApiService().downloadFile(
        username: user,
        group: widget.group.groupName,
        piece: piece,
        instrument: instrument,
      );

      if (file != null) {
        // Save the file to the device's storage
        final savedFile = await file.copy(filePath);
        print('File saved to: ${savedFile.path}');

        // Dismiss loading Snackbar and show success message
        ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide loading snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File saved to: ${savedFile.path}')),
        );
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide loading snackbar
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
