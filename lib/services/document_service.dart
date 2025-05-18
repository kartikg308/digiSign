// ignore_for_file: avoid_print, deprecated_member_use

import 'dart:ui';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import '../models/document.dart';
import '../models/signature.dart' as model;
import 'memory_service.dart';

class DocumentService {
  final InMemoryService _memoryService = InMemoryService();

  // Add this getter
  InMemoryService getMemoryService() => _memoryService;

  // Import document for web
  Future<Document?> importDocumentWeb() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true, // Important for web to get bytes directly
      );

      if (result != null && result.files.single.bytes != null) {
        String fileName = result.files.single.name;
        Uint8List fileBytes = result.files.single.bytes!;
        final blob = html.Blob([fileBytes], 'application/pdf');

        // Create document object with file bytes for in-memory storage
        final now = DateTime.now();
        final document = Document(
          name: fileName,
          path: 'memory://$fileName', // Virtual path since we're not saving to disk
          dateCreated: now,
          lastUpdated: now,
          blob: blob, // Store Blob instead of Uint8List
        );

        // Save to in-memory storage
        final id = await _memoryService.insertDocument(document);
        return document.copyWith(id: id);
      }
      return null;
    } catch (e) {
      print('Error importing document: $e');
      return null;
    }
  }

  // Add signature to document from raw bytes - working with memory
  Future<Document?> addSignatureToDocument(Document document, List<int> signatureImageBytes, Offset position) async {
    try {
      Uint8List? documentBytes = await document.getBytes();
      if (documentBytes == null) {
        throw Exception('Document bytes not available from blob');
      }

      // Load the PDF document from bytes
      final PdfDocument pdfDocument = PdfDocument(inputBytes: documentBytes);

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

      // Save the document to bytes
      final List<int> newPdfBytesList = await pdfDocument.save();

      // Dispose the document
      pdfDocument.dispose();

      final newPdfBytes = Uint8List.fromList(newPdfBytesList);
      final newBlob = html.Blob([newPdfBytes], 'application/pdf');

      // Update document in memory service
      final updatedDocument = document.copyWith(lastUpdated: DateTime.now(), isSigned: true, blob: newBlob);
      await _memoryService.updateDocument(updatedDocument);

      return updatedDocument;
    } catch (e) {
      print('Error adding signature: $e');
      return null;
    }
  }

  // Add saved signature to document
  Future<Document?> addSavedSignatureToDocument(Document document, model.Signature signature, Offset position) async {
    return addSignatureToDocument(document, signature.bytes, position);
  }

  // Add multiple signatures to document
  Future<Document?> addMultipleSignaturesToDocument(Document document, List<Map<String, dynamic>> signatures) async {
    try {
      Uint8List? documentBytes = await document.getBytes();
      if (documentBytes == null) {
        throw Exception('Document bytes not available from blob');
      }

      // Load the PDF document from bytes
      final PdfDocument pdfDocument = PdfDocument(inputBytes: documentBytes);

      // Add each signature to the document
      for (var signatureData in signatures) {
        final Uint8List sigBytes = signatureData['bytes'];
        final Offset sigPosition = signatureData['position'];
        final int pageIndex = signatureData['pageIndex'] ?? 0;

        // Create a new PDF bitmap image
        final PdfBitmap image = PdfBitmap(sigBytes);

        // Get the page to add signature (default to first page if invalid index)
        PdfPage page;
        if (pageIndex >= 0 && pageIndex < pdfDocument.pages.count) {
          page = pdfDocument.pages[pageIndex];
        } else {
          page = pdfDocument.pages[0];
        }

        // Draw the signature on the page at the specified position
        page.graphics.drawImage(
          image,
          Rect.fromLTWH(
            sigPosition.dx,
            sigPosition.dy,
            100, // Width of signature
            50, // Height of signature
          ),
        );
      }

      // Save the document to bytes
      final List<int> newPdfBytesList = await pdfDocument.save();

      // Dispose the document
      pdfDocument.dispose();

      final newPdfBytes = Uint8List.fromList(newPdfBytesList);
      final newBlob = html.Blob([newPdfBytes], 'application/pdf');

      // Update document in memory service
      final updatedDocument = document.copyWith(lastUpdated: DateTime.now(), isSigned: true, blob: newBlob);
      await _memoryService.updateDocument(updatedDocument);

      return updatedDocument;
    } catch (e) {
      print('Error adding multiple signatures: $e');
      return null;
    }
  }

  // Add multiple signatures to document bytes
  Future<Uint8List?> addMultipleSignaturesToDocumentBytes(Uint8List documentBytes, List<Map<String, dynamic>> signatures) async {
    try {
      // Load the PDF document from bytes
      final PdfDocument pdfDocument = PdfDocument(inputBytes: documentBytes);

      // Add each signature to the document
      for (var signatureData in signatures) {
        final Uint8List sigBytes = signatureData['bytes'];
        final Offset sigPosition = signatureData['position'];
        final int pageIndex = signatureData['pageIndex'] ?? 0;

        // Create a new PDF bitmap image
        final PdfBitmap image = PdfBitmap(sigBytes);

        // Get the page to add signature (default to first page if invalid index)
        PdfPage page;
        if (pageIndex >= 0 && pageIndex < pdfDocument.pages.count) {
          page = pdfDocument.pages[pageIndex];
        } else {
          page = pdfDocument.pages[0];
        }

        // Draw the signature on the page at the specified position
        page.graphics.drawImage(
          image,
          Rect.fromLTWH(
            sigPosition.dx,
            sigPosition.dy,
            100, // Width of signature
            50, // Height of signature
          ),
        );
      }

      // Save the document to bytes
      final List<int> newPdfBytes = await pdfDocument.save();

      // Dispose the document
      pdfDocument.dispose();

      return Uint8List.fromList(newPdfBytes);
    } catch (e) {
      print('Error adding multiple signatures to document bytes: $e');
      return null;
    }
  }

  // Get all documents
  Future<List<Document>> getAllDocuments({String sortBy = 'lastUpdated', bool descending = true}) async {
    return _memoryService.getAllDocuments(sortBy: sortBy, descending: descending);
  }

  // Delete document
  Future<bool> deleteDocument(Document document) async {
    try {
      // Delete from memory service
      await _memoryService.deleteDocument(document.id!);
      return true;
    } catch (e) {
      print('Error deleting document: $e');
      return false;
    }
  }

  // Share documents
  Future<bool> shareDocument(Document document) async {
    try {
      Uint8List? documentBytes = await document.getBytes();
      if (documentBytes == null) {
        print('Error sharing document: Bytes not available from blob');
        return false;
      }

      // For web sharing, we need to create a blob URL
      // This is handled by the share_plus package
      await Share.shareXFiles([XFile.fromData(documentBytes, name: document.name, mimeType: 'application/pdf')]);

      return true;
    } catch (e) {
      print('Error sharing document: $e');
      return false;
    }
  }
}
