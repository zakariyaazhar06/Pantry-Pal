import 'add_food_screen.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isLoading = false;
  bool _hasScanned = false;
  ProductData? _product;
  String _error = '';

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_hasScanned || _isLoading) return;
    final barcode = capture.barcodes.first.rawValue;
    if (barcode == null) return;

    setState(() {
      _hasScanned = true;
      _isLoading = true;
      _error = '';
    });

    await _controller.stop();
    await _fetchProduct(barcode);
  }

  Future<void> _fetchProduct(String barcode) async {
    try {
      final url = Uri.parse(
          'https://world.openfoodfacts.org/api/v0/product/$barcode.json');
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 1) {
        final nutriments = data['product']['nutriments'] ?? {};
        final productName = data['product']['product_name'] ?? 'Unknown';
        final imageUrl = data['product']['image_url'] ?? '';

        setState(() {
          _product = ProductData(
            name: productName,
            imageUrl: imageUrl,
            calories: _parseDouble(nutriments['energy-kcal_100g']),
            protein: _parseDouble(nutriments['proteins_100g']),
            fat: _parseDouble(nutriments['fat_100g']),
            carbs: _parseDouble(nutriments['carbohydrates_100g']),
            fibre: _parseDouble(nutriments['fiber_100g']),
            sugar: _parseDouble(nutriments['sugars_100g']),
            salt: _parseDouble(nutriments['salt_100g']),
            saturates: _parseDouble(nutriments['saturated-fat_100g']),
            energy: _parseDouble(nutriments['energy_100g']),
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Product not found. Try scanning again.';
          _isLoading = false;
          _hasScanned = false;
        });
        await _controller.start();
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching product. Check your connection.';
        _isLoading = false;
        _hasScanned = false;
      });
      await _controller.start();
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  void _reset() {
    setState(() {
      _hasScanned = false;
      _product = null;
      _error = '';
    });
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _product != null
          ? _buildProductResult()
          : _buildScanner(),
    );
  }

  // ── SCANNER VIEW ──
  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onBarcodeDetected,
        ),
        // Dark overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.6),
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        ),
        // Header
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 20),
                  ),
                ),
                const Text("Scan Barcode",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 40),
              ],
            ),
          ),
        ),
        // Scan frame
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 250,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isLoading
                      ? 'Looking up product...'
                      : 'Point camera at barcode',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14),
                ),
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_error,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13)),
                ),
              ],
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: CircularProgressIndicator(
                      color: Colors.white),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── PRODUCT RESULT VIEW ──
  Widget _buildProductResult() {
    final p = _product!;
    return CustomScrollView(
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
                  children: [
                    Text("Product Found",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    Text("Nutritional breakdown",
                        style: TextStyle(
                            color: Colors.white60, fontSize: 11)),
                  ],
                ),
                GestureDetector(
                  onTap: _reset,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.qr_code_scanner,
                        color: Colors.white, size: 18),
                  ),
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
                // ── PRODUCT CARD ──
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
                      // Image
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: p.imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(12),
                                child: Image.network(p.imageUrl,
                                    fit: BoxFit.cover),
                              )
                            : const Icon(Icons.fastfood,
                                color: Colors.grey, size: 34),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(p.name,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Text(
                                    p.calories.toStringAsFixed(0),
                                    style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight:
                                            FontWeight.bold)),
                                const SizedBox(width: 3),
                                const Padding(
                                  padding:
                                      EdgeInsets.only(bottom: 4),
                                  child: Text("kcal",
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _macroChip("P",
                                    "${p.protein.toStringAsFixed(1)}g",
                                    const Color(0xFFB5A642)),
                                const SizedBox(width: 6),
                                _macroChip("F",
                                    "${p.fat.toStringAsFixed(1)}g",
                                    const Color(0xFF37474F)),
                                const SizedBox(width: 6),
                                _macroChip("C",
                                    "${p.carbs.toStringAsFixed(1)}g",
                                    const Color(0xFF66BB6A)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── NUTRITION TABLE ──
                const Text("Nutritional Info",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
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
                      _tableRow("Energy",
                          "${p.energy.toStringAsFixed(0)} kJ / ${p.calories.toStringAsFixed(0)} kcal",
                          true),
                      _tableRow("Fat",
                          "${p.fat.toStringAsFixed(1)}g", false),
                      _tableRow("(Of which Saturates)",
                          "${p.saturates.toStringAsFixed(1)}g",
                          true),
                      _tableRow("Carbohydrates",
                          "${p.carbs.toStringAsFixed(1)}g", false),
                      _tableRow("(Of which Sugars)",
                          "${p.sugar.toStringAsFixed(1)}g", true),
                      _tableRow("Fibre",
                          "${p.fibre.toStringAsFixed(1)}g", false),
                      _tableRow("Protein",
                          "${p.protein.toStringAsFixed(1)}g", true),
                      _tableRow("Salt",
                          "${p.salt.toStringAsFixed(1)}g", false),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── ADD TO PANTRY BUTTON ──
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // close scanner
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddFoodScreen(productData: p),
    ),
  );
},
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text("Add to Pantry",
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFADC178),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.qr_code_scanner,
                        color: Color(0xFF2C3344)),
                    label: const Text("Scan Again",
                        style:
                            TextStyle(color: Color(0xFF2C3344))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFF2C3344)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _macroChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text("$label: $value",
          style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
          Text("Per 100g as Sold",
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _tableRow(String label, String value, bool shaded) {
    return Container(
      color: shaded ? Colors.grey[50] : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
}

// ── DATA MODEL ──
class ProductData {
  final String name;
  final String imageUrl;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double fibre;
  final double sugar;
  final double salt;
  final double saturates;
  final double energy;

  ProductData({
    required this.name,
    required this.imageUrl,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.fibre,
    required this.sugar,
    required this.salt,
    required this.saturates,
    required this.energy,
  });
}