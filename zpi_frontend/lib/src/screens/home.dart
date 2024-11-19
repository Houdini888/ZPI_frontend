import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zpi_frontend/src/models/pdf_document_class.dart';
import 'package:zpi_frontend/src/screens/bandlistscreen.dart';
import 'package:zpi_frontend/src/screens/library_main.dart';
import 'package:zpi_frontend/src/screens/pdf_preview.dart';
import 'package:zpi_frontend/src/screens/setlists_main.dart';
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
    // Fetch the username from UserPreferences
    username = (await UserPreferences.getUserName())!;
    groupName = (await UserPreferences.getActiveGroup())!;

    // Initialize the WebSocket connection with the username and group
    _webSocketService.connect(username, groupName);
  }

  void _listenToIncomingMessages() {
    // Listen to WebSocket messages
    _webSocketService.messageStream.listen((message) {
      _showIncomingMessageDialog(message); // Show dialog on message reception
    });
  }

  void _showIncomingMessageDialog(String message) {
    // Show alert dialog only for messages
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New piece to play, do you want to open it?'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.popUntil(context, (route) => route.isFirst);
              final String? instrument = await UserPreferences.getActiveGroupInstrument();
              final directory = await getApplicationDocumentsDirectory();
              final filePath = '${directory.path}/$message-$instrument.pdf';
              File messageFile = File(filePath);
              PdfNotesFile doc = PdfNotesFile(messageFile);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ReaderScreen([doc], doc.name)));
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Disconnect WebSocket when leaving HomeScreen
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
