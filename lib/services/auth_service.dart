import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'timezone_service.dart';

class AuthService with ChangeNotifier {
  final _userPool = CognitoUserPool(
    AppConstants.userPoolId, 
    AppConstants.clientId
  );

  CognitoUser? _cognitoUser;
  CognitoUserSession? _session;
  String? idToken;
  String? userId;
  String? userEmail;
  String? userTimezone; // Add timezone field
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => idToken != null;
  final _storage = const FlutterSecureStorage();
  static const _keyEmail = 'cognito_email';
  static const _keyRefreshToken = 'cognito_refresh_token';
  static const _keyTimezone = 'user_timezone';
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  final TimezoneService _timezoneService = TimezoneService();

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Get detected or stored timezone
  Future<String?> getTimezone() async {
    // First check if we have it cached
    if (userTimezone != null) return userTimezone;
    
    // Check secure storage
    final stored = await _storage.read(key: _keyTimezone);
    if (stored != null) {
      userTimezone = stored;
      return stored;
    }
    
    // Detect from device
    final detected = await _timezoneService.getDeviceTimezone();
    if (detected != null) {
      await _storage.write(key: _keyTimezone, value: detected);
      userTimezone = detected;
    }
    
    return detected;
  }

  /// Update user's timezone
  Future<void> setTimezone(String timezone) async {
    await _storage.write(key: _keyTimezone, value: timezone);
    userTimezone = timezone;
    notifyListeners();
  }

  // LOGIN
  Future<String?> login(String email, String password) async {
    _setLoading(true);
    _cognitoUser = CognitoUser(email, _userPool);
    final authDetails = AuthenticationDetails(username: email, password: password);
    
    try {
      _session = await _cognitoUser!.authenticateUser(authDetails);
      idToken = _session?.getIdToken().getJwtToken();
      userId = _session?.getIdToken().getSub();
      userEmail = email;
      
      // Detect and store timezone on login
      await getTimezone();
      
      notifyListeners();
      await _storage.write(key: _keyEmail, value: email);
      await _storage.write(key: _keyRefreshToken, value: _session!.getRefreshToken()?.getToken());

      return null; // Success
    } on CognitoUserNewPasswordRequiredException {
      return "New password required";
    } on CognitoUserMfaRequiredException {
      return "MFA required";
    } on CognitoClientException catch (e) {
      return e.message ?? "Login failed";
    } catch (e) {
      debugPrint("Login Error: $e");
      return "Invalid email or password";
    } finally {
      _setLoading(false);
    }
  }

  // SIGN UP - Now returns timezone for API call
  Future<Map<String, dynamic>> signUpWithTimezone(String email, String password, String name) async {
    _setLoading(true);

    final userAttributes = [
      AttributeArg(name: 'email', value: email),
      AttributeArg(name: 'name', value: name),
    ];

    try {
      await _userPool.signUp(
        email,
        password,
        userAttributes: userAttributes,
      );
      
      // Detect timezone during signup
      final timezone = await _timezoneService.getDeviceTimezone();
      
      return {
        'success': true,
        'timezone': timezone,
      };
    } on CognitoClientException catch (e) {
      return {
        'success': false,
        'error': e.message ?? "Sign up failed",
      };
    } catch (e) {
      debugPrint("Sign Up Error: $e");
      return {
        'success': false,
        'error': "Sign up failed. Please try again.",
      };
    } finally {
      _setLoading(false);
    }
  }

  // Keep original signUp for backward compatibility
  Future<String?> signUp(String email, String password, String name) async {
    final result = await signUpWithTimezone(email, password, name);
    if (result['success'] == true) {
      return null;
    }
    return result['error'] as String?;
  }

  // CONFIRM SIGN UP
  Future<String?> confirmSignUp(String email, String code) async {
    _setLoading(true);
    final cognitoUser = CognitoUser(email, _userPool);
    
    try {
      bool confirmed = await cognitoUser.confirmRegistration(code);
      return confirmed ? null : "Confirmation failed";
    } on CognitoClientException catch (e) {
      return e.message ?? "Invalid code";
    } catch (e) {
      debugPrint("Confirmation Error: $e");
      return "Verification failed";
    } finally {
      _setLoading(false);
    }
  }

