import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';

class AuthService with ChangeNotifier {
  final _userPool = CognitoUserPool(
    AppConstants.userPoolId, 
    AppConstants.clientId
  );

  String? idToken;
  String? userId;
  String? userEmail;
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => idToken != null;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // LOGIN
  Future<String?> login(String email, String password) async {
    _setLoading(true);
    final cognitoUser = CognitoUser(email, _userPool);
    final authDetails = AuthenticationDetails(username: email, password: password);
    
    try {
      final session = await cognitoUser.authenticateUser(authDetails);
      idToken = session?.getIdToken().getJwtToken();
      userId = session?.getIdToken().getSub();
      userEmail = email;
      notifyListeners();
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

  // SIGN UP
  Future<String?> signUp(String email, String password, {String? name}) async {
    _setLoading(true);
    final userAttributes = [
      AttributeArg(name: 'email', value: email),
      if (name != null) AttributeArg(name: 'name', value: name),
    ];
    
    try {
      await _userPool.signUp(email, password, userAttributes: userAttributes);
      return null; // Success
    } on CognitoClientException catch (e) {
      return e.message ?? "Sign up failed";
    } catch (e) {
      debugPrint("Sign Up Error: $e");
      return "Sign up failed. Please try again.";
    } finally {
      _setLoading(false);
    }
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

  // LOGOUT
  void logout() {
    idToken = null;
    userId = null;
    userEmail = null;
    notifyListeners();
  }
}
