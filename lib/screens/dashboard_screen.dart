import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/document.dart';
import '../services/document_service.dart';
import 'document_view_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DocumentService _documentService = DocumentService();
  List<Document> _documents = [];
  bool _isLoading = true;
  final List<Document> _selectedDocuments = [];
  bool _isSelectionMode = false;
  String _sortBy = 'lastUpdated';
  bool _sortDescending = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final documents = await _documentService.getAllDocuments(
        sortBy: _sortBy,
        descending: _sortDescending,
      );
      setState(() {
        _documents = documents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading documents: $e')));
    }
  }

  Future<void> _importDocument() async {
    final document = await _documentService.importDocument();
    if (document != null) {
      _loadDocuments();
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedDocuments.clear();
    });
  }

  void _toggleDocumentSelection(Document document) {
    setState(() {
      if (_selectedDocuments.contains(document)) {
        _selectedDocuments.remove(document);
      } else {
        _selectedDocuments.add(document);
      }
    });
  }

  void _shareSelectedDocuments() async {
    if (_selectedDocuments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select documents to share')),
      );
      return;
    }

    await _documentService.shareDocuments(_selectedDocuments);
    _toggleSelectionMode();
  }

  void _deleteSelectedDocuments() async {
    if (_selectedDocuments.isEmpty) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Documents'),
            content: Text(
              'Are you sure you want to delete ${_selectedDocuments.length} selected documents?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (shouldDelete == true) {
      for (var doc in _selectedDocuments) {
        await _documentService.deleteDocument(doc);
      }
      _toggleSelectionMode();
      _loadDocuments();
    }
  }

  void _changeSortOrder() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Sort by last updated'),
                leading: Radio<String>(
                  value: 'lastUpdated',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                      _loadDocuments();
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Sort by name'),
                leading: Radio<String>(
                  value: 'name',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                      _loadDocuments();
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Sort by date created'),
                leading: Radio<String>(
                  value: 'dateCreated',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                      _loadDocuments();
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Descending order'),
                value: _sortDescending,
                onChanged: (value) {
                  setState(() {
                    _sortDescending = value;
                    _loadDocuments();
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DigiSign'),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareSelectedDocuments,
            ),
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelectedDocuments,
            ),
          if (!_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: _changeSortOrder,
            ),
          IconButton(
            icon: Icon(_isSelectionMode ? Icons.cancel : Icons.select_all),
            onPressed: _toggleSelectionMode,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _documents.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No documents yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Import your first document to get started'),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _importDocument,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Import Document'),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: _documents.length,
                itemBuilder: (context, index) {
                  final document = _documents[index];
                  final isSelected = _selectedDocuments.contains(document);

                  return ListTile(
                    leading: Icon(
                      document.isSigned
                          ? Icons.description
                          : Icons.description_outlined,
                      color: document.isSigned ? Colors.green : null,
                    ),
                    title: Text(document.name),
                    subtitle: Text(
                      'Last updated: ${DateFormat('MMM dd, yyyy - HH:mm').format(document.lastUpdated)}',
                    ),
                    trailing:
                        _isSelectionMode
                            ? Checkbox(
                              value: isSelected,
                              onChanged:
                                  (_) => _toggleDocumentSelection(document),
                            )
                            : const Icon(Icons.chevron_right),
                    selected: isSelected,
                    onLongPress: () {
                      if (!_isSelectionMode) {
                        _toggleSelectionMode();
                        _toggleDocumentSelection(document);
                      }
                    },
                    onTap: () {
                      if (_isSelectionMode) {
                        _toggleDocumentSelection(document);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    DocumentViewScreen(document: document),
                          ),
                        ).then((_) => _loadDocuments());
                      }
                    },
                  );
                },
              ),
      floatingActionButton:
          !_isSelectionMode
              ? FloatingActionButton(
                onPressed: _importDocument,
                tooltip: 'Import Document',
                child: const Icon(Icons.add),
              )
              : null,
    );
  }
}
