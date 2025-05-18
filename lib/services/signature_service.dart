// ignore_for_file: avoid_print

import 'dart:typed_data';
import '../models/signature.dart';
import 'memory_service.dart';

class SignatureService {
  final InMemoryService _memoryService = InMemoryService();

  // Save a new signature
  Future<Signature?> saveSignature(String name, Uint8List bytes) async {
    try {
      final now = DateTime.now();
      final signature = Signature(name: name, bytes: bytes, dateCreated: now);

      final id = await _memoryService.insertSignature(signature);
      return signature.copyWith(id: id);
    } catch (e) {
      print('Error saving signature: $e');
      return null;
    }
  }

  // Get all saved signatures
  Future<List<Signature>> getAllSignatures() async {
    try {
      return await _memoryService.getAllSignatures();
    } catch (e) {
      print('Error getting signatures: $e');
      return [];
    }
  }

  // Get a signature by id
  Future<Signature?> getSignature(int id) async {
    try {
      return await _memoryService.getSignature(id);
    } catch (e) {
      print('Error getting signature: $e');
      return null;
    }
  }

  // Delete a signature
  Future<bool> deleteSignature(int id) async {
    try {
      await _memoryService.deleteSignature(id);
      return true;
    } catch (e) {
      print('Error deleting signature: $e');
      return false;
    }
  }

  // Update a signature name
  Future<bool> updateSignatureName(Signature signature, String newName) async {
    try {
      final updatedSignature = signature.copyWith(name: newName);
      await _memoryService.updateSignature(updatedSignature);
      return true;
    } catch (e) {
      print('Error updating signature name: $e');
      return false;
    }
  }
}
