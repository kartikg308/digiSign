import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/document.dart';
import '../services/document_service.dart';
import '../widgets/signature_pad.dart';

class DocumentViewScreen extends StatefulWidget {
  final Document document;

  const DocumentViewScreen({super.key, required this.document});

  @override
  State<DocumentViewScreen> createState() => _DocumentViewScreenState();
}

class _DocumentViewScreenState extends State<DocumentViewScreen> {
  final DocumentService _documentService = DocumentService();
  final PdfViewerController _pdfViewerController = PdfViewerController();
  Offset? _tapPosition;
  Uint8List? _signatureBytes;
  bool _isSelectingPosition = false;
  bool _isSigning = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.document.name), actions: [if (!_isSelectingPosition && !_isSigning && !widget.document.isSigned) IconButton(icon: const Icon(Icons.edit), onPressed: _startSigningProcess)]),
      body: Stack(
        children: [
          // PDF Viewer
          SfPdfViewer.file(widget.document.file, controller: _pdfViewerController, onTap: _isSelectingPosition ? _handleTap : null, enableDoubleTapZooming: !_isSelectingPosition),

          // Overlay for position selection
          if (_isSelectingPosition) Positioned(top: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.all(8), color: Colors.black87, child: const Text('Tap where you want to place your signature', style: TextStyle(color: Colors.white), textAlign: TextAlign.center))),

          // Signature input overlay
          if (_isSigning)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Create Your Signature', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SignaturePadWidget(
                      onSave: (bytes) {
                        setState(() {
                          _signatureBytes = bytes;
                          _isSigning = false;
                          _addSignatureToDocument();
                        });
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSigning = false;
                        _isSelectingPosition = false;
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),

          // Loading indicator
          if (_isLoading) Container(color: Colors.black45, child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  void _startSigningProcess() {
    setState(() {
      _isSelectingPosition = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tap where you want to place your signature'), duration: Duration(seconds: 3)));
  }

  void _handleTap(PdfGestureDetails details) {
    setState(() {
      _tapPosition = details.position;
      _isSelectingPosition = false;
      _isSigning = true;
    });
  }

  Future<void> _addSignatureToDocument() async {
    if (_signatureBytes == null || _tapPosition == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Add signature to document
      final updatedDocument = await _documentService.addSignatureToDocument(widget.document, _signatureBytes!, _tapPosition!);

      if (updatedDocument != null) {
        // Reload the PDF viewer
        setState(() {
          _pdfViewerController.zoomLevel = 1.0; // Reset zoom level
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document signed successfully')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to sign document')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
        _signatureBytes = null;
        _tapPosition = null;
      });
    }
  }
}
