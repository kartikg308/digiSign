import 'dart:typed_data';

class Signature {
  final int? id;
  final String name;
  final Uint8List bytes;
  final DateTime dateCreated;

  Signature({this.id, required this.name, required this.bytes, required this.dateCreated});

  Signature copyWith({int? id, String? name, Uint8List? bytes, DateTime? dateCreated}) {
    return Signature(id: id ?? this.id, name: name ?? this.name, bytes: bytes ?? this.bytes, dateCreated: dateCreated ?? this.dateCreated);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'bytes': bytes, 'dateCreated': dateCreated.millisecondsSinceEpoch};
  }

  factory Signature.fromMap(Map<String, dynamic> map) {
    return Signature(id: map['id'], name: map['name'], bytes: map['bytes'], dateCreated: DateTime.fromMillisecondsSinceEpoch(map['dateCreated']));
  }

  @override
  String toString() {
    return 'Signature(id: $id, name: $name, dateCreated: $dateCreated)';
  }
}
