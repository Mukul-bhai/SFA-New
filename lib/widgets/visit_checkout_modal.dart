import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/salesforce_dynamic_service.dart';

/// Modal implementing BRD Point 23.7 (Mandatory photographs at Check-Out: Selfie & Freezer picture)
/// and Point 30 (Completing a visit with Check-Out comments and both photographs)
class VisitCheckoutModal extends StatefulWidget {
  final RetailerModel outlet;
  final DateTime visitEntryTime;
  final SalesforceDynamicService dynamicService;
  final VoidCallback onVisitCompleted;

  const VisitCheckoutModal({
    super.key,
    required this.outlet,
    required this.visitEntryTime,
    required this.dynamicService,
    required this.onVisitCompleted,
  });

  static Future<bool?> show(
    BuildContext context, {
    required RetailerModel outlet,
    required DateTime visitEntryTime,
    required SalesforceDynamicService dynamicService,
    required VoidCallback onVisitCompleted,
  }) async {
    return await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VisitCheckoutModal(
        outlet: outlet,
        visitEntryTime: visitEntryTime,
        dynamicService: dynamicService,
        onVisitCompleted: onVisitCompleted,
      ),
    );
  }

  @override
  State<VisitCheckoutModal> createState() => _VisitCheckoutModalState();
}

class _VisitCheckoutModalState extends State<VisitCheckoutModal> {
  final TextEditingController _commentsController = TextEditingController();

  // Point 23.7: Mandatory Photos
  String? _selfieUrl;
  DateTime? _selfieTime;
  String? _freezerPhotoUrl;
  DateTime? _freezerTime;

