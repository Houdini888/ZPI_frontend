import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zpi_frontend/src/services/user_data.dart';
import 'package:zpi_frontend/src/widgets/app_drawer_menu.dart';
import 'package:zpi_frontend/src/models/pdf_document_class.dart';
import 'package:zpi_frontend/src/screens/pdf_preview.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LibraryMainPage extends StatefulWidget {
  const LibraryMainPage({super.key, required this.title});

  final String title;

  @override
  State<LibraryMainPage> createState() => _LibraryMainPageState();
}

class _LibraryMainPageState extends State<LibraryMainPage> {
  List<PdfNotesFile> docsList = [];

  final Future<SharedPreferencesWithCache> _prefs =
  SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
      ));

  Future _initPdfs() async {
    String? username = await UserPreferences.getUserName();
    final Directory appDir = await getApplicationDocumentsDirectory();
    final userDirectory = Directory('${appDir.path}/$username');
    final List<FileSystemEntity> files = userDirectory.listSync(); // List all files

    final List<PdfNotesFile> loadedPdfs = [];
    for (FileSystemEntity entity in files) {
      if (entity is File) {
        loadedPdfs.add(PdfNotesFile(entity));
      }
    }
    final pdfsList =
        loadedPdfs.where((string) => string.filePath.endsWith(".pdf")).toList();

    pdfsList.sort();

    setState(() {
      docsList = pdfsList;
    });
  }

  Future<void> _pickAndSavePdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'], // Allow only PDFs
    );

    if (result != null && result.files.single.path != null) {
      // Get the selected PDF file
      File pickedPdf = File(result.files.single.path!);

      String? username = await UserPreferences.getUserName();
      final Directory appDir = await getApplicationDocumentsDirectory();
      final userDirectory = Directory('${appDir.path}/$username');

      // Create a unique file name for the PDF
      String fileName = result.files.single.name;

      // Save the PDF to the app's documents directory
      File savedPdf = await pickedPdf.copy('${userDirectory.path}/$fileName');

      setState(() {
        if(!docsList.contains(PdfNotesFile(savedPdf)))
          docsList.add(PdfNotesFile(savedPdf));
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initPdfs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: Builder(
          builder: (context) => IconButton(
            icon: new Icon(Icons.menu),
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
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
        child: SingleChildScrollView(
          physics: ScrollPhysics(),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
            ElevatedButton(
              onPressed: _pickAndSavePdf,
              child: Text('Pick and Save PDF'),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: docsList.length,
              itemBuilder: (context, index) {
                final pdfName = docsList[index].name;
                return Slidable(
                  key: Key(pdfName),
                  startActionPane:
                      ActionPane(motion: const StretchMotion(), children: [
                    SlidableAction(
                      backgroundColor: Colors.red,
                      icon: Icons.delete,
                      label: 'Delete',
                      onPressed: (context) => _onDismissed(index),
                    )
                  ]),
                  child: buildPdfTile(docsList[index]),
                );
              },
            ),
          ]),
        ));
  }

  Widget buildPdfTile(PdfNotesFile doc) => ListTile(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ReaderScreen([doc], doc.name)));
        },
        title: Text(doc.name),
        leading: const Icon(
          Icons.picture_as_pdf,
          color: Colors.red,
          size: 32.0,
        ),
      );

  Future<void> _onDismissed(int index) async {
    final SharedPreferencesWithCache prefs = await _prefs;
    final List<String> list = (prefs.getStringList('setlists') ?? []);
    File pdfToDelete = File(docsList[index].filePath);
    pdfToDelete.delete();

    for(String setlist in list)
      {
        final List<String> pdfsList = (prefs.getStringList(setlist) ?? []);

        pdfsList.removeWhere((item) => item == docsList[index].name);

        await prefs.setStringList(setlist,pdfsList);
      }

    docsList.removeAt(index);

    setState(() {});
  }
}
