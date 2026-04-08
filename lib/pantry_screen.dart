import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/pantry_service.dart';
import 'models/food_item.dart';
import 'item_detail_screen.dart';

class PantryScreen extends StatefulWidget {
  final String initialFilter;
  const PantryScreen({super.key, this.initialFilter = 'All'});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final AuthService _auth = AuthService();
  final PantryService _pantryService = PantryService();
  String _search = '';
  String _filter = 'All'; // will be overridden by initState

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  final List<String> _filters = ['All', 'Fresh', 'Expiring Soon', 'Expired'];

  String _daysLeftLabel(FoodItem item) {
    final diff = item.expiryDate.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Expired';
    if (diff == 0) return 'Expires today';
    if (diff == 1) return '1 day left';
    return '$diff days left';
  }

  List<FoodItem> _applyFilters(List<FoodItem> items) {
    return items.where((item) {
      final matchSearch =
          item.name.toLowerCase().contains(_search.toLowerCase()) ||
              item.category.toLowerCase().contains(_search.toLowerCase());
      final matchFilter = _filter == 'All' || item.tag == _filter;
      return matchSearch && matchFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<List<FoodItem>>(
        stream: _pantryService.getPantryStream(_auth.uid!),
        builder: (context, snapshot) {
          final allItems = snapshot.data ?? [];
          final filtered = _applyFilters(allItems);

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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("My Pantry",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold)),
                              Text("${allItems.length} items stored",
                                  style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12)),
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
                      const SizedBox(height: 16),
                      // Search bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          onChanged: (v) => setState(() => _search = v),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: "Search pantry...",
                            hintStyle: TextStyle(color: Colors.white38),
                            prefixIcon: Icon(Icons.search,
                                color: Colors.white54),
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Filter tabs
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _filters.map((f) {
                            final isSelected = _filter == f;
                            return GestureDetector(
                              onTap: () => setState(() => _filter = f),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white12,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(f,
                                    style: TextStyle(
                                        color: isSelected
                                            ? const Color(0xFF2C3344)
                                            : Colors.white70,
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── STATS ROW ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Row(
                    children: [
                      _miniStat(
                          allItems
                              .where((i) => i.tag == 'Fresh')
                              .length
                              .toString(),
                          "Fresh",
                          Colors.green),
                      const SizedBox(width: 10),
                      _miniStat(
                          allItems
                              .where((i) => i.tag == 'Expiring Soon')
                              .length
                              .toString(),
                          "Expiring Soon",
                          Colors.orange),
                      const SizedBox(width: 10),
                      _miniStat(
                          allItems
                              .where((i) => i.tag == 'Expired')
                              .length
                              .toString(),
                          "Expired",
                          Colors.red),
                    ],
                  ),
                ),
              ),

              // ── ITEM COUNT ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    "${filtered.length} item${filtered.length == 1 ? '' : 's'}",
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12),
                  ),
                ),
              ),

              // ── LIST ──
              filtered.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              _search.isNotEmpty
                                  ? "No items match \"$_search\""
                                  : "No $_filter items",
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _foodTile(context, filtered[index]),
                          childCount: filtered.length,
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  Widget _headerIconBtn(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }

  Widget _miniStat(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color)),
            Text(label,
                style: TextStyle(fontSize: 9, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _foodTile(BuildContext context, FoodItem item) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ItemDetailScreen(item: item)),
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
            // Coloured left bar
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
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
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
              child:
                  Icon(Icons.chevron_right, color: Colors.grey, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}