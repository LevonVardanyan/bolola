import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ApiKeyService {
  static final ApiKeyService _instance = ApiKeyService._internal();
  factory ApiKeyService() => _instance;
  ApiKeyService._internal();

  String? _apiKey;
  bool _isInitialized = false;

  String? get apiKey => _apiKey;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection('general').doc('apikey').get();
      
      if (doc.exists && doc.data() != null) {
        _apiKey = doc.data()!['apikey'] as String?;
        _isInitialized = true;
        if (kDebugMode) {
          print('API key fetched successfully');
        }
      } else {
        throw Exception('API key document not found in Firebase');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching API key from Firebase: $e');
      }
      _isInitialized = false;
      rethrow;
    }
  }

  Future<void> waitForInitialization() async {
    if (_isInitialized) return;
    
    int attempts = 0;
    const maxAttempts = 30;
    const delayDuration = Duration(milliseconds: 100);
    
    while (!_isInitialized && attempts < maxAttempts) {
      await Future.delayed(delayDuration);
      attempts++;
    }
    
    if (!_isInitialized) {
      throw Exception('API key service not initialized after waiting');
    }
  }
} 