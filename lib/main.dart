import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'add_food_screen.dart';
import 'pantry_screen.dart';
import 'item_detail_screen.dart';
import 'barcode_scanner_screen.dart';
import 'services/auth_service.dart';
import 'services/pantry_service.dart';
import 'models/food_item.dart';
import 'recipe_screen.dart';
import 'profile_screen.dart';
import 'allergy_screen.dart';
import 'nutrition_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pantry Pal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2C3344)),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: AuthService().userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) return const RootScreen();
          return const LoginScreen();
        },
      ),
    );
  }
}

// ── ROOT SCREEN ──
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    PantryScreen(),
    RecipeScreen(),
    NutritionScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) {
  if (i == 2) {
    setState(() => _selectedIndex = i);
    return;
  }
  setState(() => _selectedIndex = i);
},
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2C3344),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Pantry'),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFB5A642),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.soup_kitchen_outlined,
                  color: Colors.white, size: 22),
            ),
            label: 'Recipes',
          ),
          const BottomNavigationBarItem(
              icon: Icon(Icons.trending_up_outlined),
              activeIcon: Icon(Icons.trending_up),
              label: 'Nutrition'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}

// ── HOME SCREEN ──
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _auth = AuthService();
  final PantryService _pantryService = PantryService();
  String _currentSortOption = 'Soon To Be Expired';

  String _daysLeftLabel(FoodItem item) {
    final diff = item.expiryDate.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Expired';
    if (diff == 0) return 'Today';
    if (diff == 1) return '1 day left';
    return '$diff days left';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<List<FoodItem>>(
        stream: _pantryService.getPantryStream(_auth.uid!),
        builder: (context, snapshot) {
          final pantry = snapshot.data ?? [];
          
          var sortedPantry = List<FoodItem>.from(pantry);
          if (_currentSortOption == 'Alphabetically') {
            sortedPantry.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          } else if (_currentSortOption == 'Recently Added') {
            sortedPantry.sort((a, b) => b.boughtDate.compareTo(a.boughtDate));
          } else if (_currentSortOption == 'Soon To Be Expired') {
            sortedPantry.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
          }

          final fresh = pantry.where((i) => i.tag == 'Fresh').length;
          final expiringSoon = pantry.where((i) => i.tag == 'Expiring Soon').length;
          final expired = pantry.where((i) => i.tag == 'Expired').length;
          final totalItems = pantry.length;

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
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Pantry Pal",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold)),
                              Text("Your smart food companion",
                                  style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12)),
                            ],
                          ),
                          Row(
                            children: [
                              _headerIconBtn(
                                Icons.notifications_outlined,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationsScreen(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _headerIconBtn(
                                Icons.settings_outlined,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SettingsScreen(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _statCard(
                            pantry.length.toString(),
                            "Items in Pantry",
                            Icons.inventory_2_outlined,
                            const Color(0xFFE8EAF6),
                            const Color(0xFF5C6BC0),
                          ),
                          const SizedBox(width: 10),
                          _statCard(
                            expiringSoon.toString(),
                            "Expiring Soon",
                            Icons.warning_amber_rounded,
                            const Color(0xFFFFF8E1),
                            const Color(0xFFFFB300),
                          ),
                          const SizedBox(width: 10),
                          _statCard(
                            pantry.length >= 2 ? "${pantry.length * 4}+" : "0",
                            "Recipes Ready",
                            Icons.soup_kitchen_outlined,
                            const Color(0xFFE8F5E9),
                            const Color(0xFF66BB6A),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── EXPIRING SOON HEADER ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.warning_amber_rounded,
                                color: Color(0xFFFFB300), size: 16),
                          ),
                          const SizedBox(width: 8),
                          const Text("Expiring Soon",
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        children: [
                          PopupMenuButton<String>(
                            initialValue: _currentSortOption,
                            onSelected: (String result) {
                              setState(() {
                                _currentSortOption = result;
                              });
                            },
                            offset: const Offset(0, 25),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              children: [
                                const Text("Sort by",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                const Icon(Icons.keyboard_arrow_down,
                                    size: 16, color: Colors.grey),
                              ],
                            ),
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'Alphabetically',
                                height: 40,
                                child: Text('Alphabetically', style: TextStyle(fontSize: 14)),
                              ),
                              const PopupMenuDivider(height: 1),
                              const PopupMenuItem<String>(
                                value: 'Recently Added',
                                height: 40,
                                child: Text('Recently Added', style: TextStyle(fontSize: 14)),
                              ),
                              const PopupMenuDivider(height: 1),
                              const PopupMenuItem<String>(
                                value: 'Soon To Be Expired',
                                height: 40,
                                child: Text('Soon To Be Expired', style: TextStyle(fontSize: 14)),
                              ),
                            ],
                          ),
                          const SizedBox(width: 15),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PantryScreen(initialFilter: 'All'),
                                ),
                              );
                            },
                            child: const Text("View all",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── FOOD TILES ──
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: sortedPantry.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(30),
                            child: Text(
                              "No items yet — scan or add food manually!",
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _foodTile(sortedPantry[index]),
                          childCount: sortedPantry.length,
                        ),
                      ),
              ),

              // ── QUICK ACTIONS ──
              // Updated...
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Quick Actions",
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            _actionBtn(
              "Scan Item",
              "Barcode Scanner",
              Icons.crop_free,
              const Color(0xFFE8EAF6),
              const Color(0xFF5C6BC0),
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const BarcodeScannerScreen())),
            ),
            const SizedBox(width: 12),
            _actionBtn(
              "Add Item",
              "Add Manually",
              Icons.add,
              const Color(0xFFE8F5E9),
              const Color(0xFF66BB6A),
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const AddFoodScreen())),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _actionBtn(
              "Dietary Prefs",
              "Set your filters",
              Icons.health_and_safety_outlined,
              const Color(0xFFFFEBEE),
              const Color(0xFFEF5350),
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const AllergyScreen())),
            ),
            const SizedBox(width: 12),
            _actionBtn(
  "Expiring Soon",
  "View filtered pantry",
  Icons.access_time,
  const Color(0xFFFFF8E1),
  const Color(0xFFFFB300),
  () => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => const PantryScreen(
              initialFilter: 'Expiring Soon'))),
),
          ],
        ),
      ],
    ),
  ),
),

              // ── SMART STORAGE TIPS ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Daily Tip",
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF9C4),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.lightbulb_outline,
                                  color: Color(0xFFFBC02D), size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Smart Storage",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF374151))),
                                  const SizedBox(height: 6),
                                  Text(
                                    _getDailyTip(),
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
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
            ],
          );
        },
      ),
    );
  }

  Widget _headerIconBtn(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon,
      Color bgColor, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration:
                  BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 8.5, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _foodTile(FoodItem item) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 80,
              decoration: BoxDecoration(
                color: item.tagColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 3),
                    Text('${item.category} • ${item.quantity}',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            border: Border.all(color: item.tagColor),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_daysLeftLabel(item),
                              style: TextStyle(
                                  color: item.tagColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        Text(item.formattedExpiry,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
  margin: const EdgeInsets.only(right: 10),
  width: 58,
  height: 58,
  decoration: BoxDecoration(
    color: Colors.grey[100],
    borderRadius: BorderRadius.circular(10),
  ),
  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
      ? ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(item.imageUrl!, fit: BoxFit.cover),
        )
      : const Icon(Icons.fastfood, color: Colors.grey, size: 28),
),
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.chevron_right,
                  color: Colors.grey, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(String title, String sub, IconData icon,
      Color bgColor, Color iconColor, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(sub,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDailyTip() {
    final tips = [
      "Store your onions and potatoes in separate cabinets! Onions release moisture that makes potatoes sprout faster.",
      "Keep bananas away from other fruit to slow ripening, or put them together if you want avocados to ripen faster!",
      "Herbs like cilantro and parsley last much longer if you trim the stems and store them in a glass of water in the fridge.",
      "Don't store milk in the fridge door! The temperature fluctuates too much. Keep it on a shelf towards the back.",
      "Wrap celery, broccoli, and lettuce in tin foil before storing in the crisper. It stays crisp for weeks!"
    ];
    return tips[DateTime.now().day % tips.length];
  }
}