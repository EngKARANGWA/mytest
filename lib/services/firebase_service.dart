// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/local_storage.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign in with Email
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Save user data locally
      await saveLocalData('user_email', email);
      print("Success! User UID: ${userCredential.user?.uid}");
      return userCredential;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          print('No user found for that email.');
          break;
        case 'wrong-password':
          print('Wrong password provided for that user.');
          break;
        case 'invalid-email':
          print('The email address is not valid.');
          break;
        case 'user-disabled':
          print('This user has been disabled.');
          break;
        case 'too-many-requests':
          print('Too many attempts. Please try again later.');
          break;
        default:
          print('Failed: ${e.code} - ${e.message}');
      }
      rethrow;
    } catch (e) {
      print("Unknown error: $e");
      rethrow;
    }
  }

  // Sign up with Email
  Future<UserCredential?> signUp(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Save user data locally
      await saveLocalData('user_email', email);
      print("Success! User UID: ${userCredential.user?.uid}");
      return userCredential;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          print('The password provided is too weak.');
          break;
        case 'email-already-in-use':
          print('An account already exists for that email.');
          break;
        case 'invalid-email':
          print('The email address is not valid.');
          break;
        case 'operation-not-allowed':
          print('Email/password accounts are not enabled.');
          break;
        default:
          print('Failed: ${e.code} - ${e.message}');
      }
      rethrow;
    } catch (e) {
      print("Unknown error: $e");
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      // Clear local data
      await saveLocalData('user_email', '');
    } catch (e) {
      print("Error signing out: $e");
      rethrow;
    }
  }

  // Fetch data from Firestore
  Future<List<Map<String, dynamic>>> fetchData(String collection) async {
    try {
      final snapshot = await _firestore.collection(collection).get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print("Error fetching data: $e");
      rethrow;
    }
  }

  // Add data to Firestore
  Future<void> addData(String collection, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).add(data);
    } catch (e) {
      print("Error adding data: $e");
      rethrow;
    }
  }

  // Update data in Firestore
  Future<void> updateData(
      String collection, String docId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).doc(docId).update(data);
    } catch (e) {
      print("Error updating data: $e");
      rethrow;
    }
  }

  // Delete data from Firestore
  Future<void> deleteData(String collection, String docId) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
    } catch (e) {
      print("Error deleting data: $e");
      rethrow;
    }
  }
}
