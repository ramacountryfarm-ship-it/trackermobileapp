import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../services/notification_service.dart';
import '../../utils/formatters.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final _api = ApiClient();
  bool _loading = true;
  Map<String, dynamic> _stats = {};
  List<dynamic> _alerts = [];
  Map<String, dynamic>? _weather;
  List<dynamic> _todayLogs = [];
  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  // Suraram Colony, Hyderabad coordinates
  static const double _farmLat = 17.497;
  static const double _farmLon = 78.430;

  bool get _hasTodayLog => _todayLogs.isNotEmpty;
  double? get _currentTemp => (_weather?['current']?['temperature'] as num?)?.toDouble();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final r = await Future.wait([
        _api.get('/dashboard/stats'),
        _api.get('/dashboard/alerts'),
        _api.get('/analytics/weather', query: {'lat': _farmLat, 'lon': _farmLon}),
        _api.get('/daily-logs', query: {'startDate': todayStr, 'endDate': todayStr}),
      ]);
      _stats = r[0].data ?? {};
      _alerts = r[1].data ?? [];
      _weather = r[2].data is Map ? Map<String, dynamic>.from(r[2].data) : null;
      _todayLogs = r[3].data is List ? r[3].data : [];

      // Manage daily log reminders
      if (_hasTodayLog) {
        await NotificationService().cancelDailyLogReminders();
      } else {
        await NotificationService().scheduleDailyLogReminders();
      }

      // Heat alert if temp >= 35
      final temp = _currentTemp;
      if (temp != null && temp >= 35) {
        await NotificationService().showHeatAlert(temp, severity: temp >= 37 ? 2 : 1);
      }

      _animCtrl.forward(from: 0);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.black, strokeWidth: 2))
          : RefreshIndicator(
              color: AppTheme.black, onRefresh: _load,
              child: FadeTransition(
                opacity: _fadeIn,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 100),
                  children: [
                    // Header
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Hello, ${auth.username ?? "User"}',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                        const SizedBox(height: 2),
                        Text(Fmt.date(DateTime.now()), style: const TextStyle(fontSize: 13, color: AppTheme.gray)),
                      ])),
                      GestureDetector(
                        onTap: () => auth.logout(),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.separator.withValues(alpha: 0.5)),
                          ),
                          child: const Icon(Icons.logout_rounded, size: 18, color: AppTheme.gray),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Daily log reminder (only if not logged today)
                    if (!_hasTodayLog) _dailyLogReminder(),
                    if (!_hasTodayLog) const SizedBox(height: 12),

                    // Weather card
                    if (_weather != null) _weatherCard(),
                    if (_weather != null) const SizedBox(height: 16),

                    // Stats grid
                    Row(children: [
                      Expanded(child: _stat('Birds Alive', Fmt.number(_stats['totalBirdsAlive']), Icons.pets_rounded, const Color(0xFFFF6B6B))),
                      const SizedBox(width: 12),
                      Expanded(child: _stat('Eggs Today', Fmt.number(_stats['eggsToday']), Icons.egg_rounded, const Color(0xFFFFB84D))),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _stat('Feed Today', Fmt.kg(_stats['feedTodayKg']), Icons.grass_rounded, const Color(0xFF9B59B6))),
                      const SizedBox(width: 12),
                      Expanded(child: _stat('Egg Stock', Fmt.number(_stats['eggStock']), Icons.inventory_2_rounded, const Color(0xFF3498DB))),
                    ]),
                    const SizedBox(height: 20),

                    // Financial
                    _financialCard(),
                    const SizedBox(height: 20),

                    // Alerts
                    if (_alerts.isNotEmpty) ...[
                      Row(children: [
                        const Text('Alerts', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: Text('${_alerts.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.error)),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      ..._alerts.take(5).map(_alertCard),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color accent) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [accent.withValues(alpha: 0.15), accent.withValues(alpha: 0.05)]),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 19, color: accent),
        ),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.gray, fontWeight: FontWeight.w400)),
      ]),
    );
  }

  Widget _financialCard() {
    final profit = (_stats['profitThisMonth'] as num?)?.toDouble() ?? 0;
    final pos = profit >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: const Color(0xFF1A1A2E).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('This Month', style: TextStyle(color: Color(0xFF8A8FA0), fontSize: 13)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (pos ? AppTheme.success : AppTheme.error).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(pos ? 'Profit' : 'Loss',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: pos ? AppTheme.success : AppTheme.error)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(Fmt.currency(profit), style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5,
            color: pos ? AppTheme.success : AppTheme.error)),
        const SizedBox(height: 16),
        Container(height: 0.5, color: Colors.white.withValues(alpha: 0.08)),
        const SizedBox(height: 14),
        Row(children: [
          _finCol('Revenue', Fmt.currency(_stats['allTimeSales']), AppTheme.success),
          const SizedBox(width: 24),
          _finCol('Expenses', Fmt.currency(_stats['allTimeInvestments']), AppTheme.error),
        ]),
      ]),
    );
  }

  Widget _finCol(String label, String value, Color dot) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Color(0xFF8A8FA0), fontSize: 12)),
      ]),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _dailyLogReminder() {
    final hour = DateTime.now().hour;
    // Show reminder more prominently after 9am
    final urgent = hour >= 9;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/daily-log-form'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: urgent
              ? [const Color(0xFFFF6B35), const Color(0xFFF44336)]
              : [const Color(0xFF4A5568), const Color(0xFF2D3748)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: (urgent ? AppTheme.error : AppTheme.darkGray).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.edit_calendar_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(urgent ? 'Daily log pending!' : 'Remember daily log',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            const Text('Tap to add today\'s feed, eggs & deaths',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ])),
          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
        ]),
      ),
    );
  }

  Widget _weatherCard() {
    final current = _weather?['current'] as Map<String, dynamic>?;
    if (current == null) return const SizedBox.shrink();
    final temp = (current['temperature'] as num?)?.toDouble() ?? 0;
    final humidity = (current['humidity'] as num?)?.toInt() ?? 0;
    final wind = (current['windSpeed'] as num?)?.toDouble() ?? 0;

    // Heat alert logic
    String? heatAlert;
    Color heatColor = AppTheme.success;
    IconData heatIcon = Icons.wb_sunny_outlined;
    if (temp >= 37) {
      heatAlert = 'Critical heat! Extra water & cooling needed';
      heatColor = AppTheme.error;
      heatIcon = Icons.local_fire_department_rounded;
    } else if (temp >= 35) {
      heatAlert = 'Heat warning! Birds at stress risk';
      heatColor = AppTheme.warning;
      heatIcon = Icons.wb_sunny_rounded;
    } else if (temp >= 33) {
      heatAlert = 'Warm weather. Ensure ventilation';
      heatColor = AppTheme.info;
      heatIcon = Icons.thermostat_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: temp >= 35
            ? [const Color(0xFFFF9A44), const Color(0xFFFF6B35)]
            : [const Color(0xFF42A5F5), const Color(0xFF1976D2)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: (temp >= 35 ? const Color(0xFFFF6B35) : const Color(0xFF1976D2)).withValues(alpha: 0.25),
          blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          const Text('Suraram Colony, Hyderabad', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
          const Spacer(),
          Icon(heatIcon, color: Colors.white, size: 18),
        ]),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${temp.toStringAsFixed(1)}',
              style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w700, letterSpacing: -2, height: 1)),
          const Padding(
            padding: EdgeInsets.only(bottom: 10, left: 2),
            child: Text('°C', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
          ),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(children: [
              const Icon(Icons.water_drop_outlined, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text('$humidity%', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.air_rounded, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text('${wind.toStringAsFixed(0)} km/h', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
            ]),
          ]),
        ]),
        if (heatAlert != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: heatColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(heatAlert, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _alertCard(dynamic a) {
    final type = a['type'] ?? 'info';
    final color = type == 'critical' ? AppTheme.error : type == 'warning' ? AppTheme.warning : AppTheme.info;
    final icon = type == 'critical' ? Icons.error_rounded : type == 'warning' ? Icons.warning_rounded : Icons.info_rounded;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.separator.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a['title'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          if (a['message'] != null)
            Text(a['message'], style: const TextStyle(fontSize: 12, color: AppTheme.gray), maxLines: 2, overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }
}
