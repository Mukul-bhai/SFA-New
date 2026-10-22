import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/salesforce_auth_service.dart';
import '../services/salesforce_dynamic_service.dart';
import '../services/salesforce_sync_service.dart';

void showSalesforceSessionSheet(
  BuildContext context, {
  required SalesforceAuthService authService,
  SalesforceDynamicService? dynamicService,
  required SalesforceSyncService syncService,
  VoidCallback? onSessionUpdated,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SalesforceSessionSheet(
      authService: authService,
      dynamicService: dynamicService,
      syncService: syncService,
      onSessionUpdated: onSessionUpdated,
    ),
  );
}

class SalesforceSessionSheet extends StatefulWidget {
  final SalesforceAuthService authService;
  final SalesforceDynamicService? dynamicService;
  final SalesforceSyncService syncService;
  final VoidCallback? onSessionUpdated;

  const SalesforceSessionSheet({
    super.key,
    required this.authService,
    this.dynamicService,
    required this.syncService,
    this.onSessionUpdated,
  });

  @override
  State<SalesforceSessionSheet> createState() => _SalesforceSessionSheetState();
}

class _SalesforceSessionSheetState extends State<SalesforceSessionSheet> {
  late final TextEditingController _tokenController;
  late final TextEditingController _urlController;

  bool _isTesting = false;
  bool _isSaving = false;
  bool _isAutoRefreshing = false;
  bool _obscureToken = true;
  bool? _testSuccess;
  String? _testResultMessage;

