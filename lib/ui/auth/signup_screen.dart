import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../widgets/leaf_background.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {_nameController.dispose(); _emailController.dispose(); _passwordController.dispose(); _confirmPasswordController.dispose(); super.dispose(); }

  void _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthService>(context, listen: false);
    final email = _emailController.text.trim();
    final error = await auth.signUp(email, _passwordController.text, _nameController.text);
    if (mounted) {
      if (error == null){
        Navigator.push(context, MaterialPageRoute(builder: (_) => VerificationScreen(email: email)));
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppTheme.terracotta, behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    return Scaffold(body: LeafBackground(child: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 20),
        Align(alignment: Alignment.centerLeft, child: IconButton(onPressed: () => Navigator.pop(context),
          icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.arrow_back, color: AppTheme.leafGreen)))),
        const SizedBox(height: 20),
        Center(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: const Text('🌿', style: TextStyle(fontSize: 44)))),
        const SizedBox(height: 24),
        Text('Create Account', style: GoogleFonts.comfortaa(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.leafGreen), textAlign: TextAlign.center),
        const SizedBox(height: 36),
        TextFormField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Username',
            prefixIcon: Icon(Icons.person_outline,
              color: AppTheme.leafGreen.withValues(alpha:0.7),
            ),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
const SizedBox(height: 18),
        TextFormField(controller: _emailController, keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline, color: AppTheme.leafGreen.withValues(alpha:0.7))),
          validator: (v) { if (v == null || v.isEmpty || !v.contains('@')) return 'Please enter a valid email'; return null; }),
        const SizedBox(height: 18),
        TextFormField(controller: _passwordController, obscureText: _obscurePassword,
          decoration: InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline, color: AppTheme.leafGreen.withValues(alpha:0.7)),
            suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))),
          validator: (v) { if (v == null || v.length < 8) return 'Password must be at least 8 characters'; return null; }),
        const SizedBox(height: 18),
        TextFormField(controller: _confirmPasswordController, obscureText: _obscureConfirm,
          decoration: InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outline, color: AppTheme.leafGreen.withValues(alpha:0.7)),
            suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm))),
          validator: (v) { if (v != _passwordController.text) return 'Passwords do not match'; return null; }),
        const SizedBox(height: 32),
        SizedBox(height: 56, child: ElevatedButton(onPressed: auth.isLoading ? null : _handleSignup,
          child: auth.isLoading ? const CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))
            : Text('Create Account', style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.w600)))),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("Already have an account? ", style: GoogleFonts.quicksand(color: AppTheme.soilBrown.withValues(alpha:0.7))),
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Login', style: GoogleFonts.quicksand(color: AppTheme.terracotta, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 40),
      ]))))));
  }
}

class VerificationScreen extends StatefulWidget {
  final String email;
  const VerificationScreen({super.key, required this.email});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() { for (var c in _controllers) c.dispose(); for (var f in _focusNodes) f.dispose(); super.dispose(); }

  String get _code => _controllers.map((c) => c.text).join();

  void _handleVerify() async {
    if (_code.length != 6) return;
    final auth = Provider.of<AuthService>(context, listen: false);
    final error = await auth.confirmSignUp(widget.email, _code);
    if (mounted) {
      if (error == null) { Navigator.popUntil(context, (route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Account verified! Please login.'), backgroundColor: AppTheme.leafGreen));
      } else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppTheme.terracotta));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: LeafBackground(child: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 20),
        Align(alignment: Alignment.centerLeft, child: IconButton(onPressed: () => Navigator.pop(context),
          icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.arrow_back, color: AppTheme.leafGreen)))),
        const SizedBox(height: 40),
        Center(child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: const Icon(Icons.mark_email_read_outlined, size: 48, color: AppTheme.leafGreen))),
        const SizedBox(height: 28),
        Text('Verify Email', style: GoogleFonts.comfortaa(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.leafGreen), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text('Enter the 6-digit code sent to', style: GoogleFonts.quicksand(fontSize: 15, color: AppTheme.soilBrown.withValues(alpha:0.7)), textAlign: TextAlign.center),
        Text(widget.email, style: GoogleFonts.quicksand(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.leafGreen), textAlign: TextAlign.center),
        const SizedBox(height: 40),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(6, (i) => SizedBox(width: 48, height: 56,
          child: TextField(controller: _controllers[i], focusNode: _focusNodes[i], textAlign: TextAlign.center, keyboardType: TextInputType.number, maxLength: 1,
            style: GoogleFonts.quicksand(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.leafGreen),
            decoration: InputDecoration(counterText: '', contentPadding: EdgeInsets.zero),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) { if (v.isNotEmpty && i < 5) _focusNodes[i + 1].requestFocus(); if (v.isEmpty && i > 0) _focusNodes[i - 1].requestFocus(); if (_code.length == 6) _handleVerify(); })))),
        const SizedBox(height: 40),
        SizedBox(height: 56, child: ElevatedButton(onPressed: _handleVerify, child: Text('Verify Account', style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.w600)))),
        const SizedBox(height: 40),
      ])))));
  }
}