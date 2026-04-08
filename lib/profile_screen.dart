import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController _name = TextEditingController();
  final TextEditingController _age = TextEditingController();
  final TextEditingController _weight = TextEditingController();
  final TextEditingController _height = TextEditingController();

  String _gender = 'Male';
  String _activity = 'Sedentary';
  bool _loading = false;
  bool _saved = false;

  final List<String> _genders = ['Male', 'Female'];
  final List<String> _activityLevels = [
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Very Active',
    'Extra Active',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final doc = await _db
        .collection('users')
        .doc(_auth.uid)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _name.text = data['name'] ?? '';
        _age.text = data['age']?.toString() ?? '';
        _weight.text = data['weight']?.toString() ?? '';
        _height.text = data['height']?.toString() ?? '';
        _gender = data['gender'] ?? 'Male';
        _activity = data['activity'] ?? 'Sedentary';
      });
    }
  }

  // ── TDEE CALCULATION (Mifflin-St Jeor) ──
  double _calculateTDEE() {
    final age = int.tryParse(_age.text) ?? 0;
    final weight = double.tryParse(_weight.text) ?? 0;
    final height = double.tryParse(_height.text) ?? 0;

    if (age == 0 || weight == 0 || height == 0) return 2000;

    double bmr;
    if (_gender == 'Male') {
      bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      bmr = 10 * weight + 6.25 * height - 5 * age - 161;
    }

    const activityMultipliers = {
      'Sedentary': 1.2,
      'Lightly Active': 1.375,
      'Moderately Active': 1.55,
      'Very Active': 1.725,
      'Extra Active': 1.9,
    };

    return bmr * (activityMultipliers[_activity] ?? 1.2);
  }

  Future<void> _saveProfile() async {
  setState(() => _loading = true);
  final tdee = _calculateTDEE();
  final weightLbs = (double.tryParse(_weight.text) ?? 0) * 2.205;
final proteinGoal = weightLbs;
final fatGoal = weightLbs * 0.35;
final carbsGoal = ((tdee - (proteinGoal * 4) - (fatGoal * 9)) / 4).roundToDouble().clamp(0, 9999).toDouble();

  await _db.collection('users').doc(_auth.uid).set({
    'name': _name.text.trim(),
    'age': int.tryParse(_age.text) ?? 0,
    'weight': double.tryParse(_weight.text) ?? 0,
    'height': double.tryParse(_height.text) ?? 0,
    'gender': _gender,
    'activity': _activity,
    'tdee': tdee,
    'proteinGoal': proteinGoal,
    'carbsGoal': carbsGoal,
    'fatGoal': fatGoal,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  setState(() {
    _loading = false;
    _saved = true;
  });

  Future.delayed(const Duration(seconds: 2),
      () => setState(() => _saved = false));
}

  @override
  Widget build(BuildContext context) {
    final tdee = _calculateTDEE();

    return Scaffold(
      backgroundColor: Colors.white,
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
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text("My Profile",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold)),
                          Text("Personal info & goals",
                              style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12)),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _auth.signOut(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.logout,
                                  color: Colors.white70,
                                  size: 14),
                              SizedBox(width: 6),
                              Text("Sign out",
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // TDEE preview card
                  if (tdee > 0) ...[
  Builder(
    builder: (context) {
      final weightLbs = (double.tryParse(_weight.text) ?? 0) * 2.205;
      final proteinGoal = weightLbs;
      final fatGoal = weightLbs * 0.35;
      final carbsGoal = ((tdee - (proteinGoal * 4) - (fatGoal * 9)) / 4).clamp(0.0, 9999.0);

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _tdeeStatItem("${tdee.toStringAsFixed(0)} kcal", "Daily Goal"),
            _tdeeStatItem("${proteinGoal.toStringAsFixed(0)}g", "Protein"),
            _tdeeStatItem("${carbsGoal.toStringAsFixed(0)}g", "Carbs"),
            _tdeeStatItem("${fatGoal.toStringAsFixed(0)}g", "Fat"),
          ],
        ),
      );
    },
  ),
],
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
                  // ── PERSONAL INFO ──
                  const Text("Personal Information",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildTextField(_name, "Name", "e.g. Samir",
                      Icons.person_outline),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(_age, "Age",
                            "e.g. 21", Icons.cake_outlined,
                            isNumber: true),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown(
                            "Gender", _genders, _gender,
                            (val) =>
                                setState(() => _gender = val!)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                            _weight, "Weight (kg)", "e.g. 75",
                            Icons.monitor_weight_outlined,
                            isNumber: true),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                            _height, "Height (cm)", "e.g. 175",
                            Icons.height,
                            isNumber: true),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── ACTIVITY LEVEL ──
                  const Text("Activity Level",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ..._activityLevels.map((level) {
                    final isSelected = _activity == level;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _activity = level),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2C3344)
                              : Colors.white,
                          borderRadius:
                              BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2C3344)
                                : Colors.grey.shade200,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _activityIcon(level),
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(level,
                                      style: TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                          fontSize: 13,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black)),
                                  Text(
                                      _activityDescription(level),
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: isSelected
                                              ? Colors.white70
                                              : Colors.grey)),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle,
                                  color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 24),

                  // ── SAVE BUTTON ──
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _saved
                            ? Colors.green
                            : const Color(0xFFADC178),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14)),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(
                                    _saved
                                        ? Icons.check
                                        : Icons.save_outlined,
                                    color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                    _saved
                                        ? "Saved!"
                                        : "Save Profile",
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

  // ── HELPERS ──

  Widget _tdeeStatItem(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(
                color: Colors.white60, fontSize: 10)),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller,
      String label, String hint, IconData icon,
      {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType:
              isNumber ? TextInputType.number : TextInputType.text,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: Colors.grey),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> options,
      String value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: options
                  .map((o) => DropdownMenuItem(
                      value: o, child: Text(o, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  IconData _activityIcon(String level) {
    switch (level) {
      case 'Sedentary': return Icons.weekend_outlined;
      case 'Lightly Active': return Icons.directions_walk;
      case 'Moderately Active': return Icons.directions_bike;
      case 'Very Active': return Icons.fitness_center;
      case 'Extra Active': return Icons.sports_gymnastics;
      default: return Icons.person_outline;
    }
  }

  String _activityDescription(String level) {
    switch (level) {
      case 'Sedentary': return 'Little or no exercise';
      case 'Lightly Active': return 'Light exercise 1-3 days/week';
      case 'Moderately Active': return 'Moderate exercise 3-5 days/week';
      case 'Very Active': return 'Hard exercise 6-7 days/week';
      case 'Extra Active': return 'Very hard exercise or physical job';
      default: return '';
    }
  }
}