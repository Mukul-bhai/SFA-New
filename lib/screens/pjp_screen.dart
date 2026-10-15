import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/salesforce_auth_service.dart';
import '../services/salesforce_dynamic_service.dart';
import '../services/salesforce_sync_service.dart';
import '../widgets/start_day_modal.dart';
import 'outlet_detail_screen.dart';

class PjpScreen extends StatefulWidget {
  final SalesforceDynamicService dynamicService;
  final SalesforceSyncService? syncService;
  final SalesforceAuthService? authService;

  const PjpScreen({
    super.key,
    required this.dynamicService,
    this.syncService,
    this.authService,
  });

  @override
  State<PjpScreen> createState() => _PjpScreenState();
}

class _PjpScreenState extends State<PjpScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 0);

  PjpModel? _selectedPjp;
  BeatModel? _selectedBeat;
  String _outletSearchQuery = '';

  double _userLat = 18.9322;
  double _userLon = 72.8347;
  bool _isSubmittingApproval = false;

  @override
  void initState() {
    super.initState();
    _fetchGpsCoordinates();
    _refreshPjpTree();
  }

  Future<void> _refreshPjpTree() async {
    final user = widget.authService?.currentUser;
    await widget.dynamicService.fetchPjpTree(
      email: user?.email,
      userId: user?.id,
    );

    // Sync selected PJP / Beat with freshly loaded data
    if (mounted) {
      setState(() {
        if (_selectedPjp != null) {
          final updatedPjp = widget.dynamicService.pjps.firstWhere(
            (p) => p.id == _selectedPjp!.id,
            orElse: () => _selectedPjp!,
          );
          _selectedPjp = updatedPjp;

          if (_selectedBeat != null) {
            _selectedBeat = updatedPjp.beats.firstWhere(
              (b) => b.id == _selectedBeat!.id,
              orElse: () => _selectedBeat!,
            );
          }
        }
      });
    }
  }

  Future<void> _fetchGpsCoordinates() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 4),
          );
          _userLat = pos.latitude;
          _userLon = pos.longitude;
          if (mounted) setState(() {});
        }
      }
    } catch (_) {}
  }

  Color _getStatusColor(String status) {
    final s = status.toUpperCase();
    if (s.contains('APPROVED')) return const Color(0xFF16A34A);
    if (s.contains('SUBMITTED') || s.contains('PENDING')) return const Color(0xFF0070D2);
    if (s.contains('REJECT')) return const Color(0xFFDC2626);
    return const Color(0xFFD97706); // Draft or other
  }

  IconData _getStatusIcon(String status) {
    final s = status.toUpperCase();
    if (s.contains('APPROVED')) return Icons.verified;
    if (s.contains('SUBMITTED') || s.contains('PENDING')) return Icons.hourglass_top;
    if (s.contains('REJECT')) return Icons.cancel;
    return Icons.edit_note;
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ACTION: Submit PJP for Approval
  // ==========================================
  Future<void> _submitPjpForApproval(PjpModel pjp) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit PJP for Approval'),
        content: Text('Are you sure you want to submit "${pjp.name}" with ${pjp.beats.length} beats and ${pjp.totalOutlets} outlets for manager approval in Salesforce?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0070D2)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit for Approval', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmittingApproval = true);
    final user = widget.authService?.currentUser;
    final res = await widget.dynamicService.submitPjpForApproval(
      pjpId: pjp.id,
      email: user?.email,
      userId: user?.id,
    );
    await _refreshPjpTree();

    if (mounted) {
      setState(() => _isSubmittingApproval = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'PJP submitted for approval successfully.'),
          backgroundColor: res['success'] == true ? const Color(0xFF16A34A) : Colors.red,
        ),
      );
    }
  }

  // ==========================================
  // DIALOG: Create PJP Plan
  // ==========================================
  void _showCreatePjpDialog() {
    final user = widget.authService?.currentUser;
    final repName = user?.name ?? 'Mukul';
    final currentMonth = DateFormat('MMMM').format(DateTime.now());
    final currentYear = DateTime.now().year;

    final nameCtrl = TextEditingController(text: 'PJP-$repName-${currentMonth.substring(0, 3)}-$currentYear');
    String selectedMonth = currentMonth;
    int selectedYear = currentYear;

    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final years = [2025, 2026, 2027, 2028];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.add_road, color: Color(0xFF0070D2)),
              SizedBox(width: 8),
              Text('Create PJP Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Plan Name / Code:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'e.g. PJP-North-Q4',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Target Month:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedMonth,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  items: months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        selectedMonth = val;
                        nameCtrl.text = 'PJP-$repName-${val.substring(0, 3)}-$selectedYear';
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),
                const Text('Target Year:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  initialValue: selectedYear,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        selectedYear = val;
                        nameCtrl.text = 'PJP-$repName-${selectedMonth.substring(0, 3)}-$val';
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Text(
                    'Plan will be created in Draft status in Salesforce. You can add beats & outlets and submit for manager approval.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF003A70)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0070D2)),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);

                final res = await widget.dynamicService.createPjp(
                  name: name,
                  month: selectedMonth,
                  year: selectedYear,
                  email: user?.email,
                  userId: user?.id,
                );
                await _refreshPjpTree();

                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? 'PJP Plan created.'),
                      backgroundColor: res['success'] == true ? const Color(0xFF16A34A) : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Create Plan in Salesforce', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // DIALOG: Create Beat under Selected PJP
  // ==========================================
  void _showCreateBeatDialog(PjpModel pjp) {
    final user = widget.authService?.currentUser;
    final beatNameCtrl = TextEditingController();
    final beatCodeCtrl = TextEditingController(text: 'BT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    DateTime selectedRouteDate = DateTime.now();
    String selectedDay = DateFormat('EEEE').format(selectedRouteDate);

    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.alt_route, color: Color(0xFF0070D2)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Create Beat in ${pjp.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Beat Route Name:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: beatNameCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'e.g. Dadar West Market Route',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Beat Code:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: beatCodeCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Route Execution Date:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedRouteDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        selectedRouteDate = picked;
                        selectedDay = DateFormat('EEEE').format(picked);
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade50,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: Color(0xFF0070D2)),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('yyyy-MM-dd (EEEE)').format(selectedRouteDate),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001E3C)),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.black54),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Scheduled Day of Week:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedDay,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  items: days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedDay = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0070D2)),
              onPressed: () async {
                final name = beatNameCtrl.text.trim();
                final code = beatCodeCtrl.text.trim();
                if (name.isEmpty || code.isEmpty) return;
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);

                final res = await widget.dynamicService.createBeat(
                  pjpId: pjp.id,
                  name: name,
                  code: code,
                  dayOfWeek: selectedDay,
                  beatDate: DateFormat('yyyy-MM-dd').format(selectedRouteDate),
                  email: user?.email,
                  userId: user?.id,
                );
                await _refreshPjpTree();

                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? 'Beat created.'),
                      backgroundColor: res['success'] == true ? const Color(0xFF16A34A) : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Add Beat to Plan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // DIALOG: Create Outlet under Selected Beat
  // ==========================================
  void _showCreateOutletDialog(BeatModel beat) {
    final user = widget.authService?.currentUser;
    final storeNameCtrl = TextEditingController();
    final ownerNameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final creditLimitCtrl = TextEditingController(text: '50000');
    String selectedOutletType = 'Kirana';

    final types = ['Kirana', 'General Store', 'Supermarket', 'Wholesaler', 'Chemist', 'Paan Shop'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.storefront, color: Color(0xFF0070D2)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Create Outlet in ${beat.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Retail Shop / Outlet Name:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: storeNameCtrl,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g. Om Sai Provision Store', isDense: true),
                ),
                const SizedBox(height: 12),
                const Text('Proprietor / Owner Name:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: ownerNameCtrl,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g. Rajesh Sharma', isDense: true),
                ),
                const SizedBox(height: 12),
                const Text('Contact Mobile Number:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g. 9820123456', isDense: true),
                ),
                const SizedBox(height: 12),
                const Text('Outlet Channel Type:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedOutletType,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedOutletType = val);
                  },
                ),
                const SizedBox(height: 12),
                const Text('Store Address & Location:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: addressCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Shop No. 5, Station Road', isDense: true),
                ),
                const SizedBox(height: 12),
                const Text('Initial Credit Limit (₹):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: creditLimitCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.my_location, size: 16, color: Color(0xFF16A34A)),
                      const SizedBox(width: 6),
                      Text('GPS Geotag: ${_userLat.toStringAsFixed(4)}° N, ${_userLon.toStringAsFixed(4)}° E', style: const TextStyle(fontSize: 11, color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0070D2)),
              onPressed: () async {
                final sName = storeNameCtrl.text.trim();
                final oName = ownerNameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                final address = addressCtrl.text.trim();
                final limit = double.tryParse(creditLimitCtrl.text.trim()) ?? 50000.0;
                if (sName.isEmpty) return;
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);

                final res = await widget.dynamicService.createOutlet(
                  beatId: beat.id,
                  name: sName,
                  ownerName: oName.isNotEmpty ? oName : 'Store Owner',
                  phone: phone.isNotEmpty ? phone : '9876543210',
                  address: address.isNotEmpty ? address : 'Market Location',
                  outletType: selectedOutletType,
                  creditLimit: limit,
                  latitude: _userLat,
                  longitude: _userLon,
                  email: user?.email,
                  userId: user?.id,
                );
                await _refreshPjpTree();

                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? 'Outlet created.'),
                      backgroundColor: res['success'] == true ? const Color(0xFF16A34A) : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Register Outlet', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartDayBanner() {
    final att = widget.dynamicService.attendance;
    final bool isPunchedIn = att.punchedIn;
    final bool isPunchedOut = att.punchedOut;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isPunchedIn && !isPunchedOut
              ? const Color(0xFFBBF7D0)
              : (isPunchedOut ? Colors.grey.shade300 : const Color(0xFFBFDBFE)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPunchedIn && !isPunchedOut
                  ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                  : (isPunchedOut ? Colors.grey.shade100 : const Color(0xFF0B5CAB).withValues(alpha: 0.1)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPunchedIn && !isPunchedOut
                  ? Icons.location_on
                  : (isPunchedOut ? Icons.check_circle : Icons.play_circle_fill),
              size: 20,
              color: isPunchedIn && !isPunchedOut
                  ? const Color(0xFF16A34A)
                  : (isPunchedOut ? Colors.grey : const Color(0xFF0B5CAB)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPunchedIn && !isPunchedOut
                      ? 'Day in Progress (Active)'
                      : (isPunchedOut ? 'Day Completed' : 'Start Your Working Day'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF001E3C)),
                ),
                Text(
                  isPunchedIn && !isPunchedOut
                      ? 'Started at ${att.checkInTime ?? 'Active'}'
                      : (isPunchedOut
                          ? 'Today\'s visits & log finalized'
                          : 'Point 21: Capture tour plan, mode & GPS'),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (!isPunchedIn && !isPunchedOut)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: () {
                StartDayModal.show(
                  context,
                  dynamicService: widget.dynamicService,
                  syncService: widget.syncService ?? SalesforceSyncService(),
                  authService: widget.authService,
                  onDayStatusChanged: () {
                    setState(() {});
                  },
                );
              },
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text('Start Day', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            )
          else if (isPunchedIn && !isPunchedOut)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: () {
                showEndDayDialog(
                  context,
                  dynamicService: widget.dynamicService,
                  syncService: widget.syncService ?? SalesforceSyncService(),
                  authService: widget.authService,
                  onDayStatusChanged: () {
                    setState(() {});
                  },
                );
              },
              icon: const Icon(Icons.stop, size: 16),
              label: const Text('End Day', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            )
          else
            TextButton(
              onPressed: () {
                StartDayModal.show(
                  context,
                  dynamicService: widget.dynamicService,
                  syncService: widget.syncService ?? SalesforceSyncService(),
                  authService: widget.authService,
                  onDayStatusChanged: () {
                    setState(() {});
                  },
                );
              },
              child: const Text('Re-Start', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedBeat != null) {
      return _buildOutletsLevel();
    } else if (_selectedPjp != null) {
      return _buildBeatsLevel();
    } else {
      return _buildPjpsLevel();
    }
  }

  // ==========================================
  // LEVEL 1: Employee's PJPs List
  // ==========================================
  Widget _buildPjpsLevel() {
    final pjps = widget.dynamicService.pjps;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Permanent Journey Plans (PJP)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0B5CAB),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create New PJP Plan',
            onPressed: _showCreatePjpDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sync PJPs from Salesforce',
            onPressed: _refreshPjpTree,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0070D2),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create PJP Plan', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _showCreatePjpDialog,
      ),
      body: Column(
        children: [
          _buildStartDayBanner(),
          Expanded(
            child: pjps.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.route, size: 56, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('No Permanent Journey Plans found.', style: TextStyle(fontSize: 15, color: Colors.grey)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0070D2), foregroundColor: Colors.white),
                          onPressed: _showCreatePjpDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Create First PJP Plan'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshPjpTree,
                    child: ListView.separated(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 80),
                      itemCount: pjps.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final pjp = pjps[idx];
                        return _buildPjpCard(pjp);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPjpCard(PjpModel pjp) {
    final isApproved = pjp.status.toUpperCase() == 'APPROVED';
    final isSubmitted = pjp.status.toUpperCase().contains('SUBMIT') || pjp.status.toUpperCase().contains('PENDING');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() => _selectedPjp = pjp);
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusChip(pjp.status),
                    Text(
                      '${pjp.month} ${pjp.year}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  pjp.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                ),
                Text(
                  'Code: ${pjp.code.isNotEmpty ? pjp.code : "PJP-${pjp.id.substring(0, 6)}"}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.alt_route, size: 18, color: Color(0xFF0B5CAB)),
                        const SizedBox(width: 6),
                        Text(
                          '${pjp.beats.length} Beats',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.storefront, size: 18, color: Color(0xFFE65100)),
                        const SizedBox(width: 6),
                        Text(
                          '${pjp.totalOutlets} Outlets',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                        ),
                      ],
                    ),
                    const Row(
                      children: [
                        Text('Open Beats', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0B5CAB))),
                        Icon(Icons.chevron_right, size: 18, color: Color(0xFF0B5CAB)),
                      ],
                    ),
                  ],
                ),

                // Submit for Approval Action Button if not Approved
                if (!isApproved) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isSubmitted ? const Color(0xFF0070D2) : const Color(0xFF16A34A),
                      side: BorderSide(color: isSubmitted ? Colors.blue.shade300 : const Color(0xFF16A34A)),
                      minimumSize: const Size.fromHeight(38),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isSubmittingApproval ? null : () => _submitPjpForApproval(pjp),
                    icon: Icon(isSubmitted ? Icons.done_all : Icons.send_rounded, size: 16),
                    label: Text(
                      isSubmitted ? 'Resubmit for Manager Approval' : 'Submit for Approval',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // LEVEL 2: Beats inside Selected PJP
  // ==========================================
  Widget _buildBeatsLevel() {
    final pjp = _selectedPjp!;
    final beats = pjp.beats;
    final isApproved = pjp.status.toUpperCase() == 'APPROVED';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(pjp.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0B5CAB),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedPjp = null),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create Beat under this PJP',
            onPressed: () => _showCreateBeatDialog(pjp),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Beats',
            onPressed: _refreshPjpTree,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0070D2),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Beat', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showCreateBeatDialog(pjp),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // PJP Plan Status & Approval Banner
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text('${pjp.month} ${pjp.year}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF263238))),
                      ],
                    ),
                    _buildStatusChip(pjp.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${beats.length} Route Beats  •  ${pjp.totalOutlets} Registered Outlets',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                if (!isApproved) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(38),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isSubmittingApproval ? null : () => _submitPjpForApproval(pjp),
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Submit PJP Plan for Approval', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          // Beats List
          Expanded(
            child: beats.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.alt_route, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('No route beats created for this plan yet.', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0070D2), foregroundColor: Colors.white),
                          onPressed: () => _showCreateBeatDialog(pjp),
                          icon: const Icon(Icons.add),
                          label: const Text('Create First Beat'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
                    itemCount: beats.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final beat = beats[idx];
                      return _buildBeatCard(beat);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeatCard(BeatModel beat) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            setState(() => _selectedBeat = beat);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B5CAB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.location_city, color: Color(0xFF0B5CAB), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              beat.dayOfWeek,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                            ),
                          ),
                          Text(
                            '${beat.retailers.length} Outlets',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0B5CAB)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        beat.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                      ),
                      Text(
                        'Beat Code: ${beat.code}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // LEVEL 3: Outlets inside Selected Beat
  // ==========================================
  Widget _buildOutletsLevel() {
    final beat = _selectedBeat!;
    final outlets = beat.retailers.where((o) {
      if (_outletSearchQuery.isEmpty) return true;
      return o.shopName.toLowerCase().contains(_outletSearchQuery.toLowerCase()) ||
          o.name.toLowerCase().contains(_outletSearchQuery.toLowerCase()) ||
          o.code.toLowerCase().contains(_outletSearchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(beat.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0B5CAB),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedBeat = null),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create Outlet in this Beat',
            onPressed: () => _showCreateOutletDialog(beat),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Outlets',
            onPressed: _refreshPjpTree,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0070D2),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business),
        label: const Text('Create Outlet', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showCreateOutletDialog(beat),
      ),
      body: Column(
        children: [
          _buildStartDayBanner(),
          // Search & Filter Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search shops by name, owner, or code...',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                filled: true,
                fillColor: const Color(0xFFF0F4F8),
              ),
              onChanged: (val) => setState(() => _outletSearchQuery = val),
            ),
          ),

          // Outlets List with 100m distance badge & credit check
          Expanded(
            child: outlets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.storefront, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('No outlets found in this beat.', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0070D2), foregroundColor: Colors.white),
                          onPressed: () => _showCreateOutletDialog(beat),
                          icon: const Icon(Icons.add_business),
                          label: const Text('Add First Outlet'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(left: 14, right: 14, top: 14, bottom: 80),
                    itemCount: outlets.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final outlet = outlets[idx];
                      final distMeters = outlet.distanceInMetersTo(_userLat, _userLon);
                      final bool isInside100m = distMeters <= widget.dynamicService.metadata.geofenceRadiusMeters;
                      final bool isBlocked = outlet.isOrderBlockedDueToCredit;

                      return _buildOutletCard(outlet, distMeters, isInside100m, isBlocked);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutletCard(RetailerModel outlet, double distMeters, bool isInside100m, bool isBlocked) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBlocked ? Colors.red.shade200 : Colors.transparent,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OutletDetailScreen(
                  outlet: outlet,
                  beatName: _selectedBeat?.name ?? 'Assigned Beat',
                  dynamicService: widget.dynamicService,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        outlet.shopName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                      ),
                    ),
                    // 100m Distance Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isInside100m ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isInside100m ? Icons.location_on : Icons.location_off,
                            size: 12,
                            color: isInside100m ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${distMeters.toStringAsFixed(0)}m ${isInside100m ? "(In 100m)" : "(Far)"}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isInside100m ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${outlet.code} • ${outlet.name} • ${outlet.phone}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),

                // Financial Standing & Credit Warning
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Outstanding: ${currencyFormat.format(outlet.outstandingBalance)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isBlocked ? Colors.red.shade700 : const Color(0xFF263238),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('/ Limit ${currencyFormat.format(outlet.creditLimit)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isBlocked ? Colors.red.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isBlocked ? 'HOLD' : 'ACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isBlocked ? Colors.red.shade700 : Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),

                if (isBlocked) ...[
                  const SizedBox(height: 6),
                  Text(
                    '⚠️ Credit limit exceeded! Order booking will be restricted.',
                    style: TextStyle(fontSize: 10, color: Colors.red.shade800, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
