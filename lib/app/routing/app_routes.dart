import 'package:portugal_guide/app/routing_guards/auth_guard.dart';

abstract class AppRoutes {
  
  // Base Routes
  static const String initial = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String admin = '/admin';
  static const String sales = '/sales';
  static const String salesProfile = '/sales/profile';
  static const String accessDenied = '/access-denied';
  
  // Nested Routes (if needed)
  static const String adminDashboard = '$admin/dashboard';
  static const String adminSettings = '$admin/settings';
  
  // Route Groups (for organization)
  static final adminRoutes = [admin, adminDashboard, adminSettings];
  static final salesRoutes = [sales, salesProfile];
  
  // Helper methods
  static String getSalesProfilePath(String userId) => '$salesProfile/$userId';
  
  // Basic Test for Route Guards mapping
  static final basicAuthGuardGroupsTest = {
    admin: [AuthGuard()],
    salesProfile: [AuthGuard()],
  };

  static final ownerGuardGroups = {
    //TODO --> CREATE NEW GROUPS AND THE SPECIFIC GUARD CODE FOR THEY
  };

}