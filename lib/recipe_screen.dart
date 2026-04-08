import 'package:flutter/material.dart';
import 'services/recipe_service.dart';
import 'services/pantry_service.dart';
import 'services/auth_service.dart';
import 'models/food_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  final RecipeService _recipeService = RecipeService();
  final PantryService _pantryService = PantryService();
  final AuthService _auth = AuthService();

  List<Recipe> _recipes = [];
  List<FoodItem> _pantryItems = [];
  bool _loading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
  setState(() {
    _loading = true;
    _error = '';
  });

  try {
    // Get pantry items
    final items = await _pantryService
        .getPantryStream(_auth.uid!)
        .first;

    if (items.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Add items to your pantry first!';
      });
      return;
    }

    // Prioritise expiring soon items first
    items.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    final ingredients = items.take(5).map((i) => i.name).toList();
    setState(() => _pantryItems = items);

    // Fetch user allergens + dietary from Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_auth.uid!)
        .get();

    List<String> allergens = [];
    List<String> dietary = [];

    if (userDoc.exists) {
      final data = userDoc.data()!;
      allergens = List<String>.from(data['allergens'] ?? []);
      dietary = List<String>.from(data['dietary'] ?? []);
    }

    final recipes = await _recipeService.getRecipesByIngredients(
      ingredients,
      allergens: allergens,
      dietary: dietary,
    );

    setState(() {
      _recipes = recipes;
      _loading = false;
    });
  } catch (e) {
    debugPrint('Recipe load error: $e');
    setState(() {
      _error = e.toString().contains('status')
          ? 'API error – check your key or try later.'
          : 'Failed to load recipes. Try again.';
      _loading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text("Get Recipes",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold)),
                          Text("Based on your pantry",
                              style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12)),
                        ],
                      ),
                      GestureDetector(
                        onTap: _loadRecipes,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.refresh,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  if (_pantryItems.isNotEmpty) ...[
  const SizedBox(height: 14),
  const Text("Using ingredients:",
      style: TextStyle(
          color: Colors.white60, fontSize: 11)),
  const SizedBox(height: 8),
  SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: _pantryItems
          .take(5)
          .map((item) => Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(item.name,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11)),
              ))
          .toList(),
    ),
  ),
  // ── ALLERGEN FILTER BANNER ──
  FutureBuilder<DocumentSnapshot>(
    future: FirebaseFirestore.instance
        .collection('users')
        .doc(_auth.uid!)
        .get(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const SizedBox();
      final data = snapshot.data!.data()
              as Map<String, dynamic>? ??
          {};
      final allergens =
          List<String>.from(data['allergens'] ?? []);
      final dietary =
          List<String>.from(data['dietary'] ?? []);
      final all = [...allergens, ...dietary];
      if (all.isEmpty) return const SizedBox();
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            const Icon(Icons.shield_outlined,
                color: Colors.white60, size: 12),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                "Filtering out: ${all.join(', ')}",
                style: const TextStyle(
                    color: Colors.white60, fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ),
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

          // ── CONTENT ──
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                        color: Color(0xFF2C3344)),
                    SizedBox(height: 16),
                    Text("Finding recipes...",
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else if (_error.isNotEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.soup_kitchen_outlined,
                        size: 60, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(_error,
                        style:
                            TextStyle(color: Colors.grey[400])),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loadRecipes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF2C3344),
                      ),
                      child: const Text("Try Again",
                          style:
                              TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _recipeTile(_recipes[index]),
                  childCount: _recipes.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _recipeTile(Recipe recipe) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                RecipeDetailScreen(recipeId: recipe.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: recipe.image.isNotEmpty
                  ? Image.network(
                      recipe.image,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: double.infinity,
                      height: 160,
                      color: Colors.grey[100],
                      child: const Icon(
                          Icons.soup_kitchen_outlined,
                          size: 50,
                          color: Colors.grey),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  // Ingredient tags
                  Row(
                    children: [
                      _ingredientTag(
                          "${recipe.usedIngredientCount} ingredients matched",
                          Colors.green),
                      const SizedBox(width: 8),
                      if (recipe.missedIngredientCount > 0)
                        _ingredientTag(
                            "${recipe.missedIngredientCount} missing",
                            Colors.orange),
                    ],
                  ),
                  if (recipe.usedIngredients.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Uses: ${recipe.usedIngredients.join(', ')}",
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ingredientTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600)),
    );
  }
}

// ── RECIPE DETAIL SCREEN ──
class RecipeDetailScreen extends StatefulWidget {
  final int recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  State<RecipeDetailScreen> createState() =>
      _RecipeDetailScreenState();
}

class _RecipeDetailScreenState
    extends State<RecipeDetailScreen> {
  final RecipeService _recipeService = RecipeService();
  RecipeDetail? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final detail =
          await _recipeService.getRecipeDetail(widget.recipeId);
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF2C3344)))
          : _detail == null
              ? const Center(child: Text("Failed to load recipe"))
              : CustomScrollView(
                  slivers: [
                    // ── HEADER IMAGE ──
                    SliverToBoxAdapter(
                      child: Stack(
                        children: [
                          _detail!.image.isNotEmpty
                              ? Image.network(
                                  _detail!.image,
                                  width: double.infinity,
                                  height: 250,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  height: 250,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                      Icons.soup_kitchen_outlined,
                                      size: 80,
                                      color: Colors.grey),
                                ),
                          // Back button
                          Positioned(
                            top: 50,
                            left: 20,
                            child: GestureDetector(
                              onTap: () =>
                                  Navigator.pop(context),
                              child: Container(
                                padding:
                                    const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(_detail!.title,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),

                            // Stats row
                            Row(
                              children: [
                                _statChip(
                                    Icons.timer_outlined,
                                    "${_detail!.readyInMinutes} min",
                                    const Color(0xFF5C6BC0)),
                                const SizedBox(width: 8),
                                _statChip(
                                    Icons.people_outline,
                                    "${_detail!.servings} servings",
                                    const Color(0xFF66BB6A)),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Ingredients
                            const Text("Ingredients",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: _detail!.ingredients
                                    .asMap()
                                    .entries
                                    .map((e) => Column(
                                          children: [
                                            if (e.key != 0)
                                              Divider(
                                                  height: 1,
                                                  color: Colors
                                                      .grey.shade100),
                                            Padding(
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16,
                                                      vertical: 12),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 6,
                                                    height: 6,
                                                    decoration:
                                                        BoxDecoration(
                                                      color: const Color(
                                                          0xFFB5A642),
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      width: 10),
                                                  Expanded(
                                                    child: Text(
                                                        e.value,
                                                        style: const TextStyle(
                                                            fontSize:
                                                                13)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ))
                                    .toList(),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Steps
                            const Text("Instructions",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            ..._detail!.steps
                                .asMap()
                                .entries
                                .map((e) => Container(
                                      margin: const EdgeInsets.only(
                                          bottom: 10),
                                      padding:
                                          const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(
                                                14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withOpacity(0.03),
                                            blurRadius: 8,
                                            offset:
                                                const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration:
                                                const BoxDecoration(
                                              color: Color(0xFF2C3344),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                  "${e.key + 1}",
                                                  style: const TextStyle(
                                                      color:
                                                          Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight
                                                              .bold)),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(e.value,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    height: 1.5)),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}