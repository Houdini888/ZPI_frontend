import 'package:crypto/crypto.dart';
import 'package:async/async.dart';
import 'package:convert/convert.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class PdfNotesFile implements Comparable<PdfNotesFile>{
  String filePath;
  String name;
  Future<Digest> hash;

  PdfNotesFile(File file)
      : filePath = file.path,
        name = path.basenameWithoutExtension(file.path),
        hash = getFileSha256(file);

  int compareTo(PdfNotesFile other) {
    return name.compareTo(other.name);
  }

  @override
  bool operator ==(Object other) {
    return other is PdfNotesFile
    && other.name == name;
  }
}
Future<Digest> getFileSha256(File file) async {
  final reader = ChunkedStreamReader(file.openRead());
  const chunkSize = 4096;
  var output = AccumulatorSink<Digest>();
  var input = sha256.startChunkedConversion(output);

  try {
    while (true) {
      final chunk = await reader.readChunk(chunkSize);
      if (chunk.isEmpty) {
        break;
      }
      input.add(chunk);
    }
  } finally {
    reader.cancel();
  }

  input.close();

  return output.events.single;
}