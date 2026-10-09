import 'dart:async';
import 'package:flutter/material.dart';
import '../services/salesforce_auth_service.dart';
import '../services/salesforce_dynamic_service.dart';
import '../services/salesforce_sync_service.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  final SalesforceAuthService authService;
  final SalesforceSyncService syncService;
  final SalesforceDynamicService? dynamicService;

  const LoginScreen({
    super.key,
    required this.authService,
    required this.syncService,
    this.dynamicService,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'mukulfingertipplus.23defef3af87@agentforce.com');
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isPasswordMode = true;
  bool _isLoading = false;
  bool _otpSent = false;
  String? _debugOtp;
  String? _errorMessage;
  String? _successMessage;

  int _resendCountdown = 60;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _resendCountdown = 60);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleRequestOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your Salesforce registered email.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final res = await widget.authService.requestOtp(email);
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() {
        _otpSent = true;
        _debugOtp = res['debugOtp'];
        if (_debugOtp != null) {
          _otpController.text = _debugOtp!;
        }
        _successMessage = res['message'] ?? 'OTP successfully sent to your registered email!';
      });
      _startCountdown();
    } else {
      setState(() => _errorMessage = res['message'] ?? 'Unable to send OTP.');
    }
  }

  Future<void> _handleOfflineLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await widget.authService.loginOffline(email: _emailController.text.trim());
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      try {
        if (widget.dynamicService != null) {
          await widget.dynamicService!.refreshAll();
        }
        await widget.syncService.fetchBootstrapData();
      } catch (_) {}
      if (!mounted) return;
      _navigateToDashboard();
    }
  }

  Future<void> _handleVerifyOtp() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit OTP code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await widget.authService.verifyOtp(email, otp);
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      try {
        if (widget.dynamicService != null) {
          await widget.dynamicService!.refreshAll();
        }
        await widget.syncService.fetchBootstrapData();
      } catch (_) {}
      
      if (!mounted) return;
      final bool hasPassword = res['hasPassword'] ?? false;
      if (!hasPassword) {
        _promptSetPassword();
      } else {
        _navigateToDashboard();
      }
    } else {
      setState(() => _errorMessage = res['message'] ?? 'Invalid OTP code.');
    }
  }

  Future<void> _handlePasswordLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your registered email.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await widget.authService.loginWithPassword(email, password);
      setState(() => _isLoading = false);

      if (res['success'] == true) {
        try {
          if (widget.dynamicService != null) {
            await widget.dynamicService!.refreshAll();
          }
          await widget.syncService.fetchBootstrapData();
        } catch (_) {}
        if (!mounted) return;
        _navigateToDashboard();
      } else {
        setState(() => _errorMessage = res['message'] ?? 'Invalid login credentials.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      await _handleOfflineLogin();
    }
  }

  void _promptSetPassword() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.lock_reset, color: Color(0xFF0070D2)),
            SizedBox(width: 8),
            Text('Set App Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Would you like to generate or set a password so you can sign in directly next time without OTP?',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New App Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _navigateToDashboard();
            },
            child: const Text('Skip For Now'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0070D2),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newPass = _newPasswordController.text.trim();
              if (newPass.isNotEmpty) {
                await widget.authService.setPassword(_emailController.text.trim(), newPass);
              }
              if (ctx.mounted) Navigator.pop(ctx);
              _navigateToDashboard();
            },
            child: const Text('Save Password'),
          ),
        ],
      ),
    );
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainNavigationScreen(
          authService: widget.authService,
          syncService: widget.syncService,
          dynamicService: widget.dynamicService ?? SalesforceDynamicService(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001E3C),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header & Brand Logo
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0070D2).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.cloud_done, size: 48, color: Color(0xFF0070D2)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'Enterprise SFA Mobile',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF001E3C)),
                        ),
                      ),
                      const Center(
                        child: Text(
                          'Field Sales Executive Portal • FMCG / DMS',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Mode Switcher Tab
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _isPasswordMode = false;
                                  _errorMessage = null;
                                  _successMessage = null;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !_isPasswordMode ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: !_isPasswordMode
                                        ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Email OTP',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: !_isPasswordMode ? const Color(0xFF0070D2) : Colors.black54,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _isPasswordMode = true;
                                  _errorMessage = null;
                                  _successMessage = null;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _isPasswordMode ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _isPasswordMode
                                        ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Password',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: _isPasswordMode ? const Color(0xFF0070D2) : Colors.black54,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Email / Username Field
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Registered Salesforce Email / Username',
                          hintText: 'user@company.com',
                          prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF0070D2)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Message alerts
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.red.shade300),
                                  foregroundColor: Colors.red.shade800,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.offline_bolt, size: 16),
                                label: const Text('Continue in Offline / Field Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: _isLoading ? null : _handleOfflineLogin,
                              ),
                            ],
                          ),
                        ),

                      if (_successMessage != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_successMessage!, style: const TextStyle(color: Colors.green, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),

                      // OTP Mode Content
                      if (!_isPasswordMode) ...[
                        if (!_otpSent) ...[
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0070D2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            onPressed: _isLoading ? null : _handleRequestOtp,
                            child: _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Send Login OTP to Email', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0070D2),
                              side: const BorderSide(color: Color(0xFF0070D2)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isLoading ? null : _handleOfflineLogin,
                            icon: const Icon(Icons.wifi_off_rounded, size: 18),
                            label: const Text('Field / Offline Access (Mukul Yadav)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                        ] else ...[
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
                            decoration: InputDecoration(
                              labelText: 'Enter 6-Digit OTP',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.password, color: Color(0xFF0070D2)),
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_debugOtp != null)
                            Container(
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'ℹ️ Verified OTP Code: $_debugOtp',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(0xFF0070D2), fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0070D2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            onPressed: _isLoading ? null : _handleVerifyOtp,
                            child: _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Verify OTP & Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: TextButton(
                              onPressed: _resendCountdown > 0 ? null : _handleRequestOtp,
                              child: Text(
                                _resendCountdown > 0 ? 'Resend OTP in ${_resendCountdown}s' : 'Resend OTP',
                                style: TextStyle(
                                  color: _resendCountdown > 0 ? Colors.grey : const Color(0xFF0070D2),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: TextButton.icon(
                              onPressed: _isLoading ? null : _handleOfflineLogin,
                              icon: const Icon(Icons.offline_bolt_outlined, size: 16, color: Color(0xFF0070D2)),
                              label: const Text('Or Continue in Offline / Field Mode', style: TextStyle(fontSize: 13, color: Color(0xFF0070D2))),
                            ),
                          ),
                        ],
                      ],

                      // Password Mode Content
                      if (_isPasswordMode) ...[
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'App Password',
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0070D2)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0070D2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          onPressed: _isLoading ? null : _handlePasswordLogin,
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Sign In with Password', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0070D2),
                            side: const BorderSide(color: Color(0xFF0070D2)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isLoading ? null : _handleOfflineLogin,
                          icon: const Icon(Icons.wifi_off_rounded, size: 18),
                          label: const Text('Field / Offline Access (Mukul Yadav)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Info Footer
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.security, size: 16, color: Color(0xFF16A34A)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Single email identity mapped directly to Salesforce Standard User credentials.',
                                style: TextStyle(fontSize: 11, color: Color(0xFF15803D)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
