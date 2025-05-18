import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import '../models/document.dart';
import 'database_service.dart';

class DocumentService {
  final DatabaseService _dbService = DatabaseService();

  // Import document from storage
  Future<Document?> importDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);

      if (result != null) {
        // Get the selected file
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;

        // Copy the file to app documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final appPath = appDir.path;
        final docPath = '$appPath/documents';

        // Create directory if it doesn't exist
        final docDir = Directory(docPath);
        if (!await docDir.exists()) {
          await docDir.create(recursive: true);
        }

        // Copy the file to app documents directory
        final savedFilePath = '$docPath/$fileName';
        await file.copy(savedFilePath);

        // Create document object
        final now = DateTime.now();
        final document = Document(name: fileName, path: savedFilePath, dateCreated: now, lastUpdated: now);

        // Save to database
        final id = await _dbService.insertDocument(document);
        return document.copyWith(id: id);
      }
      return null;
    } catch (e) {
      print('Error importing document: $e');
      return null;
    }
  }

  // Add signature to document
  Future<Document?> addSignatureToDocument(Document document, List<int> signatureImageBytes, Offset position) async {
    try {
      // Load the PDF document
      final File file = File(document.path);
      final PdfDocument pdfDocument = PdfDocument(inputBytes: await file.readAsBytes());

      // Create a new PDF bitmap image
      final PdfBitmap image = PdfBitmap(signatureImageBytes);

      // Get the page to add signature
      PdfPage page = pdfDocument.pages[0];

      // Draw the signature on the page at the specified position
      page.graphics.drawImage(
        image,
        Rect.fromLTWH(
          position.dx,
          position.dy,
          100, // Width of signature
          50, // Height of signature
        ),
      );

      // Save the document
      final List<int> bytes = await pdfDocument.save();
      await file.writeAsBytes(bytes);

      // Dispose the document
      pdfDocument.dispose();

      // Update document in database
      final updatedDocument = document.copyWith(lastUpdated: DateTime.now(), isSigned: true);
      await _dbService.updateDocument(updatedDocument);

      return updatedDocument;
    } catch (e) {
      print('Error adding signature: $e');
      return null;
    }
  }

  // Get all documents
  Future<List<Document>> getAllDocuments({String sortBy = 'lastUpdated', bool descending = true}) async {
    return await _dbService.getAllDocuments(sortBy: sortBy, descending: descending);
  }

  // Delete document
  Future<bool> deleteDocument(Document document) async {
    try {
      // Delete from database
      await _dbService.deleteDocument(document.id!);

      // Delete file
      final file = File(document.path);
      if (await file.exists()) {
        await file.delete();
      }

      return true;
    } catch (e) {
      print('Error deleting document: $e');
      return false;
    }
  }

  // Share documents
  Future<bool> shareDocuments(List<Document> documents) async {
    try {
      if (documents.isEmpty) return false;

      List<XFile> files = documents.map((doc) => XFile(doc.path)).toList();
      await Share.shareXFiles(files);
      return true;
    } catch (e) {
      print('Error sharing documents: $e');
      return false;
    }
  }
}
