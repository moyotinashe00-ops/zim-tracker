import 'package:flutter/material.dart';
import 'package:zim_tracker/services/auth_service.dart';
import 'package:zim_tracker/theme/volt_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLogin = true;
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    dynamic result;
    if (_isLogin) {
      result = await _authService.signIn(email, password);
    } else {
      result = await _authService.signUp(email, password);
    }

    if (result == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: VoltTheme.neonRed,
          content: Text('AUTHENTICATION FAILURE: CHECK CREDENTIALS', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoltTheme.obsidian,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Text(
                  'VOLT',
                  style: VoltTheme.dataStyle.copyWith(letterSpacing: 8, fontSize: 24, color: Colors.white),
                ),
                Text(
                  'GRID INTELLIGENCE SYSTEM',
                  style: VoltTheme.dataStyle.copyWith(fontSize: 10, color: VoltTheme.cyberBlue),
                ),
                const SizedBox(height: 60),
                Text(
                  _isLogin ? 'ACCESS\nREQUIRED' : 'INITIALIZE\nACCOUNT',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    height: 0.9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isLogin ? 'Enter your credentials to connect to the national grid.' : 'Register to receive real-time outage notifications.',
                  style: TextStyle(color: VoltTheme.textMuted, fontSize: 14),
                ),
                const SizedBox(height: 50),
                _buildTextField(
                  controller: _emailController,
                  label: 'IDENTITY (EMAIL)',
                  hint: 'protocol@grid.zim',
                  icon: LucideIcons.user,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: _passwordController,
                  label: 'ACCESS KEY (PASSWORD)',
                  hint: '••••••••',
                  icon: LucideIcons.key,
                  isPassword: true,
                ),
                const SizedBox(height: 50),
                _buildSubmitButton(),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin ? "CREATE NEW NODE (SIGN UP)" : "EXISTING NODE? (LOGIN)",
                      style: VoltTheme.dataStyle.copyWith(fontSize: 10, color: VoltTheme.cyberBlue),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: VoltTheme.dataStyle.copyWith(fontSize: 10, color: VoltTheme.textMuted),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: VoltTheme.glassDecoration,
          child: TextFormField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: keyboardType,
            style: VoltTheme.dataStyle.copyWith(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: VoltTheme.textDim, fontSize: 14),
              prefixIcon: Icon(icon, color: VoltTheme.cyberBlue, size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'REQUIRED';
              if (!isPassword && !value.contains('@')) return 'INVALID EMAIL';
              if (isPassword && value.length < 6) return 'MIN 6 CHARS';
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: VoltTheme.cyberBlue,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            : Text(
                _isLogin ? 'ESTABLISH CONNECTION' : 'INITIALIZE NODE',
                style: VoltTheme.dataStyle.copyWith(fontWeight: FontWeight.w900, color: Colors.black),
              ),
      ),
    );
  }
}
