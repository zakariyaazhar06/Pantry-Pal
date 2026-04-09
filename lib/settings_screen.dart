import 'package:flutter/material.dart';
import 'services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _auth = AuthService();
  
  // Dummy states for the UI switches
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    // main.dart StreamBuilder handles state, but we'll pop to ensure no bad back-stack behaviour
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("Preferences", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          _buildSettingsCard([
            _buildSwitchTile("Push Notifications", Icons.notifications_active_outlined, _notificationsEnabled, (val) {
              setState(() => _notificationsEnabled = val);
            }),
            _buildDivider(),
            _buildSwitchTile("Dark Mode", Icons.dark_mode_outlined, _darkModeEnabled, (val) {
              setState(() => _darkModeEnabled = val);
            }),
            _buildDivider(),
            _buildActionTile("Measurement Unit", Icons.straighten_outlined, "Metric", () {}),
          ]),
          
          const SizedBox(height: 24),
          const Text("Account", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          _buildSettingsCard([
            _buildActionTile("Edit Profile", Icons.person_outline, null, () {}),
            _buildDivider(),
            _buildActionTile("Privacy & Security", Icons.lock_outline, null, () {}),
          ]),

          const SizedBox(height: 24),
          const Text("Support", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          _buildSettingsCard([
            _buildActionTile("Help Center", Icons.help_outline, null, () {}),
            _buildDivider(),
            _buildActionTile("Terms of Service", Icons.description_outlined, null, () {}),
          ]),

          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              // Show confirmation dialog before logout
              showDialog(
                context: context,
                builder: (BuildContext ctx) {
                  return AlertDialog(
                    title: const Text('Log Out'),
                    content: const Text('Are you sure you want to log out of your account?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _logout();
                        },
                        child: const Text('Log Out', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text("Log Out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
            ),
          ),
          const SizedBox(height: 40),
          const Center(
            child: Text("Pantry Pal v1.0.0", style: TextStyle(color: Colors.grey, fontSize: 12)),
          )
        ],
      )
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.shade100, indent: 50);
  }

  Widget _buildSwitchTile(String title, IconData icon, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 22),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
          Switch(
            value: value,
            activeColor: const Color(0xFF66BB6A),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, String? trailingText, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 22),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
            if (trailingText != null) 
               Text(trailingText, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
