// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:async';

class Document {
  final int? id;
  final String name;
  final String path;
  final DateTime dateCreated;
  final DateTime lastUpdated;
  final bool isSigned;
  final html.Blob? blob;

  Document({this.id, required this.name, required this.path, required this.dateCreated, required this.lastUpdated, this.isSigned = false, this.blob});

  Document copyWith({int? id, String? name, String? path, DateTime? dateCreated, DateTime? lastUpdated, bool? isSigned, html.Blob? blob}) {
    return Document(id: id ?? this.id, name: name ?? this.name, path: path ?? this.path, dateCreated: dateCreated ?? this.dateCreated, lastUpdated: lastUpdated ?? this.lastUpdated, isSigned: isSigned ?? this.isSigned, blob: blob ?? this.blob);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'path': path, 'dateCreated': dateCreated.millisecondsSinceEpoch, 'lastUpdated': lastUpdated.millisecondsSinceEpoch, 'isSigned': isSigned ? 1 : 0};
  }

  factory Document.fromMap(Map<String, dynamic> map, {html.Blob? blobData}) {
    return Document(id: map['id'], name: map['name'], path: map['path'], dateCreated: DateTime.fromMillisecondsSinceEpoch(map['dateCreated']), lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated']), isSigned: map['isSigned'] == 1, blob: blobData);
  }

  bool get hasValidBytes => blob != null && blob!.size > 0;

  @override
  String toString() {
    return 'Document(id: $id, name: $name, path: $path, dateCreated: $dateCreated, lastUpdated: $lastUpdated, isSigned: $isSigned, hasBlob: ${blob != null})';
  }

  String get fileSize {
    if (blob == null) return '0 B';

    final bytes = blob!.size;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<Uint8List?> getBytes() async {
    if (blob == null) {
      print('No blob available to read bytes from.');
      return null;
    }

    try {
      final reader = html.FileReader();
      final completer = Completer<Uint8List?>();

      reader.onLoadEnd.listen((event) {
        if (reader.readyState == html.FileReader.DONE) {
          if (reader.result is Uint8List) {
            final result = reader.result as Uint8List;
            print('Successfully read bytes as Uint8List. Size: ${result.length} bytes');
            completer.complete(result);
          } else if (reader.result != null) {
            try {
              final result = Uint8List.fromList(reader.result as List<int>);
              print('Converted result to Uint8List. Size: ${result.length} bytes');
              completer.complete(result);
            } catch (e) {
              print('Error converting result to Uint8List: $e');
              completer.complete(null);
            }
          } else {
            print('Reader result is null after load complete');
            completer.complete(null);
          }
        }
      });

      reader.onError.listen((event) {
        print('Error during file reading: ${reader.error?.toString()}');
        completer.complete(null);
      });

      // Start reading the blob
      reader.readAsArrayBuffer(blob!);

      return await completer.future;
    } catch (e) {
      print('Error reading blob: $e');
      return null;
    }
  }
}
