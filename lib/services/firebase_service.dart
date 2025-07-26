import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/tour_model.dart';
import '../models/user_preferences_model.dart';
import '../core/constants.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // Tours
  Future<List<TourModel>> getTours() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.toursCollection)
          .get();

      return snapshot.docs
          .map((doc) => TourModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Get tours error: $e');
      return [];
    }
  }

  Future<TourModel?> getTourById(String tourId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(AppConstants.toursCollection)
          .doc(tourId)
          .get();

      if (doc.exists) {
        return TourModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Get tour by ID error: $e');
      return null;
    }
  }

  Stream<List<TourModel>> getToursStream() {
    return _firestore
        .collection(AppConstants.toursCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TourModel.fromFirestore(doc))
            .toList());
  }

  // User Preferences
  Future<void> saveUserPreferences(UserPreferencesModel preferences) async {
    if (currentUser == null) return;

    try {
      await _firestore
          .collection(AppConstants.userPreferencesCollection)
          .doc(currentUser!.uid)
          .set(preferences.toMap());
    } catch (e) {
      debugPrint('Save user preferences error: $e');
    }
  }

  Future<UserPreferencesModel?> getUserPreferences() async {
    if (currentUser == null) return null;

    try {
      final DocumentSnapshot doc = await _firestore
          .collection(AppConstants.userPreferencesCollection)
          .doc(currentUser!.uid)
          .get();

      if (doc.exists) {
        return UserPreferencesModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Get user preferences error: $e');
      return null;
    }
  }

  // Downloaded Content
  Future<void> saveDownloadedContent(String tourId, Map<String, dynamic> content) async {
    if (currentUser == null) return;

    try {
      await _firestore
          .collection(AppConstants.downloadedContentCollection)
          .doc('${currentUser!.uid}_$tourId')
          .set({
        'userId': currentUser!.uid,
        'tourId': tourId,
        'content': content,
        'downloadedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Save downloaded content error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getDownloadedContent() async {
    if (currentUser == null) return [];

    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.downloadedContentCollection)
          .where('userId', isEqualTo: currentUser!.uid)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Get downloaded content error: $e');
      return [];
    }
  }

  Future<void> deleteDownloadedContent(String tourId) async {
    if (currentUser == null) return;

    try {
      await _firestore
          .collection(AppConstants.downloadedContentCollection)
          .doc('${currentUser!.uid}_$tourId')
          .delete();
    } catch (e) {
      debugPrint('Delete downloaded content error: $e');
    }
  }

  // Authentication
  Future<User?> signInAnonymously() async {
    try {
      final UserCredential result = await _auth.signInAnonymously();
      return result.user;
    } catch (e) {
      debugPrint('Anonymous sign in error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }
}