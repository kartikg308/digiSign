import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_signature_pad/flutter_signature_pad.dart';

class SignaturePadWidget extends StatefulWidget {
  final Function(Uint8List) onSave;
  final bool allowSaveWithName;

  const SignaturePadWidget({Key? key, required this.onSave, this.allowSaveWithName = false}) : super(key: key);

  @override
  State<SignaturePadWidget> createState() => _SignaturePadWidgetState();
}

class _SignaturePadWidgetState extends State<SignaturePadWidget> {
  final GlobalKey<SignatureState> _signatureKey = GlobalKey<SignatureState>();
  Color _penColor = Colors.black;
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(height: 300, decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)), child: Signature(key: _signatureKey, color: _penColor, strokeWidth: 3.0, backgroundPainter: null)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildColorCircle(Colors.black), const SizedBox(width: 12), _buildColorCircle(Colors.blue), const SizedBox(width: 12), _buildColorCircle(Colors.red)]),
        const SizedBox(height: 16),
        if (widget.allowSaveWithName) Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Signature Name', hintText: 'Enter a name for this signature', border: OutlineInputBorder()))),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [ElevatedButton(onPressed: _clearSignature, child: const Text('Clear')), ElevatedButton(onPressed: widget.allowSaveWithName ? _saveSignatureWithName : _saveSignature, child: const Text('Save'))]),
      ],
    );
  }

  Widget _buildColorCircle(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _penColor = color;
        });
      },
      child: Container(width: 40, height: 40, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: _penColor == color ? Colors.grey.shade600 : Colors.transparent, width: 3))),
    );
  }

  void _clearSignature() {
    setState(() {
      _signatureKey.currentState?.clear();
    });
  }

  Future<void> _saveSignature() async {
    if (_signatureKey.currentState?.points.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please draw your signature')));
      return;
    }

    final signatureBytes = await _getSignatureBytes();
    if (signatureBytes != null) {
      widget.onSave(signatureBytes);
    }
  }

  Future<void> _saveSignatureWithName() async {
    if (_signatureKey.currentState?.points.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please draw your signature')));
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a name for your signature')));
      return;
    }

    final signatureName = _nameController.text.trim();
    final signatureBytes = await _getSignatureBytes();

    if (signatureBytes != null) {
      // Pass both the name and bytes to the callback
      widget.onSave(signatureBytes);

      // Clear the text field after saving
      _nameController.clear();
    }
  }

  Future<Uint8List?> _getSignatureBytes() async {
    try {
      ui.Image? image = await _signatureKey.currentState?.getData();
      if (image == null) return null;

      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      return byteData.buffer.asUint8List();
    } catch (e) {
      print('Error getting signature bytes: $e');
      return null;
    }
  }
}
