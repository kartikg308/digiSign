import 'dart:io';

class Document {
  final int? id;
  final String name;
  final String path;
  final DateTime dateCreated;
  final DateTime lastUpdated;
  final bool isSigned;

  Document({
    this.id,
    required this.name,
    required this.path,
    required this.dateCreated,
    required this.lastUpdated,
    this.isSigned = false,
  });

  Document copyWith({
    int? id,
    String? name,
    String? path,
    DateTime? dateCreated,
    DateTime? lastUpdated,
    bool? isSigned,
  }) {
    return Document(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      dateCreated: dateCreated ?? this.dateCreated,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isSigned: isSigned ?? this.isSigned,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'dateCreated': dateCreated.millisecondsSinceEpoch,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'isSigned': isSigned ? 1 : 0,
    };
  }

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'],
      name: map['name'],
      path: map['path'],
      dateCreated: DateTime.fromMillisecondsSinceEpoch(map['dateCreated']),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated']),
      isSigned: map['isSigned'] == 1,
    );
  }

  File get file => File(path);

  @override
  String toString() {
    return 'Document(id: $id, name: $name, path: $path, dateCreated: $dateCreated, lastUpdated: $lastUpdated, isSigned: $isSigned)';
  }
}