  Future<void> _handleAutoRefresh() async {
    setState(() {
      _isAutoRefreshing = true;
      _testResultMessage = 'Fetching live access token from Salesforce CLI...';
    });

    final fresh = await SalesforceAuthService.autoRefreshToken(force: true);

    if (!mounted) return;
    setState(() {
      _isAutoRefreshing = false;
      if (fresh != null && fresh.isNotEmpty) {
        _tokenController.text = fresh;
        _testSuccess = true;
        _testResultMessage = 'Token auto-refreshed successfully from Salesforce CLI!';
      } else {
        _testSuccess = false;
        _testResultMessage = 'Auto-refresh bridge connection failed. Please ensure dev server is running on host.';
      }
    });

    if (fresh != null && fresh.isNotEmpty) {
      widget.dynamicService?.reloadSession();
      widget.syncService.reloadSession();
      widget.onSessionUpdated?.call();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Live token refreshed from Salesforce CLI! Never need to enter manually.')),
            ],
          ),
          backgroundColor: Color(0xFF16A34A),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: SalesforceAuthService.currentBearerToken);
    _urlController = TextEditingController(text: SalesforceAuthService.activeInstanceUrl);
    _runInitialPing();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _runInitialPing() async {
    setState(() => _isTesting = true);
    final res = await widget.authService.testConnection();
    if (!mounted) return;
    setState(() {
      _isTesting = false;
      _testSuccess = res['success'] == true;
      _testResultMessage = res['message'];
    });
  }

  Future<void> _handleTestConnection() async {
    final token = _tokenController.text.trim();
    final url = _urlController.text.trim();
    if (token.isEmpty) {
      setState(() {
        _testSuccess = false;
        _testResultMessage = 'Please enter or paste a valid Salesforce Access Token.';
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testSuccess = null;
      _testResultMessage = null;
    });

    final res = await widget.authService.testConnection(
      testToken: token,
      testUrl: url.isNotEmpty ? url : null,
    );

    if (!mounted) return;
    setState(() {
      _isTesting = false;
      _testSuccess = res['success'] == true;
      _testResultMessage = res['message'];
    });
  }

  Future<void> _handleSaveAndSync() async {
    final token = _tokenController.text.trim();
    final url = _urlController.text.trim();

    if (token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access token cannot be empty.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await widget.authService.updateSession(
        token: token,
        newInstanceUrl: url.isNotEmpty ? url : null,
      );

      widget.dynamicService?.reloadSession();
      widget.syncService.reloadSession();

      // Trigger dynamic refresh & outbox sync
      try {
        if (widget.dynamicService != null) {
          await widget.dynamicService!.refreshAll();
        }
        await widget.syncService.syncOutbox();
        await widget.syncService.fetchBootstrapData();
      } catch (_) {}

      if (!mounted) return;
      setState(() => _isSaving = false);

      widget.onSessionUpdated?.call();

      Navigator.pop(context);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Salesforce session updated! Live sync active.')),
            ],
          ),
          backgroundColor: Color(0xFF16A34A),
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving session: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      setState(() {
        _tokenController.text = data.text!.trim();
        _testSuccess = null;
        _testResultMessage = null;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token pasted from clipboard! Click "Test Connection" to verify.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0070D2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.cloud_sync, color: Color(0xFF0070D2), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Salesforce Live Session',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001E3C)),
                        ),
                        Text(
                          'Keep mobile app in sync with Salesforce org',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Live Status Badge Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testSuccess == true
                      ? Colors.green.shade50
                      : (_testSuccess == false ? Colors.red.shade50 : Colors.blue.shade50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _testSuccess == true
                        ? Colors.green.shade300
                        : (_testSuccess == false ? Colors.red.shade300 : Colors.blue.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testSuccess == true
                          ? Icons.check_circle
                          : (_testSuccess == false ? Icons.error_outline : Icons.sync),
                      color: _testSuccess == true
                          ? const Color(0xFF16A34A)
                          : (_testSuccess == false ? const Color(0xFFDC2626) : const Color(0xFF0070D2)),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isTesting
                                ? 'Testing Salesforce Connection...'
                                : (_testSuccess == true
                                    ? 'LIVE CONNECTED TO SALESFORCE'
                                    : (_testSuccess == false ? 'SESSION EXPIRED OR DISCONNECTED' : 'STATUS UNKNOWN')),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _testSuccess == true
                                  ? const Color(0xFF16A34A)
                                  : (_testSuccess == false ? const Color(0xFFDC2626) : const Color(0xFF0070D2)),
                            ),
                          ),
                          if (_testResultMessage != null)
                            Text(
                              _testResultMessage!,
                              style: TextStyle(
                                fontSize: 11,
                                color: _testSuccess == true ? Colors.green.shade800 : Colors.red.shade800,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Instance URL Field
              const Text(
                'Salesforce Instance URL',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.link, size: 20),
                  hintText: 'https://your-instance.my.salesforce.com',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 14),

              // Access Token Field
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bearer Access Token',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: _pasteFromClipboard,
                    icon: const Icon(Icons.content_paste, size: 16, color: Color(0xFF0070D2)),
                    label: const Text('Paste Token', style: TextStyle(fontSize: 12, color: Color(0xFF0070D2))),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _tokenController,
                obscureText: _obscureToken,
                maxLines: _obscureToken ? 1 : 4,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.key, size: 20),
                  hintText: '00Dg800000LROVB!AQEA...',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureToken ? Icons.visibility : Icons.visibility_off, size: 20),
                    onPressed: () => setState(() => _obscureToken = !_obscureToken),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 10),

              // Auto Refresh 1-Click Button & Info Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      onPressed: _isAutoRefreshing ? null : _handleAutoRefresh,
                      icon: _isAutoRefreshing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.bolt, size: 18, color: Colors.white),
                      label: Text(
                        _isAutoRefreshing ? 'Auto-Refreshing Token...' : '⚡ 1-Click Auto-Refresh Token',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.autorenew, size: 16, color: Color(0xFF15803D)),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Background Auto-Refresh Active: Expired tokens (401) refresh automatically from Salesforce CLI without manual intervention.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF15803D), height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: const BorderSide(color: Color(0xFF0070D2)),
                      ),
                      onPressed: _isTesting ? null : _handleTestConnection,
                      icon: _isTesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0070D2)),
                            )
                          : const Icon(Icons.network_check, size: 18, color: Color(0xFF0070D2)),
                      label: const Text(
                        'Test Ping',
                        style: TextStyle(color: Color(0xFF0070D2), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0070D2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                      ),
                      onPressed: _isSaving ? null : _handleSaveAndSync,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.cloud_done, size: 20),
                      label: Text(
                        _isSaving ? 'Syncing...' : 'Save & Sync Live',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
              if (isKeyboardOpen) const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
