import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';


class ReaderScreen extends StatefulWidget{
  ReaderScreen(this.doc,{super.key});
  String doc;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late PdfController pdfControllerPinch;

  int totalPageCount = 0,
      currentPage = 1;

  @override
  void initState() {
    super.initState();
    pdfControllerPinch = PdfController(document: PdfDocument.openFile(widget.doc));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Theme
              .of(context)
              .colorScheme
              .inversePrimary,
          leading: IconButton(onPressed: () {}, icon: Icon(Icons.menu)),
          title: Text('Flutter PDF View')
      ),
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
            IconButton(onPressed: () {
              pdfControllerPinch.previousPage(
                duration: Duration(milliseconds: 500), curve: Curves.linear,);
            }, icon: Icon(Icons.arrow_back,)),
            Text('$currentPage/$totalPageCount'),
            IconButton(onPressed: () {
              pdfControllerPinch.nextPage(
                duration: Duration(milliseconds: 500), curve: Curves.linear,);
            }, icon: Icon(Icons.arrow_forward,)),
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