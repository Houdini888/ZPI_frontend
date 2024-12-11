import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:zpi_frontend/src/widgets/app_drawer_menu.dart';
import 'package:zpi_frontend/src/models/pdf_document_class.dart';

import '../models/piece.dart';
import '../services/apiservice.dart';
import '../services/user_data.dart';
import '../services/websocketservice.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen(
    this.doc,
    this.title,
      this.band,
      this.startPdfPath,
      {
    super.key,
    this.startPdfIndex = 0,
    this.bpm,
  });

  final List<Piece> doc;
  final String title;
  final String startPdfPath;
  final int startPdfIndex;
  final int? bpm;
  final String band;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late PdfController pdfControllerPinch;
  late int currentPdfIndex;
  late Directory userDirectory;
  late String username;
  late String instrument;

  int totalPageCount = 0, currentPage = 1;

  Timer? _metronomeTimer;
  int currentBeat = 0;
  final int totalBeats = 4;

  @override
  void initState() {
    super.initState();
    pdfControllerPinch = PdfController(
        document:
        PdfDocument.openFile(widget.startPdfPath));

    currentPdfIndex = widget.startPdfIndex;

    _initAsync;
    // Start the metronome if bpm is set
    if (widget.bpm != null && widget.bpm != 0) {
      _startMetronome(widget.bpm!);
    }
  }

  Future<void> _initAsync() async {
    final directory = await getApplicationDocumentsDirectory();
    username = (await UserPreferences.getUserName())!;
    instrument = (await UserPreferences.getActiveGroupInstrument())!;
    userDirectory = Directory('${directory.path}/$username');
  }
  @override
  void dispose() {
    pdfControllerPinch.dispose();
    _metronomeTimer?.cancel();
    super.dispose();
  }

  void _startMetronome(int bpm) {
    _metronomeTimer = Timer.periodic(
      Duration(milliseconds: (60000 / bpm).round()),
      (timer) {
        setState(() {
          currentBeat = (currentBeat + 1) % totalBeats;
        });
      },
    );
  }

  void _stopMetronome() {
    _metronomeTimer?.cancel();
    currentBeat = 0;
    setState(() {});
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
        title: Text(widget.title),
      ),
      drawer: AppDrawer(),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return Focus(
        autofocus: true,
        onKey: (node, event) {
          if (event is RawKeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _goToNextPage();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _goToPreviousPage();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Column(
          children: [
            _pdfView(),
            if (widget.bpm != null && widget.bpm != 0) ...[
              const SizedBox(height: 10),
              _buildMetronome(),
            ],
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.doc.length != 1) Text(currentPdfIndex.toString()),
                if (currentPdfIndex > 0)
                  IconButton(
                    onPressed: () {
                      _nextPiece(false);
                    },
                    icon: const Icon(Icons.keyboard_double_arrow_left),
                  )
                else if (widget.doc.length != 1)
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.keyboard_double_arrow_left),
                    color: Colors.grey,
                  ),
                //prevoius page
                IconButton(
                  onPressed: () {
                    pdfControllerPinch.previousPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.linear,
                    );
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
                Text('$currentPage/$totalPageCount'),
                //next page
                IconButton(
                  onPressed: () {
                    pdfControllerPinch.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.linear,
                    );
                  },
                  icon: const Icon(Icons.arrow_forward),
                ),
                if (currentPdfIndex + 1 < widget.doc.length)
                  IconButton(
                    onPressed: () {
                      _nextPiece(true);
                    },
                    icon: const Icon(Icons.keyboard_double_arrow_right),
                  )
                else if (widget.doc.length != 1)
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.keyboard_double_arrow_right),
                    color: Colors.grey,
                  ),
                if (widget.doc.length != 1)
                  Text((widget.doc.length - 1 - currentPdfIndex).toString())
              ],
            ),
          ],
        ));
  }

  void _goToNextPage() {
    pdfControllerPinch.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.linear,
    );
  }

  void _goToPreviousPage() {
    pdfControllerPinch.previousPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.linear,
    );
  }

  Widget _pdfView() {
    return Expanded(
      child: PdfView(
        scrollDirection: Axis.horizontal,
        controller: pdfControllerPinch,
        onDocumentLoaded: (doc) {
          setState(() {
            totalPageCount = doc.pagesCount;
          });
        },
        onPageChanged: (page) {
          setState(() {
            currentPage = page;
          });
        },
      ),
    );
  }

  Widget _buildMetronome() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalBeats, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          height: 30.0,
          width: 30.0,
          decoration: BoxDecoration(
            color: currentBeat == index ? Colors.red : Colors.grey,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
  Future<void> _nextPiece(bool forward) async{
    //TODO
    if(forward) {
      setState(() {
        currentPdfIndex++;
      });
    } else {
      setState(() {
      currentPdfIndex--;
      });
    }
    _sendMessage(widget.doc[currentPdfIndex].name, widget.doc[currentPdfIndex].bpm.toString());
  }

  Future<void> _handleFileForSender(String piece, String bpm) async {
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
            //TODO
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
      final String groupName = widget.band;

      // Download the file using the ApiService
      final file = await ApiService().downloadFile(
        username: username,
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
