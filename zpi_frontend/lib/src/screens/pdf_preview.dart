import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
import 'package:zpi_frontend/src/services/user_data.dart';
import 'package:zpi_frontend/src/widgets/app_drawer_menu.dart';
import 'package:zpi_frontend/src/models/pdf_document_class.dart';

import '../widgets/iconselector.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen(
    this.doc,
    this.title, {
    super.key,
    this.startPdfIndex = 0,
    this.bpm,
        this.isAdmin = false,
        this.local = true,
  });

  final List<PdfNotesFile> doc;
  final String title;
  final int startPdfIndex;
  final int? bpm; // Optional bpm field
  final bool isAdmin;
  final bool local;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late PdfController pdfControllerPinch;
  late int currentPdfIndex;

  late String band;
  late String username;
  late String deviceCode;

  int totalPageCount = 0, currentPage = 1;

  Timer? _metronomeTimer;
  int currentBeat = 0;
  final int totalBeats = 4;

  bool _isLoading = true; // Flag to track loading state

  @override
  void initState() {
    super.initState();
    currentPdfIndex = widget.startPdfIndex;
    pdfControllerPinch = PdfController(
        document:
        PdfDocument.openFile(widget.doc[widget.startPdfIndex].filePath));

    // Start the metronome if bpm is set
    if (widget.bpm != null && widget.bpm != 0) {
      _startMetronome(widget.bpm!);
    }

    // Initialize asynchronous data
    initAsync();
  }

  Future<void> initAsync() async {
    username = (await UserPreferences.getUserName())!;
    deviceCode = (await UserPreferences.getSessionCode())!;
    band = (await UserPreferences.getActiveGroup())!;

    setState(() {
      _isLoading = false; // Mark loading as complete
    });
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
          if (!_isLoading)
            widget.local
                ? IconSelector(
              username: username,
              group: band,
              device: deviceCode,
              isAdmin: widget.isAdmin,
            ) : const SizedBox.shrink(),
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
                    currentPdfIndex--;
                    pdfControllerPinch.loadDocument(PdfDocument.openFile(
                        widget.doc[currentPdfIndex].filePath));
                  },
                  icon: const Icon(Icons.keyboard_double_arrow_left),
                )
              else if (widget.doc.length != 1)
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.keyboard_double_arrow_left),
                  color: Colors.grey,
                ),
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
                    currentPdfIndex++;
                    pdfControllerPinch.loadDocument(PdfDocument.openFile(
                        widget.doc[currentPdfIndex].filePath));
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
      ),
    );
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
}
