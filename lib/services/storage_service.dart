import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  static Database? _database;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize local database
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'elink_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        // Create buyers table
        await db.execute('''
          CREATE TABLE buyers(
            id TEXT PRIMARY KEY,
            name TEXT,
            email TEXT,
            phone TEXT,
            address TEXT,
            location TEXT,
            createdAt TEXT
          )
        ''');

        // Create sellers table
        await db.execute('''
          CREATE TABLE sellers(
            id TEXT PRIMARY KEY,
            name TEXT,
            businessName TEXT,
            email TEXT,
            phone TEXT,
            businessAddress TEXT,
            location TEXT,
            createdAt TEXT
          )
        ''');
      },
    );
  }

  // Store buyer data
  static Future<void> storeBuyer({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String location,
    required String password,
  }) async {
    try {
      // 1. Store in Firebase
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('buyers').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'location': location,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Store in local database
      final db = await database;
      await db.insert('buyers', {
        'id': userCredential.user!.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'location': location,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error storing buyer data: $e');
    }
  }

  // Store seller data
  static Future<void> storeSeller({
    required String name,
    required String businessName,
    required String email,
    required String phone,
    required String businessAddress,
    required String location,
    required String password,
  }) async {
    try {
      // 1. Store in Firebase
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('sellers').doc(userCredential.user!.uid).set({
        'name': name,
        'businessName': businessName,
        'email': email,
        'phone': phone,
        'businessAddress': businessAddress,
        'location': location,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Store in local database
      final db = await database;
      await db.insert('sellers', {
        'id': userCredential.user!.uid,
        'name': name,
        'businessName': businessName,
        'email': email,
        'phone': phone,
        'businessAddress': businessAddress,
        'location': location,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error storing seller data: $e');
    }
  }

  // Get buyer data
  static Future<Map<String, dynamic>?> getBuyer(String userId) async {
    try {
      // Try to get from local database first
      final db = await database;
      final localData = await db.query(
        'buyers',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (localData.isNotEmpty) {
        return localData.first;
      }

      // If not in local database, get from Firebase
      final firebaseData =
          await _firestore.collection('buyers').doc(userId).get();

      if (firebaseData.exists) {
        // Store in local database for future use
        await db.insert('buyers', {
          'id': userId,
          ...firebaseData.data()!,
          'createdAt': DateTime.now().toIso8601String(),
        });
        return firebaseData.data();
      }

      return null;
    } catch (e) {
      throw Exception('Error getting buyer data: $e');
    }
  }

  // Get seller data
  static Future<Map<String, dynamic>?> getSeller(String userId) async {
    try {
      // Try to get from local database first
      final db = await database;
      final localData = await db.query(
        'sellers',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (localData.isNotEmpty) {
        return localData.first;
      }

      // If not in local database, get from Firebase
      final firebaseData =
          await _firestore.collection('sellers').doc(userId).get();

      if (firebaseData.exists) {
        // Store in local database for future use
        await db.insert('sellers', {
          'id': userId,
          ...firebaseData.data()!,
          'createdAt': DateTime.now().toIso8601String(),
        });
        return firebaseData.data();
      }

      return null;
    } catch (e) {
      throw Exception('Error getting seller data: $e');
    }
  }
}
