import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/salesforce_dynamic_service.dart';
import 'visit_hub_screen.dart';

class OutletDetailScreen extends StatefulWidget {
  final RetailerModel outlet;
  final String beatName;
  final SalesforceDynamicService dynamicService;

  const OutletDetailScreen({
    super.key,
    required this.outlet,
    required this.beatName,
    required this.dynamicService,
  });

  @override
  State<OutletDetailScreen> createState() => _OutletDetailScreenState();
}

class _OutletDetailScreenState extends State<OutletDetailScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 0);
  
  double _userLat = 18.9322;
  double _userLon = 72.8347;
  double _distanceMeters = 0.0;
  bool _isLoadingGps = true;
  bool _isActionProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentGpsAndDistance();
  }

  Future<void> _fetchCurrentGpsAndDistance() async {
    setState(() => _isLoadingGps = true);
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
            _userLat = lastPos.latitude;
            _userLon = lastPos.longitude;
            _distanceMeters = widget.outlet.distanceInMetersTo(_userLat, _userLon);
            if (mounted) setState(() {});
          }
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 8),
          );
          _userLat = pos.latitude;
          _userLon = pos.longitude;
        }
      }
    } catch (_) {
      // Fallback
    }

    // Calculate distance to shop
    _distanceMeters = widget.outlet.distanceInMetersTo(_userLat, _userLon);
    if (mounted) {
      setState(() => _isLoadingGps = false);
    }
  }

  /// Handle "Start Visit Store" with 100m Geofencing Enforcement
  Future<void> _handleStartVisit() async {
    final double allowedRadius = widget.dynamicService.metadata.geofenceRadiusMeters;
    final bool isOutside100m = _distanceMeters > allowedRadius;

    String bypassReason = '';

    if (isOutside100m) {
      // Prompt Mandatory Bypass Reason
      final selectedReason = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          String? chosen = widget.dynamicService.metadata.geofenceBypassReasons.first;
          return StatefulBuilder(
            builder: (context, setModalState) {
              return AlertDialog(
                title: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                    const SizedBox(width: 8),
                    const Text('100m Geofence Alert', style: TextStyle(fontSize: 16)),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You are ${_distanceMeters.toStringAsFixed(0)}m away from this outlet (allowed: ${allowedRadius.toInt()}m).',
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Please select a mandatory bypass reason to proceed:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: chosen,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: widget.dynamicService.metadata.geofenceBypassReasons.map((r) {
                        return DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => chosen = val);
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B5CAB)),
                    onPressed: () => Navigator.pop(ctx, chosen),
                    child: const Text('Authorize & Start', style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          );
        },
      );

      if (selectedReason == null) return;
      bypassReason = selectedReason;
    }

    setState(() => _isActionProcessing = true);
    final res = await widget.dynamicService.startVisit(
      outlet: widget.outlet,
      latitude: _userLat,
      longitude: _userLon,
      bypassReason: bypassReason,
    );
    setState(() => _isActionProcessing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Visit started'), backgroundColor: Colors.green),
      );
      // Navigate to Visit Hub
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VisitHubScreen(
            outlet: widget.outlet,
            beatName: widget.beatName,
            dynamicService: widget.dynamicService,
            entryTime: DateTime.now(),
            entryLat: _userLat,
            entryLon: _userLon,
          ),
        ),
      );
    }
  }

  /// Handle "Missed Visit" with mandatory reason
  Future<void> _handleMissedVisit() async {
    final missedReasons = widget.dynamicService.metadata.missedVisitReasons;
    final notesController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        String chosenReason = missedReasons.first;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Log Missed Visit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select mandatory reason why visit was not completed:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: chosenReason,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: missedReasons.map((r) {
                        return DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => chosenReason = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'Additional Remarks (Optional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                  onPressed: () => Navigator.pop(ctx, {'reason': chosenReason, 'notes': notesController.text}),
                  child: const Text('Submit Missed Record', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _isActionProcessing = true);
      final res = await widget.dynamicService.markVisitMissed(
        outlet: widget.outlet,
        reason: result['reason']!,
        notes: result['notes']!,
      );
      setState(() => _isActionProcessing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Missed visit recorded'), backgroundColor: Colors.orange.shade800),
        );
        Navigator.pop(context);
      }
    }
  }

  /// Handle "Customer Leave / Shop Closure"
  Future<void> _handleCustomerLeave() async {
    final leaveTypes = [
      'Customer / Shop Closed',
      'Retailer Vacation',
      'Shop Renovation',
      'Festival / Holiday',
      'Other',
    ];
    String chosenType = leaveTypes.first;
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now();
    final reasonCtrl = TextEditingController(text: 'Shop closed upon visit');

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final days = endDate.difference(startDate).inDays + 1;
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.event_busy, color: Color(0xFF0B5CAB), size: 22),
                  SizedBox(width: 8),
                  Text('Customer Leave / Closure', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Record temporary shop closure for ${widget.outlet.shopName} to update route planning.',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    const Text('Closure Reason', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: chosenType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: leaveTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => chosenType = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Dates & Duration', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now().subtract(const Duration(days: 3)),
                          lastDate: DateTime.now().add(const Duration(days: 60)),
                          initialDateRange: DateTimeRange(start: startDate, end: endDate),
                        );
                        if (picked != null) {
                          setModalState(() {
                            startDate = picked.start;
                            endDate = picked.end;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month, size: 18, color: Color(0xFF0B5CAB)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${DateFormat('dd MMM').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)} ($days ${days == 1 ? 'day' : 'days'})',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonCtrl,
                      decoration: InputDecoration(
                        labelText: 'Details / Remark',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B5CAB)),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Submit to Salesforce', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      setState(() => _isActionProcessing = true);
      final totalDays = (endDate.difference(startDate).inDays + 1).toDouble();
      final res = await widget.dynamicService.submitLeaveRequest(
        leaveCategory: 'Customer / Retailer Leave',
        leaveType: chosenType,
        outletId: widget.outlet.id,
        outletName: widget.outlet.shopName,
        beatName: widget.beatName,
        startDate: startDate,
        endDate: endDate,
        totalDays: totalDays,
        reason: reasonCtrl.text.trim(),
      );
      setState(() => _isActionProcessing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Customer leave recorded in Salesforce.'),
            backgroundColor: const Color(0xFF107C41),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOrderBlocked = widget.outlet.isOrderBlockedDueToCredit;
    final bool isInside100m = _distanceMeters <= widget.dynamicService.metadata.geofenceRadiusMeters;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(widget.outlet.shopName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0B5CAB),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCurrentGpsAndDistance,
            tooltip: 'Re-scan GPS',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. 100m Geofence Radar Card
            _buildGeofenceRadarCard(isInside100m),

            const SizedBox(height: 14),

            // 2. Shop 360° Profile Card
            _buildShopProfileCard(),

            const SizedBox(height: 14),

            // 3. Outstanding Amount vs Credit Limit Gatekeeper
            _buildCreditGatekeeperCard(isOrderBlocked),

            const SizedBox(height: 14),

            // 4. Previous Orders Section
            _buildPreviousOrdersCard(),

            const SizedBox(height: 24),

            // 5. Action Buttons (Start Visit / Missed Visit)
            _buildActionButtons(isOrderBlocked),
          ],
        ),
      ),
    );
  }

  Widget _buildGeofenceRadarCard(bool isInside100m) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isInside100m ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isInside100m ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isInside100m ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isInside100m ? Icons.location_on : Icons.location_off,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isInside100m ? '100m Geofence: VERIFIED' : '100m Geofence: OUT OF RANGE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isInside100m ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                      ),
                    ),
                    Text(
                      _isLoadingGps ? 'Pinging GPS...' : '${_distanceMeters.toStringAsFixed(0)}m',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isInside100m ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isInside100m
                      ? 'Executive is physically within the 100m store perimeter.'
                      : 'Executive is >100m away. Bypass authorization reason will be required.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isInside100m ? Colors.green.shade800 : Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'GPS: ${_userLat.toStringAsFixed(4)}, ${_userLon.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w600),
                    ),
                    InkWell(
                      onTap: _isLoadingGps ? null : _fetchCurrentGpsAndDistance,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          children: [
                            Icon(Icons.refresh, size: 13, color: Colors.blue.shade700),
                            const SizedBox(width: 2),
                            Text(
                              'Refresh GPS',
                              style: TextStyle(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.outlet.shopName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.outlet.code,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0B5CAB)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.person, 'Contact Person', widget.outlet.name),
          _buildInfoRow(Icons.phone, 'Phone Number', widget.outlet.phone),
          _buildInfoRow(Icons.place, 'Address', widget.outlet.address),
          _buildInfoRow(Icons.local_shipping, 'Fulfillment Dist.', widget.outlet.primaryDistributorName),
          _buildInfoRow(Icons.alt_route, 'Assigned Beat', widget.beatName),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF37474F))),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditGatekeeperCard(bool isOrderBlocked) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOrderBlocked ? Colors.red.shade400 : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Financial & Credit Standing', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF263238))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOrderBlocked ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isOrderBlocked ? 'CREDIT HOLD' : 'CREDIT OK',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isOrderBlocked ? Colors.red.shade700 : Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Outstanding Balance', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(
                    currencyFormat.format(widget.outlet.outstandingBalance),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isOrderBlocked ? Colors.red.shade700 : const Color(0xFF263238),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Sanctioned Credit Limit', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(
                    currencyFormat.format(widget.outlet.creditLimit),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF546E7A)),
                  ),
                ],
              ),
            ],
          ),

          if (isOrderBlocked) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.block, size: 18, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Order taking restricted: Outstanding balance exceeds credit limit! Executive must collect payment before placing fresh orders.',
                      style: TextStyle(fontSize: 11, color: Colors.red.shade900, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviousOrdersCard() {
    final prevOrders = widget.outlet.previousOrders;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Past Order History', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF263238))),
              Text('${prevOrders.length} Orders', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),

          if (prevOrders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text('No previous orders found for this outlet.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: prevOrders.length,
              separatorBuilder: (_, index) => const Divider(height: 16),
              itemBuilder: (context, idx) {
                final ord = prevOrders[idx];
                final dateStr = DateFormat('dd MMM yyyy').format(ord.orderDate);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ord.orderNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0B5CAB))),
                        Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(currencyFormat.format(ord.totalAmount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF263238))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ord.status == 'Delivered' ? Colors.green.shade50 : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            ord.status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: ord.status == 'Delivered' ? Colors.green.shade700 : Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isOrderBlocked) {
    return Column(
      children: [
        // Start Visit Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isActionProcessing ? null : _handleStartVisit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B5CAB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isActionProcessing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.storefront, color: Colors.white),
            label: const Text('Start Visit Store', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),

        const SizedBox(height: 12),

        // Missed Visit Button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: _isActionProcessing ? null : _handleMissedVisit,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade400),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('Mark as Missed Visit (Reason Required)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ),

        const SizedBox(height: 10),

        // Customer Leave / Shop Closure Button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: _isActionProcessing ? null : _handleCustomerLeave,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0B5CAB),
              side: const BorderSide(color: Color(0xFF0B5CAB)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.event_busy, size: 18),
            label: const Text('Report Customer Leave / Shop Closed', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
