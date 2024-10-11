import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:zpi_frontend/reader_screen.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter PDF View'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int totalPageCount = 0, currentPage = 1;
  List<String> docsList=[];

  Future _initPdfs() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = appDir.listSync();  // List all files

    final List<String> loadedPdfs = [];
    for (FileSystemEntity entity in files) {
      if (entity is File) {
        loadedPdfs.add(entity.path);  // Add all image files to the list
      }
    }
    final pdfsList = loadedPdfs.where((string) =>
        string.endsWith(".pdf")).toList();
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
        docsList.add(savedPdf.path);
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
        leading: IconButton(onPressed:(){},icon: Icon(Icons.menu)),
        title: Text(widget.title)
      ),
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
            title: Text(doc),
            leading: Icon(Icons.picture_as_pdf,
              color: Colors.red,
              size: 32.0,),
          )).toList(),)
        ],
      ),
    ));
  }
}


