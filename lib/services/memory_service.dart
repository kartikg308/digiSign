// ignore_for_file: cast_from_null_always_fails

import '../models/document.dart';
import '../models/signature.dart';

/// InMemoryService manages documents and signatures in memory
/// This replaces the database service for web implementation
class InMemoryService {
  static final InMemoryService _instance = InMemoryService._internal();

  // In-memory storage
  final List<Document> _documents = [];
  final List<Signature> _signatures = [];
  int _documentIdCounter = 1;
  int _signatureIdCounter = 1;

  factory InMemoryService() => _instance;

  InMemoryService._internal();

  // Document operations
  Future<int> insertDocument(Document document) async {
    final newId = _documentIdCounter++;
    final newDocument = document.copyWith(id: newId);
    _documents.add(newDocument);
    return newId;
  }

  Future<int> updateDocument(Document document) async {
    final index = _documents.indexWhere((doc) => doc.id == document.id);
    if (index != -1) {
      _documents[index] = document;
      return 1; // 1 document affected
    }
    return 0; // No documents affected
  }

  Future<int> deleteDocument(int id) async {
    final initialLength = _documents.length;
    _documents.removeWhere((doc) => doc.id == id);
    return initialLength - _documents.length; // Number of documents removed
  }

  Future<Document?> getDocument(int id) async {
    return _documents.firstWhere((doc) => doc.id == id, orElse: () => null as Document);
  }

  Future<List<Document>> getAllDocuments({String sortBy = 'lastUpdated', bool descending = true}) async {
    final sorted = List<Document>.from(_documents);

    sorted.sort((a, b) {
      dynamic valueA;
      dynamic valueB;

      switch (sortBy) {
        case 'name':
          valueA = a.name;
          valueB = b.name;
          break;
        case 'dateCreated':
          valueA = a.dateCreated.millisecondsSinceEpoch;
          valueB = b.dateCreated.millisecondsSinceEpoch;
          break;
        case 'lastUpdated':
        default:
          valueA = a.lastUpdated.millisecondsSinceEpoch;
          valueB = b.lastUpdated.millisecondsSinceEpoch;
          break;
      }

      int result = Comparable.compare(valueA, valueB);
      return descending ? -result : result;
    });

    return sorted;
  }

  // Signature operations
  Future<int> insertSignature(Signature signature) async {
    final newId = _signatureIdCounter++;
    final newSignature = signature.copyWith(id: newId);
    _signatures.add(newSignature);
    return newId;
  }

  Future<int> updateSignature(Signature signature) async {
    final index = _signatures.indexWhere((sig) => sig.id == signature.id);
    if (index != -1) {
      _signatures[index] = signature;
      return 1; // 1 signature affected
    }
    return 0; // No signatures affected
  }

  Future<int> deleteSignature(int id) async {
    final initialLength = _signatures.length;
    _signatures.removeWhere((sig) => sig.id == id);
    return initialLength - _signatures.length; // Number of signatures removed
  }

  Future<Signature?> getSignature(int id) async {
    return _signatures.firstWhere((sig) => sig.id == id, orElse: () => null as Signature);
  }

  Future<List<Signature>> getAllSignatures({String sortBy = 'dateCreated', bool descending = true}) async {
    print('Fetching all signatures with sortBy: $sortBy, descending: $descending');
    final sorted = List<Signature>.from(_signatures);

    sorted.sort((a, b) {
      dynamic valueA;
      dynamic valueB;

      switch (sortBy) {
        case 'name':
          valueA = a.name;
          valueB = b.name;
          print('Sorting by name: $valueA vs $valueB');
          break;
        case 'dateCreated':
        default:
          valueA = a.dateCreated.millisecondsSinceEpoch;
          valueB = b.dateCreated.millisecondsSinceEpoch;
          print('Sorting by dateCreated: $valueA vs $valueB');
          break;
      }

      int result = Comparable.compare(valueA, valueB);
      print('Comparison result: $result');
      return descending ? -result : result;
    });

    print('Sorted signatures: ${sorted.map((sig) => sig.name).toList()}');
    return sorted;
  }
}
