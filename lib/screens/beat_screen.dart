import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/salesforce_sync_service.dart';

class BeatScreen extends StatefulWidget {
  final SalesforceSyncService syncService;
  final VoidCallback onNavigateToVisitTab;

  const BeatScreen({
    super.key,
    required this.syncService,
    required this.onNavigateToVisitTab,
  });

  @override
  State<BeatScreen> createState() => _BeatScreenState();
}

class _BeatScreenState extends State<BeatScreen> {
  void _handleCheckIn(RetailerModel retailer) {
    widget.syncService.checkInRetailer(retailer);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Checked into ${retailer.name}. Unlocking store order booking & audits...'),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
    widget.onNavigateToVisitTab();
  }

  void _showSkipDialog(RetailerModel retailer) {
    String selectedReason = 'Shop Closed';
    final reasons = [
      'Shop Closed',
      'Owner / Key Person Unavailable',
      'Sufficient Stock Available',
      'Payment Dispute / Credit Overdue',
      'Restricted Area / Timing Conflict',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.cancel_outlined, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text('Skip Visit: ${retailer.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Select mandatory reason for skipping this scheduled beat outlet:', style: TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 12),
              ...reasons.map((r) => RadioListTile<String>(
                title: Text(r, style: const TextStyle(fontSize: 13)),
                value: r,
                groupValue: selectedReason,
                dense: true,
                onChanged: (val) {
                  if (val != null) setSheetState(() => selectedReason = val);
                },
              )),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  widget.syncService.skipRetailer(retailer, selectedReason);
                  Navigator.pop(ctx);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${retailer.name} marked as skipped: $selectedReason')),
                  );
                },
                child: const Text('Confirm Skip Outlet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentBeat = widget.syncService.beats.isNotEmpty ? widget.syncService.beats.first : null;
    final retailers = widget.syncService.retailers;
    final visits = widget.syncService.visits;

    final visitedCount = visits.values.where((v) => v.isCompleted).length;
    final skippedCount = visits.values.where((v) => v.isSkipped).length;
    final totalCount = retailers.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(currentBeat?.name ?? 'Daily Beat Route', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${currentBeat?.dayOfWeek ?? 'Today'} • ${retailers.length} Scheduled Outlets', style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Beat Route Performance Summary Card
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
                        const Text('Route Execution Progress', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('$visitedCount / $totalCount Done', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0070D2))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: totalCount > 0 ? (visitedCount / totalCount) : 0,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF16A34A)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _summaryMetric('Pending', '${totalCount - visitedCount - skippedCount}', Colors.blueGrey),
                        _summaryMetric('Completed', '$visitedCount', const Color(0xFF16A34A)),
                        _summaryMetric('Skipped', '$skippedCount', Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Store Sequence List
            const Text('Stores In Sequence', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF001E3C))),
            const SizedBox(height: 8),

            ...retailers.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final retailer = entry.value;
              final visit = visits[retailer.id];
              final isCheckedIn = widget.syncService.activeVisitRetailer?.id == retailer.id;
              final isCompleted = visit?.isCompleted ?? false;
              final isSkipped = visit?.isSkipped ?? false;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: isCheckedIn
                      ? const BorderSide(color: Color(0xFF16A34A), width: 2)
                      : BorderSide.none,
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: isCompleted
                                ? const Color(0xFF16A34A)
                                : (isSkipped ? Colors.orange : const Color(0xFF0070D2)),
                            child: isCompleted
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : (isSkipped
                                    ? const Icon(Icons.close, size: 16, color: Colors.white)
                                    : Text('$index', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(retailer.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                Text(retailer.shopName, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    const Text('Within Geofence (45m)', style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (retailer.creditHold)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(6)),
                              child: const Text('CREDIT HOLD', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const Divider(height: 20),
                      // Financials & Credit Balance
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Outstanding Balance', style: TextStyle(fontSize: 11, color: Colors.black54)),
                              Text('₹${retailer.outstandingBalance.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: retailer.outstandingBalance > retailer.creditLimit ? Colors.red : Colors.black87)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Credit Limit', style: TextStyle(fontSize: 11, color: Colors.black54)),
                              Text('₹${retailer.creditLimit.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.phone, color: Color(0xFF0070D2)),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Calling ${retailer.name} (${retailer.phone})')),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Action buttons
                      if (isCheckedIn) ...[
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(40),
                          ),
                          onPressed: widget.onNavigateToVisitTab,
                          icon: const Icon(Icons.shopping_cart),
                          label: const Text('Checked In • Open Order Booking'),
                        ),
                      ] else if (isCompleted) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('✓ Visit Completed & Order Saved', style: TextStyle(color: Color(0xFF16A34A), fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ] else if (isSkipped) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Visit Skipped (${visit?.skipReason ?? 'Reason'})', style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0070D2),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => _handleCheckIn(retailer),
                                icon: const Icon(Icons.login, size: 18),
                                label: const Text('Check In'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange.shade800,
                                  side: BorderSide(color: Colors.orange.shade300),
                                ),
                                onPressed: () => _showSkipDialog(retailer),
                                child: const Text('Skip'),
                              ),
                            ),
                          ],
                        ),
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

  Widget _summaryMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }
}
