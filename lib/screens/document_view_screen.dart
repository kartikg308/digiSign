// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_web_libraries_in_flutter, unused_import

import 'dart:typed_data';
import 'dart:html' as html;
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

  const DocumentViewScreen({super.key, required this.document});

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
  bool _isLoadingAction = false;

  List<model.Signature> _savedSignatures = [];
  List<Map<String, dynamic>> _addedSignatures = [];
  bool _showAddedSignatures = false;
  final TextEditingController _saveAsNameController = TextEditingController();

  Uint8List? _documentBytesForViewer;
  bool _isLoadingDocumentBytes = true;
  String? _loadingError;
  late Document _currentDocumentState;

  @override
  void initState() {
    super.initState();
    _currentDocumentState = widget.document;
    _loadDocumentBytesForViewer();
    _loadSavedSignatures();
    _saveAsNameController.text = _currentDocumentState.name.replaceAll('.pdf', '_signed.pdf');
  }

  Future<void> _loadDocumentBytesForViewer() async {
    setState(() {
      _isLoadingDocumentBytes = true;
      _loadingError = null;
    });
    try {
      final bytes = await _currentDocumentState.getBytes();
      if (mounted) {
        setState(() {
          _documentBytesForViewer = bytes;
          _isLoadingDocumentBytes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingError = 'Error loading document: $e';
          _isLoadingDocumentBytes = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _saveAsNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedSignatures() async {
    _savedSignatures = await _signatureService.getAllSignatures();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentDocumentState.name),
        actions: [
          if (!_isSelectingPosition && !_isSigning && !_isSelectingSavedSignature) IconButton(icon: const Icon(Icons.manage_accounts), onPressed: _navigateToSignaturesScreen, tooltip: 'Manage Signatures'),
          if (!_isSelectingPosition && !_isSigning && !_isSelectingSavedSignature && !_currentDocumentState.isSigned) IconButton(icon: const Icon(Icons.draw), onPressed: _showSigningOptions, tooltip: 'Add Signature'),
          if (_addedSignatures.isNotEmpty && !_isSelectingPosition && !_isSigning && !_isSelectingSavedSignature) IconButton(icon: const Icon(Icons.save), onPressed: _showSaveDialog, tooltip: 'Save Document'),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoadingDocumentBytes)
            const Center(child: CircularProgressIndicator(semanticsLabel: 'Loading document...'))
          else if (_loadingError != null)
            Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_loadingError!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)))
          else if (_documentBytesForViewer != null)
            SfPdfViewer.memory(
              _documentBytesForViewer!,
              controller: _pdfViewerController,
              onTap: (PdfGestureDetails details) {
                if (_isSelectingPosition) {
                  setState(() {
                    _tapPosition = details.position;
                    _isSelectingPosition = false;
                    _promptForSignatureType();
                  });
                }
              },
              enableDoubleTapZooming: !_isSelectingPosition,
            )
          else
            const Center(child: Text('Document data is not available.')),

          if (_isSelectingPosition) Positioned(top: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.all(8), color: Colors.black87, child: const Text('Tap where you want to place your signature', style: TextStyle(color: Colors.white), textAlign: TextAlign.center))),

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

          if (_isLoadingAction) Container(color: Colors.black45, child: const Center(child: CircularProgressIndicator())),

          if (_showAddedSignatures && _addedSignatures.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(8), boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]),
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
                        ElevatedButton(onPressed: _showSaveDialog, child: const Text('Save Document')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _addedSignatures.isNotEmpty && !_showAddedSignatures && !_isSelectingPosition && !_isSigning && !_isSelectingSavedSignature ? FloatingActionButton(onPressed: () => setState(() => _showAddedSignatures = true), child: const Icon(Icons.edit)) : null,
    );
  }

  void _navigateToSignaturesScreen() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const SignaturesScreen()));
    _loadSavedSignatures();
  }

  void _promptForSignatureType() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_square),
                title: const Text('Create New Signature'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _isSigning = true);
                },
              ),
              if (_savedSignatures.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.archive),
                  title: const Text('Use Saved Signature'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _isSelectingSavedSignature = true);
                  },
                ),
            ],
          ),
    );
  }

  void _addSignatureToPreview() {
    if (_signatureBytes != null && _tapPosition != null) {
      final currentPage = _pdfViewerController.pageNumber;
      setState(() {
        _addedSignatures.add({'bytes': _signatureBytes!, 'position': _tapPosition!, 'pageIndex': currentPage - 1});
        _signatureBytes = null;
        _tapPosition = null;
        _showAddedSignatures = true;
      });
    }
  }

  void _showSigningOptions() {
    setState(() {
      _isSelectingPosition = true;
      _addedSignatures.clear();
      _showAddedSignatures = false;
    });
  }

  Future<void> _showSaveDialog() async {
    final currentContext = context;
    showDialog(
      context: currentContext,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Save Signed Document'),
            content: TextField(controller: _saveAsNameController, decoration: const InputDecoration(labelText: 'Save as...')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await _applySignaturesAndSave(_saveAsNameController.text);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  Future<void> _applySignaturesAndSave(String newName) async {
    if (_addedSignatures.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No signatures added to apply.')));
      return;
    }
    setState(() => _isLoadingAction = true);
    Document? updatedDoc;
    if (_addedSignatures.length == 1) {
      final sigData = _addedSignatures.first;
      updatedDoc = await _documentService.addSignatureToDocument(_currentDocumentState, sigData['bytes'], sigData['position']);
    } else {
      updatedDoc = await _documentService.addMultipleSignaturesToDocument(_currentDocumentState, _addedSignatures);
    }

    if (updatedDoc != null) {
      final finalDocument = updatedDoc.copyWith(name: newName.endsWith('.pdf') ? newName : '$newName.pdf');
      await _documentService.getMemoryService().updateDocument(finalDocument);

      setState(() {
        _currentDocumentState = finalDocument;
        _addedSignatures.clear();
        _showAddedSignatures = false;
        _isLoadingAction = false;
      });
      _loadDocumentBytesForViewer();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Document "${finalDocument.name}" saved successfully!')));
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      }
    } else {
      setState(() => _isLoadingAction = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save document.')));
    }
  }
}
