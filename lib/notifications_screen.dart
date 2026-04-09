import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/pantry_service.dart';
import 'models/food_item.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final pantryService = PantryService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<List<FoodItem>>(
        stream: pantryService.getPantryStream(auth.uid!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator(color: Color(0xFF2C3344)));
          }
          
          final pantry = snapshot.data ?? [];
          final notifications = <Map<String, dynamic>>[];
          final now = DateTime.now();

          // Generate dynamic notifications based on expiry dates
          for (final item in pantry) {
            final diff = item.expiryDate.difference(now).inDays;
            
            if (diff < 0) {
              notifications.add({
                'title': '${item.name} has expired!',
                'body': 'Consider tossing this out to keep your pantry fresh.',
                'color': Colors.red,
                'icon': Icons.error_outline,
                'time': '${diff.abs()}d ago'
              });
            } else if (diff == 0) {
               notifications.add({
                'title': '${item.name} expires TODAY',
                'body': 'Use it quickly before it goes bad.',
                'color': Colors.orange,
                'icon': Icons.warning_amber_rounded,
                'time': 'Today'
              });
            } else if (diff == 1) {
              notifications.add({
                'title': '${item.name} expires tomorrow',
                'body': 'Time to plan a meal with this ingredient.',
                'color': Colors.orangeAccent,
                'icon': Icons.access_time,
                'time': 'Tomorrow'
              });
            } else if (diff <= 3) {
              notifications.add({
                'title': '${item.name} expires in $diff days',
                'body': 'Keep this in mind for upcoming meals.',
                'color': Colors.blueGrey,
                'icon': Icons.info_outline,
                'time': 'Soon'
              });
            }
          }

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey[300]),
                   const SizedBox(height: 12),
                   const Text("You're all caught up!", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              )
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
               final notif = notifications[index];
               return _buildNotificationCard(notif);
            },
          );
        },
      )
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: notif['color'].withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(notif['icon'], color: notif['color'], size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notif['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(notif['body'], style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(notif['time'], style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
