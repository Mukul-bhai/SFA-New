import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/models.dart';
import 'services/salesforce_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final syncService = SalesforceSyncService();
  await syncService.init();
  runApp(SfaApp(syncService: syncService));
}

class SfaApp extends StatelessWidget {
  final SalesforceSyncService syncService;

  const SfaApp({super.key, required this.syncService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salesforce SFA Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0070D2), // Salesforce Brand Blue
          primary: const Color(0xFF0070D2),
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF001E3C),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: SfaHomeScreen(syncService: syncService),
    );
  }
}

class SfaHomeScreen extends StatefulWidget {
  final SalesforceSyncService syncService;

  const SfaHomeScreen({super.key, required this.syncService});

  @override
  State<SfaHomeScreen> createState() => _SfaHomeScreenState();
}

class _SfaHomeScreenState extends State<SfaHomeScreen> {
  bool isPunchedIn = true;
  String currentBeatName = 'Monday Beat: Western Mumbai Route';
  RetailerModel? activeRetailer;

  @override
  Widget build(BuildContext context) {
    final queuedCount = widget.syncService.outbox.where((o) => o.syncStatus == 'QUEUED').length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('SFA Mobile App', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Salesforce Core Cloud • Field Rep Mode', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          // Outbox Sync Icon with Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.sync),
                tooltip: 'Sync Outbox Queue',
                onPressed: () => _showOutboxSheet(context),
              ),
              if (queuedCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$queuedCount',
                      style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Attendance Status Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isPunchedIn ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isPunchedIn ? 'Punched In (09:15 AM)' : 'Punched Out',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.battery_charging_full, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      const Text('88%', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          setState(() {
                            isPunchedIn = !isPunchedIn;
                          });
                        },
                        child: Text(isPunchedIn ? 'Punch Out' : 'Punch In', style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Active Route Banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0070D2), Color(0xFF1589EE)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.blue.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TODAY\'S ASSIGNED BEAT', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(currentBeatName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBeatStat('Stores', '${widget.syncService.retailers.length}'),
                      _buildBeatStat('Target', '₹50,000'),
                      _buildBeatStat('Achieved', '₹15,600'),
                      _buildBeatStat('Pending', '3'),
                    ],
                  ),
                ],
              ),
            ),

            // Retailer Beat Route List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Beat Retailer List (Geofence Monitored)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text('${widget.syncService.retailers.length} Retailers', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.syncService.retailers.length,
              itemBuilder: (context, index) {
                final retailer = widget.syncService.retailers[index];
                return _buildRetailerCard(retailer);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBeatStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRetailerCard(RetailerModel retailer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(retailer.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(retailer.shopName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                if (retailer.creditHold)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(6)),
                    child: const Text('CREDIT HOLD', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(6)),
                    child: const Text('READY', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.blue),
                const SizedBox(width: 4),
                const Text('Within 45m (Geofence Validated)', style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500)),
                const Spacer(),
                Text('Bal: ₹${NumberFormat('#,##,###').format(retailer.outstandingBalance)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.store, size: 16),
                    label: const Text('Check In'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Checked in at ${retailer.name} (100m Geofence Passed)')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0070D2),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: const Text('Book Order'),
                    onPressed: retailer.creditHold ? null : () => _showOrderModal(context, retailer),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderModal(BuildContext context, RetailerModel retailer) {
    final product = widget.syncService.products[0]; // Herbal Shampoo
    int qty = 50;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Book Order: ${retailer.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Text(product.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Text(product.description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Price: ₹${product.unitPrice.toStringAsFixed(0)} / unit', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: qty > 10 ? () => setModalState(() => qty -= 10) : null,
                      ),
                      Text('$qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setModalState(() => qty += 10),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Order Amount:', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('₹${NumberFormat('#,##,###').format(qty * product.unitPrice)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0070D2))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0070D2),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    await widget.syncService.createOrderLocally(
                      retailer: retailer,
                      product: product,
                      quantity: qty,
                    );
                    setState(() {});
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Order Saved Locally (Offline Outbox Queue Created)'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Confirm & Enqueue Order (Offline Safe)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOutboxSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(ctx).size.height * 0.65,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Offline Outbox Queue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload, size: 16),
                    label: const Text('Sync All'),
                    onPressed: () async {
                      await widget.syncService.syncOutbox();
                      setSheetState(() {});
                      setState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Orders saved on device and synchronizing to Salesforce Core Cloud.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const Divider(height: 24),
              Expanded(
                child: widget.syncService.outbox.isEmpty
                    ? const Center(child: Text('Outbox is empty. All orders synchronized!'))
                    : ListView.builder(
                        itemCount: widget.syncService.outbox.length,
                        itemBuilder: (context, i) {
                          final o = widget.syncService.outbox[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text('${o.quantity}x ${o.productName} • ₹${o.totalAmount.toInt()}'),
                              subtitle: Text('${o.retailerName}\nKey: ${o.localId.substring(0, 8)}...'),
                              isThreeLine: true,
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: o.syncStatus == 'SYNCED' ? Colors.green.shade100 : Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  o.syncStatus,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: o.syncStatus == 'SYNCED' ? Colors.green.shade800 : Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
