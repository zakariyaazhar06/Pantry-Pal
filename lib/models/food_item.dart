import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FoodItem {
  final String? id;
  final String name;
  final String category;
  final String quantity;
  final String tag;
  final DateTime expiryDate;
  final DateTime boughtDate;

  // Nutrition fields
  final double? calories;
  final double? protein;
  final double? fat;
  final double? carbs;
  final double? fibre;
  final double? sugar;
  final double? salt;
  final double? saturates;
  final double? energy;
  final String? imageUrl;

  FoodItem({
    this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.tag,
    required this.expiryDate,
    required this.boughtDate,
    this.calories,
    this.protein,
    this.fat,
    this.carbs,
    this.fibre,
    this.sugar,
    this.salt,
    this.saturates,
    this.energy,
    this.imageUrl,
  });

  factory FoodItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodItem(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      quantity: data['quantity'] ?? '',
      tag: data['tag'] ?? 'Fresh',
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      boughtDate: (data['boughtDate'] as Timestamp).toDate(),
      calories: (data['calories'] as num?)?.toDouble(),
      protein: (data['protein'] as num?)?.toDouble(),
      fat: (data['fat'] as num?)?.toDouble(),
      carbs: (data['carbs'] as num?)?.toDouble(),
      fibre: (data['fibre'] as num?)?.toDouble(),
      sugar: (data['sugar'] as num?)?.toDouble(),
      salt: (data['salt'] as num?)?.toDouble(),
      saturates: (data['saturates'] as num?)?.toDouble(),
      energy: (data['energy'] as num?)?.toDouble(),
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'quantity': quantity,
    'tag': tag,
    'expiryDate': Timestamp.fromDate(expiryDate),
    'boughtDate': Timestamp.fromDate(boughtDate),
    'calories': calories,
    'protein': protein,
    'fat': fat,
    'carbs': carbs,
    'fibre': fibre,
    'sugar': sugar,
    'salt': salt,
    'saturates': saturates,
    'energy': energy,
    'imageUrl': imageUrl,
    'createdAt': FieldValue.serverTimestamp(),
  };

  Color get tagColor {
    switch (tag) {
      case 'Expired': return Colors.red;
      case 'Expiring Soon': return Colors.orange;
      default: return Colors.green;
    }
  }

  String get formattedExpiry {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[expiryDate.month - 1]} ${expiryDate.day}';
  }
}