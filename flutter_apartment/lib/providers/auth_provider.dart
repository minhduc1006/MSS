import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_models.dart';
import '../services/app_api_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '428248591926-urelh32dn2b6ngbilmufgopprnduglam.apps.googleusercontent.com',
  );
  static const _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '428248591926-urelh32dn2b6ngbilmufgopprnduglam.apps.googleusercontent.com',
  );

  UserRole _role = UserRole.resident;
  SessionUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleAuthSub;
  bool _googleInitialized = false;
  Future<void>? _googleInitFuture;

  UserRole get role => _role;
  SessionUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isGoogleInitialized => _googleInitialized;
  bool get supportsGoogleAuthenticate => _googleInitialized && _googleSignIn.supportsAuthenticate();

  AuthProvider() {
    unawaited(_ensureGoogleInitialized());
  }

  int get currentUserId {
    if (_currentUser != null) {
      return _currentUser!.id;
    }
    switch (_role) {
      case UserRole.admin:
        return 1;
      case UserRole.resident:
        return 2;
      case UserRole.staff:
        return 8;
    }
  }

  String get homeRoute {
    switch (_role) {
      case UserRole.admin:
        return '/admin';
      case UserRole.staff:
        return '/staff';
      case UserRole.resident:
        return '/resident';
    }
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) {
      return;
    }
    _googleInitFuture ??= _initializeGoogleSignIn();
    await _googleInitFuture;
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(
        clientId: kIsWeb && _googleClientId.isNotEmpty ? _googleClientId : null,
        serverClientId: _googleServerClientId.isEmpty ? null : _googleServerClientId,
      );
      _googleAuthSub ??= _googleSignIn.authenticationEvents.listen(
        _handleGoogleAuthEvent,
        onError: _handleGoogleAuthError,
      );
      _googleInitialized = true;
      notifyListeners();
      unawaited(_googleSignIn.attemptLightweightAuthentication());
    } on UnimplementedError {
      _googleInitialized = false;
    }
  }

  void _handleGoogleAuthEvent(GoogleSignInAuthenticationEvent event) {
    final GoogleSignInAccount? account = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    };
    if (account == null) {
      return;
    }
    unawaited(_hydrateGoogleSession(account));
  }

  void _handleGoogleAuthError(Object error) {
    _errorMessage = _mapGoogleLoginError(error);
    _isLoading = false;
    notifyListeners();
  }

  SessionUser _sessionUserFromGoogle(GoogleSignInAccount account) {
    final mappedRole = _roleForEmail(account.email, fallback: _role);
    return SessionUser(
      id: currentUserId,
      fullName: account.displayName ?? account.email.split('@').first,
      email: account.email,
      role: mappedRole,
      unitNumber: mappedRole == UserRole.resident ? '508' : null,
      tower: mappedRole == UserRole.resident ? 'Skyline Heights' : null,
      avatarUrl: account.photoUrl,
    );
  }

  Future<void> _hydrateGoogleSession(GoogleSignInAccount account) async {
    final mappedRole = _roleForEmail(account.email, fallback: _role);
    _role = mappedRole;
    try {
      _currentUser = await AppApiService.instance.fetchUserByEmail(account.email);
    } catch (_) {
      _currentUser = _sessionUserFromGoogle(account);
    }
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final resolvedRole = _roleForEmail(email, fallback: _role);
      final user = await AppApiService.instance.login(email: email, password: password, role: resolvedRole);
      _currentUser = user;
      _role = user.role;
      return true;
    } catch (error) {
      _errorMessage = _mapLoginError(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _ensureGoogleInitialized();
      if (!_googleSignIn.supportsAuthenticate()) {
        _errorMessage = 'Google Sign-In needs the web Google button or mobile OAuth setup.';
        return false;
      }
      final account = await _googleSignIn.authenticate();
      await _hydrateGoogleSession(account);
      return true;
    } catch (error) {
      _errorMessage = _mapGoogleLoginError(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout(BuildContext context) {
    unawaited(_googleSignIn.signOut());
    _currentUser = null;
    _errorMessage = null;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    notifyListeners();
  }

  UserRole _roleForEmail(String email, {required UserRole fallback}) {
    final normalized = email.trim().toLowerCase();
    if (normalized.endsWith('@fpt.edu.vn')) {
      return UserRole.admin;
    }
    if (normalized == 'ducdayne04@gmail.com') {
      return UserRole.resident;
    }
    if (normalized == 'minhduc10604@gmail.com') {
      return UserRole.staff;
    }
    return fallback;
  }

  String _mapLoginError(Object error) {
    final normalized = _normalizedError(error);
    final statusCode = error is ApiException ? error.statusCode : null;

    if (statusCode == 401 ||
        normalized.contains('invalid credentials') ||
        normalized.contains('unauthorized')) {
      return 'Tài khoản hoặc mật khẩu không đúng.';
    }
    if (statusCode == 403 ||
        normalized.contains('access denied') ||
        normalized.contains('forbidden') ||
        normalized.contains('permission')) {
      return 'Tài khoản không có quyền truy cập vào khu vực này.';
    }
    if (normalized.contains('unable to reach backend') ||
        normalized.contains('network') ||
        normalized.contains('timeout')) {
      return 'Không thể kết nối tới hệ thống đăng nhập. Vui lòng thử lại.';
    }
    return 'Không thể đăng nhập lúc này. Vui lòng thử lại.';
  }

  String _mapGoogleLoginError(Object error) {
    final normalized = _normalizedError(error);
    if (normalized.contains('cancel') || normalized.contains('canceled')) {
      return 'Bạn đã hủy đăng nhập Google.';
    }
    if (normalized.contains('needs the web google button') ||
        normalized.contains('oauth setup') ||
        normalized.contains('unsupported')) {
      return 'Đăng nhập Google hiện chưa được cấu hình trên thiết bị này.';
    }
    return 'Không thể đăng nhập bằng Google lúc này.';
  }

  String _normalizedError(Object error) =>
      error.toString().replaceFirst('Exception: ', '').trim().toLowerCase();

  @override
  void dispose() {
    _googleAuthSub?.cancel();
    super.dispose();
  }
}
