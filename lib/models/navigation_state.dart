import 'package:flutter/foundation.dart';

class NavigationState extends ChangeNotifier {
  // Private fields
  String _currentRoute = '/';
  List<String> _routeHistory = [];
  bool _isNavigating = false;
  Map<String, dynamic> _routeArguments = {};

  // Getters
  String get currentRoute => _currentRoute;
  List<String> get routeHistory => List.unmodifiable(_routeHistory);
  bool get isNavigating => _isNavigating;
  Map<String, dynamic> get routeArguments => Map.unmodifiable(_routeArguments);
  bool get canGoBack => _routeHistory.length > 1;

  // Navigation methods
  void navigateTo(String route, {Map<String, dynamic>? arguments}) {
    if (_currentRoute != route) {
      _routeHistory.add(_currentRoute);
      _currentRoute = route;
      _routeArguments = arguments ?? {};
      _notifyListeners();
    }
  }

  void navigateToReplacement(String route, {Map<String, dynamic>? arguments}) {
    if (_routeHistory.isNotEmpty) {
      _routeHistory.removeLast();
    }
    _currentRoute = route;
    _routeArguments = arguments ?? {};
    _notifyListeners();
  }

  void navigateToAndClear(String route, {Map<String, dynamic>? arguments}) {
    _routeHistory.clear();
    _routeHistory.add('/');
    _currentRoute = route;
    _routeArguments = arguments ?? {};
    _notifyListeners();
  }

  bool canGoBackTo(String route) {
    return _routeHistory.contains(route);
  }

  void goBack() {
    if (_routeHistory.isNotEmpty) {
      _currentRoute = _routeHistory.removeLast();
      _routeArguments.clear();
      _notifyListeners();
    }
  }

  void goBackTo(String route) {
    final routeIndex = _routeHistory.lastIndexOf(route);
    if (routeIndex != -1) {
      _routeHistory = _routeHistory.sublist(0, routeIndex + 1);
      _currentRoute = route;
      _routeArguments.clear();
      _notifyListeners();
    }
  }

  void clearHistory() {
    _routeHistory.clear();
    _routeHistory.add('/');
    _notifyListeners();
  }

  // Route-specific methods
  bool get isOnSplashScreen => _currentRoute == '/';
  bool get isOnLoginScreen => _currentRoute == '/login';
  bool get isOnOwnerDashboard => _currentRoute == '/ownerDashboard';
  bool get isOnRepairmanDashboard => _currentRoute == '/repairmanDashboard';

  // Navigation state management
  void setNavigating(bool navigating) {
    _isNavigating = navigating;
    _notifyListeners();
  }

  // Route arguments management
  T? getArgument<T>(String key) {
    return _routeArguments[key] as T?;
  }

  void setArguments(Map<String, dynamic> arguments) {
    _routeArguments = Map.from(arguments);
    _notifyListeners();
  }

  void clearArguments() {
    _routeArguments.clear();
    _notifyListeners();
  }

  // Route validation
  bool isValidRoute(String route) {
    const validRoutes = [
      '/',
      '/login',
      '/ownerDashboard',
      '/repairmanDashboard',
    ];
    return validRoutes.contains(route);
  }

  // Route analytics (for future use)
  List<String> getRecentRoutes({int count = 5}) {
    if (count <= 0) return [];
    final startIndex = _routeHistory.length - count;
    final endIndex = _routeHistory.length;
    return _routeHistory.sublist(
      startIndex < 0 ? 0 : startIndex,
      endIndex,
    );
  }

  // Private method to notify listeners
  void _notifyListeners() {
    notifyListeners();
  }

  // Dispose method for cleanup
  @override
  void dispose() {
    _routeHistory.clear();
    _routeArguments.clear();
    super.dispose();
  }
}
