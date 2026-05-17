import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:firebase_core/firebase_core.dart'; // Re-enable with google-services.json
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/livestock_provider.dart';
import 'services/notification_service.dart';
import 'services/fcm_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/batches/batch_form_screen.dart';
import 'screens/daily_log/daily_log_form_screen.dart';
import 'screens/sales/sale_list_screen.dart';
import 'screens/sales/sale_form_screen.dart';
import 'screens/investments/investment_list_screen.dart';
import 'screens/investments/investment_form_screen.dart';
import 'screens/vaccination/vaccination_list_screen.dart';
import 'screens/vaccination/vaccination_form_screen.dart';
import 'screens/vendors/vendor_list_screen.dart';
import 'screens/vendors/vendor_form_screen.dart';
import 'screens/locations/location_list_screen.dart';
import 'screens/locations/location_form_screen.dart';
import 'screens/bird_breeds/breed_list_screen.dart';
import 'screens/bird_breeds/breed_form_screen.dart';
import 'screens/performance/performance_screen.dart';
import 'screens/analytics/analytics_screen.dart';
import 'screens/feed/feed_screen.dart';
import 'screens/feed/commercial_feed_form.dart';
import 'screens/feed/own_mix_form.dart';
import 'screens/medicine/medicine_list_screen.dart';
import 'screens/medicine/medicine_form_screen.dart';
import 'screens/customers/customer_list_screen.dart';
import 'screens/customers/customer_form_screen.dart';
import 'screens/egg_trading/egg_trading_screen.dart';
import 'screens/egg_trading/farmer_form_screen.dart';
import 'screens/egg_trading/procurement_form_screen.dart';
import 'screens/egg_trading/resale_form_screen.dart';
import 'screens/egg_trading/wastage_form_screen.dart';
import 'screens/reports/collection_report_screen.dart';
import 'screens/reports/order_source_report_screen.dart';
import 'screens/reports/reports_hub_screen.dart';
import 'screens/reports/monthly_pl_screen.dart';
import 'screens/reports/batch_performance_screen.dart';
import 'screens/reports/customer_report_screen.dart';
import 'screens/reports/egg_trend_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(); // Re-enable with google-services.json
  await NotificationService().init();
  await FcmService().init();
  runApp(const RCFTrackerApp());
}

class RCFTrackerApp extends StatelessWidget {
  const RCFTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuth()),
        ChangeNotifierProvider(create: (_) => LivestockProvider()),
      ],
      child: MaterialApp(
        title: 'RCF FarmLog',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        navigatorKey: navigatorKey,
        home: const AuthGate(),
        routes: {
          '/batch-form': (_) => const BatchFormScreen(),
          '/daily-log-form': (_) => const DailyLogFormScreen(),
          '/sales': (_) => const SaleListScreen(),
          '/sale-form': (_) => const SaleFormScreen(),
          '/investments': (_) => const InvestmentListScreen(),
          '/investment-form': (_) => const InvestmentFormScreen(),
          '/vaccination': (_) => const VaccinationListScreen(),
          '/vaccination-form': (_) => const VaccinationFormScreen(),
          '/vendors': (_) => const VendorListScreen(),
          '/vendor-form': (_) => const VendorFormScreen(),
          '/locations': (_) => const LocationListScreen(),
          '/location-form': (_) => const LocationFormScreen(),
          '/bird-breeds': (_) => const BreedListScreen(),
          '/breed-form': (_) => const BreedFormScreen(),
          '/performance': (_) => const PerformanceScreen(),
          '/analytics': (_) => const AnalyticsScreen(),
          '/feeds': (_) => const FeedScreen(),
          '/commercial-feed-form': (_) => const CommercialFeedForm(),
          '/own-mix-form': (_) => const OwnMixForm(),
          '/medicines': (_) => const MedicineListScreen(),
          '/medicine-form': (_) => const MedicineFormScreen(),
          '/customers': (_) => const CustomerListScreen(),
          '/customer-form': (_) => const CustomerFormScreen(),
          '/egg-trading': (_) => const EggTradingScreen(),
          '/farmer-form': (_) => const FarmerFormScreen(),
          '/procurement-form': (_) => const ProcurementFormScreen(),
          '/resale-form': (_) => const ResaleFormScreen(),
          '/wastage-form': (_) => const WastageFormScreen(),
          '/collection-report': (_) => const CollectionReportScreen(),
          '/order-source-report': (_) => const OrderSourceReportScreen(),
          '/reports': (_) => const ReportsHubScreen(),
          '/reports/monthly-pl': (_) => const MonthlyPLScreen(),
          '/reports/batch-performance': (_) => const BatchPerformanceScreen(),
          '/reports/customer-report': (_) => const CustomerReportScreen(),
          '/reports/egg-trend': (_) => const EggTrendScreen(),
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.black)),
      );
    }

    return auth.isLoggedIn ? const MainShell() : const LoginScreen();
  }
}