  // RESEND CONFIRMATION CODE
  Future<String?> resendConfirmationCode(String email) async {
    final cognitoUser = CognitoUser(email, _userPool);
    try {
      await cognitoUser.resendConfirmationCode();
      return null;
    } catch (e) {
      return "Failed to resend code";
    }
  }

  // CHANGE PASSWORD
  Future<String?> changePassword(String oldPassword, String newPassword) async {
    if (_cognitoUser == null) {
      return "Not logged in";
    }

    _setLoading(true);
    try {
      await _cognitoUser!.changePassword(oldPassword, newPassword);
      return null; // Success
    } on CognitoClientException catch (e) {
      return e.message ?? "Failed to change password";
    } catch (e) {
      debugPrint("Change Password Error: $e");
      return "Failed to change password";
    } finally {
      _setLoading(false);
    }
  }

  // FORGOT PASSWORD - INITIATE
  Future<String?> forgotPassword(String email) async {
    _setLoading(true);
    final cognitoUser = CognitoUser(email, _userPool);
    
    try {
      await cognitoUser.forgotPassword();
      return null; // Success - code sent
    } on CognitoClientException catch (e) {
      return e.message ?? "Failed to send reset code";
    } catch (e) {
      debugPrint("Forgot Password Error: $e");
      return "Failed to send reset code";
    } finally {
      _setLoading(false);
    }
  }

  // FORGOT PASSWORD - CONFIRM
  Future<String?> confirmForgotPassword(String email, String code, String newPassword) async {
    _setLoading(true);
    final cognitoUser = CognitoUser(email, _userPool);
    
    try {
      await cognitoUser.confirmPassword(code, newPassword);
      return null; // Success
    } on CognitoClientException catch (e) {
      return e.message ?? "Failed to reset password";
    } catch (e) {
      debugPrint("Confirm Password Error: $e");
      return "Failed to reset password";
    } finally {
      _setLoading(false);
    }
  }

  // GET USER ATTRIBUTES
  Future<Map<String, String>?> getUserAttributes() async {
    if (_cognitoUser == null) return null;
    
    try {
      final attributes = await _cognitoUser!.getUserAttributes();
      if (attributes == null) return null;
      
      final Map<String, String> result = {};
      for (var attr in attributes) {
        if (attr.name != null && attr.value != null) {
          result[attr.name!] = attr.value!;
        }
      }
      return result;
    } catch (e) {
      debugPrint("Get Attributes Error: $e");
      return null;
    }
  }

  // REFRESH SESSION
  Future<bool> refreshSession() async {
    if (_cognitoUser == null || _session == null) return false;
    
    try {
      _session = await _cognitoUser!.refreshSession(_session!.getRefreshToken()!);
      idToken = _session?.getIdToken().getJwtToken();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Refresh Session Error: $e");
      return false;
    }
  }
  
  // LOGOUT
  Future<void> logout() async {
    await _storage.deleteAll(); 
    
    _cognitoUser?.signOut();
    _cognitoUser = null;
    _session = null;
    idToken = null;
    userId = null;
    userEmail = null;
    userTimezone = null;
    
    notifyListeners();
  }

  // DELETE ACCOUNT
  Future<String?> deleteAccount() async {
    if (_cognitoUser == null) {
      return "Not logged in";
    }

    _setLoading(true);
    try {
      await _cognitoUser!.deleteUser();
      await logout();
      return null; // Success
    } on CognitoClientException catch (e) {
      return e.message ?? "Failed to delete account";
    } catch (e) {
      debugPrint("Delete Account Error: $e");
      return "Failed to delete account";
    } finally {
      _setLoading(false);
    }
  }

  Future<void> tryRestoreSession() async {
    if (_isInitialized) return;
    try {
      final email = await _storage.read(key: _keyEmail);
      final refreshTokenStr = await _storage.read(key: _keyRefreshToken);
      final storedTimezone = await _storage.read(key: _keyTimezone);
      
      if (email != null && refreshTokenStr != null) {
        _cognitoUser = CognitoUser(email, _userPool);
        _session = await _cognitoUser!.refreshSession(CognitoRefreshToken(refreshTokenStr));
        idToken = _session?.getIdToken().getJwtToken();
        userId = _session?.getIdToken().getSub();
        userEmail = email;
        userTimezone = storedTimezone;
        
        // If no stored timezone, detect it
        if (userTimezone == null) {
          await getTimezone();
        }
      }
    } catch (e) {
      await _storage.deleteAll();
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }
}