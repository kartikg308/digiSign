import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/document.dart';
import '../models/signature.dart' as model;
import '../services/document_service.dart';
import '../services/signature_service.dart';
import '../widgets/signature_pad.dart';
import 'signatures_screen.dart';

class DocumentViewScreen extends StatefulWidget {
  final Document document;

  const DocumentViewScreen({Key? key, required this.document}) : super(key: key);

  @override
  State<DocumentViewScreen> createState() => _DocumentViewScreenState();
}

class _DocumentViewScreenState extends State<DocumentViewScreen> {
  final DocumentService _documentService = DocumentService();
  final SignatureService _signatureService = SignatureService();
  final PdfViewerController _pdfViewerController = PdfViewerController();

  Offset? _tapPosition;
  Uint8List? _signatureBytes;
  bool _isSelectingPosition = false;
  bool _isSigning = false;
  bool _isSelectingSavedSignature = false;
  bool _isLoading = false;

  List<model.Signature> _savedSignatures = [];
  List<Map<String, dynamic>> _addedSignatures = [];
  bool _showAddedSignatures = false;

  @override
  void initState() {
    super.initState();
    _loadSavedSignatures();
  }

  Future<void> _loadSavedSignatures() async {
    _savedSignatures = await _signatureService.getAllSignatures();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document.name),
        actions: [
          if (!_isSelectingPosition && !_isSigning && !_isSelectingSavedSignature) IconButton(icon: const Icon(Icons.manage_accounts), onPressed: _navigateToSignaturesScreen, tooltip: 'Manage Signatures'),
          if (!_isSelectingPosition && !_isSigning && !_isSelectingSavedSignature && !widget.document.isSigned) IconButton(icon: const Icon(Icons.draw), onPressed: _showSigningOptions, tooltip: 'Add Signature'),
          if (_addedSignatures.isNotEmpty && !_isSelectingPosition && !_isSigning && !_isSelectingSavedSignature) IconButton(icon: const Icon(Icons.save), onPressed: _saveAllSignatures, tooltip: 'Save All Signatures'),
        ],
      ),
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
                          _addSignatureToPreview();
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

          // Saved signatures selection overlay
          if (_isSelectingSavedSignature)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Select a Saved Signature', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child:
                        _savedSignatures.isEmpty
                            ? const Center(child: Text('No saved signatures. Create one first.'))
                            : ListView.builder(
                              itemCount: _savedSignatures.length,
                              itemBuilder: (context, index) {
                                final signature = _savedSignatures[index];
                                return ListTile(
                                  leading: Container(width: 60, height: 30, decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)), child: Image.memory(signature.bytes, fit: BoxFit.contain)),
                                  title: Text(signature.name),
                                  onTap: () {
                                    setState(() {
                                      _signatureBytes = signature.bytes;
                                      _isSelectingSavedSignature = false;
                                      _addSignatureToPreview();
                                    });
                                  },
                                );
                              },
                            ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSelectingSavedSignature = false;
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

          // Show temporary signatures that will be added
          if (_showAddedSignatures && _addedSignatures.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Signatures to be added:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _addedSignatures.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                Container(width: 80, height: 80, decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)), child: Image.memory(_addedSignatures[index]['bytes'], fit: BoxFit.contain)),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _addedSignatures.removeAt(index);
                                        if (_addedSignatures.isEmpty) {
                                          _showAddedSignatures = false;
                                        }
                                      });
                                    },
                                    child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, size: 16, color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showAddedSignatures = false;
                            });
                          },
                          child: const Text('Hide'),
                        ),
                        ElevatedButton(onPressed: _saveAllSignatures, child: const Text('Save All')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton:
          _addedSignatures.isNotEmpty && !_showAddedSignatures && !_isSelectingPosition && !_isSigning && !_isSelectingSavedSignature
              ? FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _showAddedSignatures = true;
                  });
                },
                child: const Icon(Icons.edit),
              )
              : null,
    );
  }

  void _navigateToSignaturesScreen() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const SignaturesScreen()));
    // Reload saved signatures when returning from signatures screen
    _loadSavedSignatures();
  }

  void _showSigningOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.draw),
                title: const Text('Create New Signature'),
                onTap: () {
                  Navigator.pop(context);
                  _startSigningProcess();
                },
              ),
              if (_savedSignatures.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.collections),
                  title: const Text('Use Saved Signature'),
                  onTap: () {
                    Navigator.pop(context);
                    _startSavedSignatureSelection();
                  },
                ),
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

  void _startSavedSignatureSelection() {
    setState(() {
      _isSelectingPosition = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tap where you want to place your signature'), duration: Duration(seconds: 3)));
  }

  void _handleTap(PdfGestureDetails details) {
    setState(() {
      _tapPosition = details.position;
      _isSelectingPosition = false;

      if (_savedSignatures.isNotEmpty) {
        _isSelectingSavedSignature = true;
      } else {
        _isSigning = true;
      }
    });
  }

  void _addSignatureToPreview() {
    if (_signatureBytes == null || _tapPosition == null) return;

    setState(() {
      _addedSignatures.add({
        'bytes': _signatureBytes!,
        'position': _tapPosition!,
        'pageIndex': 0, // Currently only supporting first page
      });

      _signatureBytes = null;
      _tapPosition = null;
      _showAddedSignatures = true;
    });
  }

  Future<void> _saveAllSignatures() async {
    if (_addedSignatures.isEmpty) return;

    setState(() {
      _isLoading = true;
      _showAddedSignatures = false;
    });

    try {
      // Add multiple signatures to document
      final updatedDocument = await _documentService.addMultipleSignaturesToDocument(widget.document, _addedSignatures);

      if (updatedDocument != null) {
        // Reload the PDF viewer
        setState(() {
          _pdfViewerController.zoomLevel = 1.0; // Reset zoom level
          _addedSignatures.clear();
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
      });
    }
  }
}
