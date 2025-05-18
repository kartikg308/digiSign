import 'dart:typed_data';
import '../models/signature.dart';
import 'database_service.dart';

class SignatureService {
  final DatabaseService _dbService = DatabaseService();

  // Save a new signature
  Future<Signature?> saveSignature(String name, Uint8List bytes) async {
    try {
      final now = DateTime.now();
      final signature = Signature(name: name, bytes: bytes, dateCreated: now);

      final id = await _dbService.insertSignature(signature);
      return signature.copyWith(id: id);
    } catch (e) {
      print('Error saving signature: $e');
      return null;
    }
  }

  // Get all saved signatures
  Future<List<Signature>> getAllSignatures() async {
    try {
      return await _dbService.getAllSignatures();
    } catch (e) {
      print('Error getting signatures: $e');
      return [];
    }
  }

  // Get a signature by id
  Future<Signature?> getSignature(int id) async {
    try {
      return await _dbService.getSignature(id);
    } catch (e) {
      print('Error getting signature: $e');
      return null;
    }
  }

  // Delete a signature
  Future<bool> deleteSignature(int id) async {
    try {
      await _dbService.deleteSignature(id);
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
      await _dbService.updateSignature(updatedSignature);
      return true;
    } catch (e) {
      print('Error updating signature name: $e');
      return false;
    }
  }
}
