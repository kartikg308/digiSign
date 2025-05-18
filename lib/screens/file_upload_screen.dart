// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'document_view_screen.dart';
import '../models/document.dart';
import 'dart:html' as html;

class FileUploadScreen extends StatefulWidget {
  const FileUploadScreen({super.key});

  @override
  State<FileUploadScreen> createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen> {
  bool _isLoading = false;

  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true, // Important for web to get file bytes
      );

      if (result != null && result.files.single.bytes != null) {
        final fileName = result.files.single.name;
        final fileBytes = result.files.first.bytes;
        print(fileBytes);

        // Create a temporary document object
        final now = DateTime.now();
        final document = Document(
          name: fileName,
          path: 'web_memory', // Placeholder path for web
          dateCreated: now,
          lastUpdated: now,
          blob: html.Blob([fileBytes], 'application/pdf'),
        );

        if (mounted) {
          // Navigate to the document view screen
          Navigator.push(context, MaterialPageRoute(builder: (context) => DocumentViewScreen(document: document)));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No file selected or unable to read file')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DigiSign'),
        actions: [
          IconButton(
            icon: const Icon(Icons.draw),
            onPressed: () {
              Navigator.pushNamed(context, '/signatures');
            },
            tooltip: 'Manage Signatures',
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.upload_file, size: 80, color: Colors.blue),
                const SizedBox(height: 20),
                const Text('Select a PDF document to sign', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 30),
                ElevatedButton.icon(icon: const Icon(Icons.file_open), label: const Text('Select Document'), onPressed: _isLoading ? null : _pickFile, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), textStyle: const TextStyle(fontSize: 16))),
              ],
            ),
          ),
          if (_isLoading) Container(color: Colors.black.withOpacity(0.3), child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }
}
