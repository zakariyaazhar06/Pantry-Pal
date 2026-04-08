import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/auth_service.dart';
import 'services/pantry_service.dart';
import 'models/food_item.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final AuthService _auth = AuthService();
  final PantryService _pantryService = PantryService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<List<FoodItem>>(
        stream: _pantryService.getPantryStream(_auth.uid!),
        builder: (context, pantrySnap) {
          return FutureBuilder<DocumentSnapshot>(
            future: _db.collection('users').doc(_auth.uid!).get(),
            builder: (context, userSnap) {
              final pantry = pantrySnap.data ?? [];
              final withNutrition =
                  pantry.where((i) => i.calories != null).toList();

              // ── User profile data ──
              List<String> healthConditions = [];
              List<String> allAllergens = [];

              if (userSnap.hasData && userSnap.data!.exists) {
                final data =
                    userSnap.data!.data() as Map<String, dynamic>;
                healthConditions =
                    List<String>.from(data['healthConditions'] ?? []);
                final allergens =
                    List<String>.from(data['allergens'] ?? []);
                final custom =
                    List<String>.from(data['customAllergens'] ?? []);
                allAllergens = [...allergens, ...custom];
              }

              // ── Pantry totals ──
              final totalCals = withNutrition.fold<double>(
                  0, (s, i) => s + (i.calories ?? 0));
              final totalProtein = withNutrition.fold<double>(
                  0, (s, i) => s + (i.protein ?? 0));
              final totalCarbs = withNutrition.fold<double>(
                  0, (s, i) => s + (i.carbs ?? 0));
              final totalFat = withNutrition.fold<double>(
                  0, (s, i) => s + (i.fat ?? 0));
              final totalSugar = withNutrition.fold<double>(
                  0, (s, i) => s + (i.sugar ?? 0));
              final totalSalt = withNutrition.fold<double>(
                  0, (s, i) => s + (i.salt ?? 0));
              final totalSaturates = withNutrition.fold<double>(
                  0, (s, i) => s + (i.saturates ?? 0));
              final totalFibre = withNutrition.fold<double>(
                  0, (s, i) => s + (i.fibre ?? 0));

              final totalMacros =
                  totalProtein + totalCarbs + totalFat;

              // ── Health warnings ──
              final warnings = _buildHealthWarnings(
                pantry: withNutrition,
                healthConditions: healthConditions,
                allergens: allAllergens,
              );

              // ── Health score ──
              final score = _calculateHealthScore(
                hasData: withNutrition.isNotEmpty,
                totalProtein: totalProtein,
                totalCarbs: totalCarbs,
                totalFat: totalFat,
                totalFibre: totalFibre,
                warningCount: warnings.length,
              );

              // ── Tips ──
              final tips = _buildTips(
                totalProtein: totalProtein,
                totalCarbs: totalCarbs,
                totalFat: totalFat,
                totalFibre: totalFibre,
                totalSugar: totalSugar,
                totalSalt: totalSalt,
                healthConditions: healthConditions,
                hasItems: withNutrition.isNotEmpty,
              );

              return CustomScrollView(
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
                      padding:
                          const EdgeInsets.fromLTRB(20, 56, 20, 24),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text("Nutrition",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight:
                                              FontWeight.bold)),
                                  Text(
                                      "Pantry health overview",
                                      style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 12)),
                                ],
                              ),
                              Icon(
                                  Icons
                                      .health_and_safety_outlined,
                                  color: Colors.white38,
                                  size: 28),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── STAT CARDS ROW ──
                          Row(
                            children: [
                              _statCard(
                                pantry.length.toString(),
                                "Total Items",
                                Icons.inventory_2_outlined,
                                const Color(0xFFE8EAF6),
                                const Color(0xFF5C6BC0),
                              ),
                              const SizedBox(width: 10),
                              _statCard(
                                withNutrition.length.toString(),
                                "With Nutrition",
                                Icons.restaurant_outlined,
                                const Color(0xFFE8F5E9),
                                const Color(0xFF66BB6A),
                              ),
                              const SizedBox(width: 10),
                              _statCard(
                                warnings.length.toString(),
                                "Alerts",
                                Icons.warning_amber_rounded,
                                warnings.isNotEmpty
                                    ? const Color(0xFFFFEBEE)
                                    : const Color(0xFFE8F5E9),
                                warnings.isNotEmpty
                                    ? const Color(0xFFEF5350)
                                    : const Color(0xFF66BB6A),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── PANTRY HEALTH SCORE ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          20, 24, 20, 0),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFE8F5E9),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                    Icons.shield_outlined,
                                    color: Color(0xFF66BB6A),
                                    size: 16),
                              ),
                              const SizedBox(width: 8),
                              const Text("Pantry Health Score",
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight:
                                          FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.grey.shade100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Score ring
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: Stack(
                                    alignment:
                                        Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 80,
                                        height: 80,
                                        child:
                                            CircularProgressIndicator(
                                          value: 1,
                                          strokeWidth: 7,
                                          color:
                                              Colors.grey[200],
                                          strokeCap:
                                              StrokeCap.round,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 80,
                                        height: 80,
                                        child:
                                            CircularProgressIndicator(
                                          value: score / 100,
                                          strokeWidth: 7,
                                          color:
                                              _scoreColor(score),
                                          backgroundColor:
                                              Colors
                                                  .transparent,
                                          strokeCap:
                                              StrokeCap.round,
                                        ),
                                      ),
                                      Text("$score",
                                          style: TextStyle(
                                              fontSize: 22,
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                              color:
                                                  _scoreColor(
                                                      score))),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        _scoreLabel(score),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                              FontWeight.bold,
                                          color: _scoreColor(
                                              score),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _scoreDescription(
                                            score,
                                            warnings.length),
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors
                                                .grey[500],
                                            height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── HEALTH ALERTS ──
                  if (warnings.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            20, 24, 20, 0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red.shade400,
                                  size: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                                "Health Alerts (${warnings.length})",
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight:
                                        FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                          20, 12, 20, 0),
                      sliver: SliverList(
                        delegate:
                            SliverChildBuilderDelegate(
                          (context, index) =>
                              _warningCard(warnings[index]),
                          childCount: warnings.length,
                        ),
                      ),
                    ),
                  ],

                  // ── MACRO BALANCE ──
                  if (withNutrition.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            20, 24, 20, 0),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                        0xFFFFF8E1),
                                    borderRadius:
                                        BorderRadius.circular(
                                            8),
                                  ),
                                  child: const Icon(
                                      Icons.pie_chart_outline,
                                      color:
                                          Color(0xFFFFB300),
                                      size: 16),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                    "Macro Balance",
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight:
                                            FontWeight
                                                .bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "How your pantry's nutrition breaks down",
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[400]),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding:
                                  const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(16),
                                border: Border.all(
                                    color:
                                        Colors.grey.shade100),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withOpacity(0.04),
                                    blurRadius: 10,
                                    offset:
                                        const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Stacked bar
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(
                                            8),
                                    child: SizedBox(
                                      height: 16,
                                      child: Row(
                                        children: totalMacros >
                                                0
                                            ? [
                                                Expanded(
                                                  flex: (totalProtein *
                                                          100 ~/
                                                          totalMacros)
                                                      .clamp(
                                                          1,
                                                          100),
                                                  child: Container(
                                                      color: const Color(
                                                          0xFFB5A642)),
                                                ),
                                                Expanded(
                                                  flex: (totalCarbs *
                                                          100 ~/
                                                          totalMacros)
                                                      .clamp(
                                                          1,
                                                          100),
                                                  child: Container(
                                                      color: const Color(
                                                          0xFF66BB6A)),
                                                ),
                                                Expanded(
                                                  flex: (totalFat *
                                                          100 ~/
                                                          totalMacros)
                                                      .clamp(
                                                          1,
                                                          100),
                                                  child: Container(
                                                      color: const Color(
                                                          0xFF5C6BC0)),
                                                ),
                                              ]
                                            : [
                                                Expanded(
                                                    child: Container(
                                                        color: Colors
                                                            .grey[200])),
                                              ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Legend
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceAround,
                                    children: [
                                      _macroLegend(
                                        "Protein",
                                        totalProtein,
                                        totalMacros,
                                        const Color(
                                            0xFFB5A642),
                                      ),
                                      _macroLegend(
                                        "Carbs",
                                        totalCarbs,
                                        totalMacros,
                                        const Color(
                                            0xFF66BB6A),
                                      ),
                                      _macroLegend(
                                        "Fat",
                                        totalFat,
                                        totalMacros,
                                        const Color(
                                            0xFF5C6BC0),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Divider(
                                      color:
                                          Colors.grey.shade100),
                                  const SizedBox(height: 8),
                                  // Total cal + extra nutrients
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                    children: [
                                      _miniStat(
                                          "Total Calories",
                                          "${totalCals.toStringAsFixed(0)} kcal"),
                                      _miniStat("Fibre",
                                          "${totalFibre.toStringAsFixed(1)}g"),
                                      _miniStat("Sugar",
                                          "${totalSugar.toStringAsFixed(1)}g"),
                                      _miniStat("Salt",
                                          "${totalSalt.toStringAsFixed(1)}g"),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── RECOMMENDATIONS ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8EAF6),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: const Icon(
                                Icons.lightbulb_outline,
                                color: Color(0xFF5C6BC0),
                                size: 16),
                          ),
                          const SizedBox(width: 8),
                          const Text("Recommendations",
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 12, 20, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _tipCard(tips[index]),
                        childCount: tips.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ── HEALTH WARNINGS ──
  List<Map<String, String>> _buildHealthWarnings({
    required List<FoodItem> pantry,
    required List<String> healthConditions,
    required List<String> allergens,
  }) {
    final warnings = <Map<String, String>>[];

    for (final item in pantry) {
      if (healthConditions.contains('Diabetes') &&
          item.sugar != null &&
          item.sugar! > 10) {
        warnings.add({
          'title': '${item.name} — High Sugar',
          'detail':
              '${item.sugar!.toStringAsFixed(1)}g sugar. May not be suitable with Diabetes.',
          'severity': 'high',
        });
      }

      if (healthConditions.contains('High Blood Pressure') &&
          item.salt != null &&
          item.salt! > 1.5) {
        warnings.add({
          'title': '${item.name} — High Salt',
          'detail':
              '${item.salt!.toStringAsFixed(1)}g salt. May not be suitable with High Blood Pressure.',
          'severity': 'high',
        });
      }

      if (healthConditions.contains('High Cholesterol') &&
          item.saturates != null &&
          item.saturates! > 5) {
        warnings.add({
          'title': '${item.name} — High Saturated Fat',
          'detail':
              '${item.saturates!.toStringAsFixed(1)}g saturates. May not be suitable with High Cholesterol.',
          'severity': 'medium',
        });
      }

      if (healthConditions.contains('Obesity') &&
          item.calories != null &&
          item.calories! > 400) {
        warnings.add({
          'title': '${item.name} — High Calorie',
          'detail':
              '${item.calories!.toStringAsFixed(0)} kcal per serving. High calorie density.',
          'severity': 'medium',
        });
      }

      // Allergen name matching
      final itemLower = item.name.toLowerCase();
      const allergenKeywords = {
        'Gluten': ['gluten', 'wheat', 'barley', 'rye', 'oats'],
        'Dairy': ['milk', 'dairy', 'cheese', 'butter', 'cream', 'yogurt'],
        'Eggs': ['egg', 'eggs'],
        'Peanuts': ['peanut'],
        'Tree Nuts': ['almond', 'cashew', 'walnut', 'pistachio', 'hazelnut'],
        'Fish': ['fish', 'cod', 'salmon', 'tuna'],
        'Shellfish': ['shrimp', 'prawn', 'crab', 'lobster'],
        'Soy': ['soy', 'soya', 'tofu'],
        'Sesame': ['sesame', 'tahini'],
      };

      for (final allergen in allergens) {
        final keywords =
            allergenKeywords[allergen] ?? [allergen.toLowerCase()];
        for (final keyword in keywords) {
          if (itemLower.contains(keyword)) {
            warnings.add({
              'title': '${item.name} — Contains $allergen',
              'detail':
                  'This item may contain $allergen. Check the label.',
              'severity': 'high',
            });
            break;
          }
        }
      }
    }

    return warnings;
  }

  // ── HEALTH SCORE ──
  int _calculateHealthScore({
    required bool hasData,
    required double totalProtein,
    required double totalCarbs,
    required double totalFat,
    required double totalFibre,
    required int warningCount,
  }) {
    if (!hasData) return 50;

    double score = 70;

    // Reward balanced macro ratio
    final total = totalProtein + totalCarbs + totalFat;
    if (total > 0) {
      final protPct = totalProtein / total;
      final carbPct = totalCarbs / total;
      final fatPct = totalFat / total;

      // Balanced = roughly 25-35% protein, 40-55% carbs, 20-35% fat
      if (protPct >= 0.15 && protPct <= 0.40) score += 5;
      if (carbPct >= 0.30 && carbPct <= 0.60) score += 5;
      if (fatPct >= 0.15 && fatPct <= 0.40) score += 5;
    }

    // Reward fibre
    if (totalFibre > 10) score += 5;
    if (totalFibre > 25) score += 5;

    // Penalise health warnings
    score -= warningCount * 7;

    return score.clamp(0, 100).round();
  }

  // ── TIPS ──
  List<Map<String, String>> _buildTips({
    required double totalProtein,
    required double totalCarbs,
    required double totalFat,
    required double totalFibre,
    required double totalSugar,
    required double totalSalt,
    required List<String> healthConditions,
    required bool hasItems,
  }) {
    final tips = <Map<String, String>>[];

    if (!hasItems) {
      tips.add({
        'icon': 'scan',
        'title': 'Scan items to get insights',
        'detail':
            'Use the barcode scanner to add items with nutrition data. We\'ll analyse your pantry and cross-check with your health profile.',
      });
      return tips;
    }

    final total = totalProtein + totalCarbs + totalFat;
    if (total > 0) {
      final protPct = totalProtein / total;
      if (protPct < 0.15) {
        tips.add({
          'icon': 'protein',
          'title': 'Pantry is low in protein',
          'detail':
              'Only ${(protPct * 100).toStringAsFixed(0)}% of your pantry macros are protein. Consider stocking chicken, eggs, or legumes.',
        });
      }

      final fatPct = totalFat / total;
      if (fatPct > 0.40) {
        tips.add({
          'icon': 'fat',
          'title': 'Pantry is high in fat',
          'detail':
              '${(fatPct * 100).toStringAsFixed(0)}% of your pantry macros are fat. Consider adding more lean items.',
        });
      }
    }

    if (totalFibre < 10 && hasItems) {
      tips.add({
        'icon': 'fibre',
        'title': 'Low fibre in pantry',
        'detail':
            'Only ${totalFibre.toStringAsFixed(0)}g fibre across your pantry. Fruits, veg, and whole grains can help.',
      });
    }

    if (healthConditions.contains('Diabetes') && totalSugar > 50) {
      tips.add({
        'icon': 'sugar',
        'title': 'Sugar levels in pantry',
        'detail':
            '${totalSugar.toStringAsFixed(0)}g of sugar across your pantry items. With Diabetes, consider swapping for lower-sugar alternatives.',
      });
    }

    if (healthConditions.contains('High Blood Pressure') &&
        totalSalt > 6) {
      tips.add({
        'icon': 'salt',
        'title': 'Salt levels in pantry',
        'detail':
            '${totalSalt.toStringAsFixed(1)}g salt across pantry items. NHS recommends no more than 6g/day for adults.',
      });
    }

    if (tips.isEmpty) {
      tips.add({
        'icon': 'check',
        'title': 'Looking good!',
        'detail':
            'Your pantry looks well-balanced based on your health profile. Keep it up!',
      });
    }

    return tips;
  }

  // ── WIDGET HELPERS ──

  String _scoreLabel(int score) {
    if (score >= 80) return "Excellent";
    if (score >= 60) return "Good";
    if (score >= 40) return "Fair";
    return "Needs Attention";
  }

  String _scoreDescription(int score, int warningCount) {
    if (score >= 80) {
      return "Your pantry is well-balanced and aligned with your health profile.";
    }
    if (score >= 60) {
      return "Your pantry is in decent shape. ${warningCount > 0 ? '$warningCount item${warningCount > 1 ? 's' : ''} flagged based on your health profile.' : ''}";
    }
    if (score >= 40) {
      return "Some items in your pantry may conflict with your health profile. Check the alerts below.";
    }
    return "Several items need attention based on your health conditions and dietary restrictions.";
  }

  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFF66BB6A);
    if (score >= 60) return const Color(0xFFB5A642);
    if (score >= 40) return const Color(0xFFFFB300);
    return Colors.redAccent;
  }

  Widget _statCard(String value, String label, IconData icon,
      Color bgColor, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 8.5, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _macroLegend(
      String label, double value, double total, Color color) {
    final pct =
        total > 0 ? (value / total * 100).toStringAsFixed(0) : "0";
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 4),
        Text("${value.toStringAsFixed(0)}g ($pct%)",
            style: TextStyle(
                fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 9, color: Colors.grey[400])),
      ],
    );
  }

  Widget _warningCard(Map<String, String> warning) {
    final isHigh = warning['severity'] == 'high';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            isHigh ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isHigh
                ? Colors.red.shade200
                : Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isHigh
                ? Icons.warning_amber_rounded
                : Icons.info_outline,
            color: isHigh ? Colors.red : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(warning['title']!,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isHigh
                            ? Colors.red.shade700
                            : Colors.orange.shade800)),
                const SizedBox(height: 3),
                Text(warning['detail']!,
                    style: TextStyle(
                        fontSize: 11,
                        color: isHigh
                            ? Colors.red.shade600
                            : Colors.orange.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipCard(Map<String, String> tip) {
    IconData icon;
    switch (tip['icon']) {
      case 'protein':
        icon = Icons.fitness_center;
        break;
      case 'fat':
        icon = Icons.opacity;
        break;
      case 'fibre':
        icon = Icons.grass;
        break;
      case 'sugar':
        icon = Icons.cake_outlined;
        break;
      case 'salt':
        icon = Icons.water_drop_outlined;
        break;
      case 'scan':
        icon = Icons.qr_code_scanner;
        break;
      case 'check':
        icon = Icons.check_circle_outline;
        break;
      default:
        icon = Icons.lightbulb_outline;
    }

    final isPositive = tip['icon'] == 'check';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPositive
            ? const Color(0xFFE8F5E9)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isPositive
                ? const Color(0xFF66BB6A)
                : Colors.grey.shade100),
        boxShadow: isPositive
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isPositive
                  ? const Color(0xFF66BB6A).withOpacity(0.2)
                  : const Color(0xFFE8EAF6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                size: 16,
                color: isPositive
                    ? const Color(0xFF66BB6A)
                    : const Color(0xFF5C6BC0)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip['title']!,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
                const SizedBox(height: 3),
                Text(tip['detail']!,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
