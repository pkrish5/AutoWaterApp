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

  // 1. LOGIN
  Future<bool> login(String email, String password) async {
    final cognitoUser = CognitoUser(email, _userPool);
    final authDetails = AuthenticationDetails(username: email, password: password);
    try {
      final session = await cognitoUser.authenticateUser(authDetails);
      idToken = session?.getIdToken().getJwtToken();
      userId = session?.getIdToken().getSub();
      notifyListeners(); 
      return true;
    } catch (e) {
      debugPrint("Login Error: $e");
      return false;
    }
  }

  // 2. SIGN UP
  Future<bool> signUp(String email, String password) async {
    final userAttributes = [AttributeArg(name: 'email', value: email)];
    try {
      await _userPool.signUp(email, password, userAttributes: userAttributes);
      return true;
    } catch (e) {
      debugPrint("Sign Up Error: $e");
      return false;
    }
  }

  // 3. CONFIRM SIGN UP
  Future<bool> confirmSignUp(String email, String code) async {
    final cognitoUser = CognitoUser(email, _userPool);
    try {
      return await cognitoUser.confirmRegistration(code);
    } catch (e) {
      debugPrint("Confirmation Error: $e");
      return false;
    }
  }
}