import 'dart:io';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:zpi_frontend/src/models/group.dart';
import 'package:zpi_frontend/src/services/apiservice.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:zpi_frontend/src/services/user_data.dart';

class BandsFilesList extends StatefulWidget {
  const BandsFilesList({super.key, required this.group});

  final Group group;

  @override
  _BandsFilesListState createState() => _BandsFilesListState();
}

class MenuItem {
  final int id;
  final String label;
  final IconData icon;

  MenuItem(this.id, this.label, this.icon);
}

class _BandsFilesListState extends State<BandsFilesList> {
  late TextEditingController instrumentTextController;
  late TextEditingController pieceTextController;
  late String user;
  final TextEditingController menuController = TextEditingController();
  MenuItem? selectedMenu;
  File? selectedFile;



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
    instrumentTextController = TextEditingController();
    pieceTextController = TextEditingController();
    _loadUserName();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ElevatedButton(
          onPressed: _uploadFileToServer,
          child: Text('Add File to Server'),
        ),
      ],
    );
  }

  Future<void> _uploadFileToServer() async {
    final result = await openDialog();
    if (result != null) {
      // Ensure selectedFile exists before attempting upload
      if (result['file'] != null) {
        final success = await ApiService.uploadFile(
          file: result['file'] as File,
          memberName: user,
          groupName: widget.group.groupName,
          piece: result['piece'] as String,
          instrument: result['instrument'] as String,
          fileType: "pdf",
        );

        if (success) {
          print("File uploaded successfully");
        } else {
          print("Failed to upload file");
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

  Future<void> _loadUserName() async {
    user = (await UserPreferences.getUserName())!;
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
}
