import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zpi_frontend/src/models/pdf_document_class.dart';
import 'package:zpi_frontend/src/screens/bandlistscreen.dart';
import 'package:zpi_frontend/src/screens/library_main.dart';
import 'package:zpi_frontend/src/screens/pdf_preview.dart';
import 'package:zpi_frontend/src/screens/setlists_main.dart';
import 'package:zpi_frontend/src/services/apiservice.dart';
import 'package:zpi_frontend/src/services/user_data.dart'; // For UserPreferences
import 'package:zpi_frontend/src/services/websocketservice.dart'; // For WebSocketService
import 'package:zpi_frontend/src/widgets/app_drawer_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String username;
  late String groupName;
  final WebSocketService _webSocketService = WebSocketService();

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
    _listenToIncomingMessages();
  }

  Future<void> _initializeWebSocket() async {

    username = (await UserPreferences.getUserName())!;
    groupName = (await UserPreferences.getActiveGroup())!;
    _webSocketService.connect(username, groupName);

    String activeInstrument = (await UserPreferences.getActiveGroupInstrument())!;
    List<String> instrument = await ApiService().getUserInstrument(group: groupName, username: username);
    if(activeInstrument != instrument[0])
      {
        UserPreferences.saveActiveGroupInstrument(instrument[0]);
      }
  }


  void _listenToIncomingMessages() {
    _webSocketService.messageStream.listen((message) {
      RegExp regex = RegExp(r"^piece:(.*),bpm:(\d*)$");
      if(regex.hasMatch(message)) {
        _showIncomingMessageDialog(message);
      }
    });
  }

  void _showIncomingMessageDialog(String message) async {
    if (!mounted) return;

    RegExp regex = RegExp(r"^piece:(.*),bpm:(\d*)$");
    String matchedPiece = "";
    String matchedBpm = "";

    RegExpMatch? match = regex.firstMatch(message);
    if (match != null) {
        matchedPiece = match.group(1)!;
        matchedBpm = match.group(2)!;
    }


    // Save a reference to the current context
    final BuildContext dialogContext = context;

    showDialog(
      context: dialogContext,
      builder: (BuildContext dialogBuilderContext) => AlertDialog(
        title: const Text('New piece to play, do you want to open it?'),
        content: Text(matchedPiece),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogBuilderContext).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogBuilderContext).pop(); // Close initial dialog
              final String? instrument = await UserPreferences.getActiveGroupInstrument();

              if (instrument == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No active group instrument found.')),
                  );
                }
                return;
              }

              // Show loading dialog
              if (!mounted) return;
              await _showLoadingDialog(dialogContext, 'Downloading...');

              try {
                final file = await _downloadAndSavePdf(matchedPiece, instrument);

                if (mounted) Navigator.of(dialogContext).pop(); // Close loading dialog

                if (file != null && await file.exists()) {
                  if (mounted) {
                    PdfNotesFile doc = PdfNotesFile(file);
                    Navigator.push(
                      dialogContext,
                      MaterialPageRoute(
                        builder: (context) => ReaderScreen([doc], doc.name,bpm: matchedBpm != ''? int.parse(matchedBpm):0,),
                      ),
                    );
                  }
                } else {
                  throw Exception('File does not exist after download.');
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(dialogContext).pop(); // Close loading dialog
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
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

  Future<File?> _downloadAndSavePdf(String piece, String instrument) async {
    try {
      final directory = await getApplicationDocumentsDirectory();

      // Create a subdirectory named after the current user
      final userDirectory = Directory('${directory.path}/$username');
      if (!await userDirectory.exists()) {
        await userDirectory.create(recursive: true); // Create directory if it doesn't exist
      }
      final filePath = '${userDirectory.path}/$piece-$instrument.pdf';

      if (await File(filePath).exists()) {
        return File(filePath); // Return existing file if it exists
      }

      groupName = (await UserPreferences.getActiveGroup())!;

      final file = await ApiService().downloadFile(
        username: username,
        group: groupName,
        piece: piece,
        instrument: instrument,
      );

      if (file != null) {
        final savedFile = await file.copy(filePath);
        return savedFile;
      } else {
        throw Exception('Failed to download file.');
      }
    } catch (e) {
      throw Exception('Error downloading file: $e');
    }
  }



  @override
  void dispose() {
    _webSocketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Home Page'),
      ),
      drawer: AppDrawer(),
      body: _buildUI(), // Show loading indicator
    );
  }

  Widget _buildUI() {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      children: [
        _buildCard(Icons.groups, 'Bands', BandListScreen()),
        _buildCard(Icons.library_music_outlined, 'Library', LibraryMainPage(title: 'Library')),
        _buildCard(Icons.settings, 'Settings', null),
        _buildCard(Icons.list_alt_sharp, 'Setlists', SetlistsMain()),
      ],
    );
  }

  Widget _buildCard(IconData icon, String title, Widget? destination) {
    return Center(
      child: Card(
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: () {
            if (destination != null) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
            } else {
              debugPrint('$title card tapped.');
              _webSocketService.sendMessage('Navigated to $title'); // Send message over WebSocket
            }
          },
          child: SizedBox(
            child: Column(
              children: [
                Icon(icon, size: 150),
                Text(title, style: const TextStyle(fontSize: 25)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
