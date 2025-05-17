import 'package:flutter/foundation.dart';
import '../models/buyer.dart';
import '../services/database_helper.dart';

class BuyerProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Buyer> _buyers = [];
  bool _isLoading = false;

  List<Buyer> get buyers => _buyers;
  bool get isLoading => _isLoading;

  Future<void> loadBuyers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final buyersList = await _dbHelper.getBuyers();
      _buyers = buyersList.map((buyer) => Buyer.fromMap(buyer)).toList();
    } catch (e) {
      debugPrint('Error loading buyers: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signUpBuyer(Buyer buyer) async {
    try {
      // Check if email already exists
      final existingBuyer = await _dbHelper.getBuyerByEmail(buyer.email);
      if (existingBuyer != null) {
        return false; // Email already exists
      }

      // Insert new buyer
      await _dbHelper.insertBuyer(buyer.toMap());
      await loadBuyers(); // Refresh the list
      return true;
    } catch (e) {
      debugPrint('Error signing up buyer: $e');
      return false;
    }
  }

  Future<bool> updateBuyer(Buyer buyer) async {
    try {
      await _dbHelper.updateBuyer(buyer.toMap());
      await loadBuyers(); // Refresh the list
      return true;
    } catch (e) {
      debugPrint('Error updating buyer: $e');
      return false;
    }
  }

  Future<bool> deleteBuyer(int id) async {
    try {
      await _dbHelper.deleteBuyer(id);
      await loadBuyers(); // Refresh the list
      return true;
    } catch (e) {
      debugPrint('Error deleting buyer: $e');
      return false;
    }
  }
}
