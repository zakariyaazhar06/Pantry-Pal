import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/pantry_service.dart';
import 'models/food_item.dart';
import 'barcode_scanner_screen.dart';

class AddFoodScreen extends StatefulWidget {
  final ProductData? productData; // pre-filled from scanner

  const AddFoodScreen({super.key, this.productData});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final AuthService _auth = AuthService();
  final PantryService _pantryService = PantryService();

  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _quantity;
  DateTime _boughtDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill from scanner if available
    _name = TextEditingController(
        text: widget.productData?.name ?? '');
    _category = TextEditingController();
    _quantity = TextEditingController();
  }

  Future<void> _pickDate(bool isExpiry) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isExpiry ? _expiryDate : _boughtDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isExpiry) {
          _expiryDate = picked;
        } else {
          _boughtDate = picked;
        }
      });
    }
  }

  String _computeTag(DateTime expiry) {
    final now = DateTime.now();
    final diff = expiry.difference(now).inDays;
    if (diff < 0) return 'Expired';
    if (diff <= 2) return 'Expiring Soon';
    return 'Fresh';
  }

  Future<void> _submit() async {
  if (_name.text.isEmpty) return;
  setState(() => _loading = true);

  final p = widget.productData;

  final item = FoodItem(
    name: _name.text.trim(),
    category: _category.text.trim(),
    quantity: _quantity.text.trim(),
    tag: _computeTag(_expiryDate),
    expiryDate: _expiryDate,
    boughtDate: _boughtDate,
    calories: p?.calories,
    protein: p?.protein,
    fat: p?.fat,
    carbs: p?.carbs,
    fibre: p?.fibre,
    sugar: p?.sugar,
    salt: p?.salt,
    saturates: p?.saturates,
    energy: p?.energy,
    imageUrl: p?.imageUrl,
  );

  await _pantryService.addItem(_auth.uid!, item);
  if (mounted) Navigator.pop(context);
}

  @override
  Widget build(BuildContext context) {
    final bool isFromScanner = widget.productData != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
                  Column(
                    children: [
                      const Text("Add to Pantry",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      Text(
                        isFromScanner
                            ? "Pre-filled from barcode"
                            : "Add item manually",
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 11),
                      ),
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
                  // Scanner nutrition summary if from barcode
                  if (isFromScanner) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
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
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: widget.productData!.imageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    child: Image.network(
                                        widget.productData!.imageUrl,
                                        fit: BoxFit.cover),
                                  )
                                : const Icon(Icons.fastfood,
                                    color: Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(widget.productData!.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(
                                    "${widget.productData!.calories.toStringAsFixed(0)} kcal • P: ${widget.productData!.protein.toStringAsFixed(1)}g • F: ${widget.productData!.fat.toStringAsFixed(1)}g • C: ${widget.productData!.carbs.toStringAsFixed(1)}g",
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  const Text("Basic Information",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildTextField(_name, "Food Name",
                      "e.g. Chicken Breast"),
                  const SizedBox(height: 12),
                  _buildTextField(_category, "Category", "e.g. Meat"),
                  const SizedBox(height: 12),
                  _buildTextField(_quantity, "Quantity", "e.g. 500g"),
                  const SizedBox(height: 20),
                  const Text("Dates",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _buildDateButton(
                              "Date Bought", _boughtDate, false)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildDateButton(
                              "Date Expires", _expiryDate, true)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFADC178),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text("Add to Pantry",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel",
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller,
      String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildDateButton(
      String label, DateTime date, bool isExpiry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () => _pickDate(isExpiry),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 15, vertical: 15),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}