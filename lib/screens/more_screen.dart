import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/notification_service.dart';

class _MenuItem {
  final IconData icon;
  final String label;
  final String route;
  const _MenuItem(this.icon, this.label, this.route);
}

const _items = [
  _MenuItem(Icons.swap_horiz_rounded, 'Egg Trading', '/egg-trading'),
  _MenuItem(Icons.people_outline, 'Customers', '/customers'),
  _MenuItem(Icons.grass_outlined, 'Feed Management', '/feeds'),
  _MenuItem(Icons.medication_outlined, 'Medicine', '/medicines'),
  _MenuItem(Icons.point_of_sale_outlined, 'Sales', '/sales'),
  _MenuItem(Icons.account_balance_wallet_outlined, 'Investments', '/investments'),
  _MenuItem(Icons.vaccines_outlined, 'Vaccination', '/vaccination'),
  _MenuItem(Icons.store_outlined, 'Vendors', '/vendors'),
  _MenuItem(Icons.location_on_outlined, 'Locations', '/locations'),
  _MenuItem(Icons.pets_outlined, 'Bird Breeds', '/bird-breeds'),
  _MenuItem(Icons.speed_outlined, 'Performance', '/performance'),
  _MenuItem(Icons.insights_outlined, 'Analytics', '/analytics'),
];

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          ..._items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              leading: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(10)),
                child: Icon(item.icon, size: 20, color: AppTheme.darkGray),
              ),
              title: Text(item.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.chevron_right, color: AppTheme.gray, size: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppTheme.separator.withValues(alpha: 0.5))),
              onTap: () => Navigator.pushNamed(context, item.route),
            ),
          )),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Test Notifications', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.gray)),
          ),
          _testCard(
            'Send Daily Log Reminder',
            'Test what the 3-hour reminder looks like',
            Icons.edit_calendar_rounded,
            AppTheme.info,
            () async {
              await NotificationService().testDailyLogReminder();
              if (context.mounted) _showInfo(context, 'Notification sent! (Only visible on installed Android/iOS app)');
            },
          ),
          const SizedBox(height: 8),
          _testCard(
            'Send Heat Alert',
            'Test what heat warning looks like at 36°C',
            Icons.local_fire_department_rounded,
            AppTheme.error,
            () async {
              await NotificationService().showHeatAlert(36.5, severity: 1);
              if (context.mounted) _showInfo(context, 'Heat alert sent! (Only visible on installed Android/iOS app)');
            },
          ),
        ],
      ),
    );
  }

  Widget _testCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.separator.withValues(alpha: 0.5)),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)]),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
          ])),
          const Icon(Icons.arrow_forward_rounded, size: 18, color: AppTheme.gray),
        ]),
      ),
    );
  }

  void _showInfo(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      ),
    );
  }
}
