
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:zpi_frontend/src/widgets/app_drawer_menu.dart';
import 'package:zpi_frontend/src/models/pdf_document_class.dart';


class ReaderScreen extends StatefulWidget{
  const ReaderScreen(this.doc,this.title,{super.key, this.startPdfIndex = 0});
  final List<PdfNotesFile> doc;
  final String title;
  final int startPdfIndex;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late PdfController pdfControllerPinch;
  late int currentPdfIndex;

  int totalPageCount = 0,
      currentPage = 1;

  @override
  void initState() {
    super.initState();
    currentPdfIndex = widget.startPdfIndex;
    pdfControllerPinch = PdfController(document: PdfDocument.openFile(widget.doc[widget.startPdfIndex].filePath));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Theme
              .of(context)
              .colorScheme
              .inversePrimary,
          leading: Builder(
            builder: (context) => IconButton(
              icon: new Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Text(widget.title)
      ),
      drawer: AppDrawer(),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return Column(
      children: [
        _pdfView(),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if(widget.doc.length!=1)
            Text(currentPdfIndex.toString()),
            if(currentPdfIndex>0)
              IconButton(onPressed: () {
                {
                  currentPdfIndex--;
                  pdfControllerPinch.loadDocument(PdfDocument.openFile(
                      widget.doc[currentPdfIndex].filePath));
                }
              },
                  icon: const Icon(Icons.keyboard_double_arrow_left,))
            else if(widget.doc.length!=1)
              IconButton(onPressed: () {},
                icon: const Icon(Icons.keyboard_double_arrow_left,),
                color: Colors.grey,),
            IconButton(onPressed: () {
              pdfControllerPinch.previousPage(
                duration: Duration(milliseconds: 500), curve: Curves.linear,);
            }, icon: Icon(Icons.arrow_back,)),
            Text('$currentPage/$totalPageCount'),
            IconButton(onPressed: () {
              pdfControllerPinch.nextPage(
                duration: Duration(milliseconds: 500), curve: Curves.linear,);
            }, icon: Icon(Icons.arrow_forward,)),
             if(currentPdfIndex+1<widget.doc.length)
              IconButton(onPressed: () {
                {

                  currentPdfIndex++;
                  pdfControllerPinch.loadDocument(PdfDocument.openFile(
                      widget.doc[currentPdfIndex].filePath));
                }
                },
                icon: const Icon(Icons.keyboard_double_arrow_right,))
            else if(widget.doc.length != 1)
              IconButton(onPressed: () {},
                  icon: const Icon(Icons.keyboard_double_arrow_right,),
              color: Colors.grey,),
            if(widget.doc.length!=1)
              Text((widget.doc.length-1-currentPdfIndex).toString())
          ],),
      ],
    );
  }

  Widget _pdfView() {
    return Expanded(child:
    PdfView(scrollDirection: Axis.horizontal,
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
    ));
  }
}