import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/signature.dart' as model;
import '../services/signature_service.dart';
import '../widgets/signature_pad.dart';

class SignaturesScreen extends StatefulWidget {
  const SignaturesScreen({Key? key}) : super(key: key);

  @override
  State<SignaturesScreen> createState() => _SignaturesScreenState();
}

class _SignaturesScreenState extends State<SignaturesScreen> {
  final SignatureService _signatureService = SignatureService();
  List<model.Signature> _signatures = [];
  bool _isLoading = true;
  bool _isCreatingSignature = false;
  final TextEditingController _signatureNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSignatures();
  }

  @override
  void dispose() {
    _signatureNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSignatures() async {
    setState(() {
      _isLoading = true;
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
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading signatures: $e')));
      }
    }
  }

  void _showCreateSignatureDialog() {
    setState(() {
      _isCreatingSignature = true;
    });
  }

  Future<void> _saveSignature(Uint8List bytes) async {
    final name = _signatureNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a name for your signature')));
      return;
    }

    try {
      await _signatureService.saveSignature(name, bytes);
      setState(() {
        _isCreatingSignature = false;
        _signatureNameController.clear();
      });
      _loadSignatures();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving signature: $e')));
    }
  }

  Future<void> _deleteSignature(model.Signature signature) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Signature'),
            content: Text('Are you sure you want to delete "${signature.name}"?'),
            actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))],
          ),
    );

    if (confirm == true) {
      try {
        await _signatureService.deleteSignature(signature.id!);
        _loadSignatures();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting signature: $e')));
      }
    }
  }

  Future<void> _renameSignature(model.Signature signature) async {
    final TextEditingController controller = TextEditingController(text: signature.name);
    final newName = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Rename Signature'),
            content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Name', hintText: 'Enter a new name for this signature')),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save'))],
          ),
    );

    if (newName != null && newName.isNotEmpty && newName != signature.name) {
      try {
        await _signatureService.updateSignatureName(signature, newName);
        _loadSignatures();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error renaming signature: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Signatures')),
      body:
          _isCreatingSignature
              ? _buildCreateSignatureView()
              : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildSignaturesList(),
      floatingActionButton: !_isCreatingSignature ? FloatingActionButton(onPressed: _showCreateSignatureDialog, tooltip: 'Create Signature', child: const Icon(Icons.add)) : null,
    );
  }

  Widget _buildCreateSignatureView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(controller: _signatureNameController, decoration: const InputDecoration(labelText: 'Signature Name', hintText: 'Enter a name for this signature', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          Expanded(child: SignaturePadWidget(onSave: _saveSignature)),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isCreatingSignature = false;
                _signatureNameController.clear();
              });
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildSignaturesList() {
    if (_signatures.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [const Icon(Icons.brush, size: 64, color: Colors.grey), const SizedBox(height: 16), const Text('No Signatures Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('Create your first signature by tapping the + button')],
        ),
      );
    }

    return ListView.builder(
      itemCount: _signatures.length,
      itemBuilder: (context, index) {
        final signature = _signatures[index];
        return ListTile(
          leading: Container(width: 40, height: 40, decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)), child: Image.memory(signature.bytes, fit: BoxFit.contain)),
          title: Text(signature.name),
          subtitle: Text('Created: ${_formatDate(signature.dateCreated)}'),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'rename') {
                _renameSignature(signature);
              } else if (value == 'delete') {
                _deleteSignature(signature);
              }
            },
            itemBuilder: (context) => [const PopupMenuItem(value: 'rename', child: Text('Rename')), const PopupMenuItem(value: 'delete', child: Text('Delete'))],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
