import 'package:flutter/material.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';

class AppRoutes {
  static const login = '/login';
  static const dashboard = '/dashboard';

  static final routes = <String, WidgetBuilder>{
    login: (_) => const LoginScreen(),
    dashboard: (_) => const DashboardScreen(),
  };
}