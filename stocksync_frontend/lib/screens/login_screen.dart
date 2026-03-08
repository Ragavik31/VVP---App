import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  
  // For Change Password
  final _oldPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSubmitting = false;
  bool _isChangePasswordMode = false;
  bool _obscurePassword = true;
  bool _obscureOldPassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _oldPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      await auth.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: const Color(0xFFEF233C)),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitChangePassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("New password and confirm password do not match"), backgroundColor: Color(0xFFEF233C)),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      await auth.changePassword(
        _usernameController.text.trim(),
        _oldPasswordController.text.trim(),
        _passwordController.text.trim(),
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password changed successfully! Please login."), backgroundColor: Colors.green),
      );
      
      setState(() {
        _isChangePasswordMode = false;
        _passwordController.clear();
        _oldPasswordController.clear();
        _confirmPasswordController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: const Color(0xFFEF233C)),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            height: size.height * 0.45,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4361EE), Color(0xFF3A0CA3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Decorative circles
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            top: 60,
            right: 40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4CC9F0).withOpacity(0.25),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        // VVP Logo
                        Container(
                          width: 200,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Venkateswara Vaccine Pharma',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Wholesale Vaccine Distribution',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.75),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4361EE).withOpacity(0.12),
                                blurRadius: 40,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(28),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _isChangePasswordMode ? 'Change Password' : 'Welcome back',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0D1B2A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isChangePasswordMode ? 'Enter your details below' : 'Sign in to continue',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7A9D),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Username / Code
                                _buildLabel('Username / Client Code'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _usernameController,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. admin or WP001',
                                    prefixIcon: Icon(Icons.person_outline, color: Color(0xFF4361EE)),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty) ? 'Username / Code required' : null,
                                ),
                                const SizedBox(height: 16),

                                if (_isChangePasswordMode) ...[
                                  // Old Password
                                  _buildLabel('Current Password'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _oldPasswordController,
                                    obscureText: _obscureOldPassword,
                                    decoration: InputDecoration(
                                      hintText: 'Enter current password',
                                      prefixIcon: const Icon(Icons.lock_clock_outlined, color: Color(0xFF4361EE)),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureOldPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                          color: const Color(0xFF6B7A9D),
                                        ),
                                        onPressed: () => setState(() => _obscureOldPassword = !_obscureOldPassword),
                                      ),
                                    ),
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Old Password required' : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // New Password
                                  _buildLabel('New Password'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    decoration: InputDecoration(
                                      hintText: 'Enter new password',
                                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF4361EE)),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                          color: const Color(0xFF6B7A9D),
                                        ),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                    ),
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'New Password required' : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // Confirm New Password
                                  _buildLabel('Confirm New Password'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: _obscureConfirmPassword,
                                    decoration: InputDecoration(
                                      hintText: 'Confirm new password',
                                      prefixIcon: const Icon(Icons.lock_reset_outlined, color: Color(0xFF4361EE)),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                          color: const Color(0xFF6B7A9D),
                                        ),
                                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                      ),
                                    ),
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Confirm Password required' : null,
                                  ),
                                ] else ...[
                                  // Password (Login)
                                  _buildLabel('Password'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    decoration: InputDecoration(
                                      hintText: 'Enter password',
                                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF4361EE)),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                          color: const Color(0xFF6B7A9D),
                                        ),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                    ),
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Password required' : null,
                                  ),
                                ],
                                
                                const SizedBox(height: 28),

                                SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _isSubmitting ? null : (_isChangePasswordMode ? _submitChangePassword : _submitLogin),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4361EE),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: _isSubmitting
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                                color: Colors.white, strokeWidth: 2.5))
                                        : Text(
                                            _isChangePasswordMode ? 'Change Password' : 'Sign In',
                                            style: const TextStyle(
                                                fontSize: 16, fontWeight: FontWeight.w700),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Toggle Mode Button
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isChangePasswordMode = !_isChangePasswordMode;
                                      _passwordController.clear();
                                      _oldPasswordController.clear();
                                      _confirmPasswordController.clear();
                                    });
                                  },
                                  child: Text(
                                    _isChangePasswordMode 
                                        ? 'Back to Login' 
                                        : 'Change Password?',
                                    style: const TextStyle(
                                      color: Color(0xFF4361EE),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          '© 2025 Venkateswara Vaccine Pharma. All rights reserved.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: Color(0xFF0D1B2A),
      ),
    );
  }
}
