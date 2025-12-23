import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class VerificationScreen extends StatelessWidget {
  final String email;
  final _codeController = TextEditingController();

  VerificationScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Email")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text("Enter the code sent to $email"),
            TextField(controller: _codeController, decoration: const InputDecoration(labelText: "Verification Code")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final auth = Provider.of<AuthService>(context, listen: false);
                bool success = await auth.confirmSignUp(email, _codeController.text);
                if (success && context.mounted) {
                  Navigator.pop(context); // Go back to login
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Confirmed! You can now login.")));
                }
              }, 
              child: const Text("Verify Account")
            ),
          ],
        ),
      ),
    );
  }
}