// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_web_libraries_in_flutter

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

  const DocumentViewScreen({super.key, required this.document});

  @override
  State<DocumentViewScreen> createState() => _DocumentViewScreenState();
}

class _DocumentViewScreenState extends State<DocumentViewScreen> {
  final DocumentService _documentService = DocumentService();
  final SignatureService _signatureService = SignatureService();
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  Offset? _tapPosition;
  Uint8List? _signatureBytes;
  bool _isSelectingPosition = false;
  bool _isSigning = false;
  bool _isSelectingSavedSignature = false;
  bool _isLoadingAction = false;
  int _currentPageIndex = 0;

  // Selected signature for dragging
  int? _selectedSignatureIndex;
  bool _isDraggingSignature = false;

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
    _saveAsNameController.text = _createDefaultSignedFilename(_currentDocumentState.name);
  }

  String _createDefaultSignedFilename(String originalName) {
    if (originalName.toLowerCase().endsWith('.pdf')) {
      return originalName.substring(0, originalName.length - 4) + '_signed.pdf';
    } else {
      return originalName + '_signed.pdf';
    }
  }

  Future<void> _loadDocumentBytesForViewer() async {
    setState(() {
      _isLoadingDocumentBytes = true;
      _loadingError = null;
    });
    try {
      final bytes = await _currentDocumentState.getBytes();
      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          setState(() {
            _loadingError = 'Error: Document data is empty or invalid.';
            _isLoadingDocumentBytes = false;
          });
        }
        return;
      }

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

  Future<void> _navigateToSignaturesScreen() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const SignaturesScreen()));

    // Refresh signatures when returning from signatures screen
    await _loadSavedSignatures();
  }

  void _showSigningOptions() {
    if (mounted) {
      setState(() {
        _signatureBytes = null;
        _isSelectingPosition = false;
      });
    }

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.draw),
                title: const Text('Draw new signature'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _signatureBytes = null;
                    _isSigning = true;
                  });
                },
              ),
              if (_savedSignatures.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.bookmark),
                  title: const Text('Use saved signature'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _signatureBytes = null;
                      _isSelectingSavedSignature = true;
                    });
                  },
                ),
              if (_savedSignatures.isEmpty) const ListTile(leading: Icon(Icons.info_outline), title: Text('No saved signatures available'), subtitle: Text('Draw a new signature first')),
              ListTile(
                leading: const Icon(Icons.touch_app),
                title: const Text('Select position first'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _signatureBytes = null;
                    _isSelectingPosition = true;
                  });
                  ScaffoldMessenger.of(context).removeCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tap where you want to place your signature')));
                },
              ),
            ],
          ),
    );
  }

  void _promptForSignatureType() {
    if (_tapPosition == null) return;

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.draw),
                title: const Text('Draw new signature'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _signatureBytes = null;
                    _isSigning = true;
                  });
                },
              ),
              if (_savedSignatures.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.bookmark),
                  title: const Text('Use saved signature'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _signatureBytes = null;
                      _isSelectingSavedSignature = true;
                    });
                  },
                ),
              if (_savedSignatures.isEmpty) const ListTile(leading: Icon(Icons.info_outline), title: Text('No saved signatures available'), subtitle: Text('Draw a new signature first')),
            ],
          ),
    );
  }

  void _addSignatureToPreview() {
    if (_signatureBytes == null || _tapPosition == null) return;

    setState(() {
      _addedSignatures.add({'bytes': _signatureBytes!, 'position': _tapPosition!, 'pageIndex': _currentPageIndex, 'width': 150.0, 'height': 70.0, 'id': DateTime.now().millisecondsSinceEpoch});
      _showAddedSignatures = true;
      _tapPosition = null;
    });
  }

  Future<void> _saveSignedDocument() async {
    final fileName = _saveAsNameController.text.trim();
    if (fileName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a file name')));
      return;
    }

    if (_addedSignatures.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one signature')));
      return;
    }

    if (_pdfViewerKey.currentState == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF Viewer not ready. Please wait and try again.')));
      return;
    }

    setState(() {
      _isLoadingAction = true;
    });

    try {
      List<Map<String, dynamic>> signaturesForService = [];

      for (var sigData in _addedSignatures) {
        // Get page information to convert screen coordinates to PDF coordinates
        final pageIndex = sigData['pageIndex'] as int;
        final position = sigData['position'] as Offset;
        final width = sigData['width'] as double;
        final height = sigData['height'] as double;

        // Calculate PDF coordinates
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        // Get the PDF page dimensions - This is an estimation since we don't have direct access
        // to page dimensions from SfPdfViewer. In production, these values should be obtained properly.
        final page = _pdfViewerController.pageNumber - 1 == pageIndex ? _pdfViewerController.pageNumber : pageIndex + 1;

        final pdfPosition = Offset(
          // Convert to proportional position relative to screen size
          (position.dx - (width / 2)) / screenWidth * 612, // Assuming standard PDF width of 612 points
          (position.dy - (height / 2)) / screenHeight * 792, // Assuming standard PDF height of 792 points
        );

        // Scale width and height to PDF dimensions
        final pdfWidth = (width / screenWidth) * 612;
        final pdfHeight = (height / screenHeight) * 792;

        signaturesForService.add({'bytes': sigData['bytes'], 'pageIndex': pageIndex, 'pdfPosition': pdfPosition, 'pdfWidth': pdfWidth, 'pdfHeight': pdfHeight});
      }

      if (signaturesForService.isEmpty && _addedSignatures.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No signatures prepared for saving.')));
        setState(() {
          _isLoadingAction = false;
        });
        return;
      }

      final updatedDocument = await _documentService.addMultipleSignaturesToDocument(_currentDocumentState, signaturesForService);

      if (updatedDocument != null) {
        // Download the document with the provided name
        final downloadSuccess = await _documentService.downloadDocument(updatedDocument, fileName: fileName.endsWith('.pdf') ? fileName : '$fileName.pdf');

        if (downloadSuccess) {
          setState(() {
            _currentDocumentState = updatedDocument;
            _addedSignatures.clear();
            _showAddedSignatures = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document saved successfully')));
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to download the document')));
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save the document')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving document: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAction = false;
        });
      }
    }
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Save Document'),
            content: TextField(controller: _saveAsNameController, decoration: const InputDecoration(labelText: 'File Name', hintText: 'Enter file name with .pdf extension')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _saveSignedDocument();
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
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
            Positioned.fill(
              child: SfPdfViewer.memory(
                _documentBytesForViewer!,
                key: _pdfViewerKey,
                controller: _pdfViewerController,
                onTap: (PdfGestureDetails details) {
                  print('SfPdfViewer tapped at: ${details.position}, Page: ${_pdfViewerController.pageNumber}');

                  if (_isSelectingPosition) {
                    setState(() {
                      _tapPosition = details.position;
                      _isSelectingPosition = false;

                      if (_signatureBytes != null) {
                        _addSignatureToPreview();
                        _isSelectingPosition = true;
                        ScaffoldMessenger.of(context).removeCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signature placed. Tap document to place again, or use App Bar to change/cancel.')));
                      } else {
                        _promptForSignatureType();
                      }
                    });
                  } else {
                    // Deselect signature when tapping elsewhere
                    setState(() {
                      _selectedSignatureIndex = null;
                      _isDraggingSignature = false;
                    });
                  }
                },
                onPageChanged: (PdfPageChangedDetails details) {
                  setState(() {
                    _currentPageIndex = details.newPageNumber - 1; // Pages are 1-indexed
                    _selectedSignatureIndex = null; // Deselect when changing pages
                  });
                },
                enableDoubleTapZooming: !_isSelectingPosition && !_isDraggingSignature,
                canShowPaginationDialog: true,
              ),
            )
          else
            const Center(child: Text('Document data is not available.')),

          // Display draggable signatures on the current page
          if (!_isLoadingDocumentBytes && _documentBytesForViewer != null && _addedSignatures.isNotEmpty) ..._buildDraggableSignatures(),

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
                          if (_tapPosition != null) {
                            _addSignatureToPreview();
                            _isSelectingPosition = true;
                            ScaffoldMessenger.of(context).removeCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Drawn signature placed. Tap document to place again.')));
                          } else {
                            _isSelectingPosition = true;
                            ScaffoldMessenger.of(context).removeCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signature drawn. Now tap where you want to place it.')));
                          }
                        });
                      },
                      allowSaveWithName: true,
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
                                      if (_tapPosition != null) {
                                        _addSignatureToPreview();
                                        _isSelectingPosition = true;
                                        ScaffoldMessenger.of(context).removeCurrentSnackBar();
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved signature placed. Tap document to place again.')));
                                      } else {
                                        _isSelectingPosition = true;
                                        ScaffoldMessenger.of(context).removeCurrentSnackBar();
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved signature selected. Tap where you want to place it.')));
                                      }
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
    );
  }

  // Build draggable signatures that are on the current page
  List<Widget> _buildDraggableSignatures() {
    final List<Widget> result = [];

    for (int i = 0; i < _addedSignatures.length; i++) {
      final sig = _addedSignatures[i];
      final int sigPageIndex = sig['pageIndex'] ?? 0;

      // Only show signatures for the current page
      if (sigPageIndex == _currentPageIndex) {
        final Offset position = sig['position'];
        final double width = sig['width'] ?? 150.0;
        final double height = sig['height'] ?? 70.0;
        final bool isSelected = _selectedSignatureIndex == i;

        result.add(
          Positioned(
            left: position.dx - (width / 2),
            top: position.dy - (height / 2),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  // Toggle selection
                  _selectedSignatureIndex = isSelected ? null : i;
                  _isDraggingSignature = false;
                });
              },
              onPanStart: (_) {
                setState(() {
                  _selectedSignatureIndex = i;
                  _isDraggingSignature = true;
                });
              },
              onPanUpdate: (details) {
                if (_selectedSignatureIndex == i) {
                  setState(() {
                    // Update signature position
                    final updatedSig = Map<String, dynamic>.from(_addedSignatures[i]);

                    // Get current position and add the delta
                    final currentPos = updatedSig['position'] as Offset;
                    final newPosition = Offset(currentPos.dx + details.delta.dx, currentPos.dy + details.delta.dy);

                    // Ensure signature stays within reasonable bounds
                    final updatedPosition = Offset(newPosition.dx.clamp(width / 2, MediaQuery.of(context).size.width - width / 2), newPosition.dy.clamp(height / 2, MediaQuery.of(context).size.height - height / 2));

                    updatedSig['position'] = updatedPosition;
                    _addedSignatures[i] = updatedSig;
                  });
                }
              },
              onPanEnd: (_) {
                setState(() {
                  _isDraggingSignature = false;
                });
              },
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(border: Border.all(color: isSelected ? Colors.blue : Colors.transparent, width: 2.0)),
                child: Stack(
                  children: [
                    // Signature image
                    Positioned.fill(child: Image.memory(sig['bytes'], fit: BoxFit.contain)),

                    // Delete button for selected signature
                    if (isSelected)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _addedSignatures.removeAt(i);
                              _selectedSignatureIndex = null;
                              if (_addedSignatures.isEmpty) {
                                _showAddedSignatures = false;
                              }
                            });
                          },
                          child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, size: 16, color: Colors.white)),
                        ),
                      ),

                    // Resize handle for selected signature
                    if (isSelected)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              // Update signature size
                              final updatedSig = Map<String, dynamic>.from(_addedSignatures[i]);

                              // Increase/decrease width and height
                              double newWidth = (updatedSig['width'] as double) + details.delta.dx;
                              double newHeight = (updatedSig['height'] as double) + details.delta.dy;

                              // Ensure minimum size
                              updatedSig['width'] = newWidth.clamp(50.0, 300.0);
                              updatedSig['height'] = newHeight.clamp(30.0, 150.0);

                              _addedSignatures[i] = updatedSig;
                            });
                          },
                          child: Container(width: 20, height: 20, decoration: BoxDecoration(color: Colors.blue.withOpacity(0.5), shape: BoxShape.circle), child: const Icon(Icons.open_with, size: 14, color: Colors.white)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    return result;
  }
}
