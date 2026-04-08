import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/food_item.dart';
import 'services/pantry_service.dart';
import 'services/auth_service.dart';

class ItemDetailScreen extends StatefulWidget {
  final FoodItem item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final AuthService _auth = AuthService();
  final PantryService _pantryService = PantryService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  double _tdee = 2000;
  double _proteinGoal = 150;
  double _carbsGoal = 250;
  double _fatGoal = 70;
  double _fibreGoal = 30;
  List<String> _allergens = [];
  List<String> _customAllergens = [];
  List<String> _healthConditions = [];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final doc = await _db.collection('users').doc(_auth.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _tdee = (data['tdee'] as num?)?.toDouble() ?? 2000;
        _proteinGoal = (data['proteinGoal'] as num?)?.toDouble() ?? 150;
        _carbsGoal = (data['carbsGoal'] as num?)?.toDouble() ?? 250;
        _fatGoal = (data['fatGoal'] as num?)?.toDouble() ?? 70;
        _allergens = List<String>.from(data['allergens'] ?? []);
        _customAllergens = List<String>.from(data['customAllergens'] ?? []);
        _healthConditions = List<String>.from(data['healthConditions'] ?? []);
      });
    }
  }

  String _daysLeftLabel() {
    final diff = widget.item.expiryDate.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Expired';
    if (diff == 0) return 'Expires today';
    if (diff == 1) return '1 day left';
    return '$diff days left';
  }

  List<String> _getWarnings() {
    final item = widget.item;
    final warnings = <String>[];

    // Allergen warnings
    final allAllergens = [..._allergens, ..._customAllergens];
    if (allAllergens.isNotEmpty) {
      const allergenKeywords = {
        'Gluten': ['gluten', 'wheat', 'barley', 'rye', 'oats'],
        'Dairy': ['milk', 'dairy', 'lactose', 'cheese', 'butter', 'cream'],
        'Eggs': ['egg', 'eggs', 'albumin'],
        'Peanuts': ['peanut', 'groundnut'],
        'Tree Nuts': ['almond', 'cashew', 'walnut', 'pistachio', 'hazelnut', 'pecan'],
        'Fish': ['fish', 'cod', 'salmon', 'tuna', 'haddock'],
        'Shellfish': ['shellfish', 'shrimp', 'prawn', 'crab', 'lobster'],
        'Soy': ['soy', 'soya', 'tofu'],
        'Sesame': ['sesame', 'tahini'],
        'Mustard': ['mustard'],
        'Celery': ['celery', 'celeriac'],
        'Lupin': ['lupin', 'lupine'],
        'Molluscs': ['mollusc', 'squid', 'oyster', 'mussel', 'scallop'],
        'Sulphites': ['sulphite', 'sulfite', 'sulphur dioxide'],
      };

      final itemText = item.name.toLowerCase();
      for (final allergen in allAllergens) {
        final keywords =
            allergenKeywords[allergen] ?? [allergen.toLowerCase()];
        for (final keyword in keywords) {
          if (itemText.contains(keyword)) {
            warnings.add('Contains $allergen');
            break;
          }
        }
      }
    }

    // Health condition warnings
    if (_healthConditions.contains('Diabetes') &&
        item.sugar != null &&
        item.sugar! > 10) {
      warnings.add('High sugar — not recommended for Diabetes');
    }
    if (_healthConditions.contains('High Blood Pressure') &&
        item.salt != null &&
        item.salt! > 1.5) {
      warnings.add('High salt — not recommended for High Blood Pressure');
    }
    if (_healthConditions.contains('High Cholesterol') &&
        item.saturates != null &&
        item.saturates! > 5) {
      warnings
          .add('High saturated fat — not recommended for High Cholesterol');
    }
    if (_healthConditions.contains('Obesity') &&
        item.calories != null &&
        item.calories! > 400) {
      warnings.add('High calorie density — not recommended for Obesity');
    }
    if (_healthConditions.contains('Celiac Disease') &&
        (item.name.toLowerCase().contains('gluten') ||
            item.name.toLowerCase().contains('wheat'))) {
      warnings.add('Contains gluten — not safe for Celiac Disease');
    }
    if (_healthConditions.contains('Lactose Intolerance') &&
        (item.name.toLowerCase().contains('milk') ||
            item.name.toLowerCase().contains('dairy') ||
            item.name.toLowerCase().contains('cheese'))) {
      warnings
          .add('Contains dairy — not recommended for Lactose Intolerance');
    }

    return warnings;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // ── HEADER ──
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF2C3344),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("Food Overview",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      Text("Your food broken down",
                          style: TextStyle(
                              color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                  Row(
                    children: [
                      _headerIconBtn(Icons.notifications_outlined),
                      const SizedBox(width: 8),
                      _headerIconBtn(Icons.settings_outlined),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── ALLERGY WARNING BANNER ──
                  Builder(
                    builder: (context) {
                      final warnings = _getWarnings();
                      if (warnings.isEmpty) return const SizedBox();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.red, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text("Dietary Warning",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                          fontSize: 13)),
                                  const SizedBox(height: 6),
                                  ...warnings.map((w) => Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: 3),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text("• ",
                                                style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 11)),
                                            Expanded(
                                              child: Text(w,
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors
                                                          .red.shade700)),
                                            ),
                                          ],
                                        ),
                                      )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // ── TOP CARD ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: item.imageUrl != null &&
                                  item.imageUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  child: Image.network(item.imageUrl!,
                                      fit: BoxFit.cover),
                                )
                              : const Icon(Icons.fastfood,
                                  color: Colors.grey, size: 36),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(item.name,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                      item.calories != null
                                          ? item.calories!
                                              .toStringAsFixed(0)
                                          : "--",
                                      style: const TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 4),
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 5),
                                    child: Text("kcal",
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _macroChip(
                                      "P",
                                      item.protein != null
                                          ? "${item.protein!.toStringAsFixed(1)}g"
                                          : "--g",
                                      const Color(0xFFB5A642)),
                                  const SizedBox(width: 6),
                                  _macroChip(
                                      "F",
                                      item.fat != null
                                          ? "${item.fat!.toStringAsFixed(1)}g"
                                          : "--g",
                                      const Color(0xFF37474F)),
                                  const SizedBox(width: 6),
                                  _macroChip(
                                      "C",
                                      item.carbs != null
                                          ? "${item.carbs!.toStringAsFixed(1)}g"
                                          : "--g",
                                      const Color(0xFF66BB6A)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 8,
                          height: 90,
                          decoration: BoxDecoration(
                            color: item.tagColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── MIDDLE ROW ──
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withOpacity(0.03),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding:
                                            const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color:
                                              const Color(0xFFFFF8E1),
                                          borderRadius:
                                              BorderRadius.circular(9),
                                        ),
                                        child: const Icon(
                                            Icons.warning_amber_rounded,
                                            color: Color(0xFFFFB300),
                                            size: 16),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text("Expires:",
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey)),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 8,
                                                vertical: 3),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: const Color(
                                                      0xFFFFB300)),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      6),
                                            ),
                                            child: Text(
                                              _formatShortDate(
                                                  item.expiryDate),
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      Color(0xFFFFB300),
                                                  fontWeight:
                                                      FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withOpacity(0.03),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding:
                                            const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color:
                                              const Color(0xFFFFF8E1),
                                          borderRadius:
                                              BorderRadius.circular(9),
                                        ),
                                        child: const Icon(
                                            Icons.soup_kitchen_outlined,
                                            color: Color(0xFFFFB300),
                                            size: 16),
                                      ),
                                      const SizedBox(width: 10),
                                      const Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text("Find Recipes:",
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight.bold)),
                                          SizedBox(height: 3),
                                          Text("Uses this item",
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          flex: 5,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withOpacity(0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text("Daily Contribution",
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                                const Text("vs your goals",
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey)),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    _verticalBar(
                                        "Cal",
                                        item.calories != null
                                            ? (item.calories! / _tdee)
                                                .clamp(0.0, 1.0)
                                            : 0.0,
                                        const Color(0xFFEF5350)),
                                    _verticalBar(
                                        "Pro",
                                        item.protein != null
                                            ? (item.protein! /
                                                    _proteinGoal)
                                                .clamp(0.0, 1.0)
                                            : 0.0,
                                        const Color(0xFFB5A642)),
                                    _verticalBar(
                                        "Carbs",
                                        item.carbs != null
                                            ? (item.carbs! / _carbsGoal)
                                                .clamp(0.0, 1.0)
                                            : 0.0,
                                        const Color(0xFF66BB6A)),
                                    _verticalBar(
                                        "Fat",
                                        item.fat != null
                                            ? (item.fat! / _fatGoal)
                                                .clamp(0.0, 1.0)
                                            : 0.0,
                                        const Color(0xFF37474F)),
                                    _verticalBar(
                                        "Fibre",
                                        item.fibre != null
                                            ? (item.fibre! / _fibreGoal)
                                                .clamp(0.0, 1.0)
                                            : 0.0,
                                        const Color(0xFF5C6BC0)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (item.calories == null)
                                  const Text("Scan to populate",
                                      style: TextStyle(
                                          fontSize: 8,
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── NUTRITION TABLE ──
                  const Text("Nutritional Info",
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _tableHeader(),
                        _tableRow(
                            "Energy",
                            item.energy != null
                                ? "${item.energy!.toStringAsFixed(0)} kJ / ${item.calories!.toStringAsFixed(0)} kcal"
                                : "-- kJ / -- kcal",
                            true),
                        _tableRow(
                            "Fat",
                            item.fat != null
                                ? "${item.fat!.toStringAsFixed(1)}g"
                                : "--g",
                            false),
                        _tableRow(
                            "(Of which Saturates)",
                            item.saturates != null
                                ? "${item.saturates!.toStringAsFixed(1)}g"
                                : "--g",
                            true),
                        _tableRow(
                            "Carbohydrates",
                            item.carbs != null
                                ? "${item.carbs!.toStringAsFixed(1)}g"
                                : "--g",
                            false),
                        _tableRow(
                            "(Of which Sugars)",
                            item.sugar != null
                                ? "${item.sugar!.toStringAsFixed(1)}g"
                                : "--g",
                            true),
                        _tableRow(
                            "Fibre",
                            item.fibre != null
                                ? "${item.fibre!.toStringAsFixed(1)}g"
                                : "--g",
                            false),
                        _tableRow(
                            "Protein",
                            item.protein != null
                                ? "${item.protein!.toStringAsFixed(1)}g"
                                : "--g",
                            true),
                        _tableRow(
                            "Salt",
                            item.salt != null
                                ? "${item.salt!.toStringAsFixed(1)}g"
                                : "--g",
                            false),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── DELETE BUTTON ──
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Delete Item"),
                            content: Text(
                                "Remove ${item.name} from your pantry?"),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("Cancel")),
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text("Delete",
                                      style: TextStyle(
                                          color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _pantryService.deleteItem(
                              _auth.uid!, item.id!);
                          if (context.mounted)
                            Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.white),
                      label: const Text("Remove from Pantry",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _headerIconBtn(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }

  Widget _macroChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text("$label: $value",
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _verticalBar(String label, double value, Color color) {
    const double barHeight = 55;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 12,
          height: barHeight,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(label,
            style: const TextStyle(fontSize: 8, color: Colors.grey)),
      ],
    );
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Typical Values",
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text("Per 100g as Sold",
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _tableRow(String label, String value, bool shaded) {
    return Container(
      color: shaded ? Colors.grey[50] : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatShortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}';
  }
}