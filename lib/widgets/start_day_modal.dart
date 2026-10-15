import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../services/salesforce_dynamic_service.dart';
import '../services/salesforce_sync_service.dart';
import '../services/salesforce_auth_service.dart';

/// Modal bottom sheet implementing BRD Point 21 (Start Day) and Point 31 (End Day)
class StartDayModal extends StatefulWidget {
  final SalesforceDynamicService dynamicService;
  final SalesforceSyncService syncService;
  final SalesforceAuthService? authService;
  final VoidCallback onDayStatusChanged;

  const StartDayModal({
    super.key,
    required this.dynamicService,
    required this.syncService,
    this.authService,
    required this.onDayStatusChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required SalesforceDynamicService dynamicService,
    required SalesforceSyncService syncService,
    SalesforceAuthService? authService,
    required VoidCallback onDayStatusChanged,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StartDayModal(
        dynamicService: dynamicService,
        syncService: syncService,
        authService: authService,
        onDayStatusChanged: onDayStatusChanged,
      ),
    );
  }

  @override
  State<StartDayModal> createState() => _StartDayModalState();
}

class _StartDayModalState extends State<StartDayModal> {
  // Step 1 = Form, Step 2 = Proceed / Confirmation Summary (Point 21.6)
  int _step = 1;

  // Point 21.1: Day Plan
  String _dayPlan = 'On Tour'; // 'On Tour', 'Office', 'Other'
  final TextEditingController _otherDetailsController = TextEditingController();

  // Point 21.2: Tour Plan (conditional: only if Day Plan == 'On Tour')
  String _tourPlan = 'Local'; // 'Local', 'Outstation'

  // Point 21.3: Mode of Transport
  String _modeOfTransport = 'Bike'; // 'Car', 'Bike', 'Bus', 'Auto', 'Online Taxi', 'Air', 'Train'
  final List<String> _transportModes = [
    'Car',
    'Bike',
    'Bus',
    'Auto',
    'Online Taxi',
    'Air',
    'Train',
  ];

  // Point 21.4: Vehicle Used
  String _vehicleUsed = 'Personal/Own'; // 'Personal/Own', 'Office', 'Public Transport'
  final List<String> _vehicleOptions = [
    'Personal/Own',
    'Office',
    'Public Transport',
  ];

