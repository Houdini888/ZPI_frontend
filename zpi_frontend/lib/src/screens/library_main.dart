import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
  List<PdfNotesFile> docsList=[];

  Future _initPdfs() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = appDir.listSync();  // List all files

    final List<PdfNotesFile> loadedPdfs = [];
    for (FileSystemEntity entity in files) {
      if (entity is File) {
        loadedPdfs.add(PdfNotesFile(entity));
      }
    }
    final pdfsList = loadedPdfs.where((string) =>
        string.filePath.endsWith(".pdf")).toList();
    setState(() {
      docsList = pdfsList;
    });
  }

  Future<void> _pickAndSavePdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],  // Allow only PDFs
    );

    if (result != null && result.files.single.path != null) {
      // Get the selected PDF file
      File pickedPdf = File(result.files.single.path!);

      // Get the app's documents directory
      Directory appDir = await getApplicationDocumentsDirectory();

      // Create a unique file name for the PDF
      String fileName = result.files.single.name;

      // Save the PDF to the app's documents directory
      File savedPdf = await pickedPdf.copy('${appDir.path}/$fileName');

      setState(() {
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
           builder: (context) => IconButton( icon: new Icon(Icons.menu),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: _pickAndSavePdf,
            child: Text('Pick and Save PDF'),
          ),
          Text(
            "Pliki",
          ),
          Column(children: docsList.map((doc) => ListTile(
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=> ReaderScreen(doc)));
            },
            onLongPress: (){

            },
            title: Text(doc.name),
            leading: Icon(Icons.picture_as_pdf,
              color: Colors.red,
              size: 32.0,),
          )).toList(),)
        ],
      ),
    ));
  }
}


