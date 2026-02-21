import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import 'reset_password_screen.dart';


class OtpVerifyScreen extends StatefulWidget {
  final String emailOrPhone;
  final bool isEmail;

  const OtpVerifyScreen({
    Key? key,
    required this.emailOrPhone,
    required this.isEmail,
  }) : super(key: key);

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}


class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _otpControllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer == 0) {
        timer.cancel();
      } else {
        if (mounted) setState(() => _resendTimer--);
      }
    });
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) {
      _showError('Please enter complete 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'emailOrPhone': widget.emailOrPhone,
          'otpCode': _otpCode,
          'otpType': 'PASSWORD_RESET',
        }),
      ).timeout(const Duration(seconds: 30));

      setState(() => _isLoading = false);

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              emailOrPhone: widget.emailOrPhone,
              otpCode: _otpCode,
            ),
          ),
        );
      } else {
        _showError(data['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Something went wrong. Please try again.');
    }
  }

  Future<void> _resendOtp() async {
    try {
      if (widget.isEmail) {
        // Email — body mein JSON
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/auth/forgot-password'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'email': widget.emailOrPhone}),
        );
      } else {
        // Phone — query param mein
        await http.post(
          Uri.parse(
              '${ApiConfig.baseUrl}/api/auth/send-phone-otp?phone=${widget.emailOrPhone}'),
        );
      }

      _startResendTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP resent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to resend OTP');
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
          'Verify OTP',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.verified_outlined,
                  size: 48, color: AppTheme.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'Enter Verification Code',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'OTP sent to\n${widget.emailOrPhone}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 36),

            // 6 OTP boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 48,
                  height: 56,
                  child: TextFormField(
                    controller: _otpControllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: AppTheme.primary, width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                      if (index == 5 && value.isNotEmpty) {
                        _verifyOtp();
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 36),

            // Verify Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
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
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Verify OTP',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Resend Timer
            _resendTimer > 0
                ? Text(
                    'Resend OTP in $_resendTimer seconds',
                    style: TextStyle(
                        fontSize: 14, color: AppTheme.textSecondary),
                  )
                : TextButton(
                    onPressed: _resendOtp,
                    child: Text(
                      'Resend OTP',
                      style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
