import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/app_user.dart';

class UserSearchRepository {
  final FirebaseFirestore _firestore;

  UserSearchRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> _debugListAllUsers() async {
    try {
      if (kDebugMode) print('🔍 DEBUG: Listing all users in the database...');
      final allUsers = await _firestore.collection('users').limit(10).get();
      
      if (allUsers.docs.isEmpty) {
        if (kDebugMode) print('⚠️ No users found in the database');
        return;
      }
      
      if (kDebugMode) print('📋 Found ${allUsers.docs.length} users:');
      for (var doc in allUsers.docs) {
        if (kDebugMode) {
          print('----------------------------------------');
          print('📄 Document ID: ${doc.id}');
          print('📦 Data: ${doc.data()}');
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error listing users: $e');
    }
  }

  Future<void> _debugCheckUserByEmail(String email) async {
    try {
      if (kDebugMode) print('🔍 DEBUG: Checking for user with email: $email');
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email) 
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        if (kDebugMode) print('⚠️ No user found with email: $email');
        
        final allUsers = await _firestore.collection('users').get();
        final matching = allUsers.docs.where((doc) => 
            (doc.data()['email'] as String?)?.toLowerCase() == email.toLowerCase());
            
        if (matching.isNotEmpty) {
          if (kDebugMode) print('ℹ️ Found user with case-insensitive match:');
          for (var doc in matching) {
            if (kDebugMode) {
              print('----------------------------------------');
              print('📄 Document ID: ${doc.id}');
              print('📦 Data: ${doc.data()}');
            }
          }
        } else {
          if (kDebugMode) print('❌ No users found with any case variation of email: $email');
        }
      } else {
        if (kDebugMode) {
          print('✅ Found user:');
          print('----------------------------------------');
          print('📄 Document ID: ${query.docs.first.id}');
          print('📦 Data: ${query.docs.first.data()}');
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error checking user by email: $e');
    }
  }

  Future<List<AppUser>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    
    final searchTerm = query.trim().toLowerCase();
    if (kDebugMode) {
      print('🔍 Searching for: "$searchTerm"');
    }
    
    try {
      // First, let's check if we can find the user by exact email match
      if (kDebugMode) {
        print('🔍 Trying exact email match...');
      }
      final exactEmailQuery = _firestore
          .collection('users')
          .where('email_lowercase', isEqualTo: searchTerm)
          .limit(1);
      
      final exactEmailResults = await exactEmailQuery.get();
      if (exactEmailResults.docs.isNotEmpty) {
        if (kDebugMode) {
          print('✅ Found user by exact email match');
        }
        return exactEmailResults.docs
            .map((doc) => AppUser.fromJson(doc.data()..['uid'] = doc.id))
            .toList();
      }
      
      // If no exact match, try prefix search on email
      if (kDebugMode) {
        print('🔍 Trying email prefix search...');
      }
      final emailSearchQuery = _firestore
          .collection('users')
          .where('email_lowercase', isGreaterThanOrEqualTo: searchTerm)
          .where('email_lowercase', isLessThan: searchTerm + '\uf8ff')
          .limit(20);
      
      // Try display name prefix search
      if (kDebugMode) {
        print('🔍 Trying display name prefix search...');
      }
      final nameSearchQuery = _firestore
          .collection('users')
          .where('displayName_lowercase', isGreaterThanOrEqualTo: searchTerm)
          .where('displayName_lowercase', isLessThan: searchTerm + '\uf8ff')
          .limit(20);
      
      // Execute primary search queries in parallel
      if (kDebugMode) {
        print('🔍 Executing primary search queries...');
      }
      final List<QuerySnapshot<Map<String, dynamic>>> queryResults = await Future.wait([
        emailSearchQuery.get(),
        nameSearchQuery.get(),
      ]);
      
      final emailResults = queryResults[0];
      final nameResults = queryResults[1];

      // Conditional debug calls (moved from Future.wait & made sequential)
      if (kDebugMode) {
        print('🔍 [DEBUG MODE] Running additional diagnostic checks...');
        await _debugListAllUsers();
        if (searchTerm.contains('@')) {
          await _debugCheckUserByEmail(searchTerm);
        }
      }
      
      // Log raw results for debugging
      if (kDebugMode) {
        print('🔍 Email query found: ${emailResults.docs.length} results');
        print('🔍 Name query found: ${nameResults.docs.length} results');
      }
      
      // Combine and deduplicate results
      final allDocs = [...emailResults.docs, ...nameResults.docs];
      if (kDebugMode) {
        print('🔍 Total documents before deduplication: ${allDocs.length}');
      }
      
      final uniqueDocs = allDocs.fold<Map<String, dynamic>>(
        {},
        (map, doc) {
          if (kDebugMode) {
            // Be mindful of PII if printing full data in production logs
            print('📄 Processing document for deduplication: ${doc.id}');
          }
          return map..putIfAbsent(doc.id, () => doc.data()..['uid'] = doc.id);
        },
      );
      
      if (kDebugMode) {
        print('🔍 Found ${uniqueDocs.length} unique results after deduplication');
      }
      return uniqueDocs.values.map((data) => AppUser.fromJson(data)).toList();
    } catch (e, stack) {
      // General error logging (consider a more robust logger for production)
      print('❌ Error searching users: $e'); 
      if (kDebugMode) {
        print('Stack trace: $stack');
      }
      return []; // Return empty list on error to prevent app crash
    }
  }
  
  // No longer needed with prefix range queries
  List<String> _generateSearchTokens(String input) => [];
}
