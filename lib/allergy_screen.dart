import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/auth_service.dart';

class AllergyScreen extends StatefulWidget {
  const AllergyScreen({super.key});

  @override
  State<AllergyScreen> createState() => _AllergyScreenState();
}

class _AllergyScreenState extends State<AllergyScreen> {
  final AuthService _auth = AuthService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _customController =
      TextEditingController();

  final List<Map<String, dynamic>> _allergens = [
    {'name': 'Gluten'},
    {'name': 'Dairy'},
    {'name': 'Eggs'},
    {'name': 'Peanuts'},
    {'name': 'Tree Nuts'},
    {'name': 'Fish'},
    {'name': 'Shellfish'},
    {'name': 'Soy'},
    {'name': 'Sesame'},
    {'name': 'Mustard'},
    {'name': 'Celery'},
    {'name': 'Lupin'},
    {'name': 'Molluscs'},
    {'name': 'Sulphites'},
  ];

  final List<Map<String, dynamic>> _healthConditions = [
    {'name': 'Diabetes', 'description': 'Warns on high sugar content'},
    {'name': 'High Blood Pressure', 'description': 'Warns on high salt content'},
    {'name': 'High Cholesterol', 'description': 'Warns on high saturated fat'},
    {'name': 'Obesity', 'description': 'Warns on high calorie density'},
    {'name': 'Celiac Disease', 'description': 'Warns on any gluten content'},
    {'name': 'Lactose Intolerance', 'description': 'Warns on dairy content'},
  ];

  final List<Map<String, dynamic>> _dietaryOptions = [
    {'name': 'Halal'},
    {'name': 'Vegetarian'},
    {'name': 'Vegan'},
    {'name': 'Kosher'},
    {'name': 'Gluten-Free'},
    {'name': 'Dairy-Free'},
  ];

  List<String> _selectedAllergens = [];
  List<String> _selectedDietary = [];
  List<String> _selectedConditions = [];
  List<String> _customAllergens = [];
  bool _loading = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final doc = await _db.collection('users').doc(_auth.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _selectedAllergens = List<String>.from(data['allergens'] ?? []);
        _selectedDietary = List<String>.from(data['dietary'] ?? []);
        _selectedConditions = List<String>.from(data['healthConditions'] ?? []);
        _customAllergens = List<String>.from(data['customAllergens'] ?? []);
      });
    }
  }

  Future<void> _saveData() async {
    setState(() => _loading = true);
    await _db.collection('users').doc(_auth.uid).set({
      'allergens': _selectedAllergens,
      'dietary': _selectedDietary,
      'healthConditions': _selectedConditions,
      'customAllergens': _customAllergens,
    }, SetOptions(merge: true));
    setState(() {
      _loading = false;
      _saved = true;
    });
    Future.delayed(const Duration(seconds: 2),
        () => setState(() => _saved = false));
  }

  void _addCustomAllergen() {
    final text = _customController.text.trim();
    if (text.isEmpty) return;
    if (_customAllergens.contains(text)) return;
    setState(() {
      _customAllergens.add(text);
      _customController.clear();
    });
  }

  Widget _buildSelectableGrid(
      List<Map<String, dynamic>> items,
      List<String> selected,
      Color selectedColor,
      Color selectedBorder) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selected.contains(item['name']);
        return GestureDetector(
          onTap: () => setState(() {
            if (isSelected) {
              selected.remove(item['name']);
            } else {
              selected.add(item['name']);
            }
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? selectedColor.withOpacity(0.1)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? selectedBorder : Colors.grey.shade200,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(item['name'],
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? selectedBorder
                              : Colors.black87)),
                ),
                if (isSelected)
                  Icon(Icons.check_circle,
                      color: selectedBorder, size: 14),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalSelected = _selectedAllergens.length +
        _customAllergens.length +
        _selectedDietary.length +
        _selectedConditions.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
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
                      Text("Dietary Restrictions",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      Text("Manage your restrictions",
                          style: TextStyle(
                              color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(width: 34),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (totalSelected > 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "$totalSelected restriction${totalSelected > 1 ? 's' : ''} active — we'll warn you on affected foods",
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── ALLERGENS ──
                  const Text("Allergens",
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text("14 Major UK allergens — tap to select",
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 12),
                  _buildSelectableGrid(
                    _allergens,
                    _selectedAllergens,
                    Colors.red,
                    Colors.red.shade400,
                  ),

                  const SizedBox(height: 20),

                  // ── CUSTOM ──
                  const Text("Custom Restrictions",
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text("Add anything not in the list above",
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customController,
                          decoration: InputDecoration(
                            hintText: "e.g. Garlic, Corn...",
                            hintStyle: const TextStyle(fontSize: 13),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                          onSubmitted: (_) => _addCustomAllergen(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _addCustomAllergen,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C3344),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                  if (_customAllergens.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _customAllergens
                          .map((allergen) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.red.shade300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(allergen,
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red.shade700)),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => setState(() =>
                                          _customAllergens.remove(allergen)),
                                      child: Icon(Icons.close,
                                          size: 14,
                                          color: Colors.red.shade400),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── HEALTH CONDITIONS ──
                  const Text("Health Conditions",
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                      "We'll warn you based on nutritional content",
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 12),
                  _buildSelectableGrid(
                    _healthConditions,
                    _selectedConditions,
                    const Color(0xFFFFB300),
                    const Color(0xFFFFB300),
                  ),

                  const SizedBox(height: 20),

                  // ── DIETARY PREFERENCES ──
                  const Text("Dietary Preferences",
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text("Select your dietary preferences",
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 12),
                  _buildSelectableGrid(
                    _dietaryOptions,
                    _selectedDietary,
                    const Color(0xFF66BB6A),
                    const Color(0xFF66BB6A),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _saveData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _saved
                            ? Colors.green
                            : const Color(0xFFADC178),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                    _saved
                                        ? Icons.check
                                        : Icons.save_outlined,
                                    color: Colors.white),
                                const SizedBox(width: 8),
                                Text(_saved ? "Saved!" : "Save",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16)),
                              ],
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
}