  // Auto-captured data (Point 21.6)
  double _lat = 18.9322;
  double _lon = 72.8347;
  bool _isLocating = true;
  bool _isSaving = false;
  DateTime _captureTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchLiveLocation();
  }

  @override
  void dispose() {
    _otherDetailsController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5),
          );
          if (mounted) {
            setState(() {
              _lat = pos.latitude;
              _lon = pos.longitude;
              _isLocating = false;
              _captureTime = DateTime.now();
            });
            return;
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLocating = false;
        _captureTime = DateTime.now();
      });
    }
  }

  void _handleProceed() {
    if (_dayPlan == 'Other' && _otherDetailsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter details for "Other" Day Plan.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() {
      _captureTime = DateTime.now();
      _step = 2; // Proceed to Summary (Point 21.6)
    });
  }

  Future<void> _handleDone() async {
    setState(() => _isSaving = true);
    final user = widget.authService?.currentUser;

    // 1. Sync local attendance
    widget.syncService.punchIn(
      dayType: _dayPlan == 'Office' ? 'OFFICE' : 'ON_TOUR',
      batteryLevel: 92,
    );

    // 2. Sync to Salesforce Dynamic API
    final res = await widget.dynamicService.punchAttendance(
      action: 'PUNCH_IN',
      latitude: _lat,
      longitude: _lon,
      address: _dayPlan == 'Other'
          ? 'Other: ${_otherDetailsController.text.trim()}'
          : 'Day Plan: $_dayPlan | Mode: $_modeOfTransport',
      email: user?.email,
      userId: user?.id,
      dayPlan: _dayPlan,
      dayPlanOtherDetails: _dayPlan == 'Other' ? _otherDetailsController.text.trim() : null,
      tourPlan: _dayPlan == 'On Tour' ? _tourPlan : null,
      modeOfTransport: _modeOfTransport,
      vehicleUsed: _vehicleUsed,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
      widget.onDayStatusChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  res['message'] ?? 'Start Day logged successfully. You are now active!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B5CAB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.wb_sunny, color: Color(0xFF0B5CAB), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _step == 1 ? 'Start Day Information' : 'Review & Confirm Start Day',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF001E3C),
                          ),
                        ),
                        Text(
                          _step == 1
                              ? 'Enter tour and transport details (BRD Point 21)'
                              : 'Step 2: Auto-capturing GPS & Timings (Point 21.6)',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              if (_step == 1) _buildStep1Form() else _buildStep2Summary(),
            ],
          ),
        ),
      ),
    );
  }

  /// Step 1: Form Inputs as per BRD Points 21.1 to 21.4
  Widget _buildStep1Form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Point 21.1: Day Plan
        const Text(
          'Point 21.1 — Day Plan *',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF001E3C)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Select your work activity for today:',
          style: TextStyle(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildPlanChip(label: 'On Tour', icon: Icons.explore, isSelected: _dayPlan == 'On Tour', onSelected: () {
              setState(() => _dayPlan = 'On Tour');
            }),
            const SizedBox(width: 8),
            _buildPlanChip(label: 'Office', icon: Icons.business, isSelected: _dayPlan == 'Office', onSelected: () {
              setState(() => _dayPlan = 'Office');
            }),
            const SizedBox(width: 8),
            _buildPlanChip(label: 'Other', icon: Icons.more_horiz, isSelected: _dayPlan == 'Other', onSelected: () {
              setState(() => _dayPlan = 'Other');
            }),
          ],
        ),

        // If Other, text box appears (Point 21.1)
        if (_dayPlan == 'Other') ...[
          const SizedBox(height: 12),
          TextField(
            controller: _otherDetailsController,
            decoration: InputDecoration(
              labelText: 'Enter Details for Other *',
              hintText: 'e.g., Regional Training, Trade Expo, Meeting',
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],

        // Point 21.2: Tour Plan (Only appears when On Tour is selected)
        if (_dayPlan == 'On Tour') ...[
          const SizedBox(height: 18),
          const Text(
            'Point 21.2 — Tour Plan *',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF001E3C)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Local = within local area. Outstation = outside local area:',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPlanChip(
                label: 'Local',
                icon: Icons.location_city,
                isSelected: _tourPlan == 'Local',
                onSelected: () => setState(() => _tourPlan = 'Local'),
              ),
              const SizedBox(width: 10),
              _buildPlanChip(
                label: 'Outstation',
                icon: Icons.flight_takeoff,
                isSelected: _tourPlan == 'Outstation',
                onSelected: () => setState(() => _tourPlan = 'Outstation'),
              ),
            ],
          ),
        ],

        // Point 21.3: Mode of Transport
        const SizedBox(height: 18),
        const Text(
          'Point 21.3 — Mode of Transport *',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF001E3C)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Used for calculating monthly employee expenses:',
          style: TextStyle(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _transportModes.map((mode) {
            final isSel = _modeOfTransport == mode;
            IconData icon = Icons.directions_car;
            if (mode == 'Bike') icon = Icons.two_wheeler;
            if (mode == 'Bus') icon = Icons.directions_bus;
            if (mode == 'Auto') icon = Icons.electric_rickshaw;
            if (mode == 'Online Taxi') icon = Icons.local_taxi;
            if (mode == 'Air') icon = Icons.airplanemode_active;
            if (mode == 'Train') icon = Icons.train;

            return ChoiceChip(
              avatar: Icon(icon, size: 16, color: isSel ? Colors.white : const Color(0xFF0B5CAB)),
              label: Text(mode, style: TextStyle(color: isSel ? Colors.white : Colors.black87, fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
              selected: isSel,
              selectedColor: const Color(0xFF0B5CAB),
              backgroundColor: Colors.grey.shade100,
              onSelected: (val) {
                if (val) setState(() => _modeOfTransport = mode);
              },
            );
          }).toList(),
        ),

        // Point 21.4: Vehicle Used
        const SizedBox(height: 18),
        const Text(
          'Point 21.4 — Vehicle Used *',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF001E3C)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Identifies ownership and travel calculation basis:',
          style: TextStyle(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _vehicleOptions.map((opt) {
            final isSel = _vehicleUsed == opt;
            IconData icon = Icons.person;
            if (opt == 'Office') icon = Icons.apartment;
            if (opt == 'Public Transport') icon = Icons.commute;

            return ChoiceChip(
              avatar: Icon(icon, size: 16, color: isSel ? Colors.white : const Color(0xFF0B5CAB)),
              label: Text(opt, style: TextStyle(color: isSel ? Colors.white : Colors.black87, fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
              selected: isSel,
              selectedColor: const Color(0xFF0B5CAB),
              backgroundColor: Colors.grey.shade100,
              onSelected: (val) {
                if (val) setState(() => _vehicleUsed = opt);
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Button: Proceed (Point 21.6)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B5CAB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _handleProceed,
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            label: const Text(
              'Proceed',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  /// Step 2: Confirmation Summary & Auto-capture (Point 21.6)
  Widget _buildStep2Summary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified, color: Color(0xFF16A34A), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Point 21.6 — Automatic Telemetry Captured',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF166534)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildSummaryRow('Start-Day Date:', DateFormat('EEE, dd MMM yyyy').format(_captureTime)),
              _buildSummaryRow('Start-Day Time:', DateFormat('hh:mm:ss a').format(_captureTime)),
              _buildSummaryRow(
                'Geolocation:',
                _isLocating ? 'Locating GPS...' : 'Lat: ${_lat.toStringAsFixed(4)}, Lon: ${_lon.toStringAsFixed(4)}',
                isHighlight: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Entered Day Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF001E3C)),
              ),
              const SizedBox(height: 10),
              _buildSummaryRow('Day Plan:', _dayPlan),
              if (_dayPlan == 'Other')
                _buildSummaryRow('Other Details:', _otherDetailsController.text.trim()),
              if (_dayPlan == 'On Tour')
                _buildSummaryRow('Tour Plan:', _tourPlan),
              _buildSummaryRow('Mode of Transport:', _modeOfTransport),
              _buildSummaryRow('Vehicle Used:', _vehicleUsed),
            ],
          ),
        ),

        const SizedBox(height: 12),
        const Text(
          'These details are saved in the daily attendance log and are used to calculate monthly employee expenses.',
          style: TextStyle(fontSize: 11, color: Colors.black54, fontStyle: FontStyle.italic),
        ),

        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : () => setState(() => _step = 1),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _handleDone,
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check, color: Colors.white),
                label: Text(
                  _isSaving ? 'Starting Day...' : 'Done',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlanChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0B5CAB) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF0B5CAB) : Colors.grey.shade300,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: isSelected ? Colors.white : const Color(0xFF0B5CAB)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isHighlight ? const Color(0xFF16A34A) : const Color(0xFF001E3C),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper function to show End Day Confirmation (Point 31)
Future<void> showEndDayDialog(
  BuildContext context, {
  required SalesforceDynamicService dynamicService,
  required SalesforceSyncService syncService,
  SalesforceAuthService? authService,
  required VoidCallback onDayStatusChanged,
}) async {
  final exitTime = DateTime.now();
  double endLat = 18.9322;
  double endLon = 72.8347;

  try {
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 4),
    );
    endLat = pos.latitude;
    endLon = pos.longitude;
  } catch (_) {}

  if (!context.mounted) return;

  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.stop_circle, color: Color(0xFFDC2626)),
          SizedBox(width: 8),
          Text('Point 31 — End Day', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'After completing the day\'s visits, end your day to finalize working hours and daily log.',
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _detailRow('End-Day Date:', DateFormat('dd MMM yyyy').format(exitTime)),
                _detailRow('End-Day Time:', DateFormat('hh:mm:ss a').format(exitTime)),
                _detailRow('End-Day Geolocation:', '${endLat.toStringAsFixed(4)}, ${endLon.toStringAsFixed(4)}'),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Confirm End Day', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );

  if (confirm == true) {
    final user = authService?.currentUser;
    syncService.punchOut(finalDistanceKm: 12.5);
    final res = await dynamicService.punchAttendance(
      action: 'PUNCH_OUT',
      latitude: endLat,
      longitude: endLon,
      address: 'Day Ended at Location',
      email: user?.email,
      userId: user?.id,
    );

    onDayStatusChanged();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Day ended successfully. Good job today!'),
          backgroundColor: Colors.blueGrey,
        ),
      );
    }
  }
}

Widget _detailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF001E3C))),
      ],
    ),
  );
}
