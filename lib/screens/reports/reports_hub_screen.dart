import 'package:flutter/material.dart';
import '../../config/theme.dart';

class _ReportCard {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  const _ReportCard(this.title, this.subtitle, this.icon, this.color, this.route);
}

const _cards = [
  _ReportCard('Monthly P&L', 'Revenue vs expenses, profit per month', Icons.bar_chart_rounded, Color(0xFF204D3A), '/reports/monthly-pl'),
  _ReportCard('Batch Performance', 'Eggs, feed efficiency (FCR), mortality', Icons.egg_alt_outlined, Color(0xFF007AFF), '/reports/batch-performance'),
  _ReportCard('Customer Report', 'Top buyers, pending payments, order count', Icons.people_alt_outlined, Color(0xFFAF52DE), '/reports/customer-report'),
  _ReportCard('Egg Production', 'Daily egg trend, breakage, deaths', Icons.show_chart_rounded, Color(0xFFF0B322), '/reports/egg-trend'),
  _ReportCard('Collection Report', 'Cash vs UPI vs Bank breakdown', Icons.payments_outlined, Color(0xFF34C759), '/collection-report'),
  _ReportCard('Order Sources', 'WhatsApp, Instagram, walk-in revenue', Icons.storefront_outlined, Color(0xFF25D366), '/order-source-report'),
];

class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceBg,
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: AppTheme.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _cards.length,
        itemBuilder: (context, i) {
          final c = _cards[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, c.route),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: c.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(c.icon, color: c.color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E))),
                    const SizedBox(height: 2),
                    Text(c.subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
                  ])),
                  Icon(Icons.chevron_right_rounded, color: c.color.withValues(alpha: 0.7)),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}
