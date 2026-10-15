import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../services/salesforce_auth_service.dart';
import '../services/salesforce_dynamic_service.dart';
import '../services/salesforce_sync_service.dart';
import '../widgets/start_day_modal.dart';

class AttendanceExpensesScreen extends StatefulWidget {
  final SalesforceSyncService syncService;
  final SalesforceDynamicService? dynamicService;
  final SalesforceAuthService? authService;

  const AttendanceExpensesScreen({
    super.key,
    required this.syncService,
    this.dynamicService,
    this.authService,
  });

  @override
  State<AttendanceExpensesScreen> createState() => _AttendanceExpensesScreenState();
}

class _AttendanceExpensesScreenState extends State<AttendanceExpensesScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoadingAttendance = false;
  bool _isPunching = false;

  String _selectedDayType = 'FULL_DAY'; // 'FULL_DAY' or 'HALF_DAY'
  final _startKmCtrl = TextEditingController(text: '1420.0');
  final _endKmCtrl = TextEditingController(text: '1448.5');
  double _calculatedDistance = 28.5;
  double? _liveLat;
  double? _liveLon;

  @override
  void initState() {
    super.initState();
    _recomputeDistance();
    _fetchAttendanceForSelectedDate(_selectedDate);
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      final pos = await Geolocator.getLastKnownPosition();
      if (pos != null && mounted) {
        setState(() {
          _liveLat = pos.latitude;
          _liveLon = pos.longitude;
        });
      }
      final currentPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 6),
      );
      if (mounted) {
        setState(() {
          _liveLat = currentPos.latitude;
          _liveLon = currentPos.longitude;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _startKmCtrl.dispose();
    _endKmCtrl.dispose();
    super.dispose();
  }

  void _recomputeDistance() {
    final start = double.tryParse(_startKmCtrl.text) ?? 0.0;
    final end = double.tryParse(_endKmCtrl.text) ?? 0.0;
    setState(() {
      _calculatedDistance = (end >= start) ? (end - start) : 0.0;
    });
  }

  Future<void> _fetchAttendanceForSelectedDate(DateTime date) async {
    if (widget.dynamicService == null) return;
    setState(() => _isLoadingAttendance = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final user = widget.authService?.currentUser;
      await widget.dynamicService!.fetchAttendance(
        date: dateStr,
        email: user?.email,
        userId: user?.id,
      );
    } catch (_) {
      // Ignored - fallback to cached state
    } finally {
      if (mounted) {
        setState(() => _isLoadingAttendance = false);
      }
    }
  }

  void _onDatePicked(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _fetchAttendanceForSelectedDate(date);
  }

  Future<void> _showCalendarPicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0070D2),
              onPrimary: Colors.white,
              onSurface: Color(0xFF001E3C),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _onDatePicked(picked);
    }
  }

  Future<void> _handlePunchAction(String action) async {
    setState(() => _isPunching = true);

    double lat = 18.9322;
    double lon = 72.8347;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          final lastPos = await Geolocator.getLastKnownPosition();
          if (lastPos != null) {
            lat = lastPos.latitude;
            lon = lastPos.longitude;
          }
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 8),
          );
          lat = position.latitude;
          lon = position.longitude;
        }
      }
    } catch (_) {}

    final user = widget.authService?.currentUser;

    if (action == 'PUNCH_IN') {
      widget.syncService.punchIn(dayType: _selectedDayType, batteryLevel: 88);
      if (widget.dynamicService != null) {
        await widget.dynamicService!.punchAttendance(
          action: 'PUNCH_IN',
          latitude: lat,
          longitude: lon,
          address: 'Fort Commercial Hub, South Mumbai',
          email: user?.email,
          userId: user?.id,
        );
      }
    } else {
      widget.syncService.punchOut(finalDistanceKm: _calculatedDistance);
      if (widget.dynamicService != null) {
        await widget.dynamicService!.punchAttendance(
          action: 'PUNCH_OUT',
          latitude: lat,
          longitude: lon,
          address: 'Fort Commercial Hub, South Mumbai',
          email: user?.email,
          userId: user?.id,
        );
      }
    }

    await _fetchAttendanceForSelectedDate(_selectedDate);

    if (mounted) {
      setState(() {
        _liveLat = lat;
        _liveLon = lon;
        _isPunching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(action == 'PUNCH_IN'
              ? 'Punched In for $_selectedDayType at ${DateFormat('hh:mm a').format(DateTime.now())}'
              : 'Day Attendance closed & punched out successfully.'),
          backgroundColor: action == 'PUNCH_IN' ? const Color(0xFF16A34A) : Colors.blueGrey,
        ),
      );
    }
  }

  void _handleSubmitClaim() async {
    final claim = widget.syncService.calculateExpense(
      distanceKm: _calculatedDistance,
      dayType: _selectedDayType,
    );
    widget.syncService.submitExpenseClaim(claim);
    final user = widget.authService?.currentUser;
    if (widget.dynamicService != null) {
      final da = _selectedDayType == 'FULL_DAY' ? 250.0 : 125.0;
      final ta = _calculatedDistance * 3.50;
      await widget.dynamicService!.submitExpenseClaim(
        distanceKm: _calculatedDistance,
        dayType: _selectedDayType,
        travelAllowance: ta,
        dailyAllowance: da,
        totalAmount: ta + da,
        email: user?.email,
        userId: user?.id, 
      );
    }
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('TA/DA Claim of ₹${claim.totalAmount.toStringAsFixed(2)} submitted to Salesforce Expense Ledger!'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Color _getStatusColor(String status) {
    final s = status.toUpperCase();
    if (s.contains('PRESENT') || s.contains('COMPLETED')) return const Color(0xFF16A34A);
    if (s.contains('HALF')) return const Color(0xFFD97706);
    if (s.contains('ABSENT')) return const Color(0xFFDC2626);
    if (s.contains('LEAVE')) return const Color(0xFF7C3AED);
    return Colors.grey.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = _isSameDay(_selectedDate, now);
    final isYesterday = _isSameDay(_selectedDate, now.subtract(const Duration(days: 1)));

    final localAttendance = widget.syncService.todayAttendance;
    final isLocalPunchedIn = localAttendance != null && localAttendance.status == 'PRESENT';

    // Live Salesforce Attendance Record for the selected date
    final liveRecord = widget.dynamicService?.selectedDateAttendance;
    final historyList = widget.dynamicService?.attendanceHistory ?? [];
    final expenses = widget.syncService.expenses;

    final kmRate = 3.50;
    final da = _selectedDayType == 'FULL_DAY' ? 250.0 : 125.0;
    final ta = _calculatedDistance * kmRate;
    final totalClaim = ta + da;

    // Determine effective status for display
    String displayStatus = 'Not Marked';
    if (liveRecord != null && liveRecord.status.isNotEmpty) {
      displayStatus = liveRecord.status;
    } else if (isToday && isLocalPunchedIn) {
      displayStatus = 'Present';
    }

    final isDayActive = isToday && (isLocalPunchedIn || (liveRecord != null && liveRecord.isDayActive));
    final isDayCompleted = (liveRecord != null && !liveRecord.isDayActive && (liveRecord.endTime != null && liveRecord.endTime!.isNotEmpty)) ||
        (isToday && localAttendance != null && localAttendance.punchOutTime != null);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Attendance & TA/DA Allowance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Attendance Data',
            onPressed: () => _fetchAttendanceForSelectedDate(_selectedDate),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. MASTER DAILY ATTENDANCE & SHIFT PUNCH CARD
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDayActive
                      ? const Color(0xFF16A34A).withOpacity(0.5)
                      : (isDayCompleted ? Colors.blue.shade200 : Colors.grey.shade300),
                  width: isDayActive ? 1.5 : 1.0,
                ),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: Shift Title & Status Pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isDayActive ? const Color(0xFF16A34A) : const Color(0xFF0070D2)).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isDayActive ? Icons.timer : Icons.fingerprint,
                                color: isDayActive ? const Color(0xFF16A34A) : const Color(0xFF0070D2),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isToday ? 'Today\'s Shift & Punch' : 'Historical Day Record',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF001E3C)),
                                ),
                                Text(
                                  DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDayActive
                                ? const Color(0xFF16A34A).withOpacity(0.15)
                                : (isDayCompleted
                                    ? Colors.blue.shade50
                                    : Colors.orange.shade50),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDayActive
                                  ? const Color(0xFF16A34A)
                                  : (isDayCompleted ? Colors.blue.shade300 : Colors.orange.shade300),
                            ),
                          ),
                          child: Text(
                            isDayActive
                                ? '● ACTIVE'
                                : (isDayCompleted ? '✓ COMPLETED' : '○ ${displayStatus.toUpperCase()}'),
                            style: TextStyle(
                              color: isDayActive
                                  ? const Color(0xFF16A34A)
                                  : (isDayCompleted ? Colors.blue.shade800 : Colors.orange.shade800),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (_isLoadingAttendance)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                              SizedBox(width: 12),
                              Text('Syncing live attendance data...', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      // Exact Timings & Location Metrics Grid
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildAttendanceInfoTile(
                                    icon: Icons.login,
                                    label: 'Punch In / Start',
                                    value: liveRecord?.startTime != null && liveRecord!.startTime!.isNotEmpty
                                        ? liveRecord.startTime!
                                        : (isToday && isLocalPunchedIn
                                            ? DateFormat('hh:mm a').format(localAttendance.punchInTime)
                                            : '--'),
                                    color: const Color(0xFF16A34A),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildAttendanceInfoTile(
                                    icon: Icons.logout,
                                    label: 'Punch Out / End',
                                    value: liveRecord?.endTime != null && liveRecord!.endTime!.isNotEmpty
                                        ? liveRecord.endTime!
                                        : (isDayActive ? 'Ongoing' : '--'),
                                    color: const Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildAttendanceInfoTile(
                                    icon: Icons.access_time,
                                    label: 'Total Work Hours',
                                    value: '${liveRecord != null && liveRecord.workHours > 0 ? liveRecord.workHours.toStringAsFixed(1) : (isDayActive ? 'Active' : '0.0')} Hrs',
                                    color: const Color(0xFF0070D2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildAttendanceInfoTile(
                                    icon: Icons.location_on,
                                    label: 'Exact Coordinates',
                                    value: _liveLat != null && _liveLon != null
                                        ? '${_liveLat!.toStringAsFixed(4)}°, ${_liveLon!.toStringAsFixed(4)}°'
                                        : (liveRecord?.geoLocation ?? '19.0760°, 72.8777°'),
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Shift Type & Action Button for Today
                      if (isToday) ...[
                        if (liveRecord?.dayPlan != null) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.badge, size: 16, color: Color(0xFF0B5CAB)),
                                    SizedBox(width: 6),
                                    Text('Start-Day Tour Details (Point 21)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0B5CAB))),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Chip(
                                      visualDensity: VisualDensity.compact,
                                      backgroundColor: Colors.white,
                                      avatar: const Icon(Icons.explore, size: 14, color: Color(0xFF0B5CAB)),
                                      label: Text('Plan: ${liveRecord!.dayPlan}${liveRecord.tourPlan != null ? ' (${liveRecord.tourPlan})' : ''}', style: const TextStyle(fontSize: 11)),
                                    ),
                                    if (liveRecord.modeOfTransport != null)
                                      Chip(
                                        visualDensity: VisualDensity.compact,
                                        backgroundColor: Colors.white,
                                        avatar: const Icon(Icons.directions_car, size: 14, color: Color(0xFF0B5CAB)),
                                        label: Text('Mode: ${liveRecord.modeOfTransport}', style: const TextStyle(fontSize: 11)),
                                      ),
                                    if (liveRecord.vehicleUsed != null)
                                      Chip(
                                        visualDensity: VisualDensity.compact,
                                        backgroundColor: Colors.white,
                                        avatar: const Icon(Icons.person, size: 14, color: Color(0xFF0B5CAB)),
                                        label: Text('Vehicle: ${liveRecord.vehicleUsed}', style: const TextStyle(fontSize: 11)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Shift Type:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF001E3C))),
                            Row(
                              children: [
                                ChoiceChip(
                                  label: const Text('Full Day (₹250 DA)', style: TextStyle(fontSize: 11)),
                                  selected: _selectedDayType == 'FULL_DAY',
                                  selectedColor: const Color(0xFF0070D2),
                                  labelStyle: TextStyle(
                                    color: _selectedDayType == 'FULL_DAY' ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  onSelected: (_) => setState(() => _selectedDayType = 'FULL_DAY'),
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text('Half Day (₹125 DA)', style: TextStyle(fontSize: 11)),
                                  selected: _selectedDayType == 'HALF_DAY',
                                  selectedColor: const Color(0xFF0070D2),
                                  labelStyle: TextStyle(
                                    color: _selectedDayType == 'HALF_DAY' ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  onSelected: (_) => setState(() => _selectedDayType = 'HALF_DAY'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (!isDayActive && !isDayCompleted) ...[
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            onPressed: () {
                              if (widget.dynamicService != null) {
                                StartDayModal.show(
                                  context,
                                  dynamicService: widget.dynamicService!,
                                  syncService: widget.syncService,
                                  authService: widget.authService,
                                  onDayStatusChanged: () {
                                    _fetchAttendanceForSelectedDate(_selectedDate);
                                  },
                                );
                              } else {
                                _handlePunchAction('PUNCH_IN');
                              }
                            },
                            icon: const Icon(Icons.play_circle_fill, size: 22),
                            label: const Text(
                              'START DAY',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              'Point 21: Auto-captures Day Plan, Geolocation & Verification Timestamp',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ),
                        ] else if (isDayActive) ...[
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            onPressed: () {
                              if (widget.dynamicService != null) {
                                showEndDayDialog(
                                  context,
                                  dynamicService: widget.dynamicService!,
                                  syncService: widget.syncService,
                                  authService: widget.authService,
                                  onDayStatusChanged: () {
                                    _fetchAttendanceForSelectedDate(_selectedDate);
                                  },
                                );
                              } else {
                                _handlePunchAction('PUNCH_OUT');
                              }
                            },
                            icon: const Icon(Icons.stop_circle, size: 22),
                            label: const Text(
                              'END DAY',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              'Point 31: Completes Day & captures End-day GPS and Timestamp',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Today\'s attendance is completed and synced to Salesforce.',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    if (widget.dynamicService != null) {
                                      StartDayModal.show(
                                        context,
                                        dynamicService: widget.dynamicService!,
                                        syncService: widget.syncService,
                                        authService: widget.authService,
                                        onDayStatusChanged: () {
                                          _fetchAttendanceForSelectedDate(_selectedDate);
                                        },
                                      );
                                    } else {
                                      _handlePunchAction('PUNCH_IN');
                                    }
                                  },
                                  child: const Text('Re-Punch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ] else ...[
                        // Historical Date View Indicator
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Viewing past record for ${DateFormat('dd MMM').format(_selectedDate)}',
                                style: TextStyle(fontSize: 12, color: Colors.blue.shade900, fontWeight: FontWeight.w500),
                              ),
                              TextButton(
                                onPressed: () => _onDatePicked(DateTime.now()),
                                child: const Text('Back to Today', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 2. COMPACT DATE PICKER & FILTER BAR
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Today', style: TextStyle(fontSize: 11)),
                          selected: isToday,
                          selectedColor: const Color(0xFF0070D2),
                          labelStyle: TextStyle(color: isToday ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                          onSelected: (_) => _onDatePicked(DateTime.now()),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Yesterday', style: TextStyle(fontSize: 11)),
                          selected: isYesterday,
                          selectedColor: const Color(0xFF0070D2),
                          labelStyle: TextStyle(color: isYesterday ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                          onSelected: (_) => _onDatePicked(DateTime.now().subtract(const Duration(days: 1))),
                        ),
                        if (!isToday && !isYesterday) ...[
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text(DateFormat('dd MMM').format(_selectedDate), style: const TextStyle(fontSize: 11)),
                            selected: true,
                            selectedColor: const Color(0xFF0070D2),
                            labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            onSelected: (_) {},
                          ),
                        ],
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_month, color: Color(0xFF0070D2), size: 20),
                      tooltip: 'Pick Date from Calendar',
                      onPressed: _showCalendarPicker,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 3. 30-DAY ATTENDANCE HISTORY FROM SALESFORCE
            if (historyList.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Salesforce Attendance History (30 Days)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF001E3C)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${historyList.length} logs',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                color: Colors.white,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: historyList.length > 5 ? 5 : historyList.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = historyList[index];
                    DateTime? parsedDate = DateTime.tryParse(item.date);
                    final isSelected = parsedDate != null && _isSameDay(parsedDate, _selectedDate);

                    return ListTile(
                      dense: true,
                      selected: isSelected,
                      selectedTileColor: const Color(0xFF0070D2).withOpacity(0.08),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: _getStatusColor(item.status).withOpacity(0.15),
                        child: Icon(
                          item.status.toUpperCase().contains('PRESENT') ? Icons.check : Icons.access_time,
                          size: 16,
                          color: _getStatusColor(item.status),
                        ),
                      ),
                      title: Text(
                        parsedDate != null ? DateFormat('dd MMM yyyy (EEE)').format(parsedDate) : item.date,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: Text(
                        'In: ${item.startTime ?? '--'}  •  Out: ${item.endTime ?? '--'}  •  ${item.workHours.toStringAsFixed(1)} hrs',
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getStatusColor(item.status).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _getStatusColor(item.status).withOpacity(0.3)),
                        ),
                        child: Text(
                          item.status,
                          style: TextStyle(color: _getStatusColor(item.status), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      onTap: () {
                        if (parsedDate != null) {
                          _onDatePicked(parsedDate);
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 4. FIELD TA / DA EXPENSE CLAIM CARD
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Travel & Daily Allowance (TA / DA)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Automated claim based on odometer distance and shift policy', style: TextStyle(fontSize: 11, color: Colors.black54)),
                    const SizedBox(height: 14),

                    // Odometer Readings
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _startKmCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Start KM',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.speed, size: 18),
                            ),
                            onChanged: (_) => _recomputeDistance(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _endKmCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Closing KM',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.flag_outlined, size: 18),
                            ),
                            onChanged: (_) => _recomputeDistance(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Formula Breakdown Pill
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Distance Traveled:', style: TextStyle(fontSize: 12, color: Colors.black87)),
                              Text('${_calculatedDistance.toStringAsFixed(1)} KM', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Travel Allowance (TA @ ₹$kmRate/KM):', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                              Text('₹${ta.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Daily Allowance (DA - $_selectedDayType):', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                              Text('₹${da.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Expense Claim:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                              Text('₹${totalClaim.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0070D2),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(42),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _handleSubmitClaim,
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('Submit TA/DA Claim to Salesforce'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 5. EXPENSE SUBMISSION HISTORY
            if (expenses.isNotEmpty) ...[
              const Text('Recent Expense Submissions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF001E3C))),
              const SizedBox(height: 8),
              ...expenses.map((e) => Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 8),
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF0070D2),
                    child: Icon(Icons.two_wheeler, color: Colors.white, size: 20),
                  ),
                  title: Text('Claim: ₹${e.totalAmount.toStringAsFixed(0)} (${e.dayType})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${DateFormat('dd MMM yyyy').format(e.date)} • ${e.distanceKm.toStringAsFixed(1)} KM traveled'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Text(e.status, style: TextStyle(color: Colors.green.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w500)),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF001E3C)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
