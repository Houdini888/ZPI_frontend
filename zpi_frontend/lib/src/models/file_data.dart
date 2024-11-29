class FileData {
  final int fileId;
  final String hash;
  final String fileType;
  final String fileName;
  final String instrument;
  final String piece;
  final String bpm;

  FileData({
    required this.fileId,
    required this.hash,
    required this.fileType,
    required this.fileName,
    required this.instrument,
    required this.piece,
    required this.bpm,
  });

  factory FileData.fromJson(Map<String, dynamic> json) {
    return FileData(
      fileId: json['file_id'],
      hash: json['hash'],
      fileType: json['file_type'],
      fileName: json['file_name'],
      instrument: json['instrument'],
      piece: json['piece'],
      bpm: json['bpm'],
    );
  }
}
