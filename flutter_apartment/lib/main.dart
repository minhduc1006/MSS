import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'providers/auth_provider.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_activity_screen.dart';
import 'screens/apartment_screen.dart';
import 'screens/billing_screen.dart';
import 'screens/admin_leasing_screen.dart';
import 'screens/admin_operations_hub_screen.dart';
import 'screens/facilities_screen.dart';
import 'screens/login_screen.dart';
import 'screens/resident_account_screen.dart';
import 'screens/resident_bills_screen.dart';
import 'screens/resident_bookings_screen.dart';
import 'screens/resident_dashboard_screen.dart';
import 'screens/resident_list_screen.dart';
import 'screens/resident_support_screen.dart';
import 'screens/resident_security_screen.dart';
import 'screens/security_screen.dart';
import 'screens/staff_dashboard_screen.dart';
import 'screens/staff_facilities_screen.dart';
import 'screens/staff_list_screen.dart';
import 'screens/staff_roster_screen.dart';
import 'screens/staff_security_screen.dart';
import 'screens/staff_settings_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const SkylineHeightsApp());
}

class SkylineHeightsApp extends StatelessWidget {
  const SkylineHeightsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return MaterialApp(
            title: 'Skyline Heights',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appState.themeMode,
            locale: appState.locale,
            supportedLocales: const [
              Locale('en'),
              Locale('vi'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: '/login',
            routes: {
              '/login': (_) => const LoginScreen(),
              '/admin': (_) => const AdminDashboardScreen(),
              '/admin/activity': (_) => const AdminActivityScreen(),
              '/admin/residents': (_) => const ResidentListScreen(),
              '/admin/staff': (_) => const StaffListScreen(),
              '/admin/billing': (_) => const BillingScreen(),
              '/admin/facilities': (_) => const FacilitiesScreen(),
              '/admin/apartment': (_) => const ApartmentScreen(),
              '/admin/security': (_) => const SecurityScreen(),
              '/admin/leasing': (_) => const AdminLeasingScreen(),
              '/admin/ops': (_) => const AdminOperationsHubScreen(),
              '/resident': (_) => const ResidentDashboardScreen(),
              '/resident/bills': (_) => const ResidentBillsScreen(),
              '/resident/bookings': (_) => const ResidentBookingsScreen(),
              '/resident/security': (_) => const ResidentSecurityScreen(),
              '/resident/account': (_) => const ResidentAccountScreen(),
              '/resident/support': (_) => const ResidentSupportScreen(),
              '/staff': (_) => const StaffDashboardScreen(),
              '/staff/facilities': (_) => const StaffFacilitiesScreen(),
              '/staff/security': (_) => const StaffSecurityScreen(),
              '/staff/settings': (_) => const StaffSettingsScreen(),
              '/staff/roster': (_) => const StaffRosterScreen(),
            },
          );
        },
      ),
    );
  }
}
