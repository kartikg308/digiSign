import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/signature.dart' as model;
import '../services/signature_service.dart';
import '../widgets/signature_pad.dart';

class SignaturesScreen extends StatefulWidget {
  const SignaturesScreen({super.key});

  @override
  State<SignaturesScreen> createState() => _SignaturesScreenState();
}

class _SignaturesScreenState extends State<SignaturesScreen> {
  final SignatureService _signatureService = SignatureService();
  List<model.Signature> _signatures = [];
  bool _isLoading = true;
  bool _isCreating = false;
  bool _isError = false;
  String _errorMessage = '';
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSignatures();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadSignatures() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = '';
    });

    try {
      final signatures = await _signatureService.getAllSignatures();
      setState(() {
        _signatures = signatures;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = 'Failed to load signatures: $e';
      });
    }
  }

  void _showAddSignatureDialog() {
    setState(() {
      _isCreating = true;
    });
  }

  void _cancelCreating() {
    setState(() {
      _isCreating = false;
    });
  }

  Future<void> _deleteSignature(model.Signature signature) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Signature'),
            content: Text('Are you sure you want to delete "${signature.name}"?'),
            actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))],
          ),
    );

    if (confirmed == true && mounted) {
      try {
        if (signature.id != null) {
          final success = await _signatureService.deleteSignature(signature.id!);
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signature "${signature.name}" deleted')));
            _loadSignatures();
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete signature')));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting signature: $e')));
        }
      }
    }
  }

  Future<void> _renameSignature(model.Signature signature) async {
    _nameController.text = signature.name;

    final newName = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Rename Signature'),
            content: TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'New Name', border: OutlineInputBorder()), autofocus: true),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  final name = _nameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a name')));
                    return;
                  }
                  Navigator.pop(context, name);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (newName != null && newName.isNotEmpty && newName != signature.name && mounted) {
      try {
        final success = await _signatureService.updateSignatureName(signature, newName);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signature renamed successfully')));
          _loadSignatures();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to rename signature')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error renaming signature: $e')));
        }
      }
    }
  }

  Future<void> _saveNewSignature(Uint8List bytes) async {
    _nameController.text = 'My Signature ${_signatures.length + 1}';

    final name = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Save Signature'),
            content: TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Signature Name', border: OutlineInputBorder()), autofocus: true),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  final name = _nameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a name')));
                    return;
                  }
                  Navigator.pop(context, name);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (name != null && name.isNotEmpty && mounted) {
      try {
        final signature = await _signatureService.saveSignature(name, bytes);
        if (signature != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signature "$name" saved successfully')));
          setState(() {
            _isCreating = false;
          });
          _loadSignatures();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save signature')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving signature: $e')));
        }
      }
    } else {
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Signatures')),
      body:
          _isCreating
              ? _buildSignatureCreator()
              : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _isError
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _loadSignatures, child: const Text('Retry')),
                  ],
                ),
              )
              : _signatures.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.gesture, size: 64, color: Colors.blue),
                    const SizedBox(height: 16),
                    const Text('No saved signatures', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 8),
                    const Text('Create your first signature to get started', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(onPressed: _showAddSignatureDialog, icon: const Icon(Icons.add), label: const Text('Create Signature')),
                  ],
                ),
              )
              : Column(
                children: [
                  Padding(padding: const EdgeInsets.all(16.0), child: Text('You have ${_signatures.length} saved signature${_signatures.length == 1 ? "" : "s"}', style: const TextStyle(fontSize: 16))),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _signatures.length,
                      itemBuilder: (context, index) {
                        final signature = _signatures[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(8),
                            leading: Container(width: 80, height: 40, decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)), child: Image.memory(signature.bytes, fit: BoxFit.contain)),
                            title: Text(signature.name),
                            subtitle: Text('Created: ${_formatDate(signature.dateCreated)}', style: TextStyle(color: Colors.grey.shade600)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [IconButton(icon: const Icon(Icons.edit), tooltip: 'Rename', onPressed: () => _renameSignature(signature)), IconButton(icon: const Icon(Icons.delete), tooltip: 'Delete', onPressed: () => _deleteSignature(signature))],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      floatingActionButton: !_isCreating && !_isLoading && !_isError ? FloatingActionButton(onPressed: _showAddSignatureDialog, tooltip: 'Create Signature', child: const Icon(Icons.add)) : null,
    );
  }

  Widget _buildSignatureCreator() {
    return Column(
      children: [
        AppBar(leading: IconButton(icon: const Icon(Icons.close), onPressed: _cancelCreating), title: const Text('Create Signature'), automaticallyImplyLeading: false, centerTitle: true),
        Expanded(child: Padding(padding: const EdgeInsets.all(16.0), child: SignaturePadWidget(onSave: _saveNewSignature, allowSaveWithName: false))),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
