import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/salesforce_auth_service.dart';
import '../services/salesforce_dynamic_service.dart';
import '../services/salesforce_sync_service.dart';
import '../widgets/salesforce_session_sheet.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final SalesforceAuthService authService;
  final SalesforceSyncService syncService;
  final SalesforceDynamicService? dynamicService;

  const ProfileScreen({
    super.key,
    required this.authService,
    required this.syncService,
    this.dynamicService,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSyncing = false;
  bool _isCheckingConnection = false;
  bool? _isConnectedLive;

  @override
  void initState() {
    super.initState();
    _checkLiveConnection();
  }

  Future<void> _checkLiveConnection() async {
    setState(() => _isCheckingConnection = true);
    final res = await widget.authService.testConnection();
    if (!mounted) return;
    setState(() {
      _isCheckingConnection = false;
      _isConnectedLive = res['success'] == true;
    });
  }

  Future<void> _handleForceSync() async {
    setState(() => _isSyncing = true);
    await widget.syncService.syncOutbox();
    await widget.syncService.fetchBootstrapData();
    if (widget.dynamicService != null) {
      await widget.dynamicService!.refreshAll();
    }
    await _checkLiveConnection();
    setState(() => _isSyncing = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isConnectedLive == true
            ? 'All outbox records synced successfully with Salesforce Core Cloud!'
            : 'Synced locally. Note: Salesforce session expired, please update token.'),
        backgroundColor: _isConnectedLive == true ? const Color(0xFF16A34A) : Colors.orange.shade800,
      ),
    );
  }

  void _openSessionSheet() {
    showSalesforceSessionSheet(
      context,
      authService: widget.authService,
      dynamicService: widget.dynamicService,
      syncService: widget.syncService,
      onSessionUpdated: () {
        setState(() {});
        _checkLiveConnection();
      },
    );
  }

  void _showChangePasswordDialog() {
    final newPassCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change App Password', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set a new permanent app password for password-based logins:',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0070D2),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newPass = newPassCtrl.text.trim();
              if (newPass.isNotEmpty) {
                final email = widget.authService.currentUser?.email ?? '';
                final res = await widget.authService.setPassword(email, newPass);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res['message'] ?? 'Password updated')),
                  );
                }
              }
            },
            child: const Text('Save Password'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out from the SFA Mobile app?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    await widget.authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          authService: widget.authService,
          syncService: widget.syncService,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.currentUser;
    final outbox = widget.syncService.outbox;
    final queuedCount = outbox.where((o) => o.syncStatus == 'QUEUED').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Executive Profile & Sync'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Executive Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFF0070D2),
                      child: Text(
                        (user?.name.isNotEmpty == true ? user!.name[0] : 'S'),
                        style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.name ?? 'Field Executive', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(user?.email ?? 'user@company.com', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              user?.territoryName.isNotEmpty == true ? user!.territoryName : 'Mumbai Territory',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0070D2)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Connection & Sync Engine Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Salesforce Offline Sync Engine', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        GestureDetector(
                          onTap: _checkLiveConnection,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _isConnectedLive == true
                                  ? Colors.green.shade50
                                  : (_isConnectedLive == false ? Colors.red.shade50 : Colors.blue.shade50),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isConnectedLive == true
                                    ? Colors.green.shade200
                                    : (_isConnectedLive == false ? Colors.red.shade200 : Colors.blue.shade200),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isConnectedLive == true
                                      ? Icons.cloud_done
                                      : (_isConnectedLive == false ? Icons.cloud_off : Icons.sync),
                                  size: 14,
                                  color: _isConnectedLive == true
                                      ? const Color(0xFF16A34A)
                                      : (_isConnectedLive == false ? const Color(0xFFDC2626) : const Color(0xFF0070D2)),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isCheckingConnection
                                      ? 'Checking...'
                                      : (_isConnectedLive == true ? 'Connected' : 'Token Expired'),
                                  style: TextStyle(
                                    color: _isConnectedLive == true
                                        ? const Color(0xFF16A34A)
                                        : (_isConnectedLive == false ? const Color(0xFFDC2626) : const Color(0xFF0070D2)),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Instance: ${SalesforceAuthService.activeInstanceUrl.replaceAll('https://', '')}',
                        style: const TextStyle(fontSize: 11, color: Colors.black54)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$queuedCount Queued', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const Text('Pending Outbox', style: TextStyle(fontSize: 11, color: Colors.black54)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0070D2),
                              side: const BorderSide(color: Color(0xFF0070D2)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _openSessionSheet,
                            icon: const Icon(Icons.key, size: 16),
                            label: const Text('Session Token', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0070D2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _isSyncing ? null : _handleForceSync,
                            icon: _isSyncing
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.sync, size: 16),
                            label: const Text('Force Sync', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Account Security & Actions
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.cloud_sync, color: Color(0xFF0070D2)),
                    title: const Text('Salesforce Session & Access Token'),
                    subtitle: Text(_isConnectedLive == true
                        ? 'Live connected • Changes sync to Salesforce'
                        : 'Session expired • Tap to update access token'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openSessionSheet,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.key, color: Color(0xFF0070D2)),
                    title: const Text('Set / Change App Password'),
                    subtitle: const Text('Manage your direct password credentials'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showChangePasswordDialog,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: Colors.grey),
                    title: const Text('App Version & Architecture'),
                    subtitle: const Text('v1.0.0 • Salesforce Apex REST Connected'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Outbox Orders History
            const Text('Outbox Orders & Transactions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF001E3C))),
            const SizedBox(height: 8),

            if (outbox.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const Text('No orders in outbox. Orders placed will appear here.', style: TextStyle(color: Colors.black54)),
              )
            else
              ...outbox.map((order) {
                final isSynced = order.syncStatus == 'SYNCED';
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 10),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSynced ? Colors.green.shade50 : Colors.amber.shade50,
                            child: Icon(isSynced ? Icons.cloud_done : Icons.cloud_upload, color: isSynced ? const Color(0xFF16A34A) : Colors.amber.shade800),
                          ),
                          title: Text('${order.retailerName} • ₹${order.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${DateFormat('dd MMM hh:mm a').format(order.orderDate)} • ${order.serverOrderId ?? 'Local Queue'}'),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEBF5FF),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${order.totalProductsCount} Products (${order.totalUnitsCount.toInt()} Units)',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0070D2)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSynced ? Colors.green.shade100 : Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              order.syncStatus,
                              style: TextStyle(
                                color: isSynced ? Colors.green.shade800 : Colors.brown,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (order.items.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(height: 12),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: const Text(
                              'Ordered Items:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ),
                          ...order.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '• ${item.productName}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${item.quantity.toInt()} pcs • ₹${item.totalAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0070D2)),
                                ),
                              ],
                            ),
                          )),
                          const SizedBox(height: 4),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