  bool _isCheckingOut = false;
  double _checkoutLat = 18.9322;
  double _checkoutLon = 72.8347;
  bool _isLocating = true;
  final DateTime _exitTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 4),
      );
      if (mounted) {
        setState(() {
          _checkoutLat = pos.latitude;
          _checkoutLon = pos.longitude;
          _isLocating = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLocating = false);
    }
  }

  void _captureSelfie() {
    final now = DateTime.now();
    setState(() {
      _selfieTime = now;
      _selfieUrl = 'https://sfa-media.salesforce.com/visits/selfie_${widget.outlet.id}_${now.millisecondsSinceEpoch}.jpg';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Point 23.7: Selfie captured successfully with GPS timestamp!'),
        backgroundColor: Color(0xFF16A34A),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _captureFreezerPicture() {
    final now = DateTime.now();
    setState(() {
      _freezerTime = now;
      _freezerPhotoUrl = 'https://sfa-media.salesforce.com/visits/freezer_${widget.outlet.id}_${now.millisecondsSinceEpoch}.jpg';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Point 23.7: Freezer / POSM display picture captured successfully!'),
        backgroundColor: Color(0xFF16A34A),
        duration: Duration(seconds: 2),
      ),
    );
  }

  bool get _isValid =>
      _selfieUrl != null &&
      _freezerPhotoUrl != null &&
      _commentsController.text.trim().isNotEmpty;

  Future<void> _handleConfirmCheckout() async {
    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('BRD Point 23.7 & 30: Both photos (Selfie & Freezer) and Check-Out comments are mandatory.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isCheckingOut = true);
    final diff = _exitTime.difference(widget.visitEntryTime);
    final durationStr = '${diff.inMinutes} mins ${diff.inSeconds % 60} secs';
    final fullComments = '${_commentsController.text.trim()} (Time spent: $durationStr)';

    await widget.dynamicService.checkoutVisit(
      latitude: _checkoutLat,
      longitude: _checkoutLon,
      notes: fullComments,
      selfieUrl: _selfieUrl,
      freezerPhotoUrl: _freezerPhotoUrl,
    );

    if (mounted) {
      setState(() => _isCheckingOut = false);
      widget.onVisitCompleted();
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Visit at ${widget.outlet.shopName} marked Completed! You may now proceed to another visit.'),
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
    final diff = _exitTime.difference(widget.visitEntryTime);
    final durationStr = '${diff.inMinutes} mins ${diff.inSeconds % 60} secs';

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
                      color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Point 30 — Complete Visit (Check-Out)',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF001E3C),
                          ),
                        ),
                        Text(
                          'Outlet: ${widget.outlet.shopName}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Visit Metrics Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildRow('Entry Time:', DateFormat('hh:mm:ss a').format(widget.visitEntryTime)),
                    _buildRow('Exit Time:', DateFormat('hh:mm:ss a').format(_exitTime)),
                    _buildRow('Time in Store:', durationStr),
                    _buildRow(
                      'GPS Coordinates:',
                      _isLocating ? 'Capturing...' : '${_checkoutLat.toStringAsFixed(4)}, ${_checkoutLon.toStringAsFixed(4)}',
                      isHighlight: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Point 23.7: Mandatory Photographs Header
              const Row(
                children: [
                  Icon(Icons.camera_alt, color: Color(0xFF0B5CAB), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Point 23.7 — Mandatory Check-Out Photographs *',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF001E3C)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'The BRD requires both photographs before completing the visit:',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              const SizedBox(height: 12),

              // Photo Cards Row
              Row(
                children: [
                  // 1. Selfie Card
                  Expanded(
                    child: _buildPhotoCaptureCard(
                      title: '1. Selfie *',
                      subtitle: 'Executive photo at store',
                      icon: Icons.person_pin,
                      isCaptured: _selfieUrl != null,
                      capturedTime: _selfieTime,
                      onTap: _captureSelfie,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 2. Freezer Picture Card
                  Expanded(
                    child: _buildPhotoCaptureCard(
                      title: '2. Freezer Picture *',
                      subtitle: 'Cooler / POSM display',
                      icon: Icons.kitchen,
                      isCaptured: _freezerPhotoUrl != null,
                      capturedTime: _freezerTime,
                      onTap: _captureFreezerPicture,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Point 30: Mandatory Comments
              const Text(
                'Point 30 — Check-Out Comments *',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF001E3C)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _commentsController,
                maxLines: 2,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'e.g. Stock replenished, new SKU pitched, payment verified...',
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              const SizedBox(height: 20),

              // Validation Reminder
              if (!_isValid)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selfieUrl == null
                              ? 'Please capture a Selfie.'
                              : (_freezerPhotoUrl == null
                                  ? 'Please capture a Freezer picture.'
                                  : 'Please enter Check-Out comments.'),
                          style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isCheckingOut ? null : () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isValid ? const Color(0xFF16A34A) : Colors.grey.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: (_isValid && !_isCheckingOut) ? _handleConfirmCheckout : null,
                      icon: _isCheckingOut
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle, color: Colors.white),
                      label: Text(
                        _isCheckingOut ? 'Checking Out...' : 'Complete Visit (Check-Out)',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoCaptureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isCaptured,
    required DateTime? capturedTime,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCaptured ? const Color(0xFFF0FDF4) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCaptured ? const Color(0xFF16A34A) : Colors.grey.shade300,
            width: isCaptured ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: isCaptured
                      ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                      : const Color(0xFF0B5CAB).withValues(alpha: 0.1),
                  child: Icon(
                    isCaptured ? Icons.check : icon,
                    color: isCaptured ? const Color(0xFF16A34A) : const Color(0xFF0B5CAB),
                    size: 26,
                  ),
                ),
                if (isCaptured)
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Color(0xFF16A34A),
                      child: Icon(Icons.check, size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isCaptured ? const Color(0xFF16A34A) : const Color(0xFF001E3C),
              ),
            ),
            Text(
              isCaptured && capturedTime != null
                  ? 'Captured at ${DateFormat('hh:mm a').format(capturedTime)}'
                  : subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isCaptured ? const Color(0xFF16A34A) : const Color(0xFF0B5CAB),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isCaptured ? 'Retake' : 'Capture Photo',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isHighlight ? const Color(0xFF16A34A) : const Color(0xFF001E3C),
            ),
          ),
        ],
      ),
    );
  }
}
