import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_item.dart';

class PantryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Shortcut to the pantry collection for a user
  CollectionReference _pantryRef(String uid) =>
      _db.collection('users').doc(uid).collection('pantry');

  // READ — live stream of pantry items (auto-updates the UI)
  Stream<List<FoodItem>> getPantryStream(String uid) {
    return _pantryRef(uid)
        .orderBy('expiryDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FoodItem.fromFirestore(doc))
            .toList());
  }

  // CREATE — save a new food item
  Future<void> addItem(String uid, FoodItem item) async {
    await _pantryRef(uid).add(item.toMap());
  }

  // DELETE — remove a food item
  Future<void> deleteItem(String uid, String itemId) async {
    await _pantryRef(uid).doc(itemId).delete();
  }

  // UPDATE tag (Fresh / Expiring Soon / Expired)
  Future<void> updateTag(String uid, String itemId, String tag) async {
    await _pantryRef(uid).doc(itemId).update({'tag': tag});
  }
}