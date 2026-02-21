import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import 'otp_verify_screen.dart';


class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}


class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    super.dispose();
  }

  bool _isEmailInput(String value) => value.contains('@');

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final input = _emailOrPhoneController.text.trim();
      final isEmail = _isEmailInput(input);

      http.Response response;

      if (isEmail) {
        // Email — body mein JSON
        response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/auth/forgot-password'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'email': input}),
        ).timeout(const Duration(seconds: 30));
      } else {
        // Phone — query param mein
        response = await http.post(
          Uri.parse(
              '${ApiConfig.baseUrl}/api/auth/send-phone-otp?phone=$input'),
        ).timeout(const Duration(seconds: 30));
      }

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerifyScreen(
              emailOrPhone: input,
              isEmail: isEmail,
            ),
          ),
        );
      } else {
        final data = json.decode(response.body);
        _showError(data['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Something went wrong. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text(
          'Forgot Password',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                    Icons.lock_reset, size: 48, color: AppTheme.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'Reset Password',
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your email or phone number. We will send you a verification code.',
                style: TextStyle(
                    fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),

              // Email or Phone Field
              TextFormField(
                controller: _emailOrPhoneController,
                keyboardType: TextInputType.emailAddress,
                inputFormatters: [],
                decoration: InputDecoration(
                  labelText: 'Email or Phone Number',
                  hintText: 'example@email.com or 9876543210',
                  prefixIcon:
                      Icon(Icons.person_outline, color: AppTheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: AppTheme.primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: AppTheme.error, width: 1),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email or phone is required';
                  }
                  if (value.contains('@')) {
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Invalid email format';
                    }
                  } else {
                    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                      return 'Enter valid 10 digit phone number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Send OTP Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Send OTP',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
