import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/salesforce_dynamic_service.dart';

class SupportTicketsScreen extends StatefulWidget {
  final SalesforceDynamicService dynamicService;

  const SupportTicketsScreen({
    super.key,
    required this.dynamicService,
  });

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Grievance / Ticket fields
  PjpModel? _selectedPjp;
  BeatModel? _selectedBeat;
  RetailerModel? _selectedOutlet;
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  String _selectedPriority = 'Medium';
  bool _isSubmittingTicket = false;

  // Leave / Shop Closure fields
  String _leaveCategory = 'Customer / Retailer Leave';
  String? _selectedLeaveType;
  PjpModel? _selectedLeavePjp;
  BeatModel? _selectedLeaveBeat;
  RetailerModel? _selectedLeaveOutlet;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  final _leaveReasonController = TextEditingController();
  bool _isSubmittingLeave = false;
  bool _isRefreshingLeaves = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final pjps = widget.dynamicService.pjps;
    if (pjps.isNotEmpty) {
      _selectedPjp = pjps.first;
      _selectedLeavePjp = pjps.first;
      if (_selectedPjp!.beats.isNotEmpty) {
        _selectedBeat = _selectedPjp!.beats.first;
        _selectedLeaveBeat = _selectedLeavePjp!.beats.first;
        if (_selectedBeat!.retailers.isNotEmpty) {
          _selectedOutlet = _selectedBeat!.retailers.first;
          _selectedLeaveOutlet = _selectedLeaveBeat!.retailers.first;
        }
      }
    }

    _refreshLeaves();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    _leaveReasonController.dispose();
    super.dispose();
  }

  Future<void> _refreshLeaves() async {
    setState(() => _isRefreshingLeaves = true);
    await widget.dynamicService.fetchLeaves();
    if (mounted) {
      setState(() => _isRefreshingLeaves = false);
    }
  }

  Future<void> _handleSubmitTicket() async {
    if (_selectedOutlet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an outlet for the ticket')),
      );
      return;
    }
    if (_subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an issue subject')),
      );
      return;
    }

    setState(() => _isSubmittingTicket = true);

    final category = _selectedCategory ??
        (widget.dynamicService.metadata.ticketCategories.isNotEmpty
            ? widget.dynamicService.metadata.ticketCategories.first
            : 'Billing & Invoice');

    final res = await widget.dynamicService.createSupportTicket(
      outletId: _selectedOutlet!.id,
      category: category,
      priority: _selectedPriority,
      subject: _subjectController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    setState(() => _isSubmittingTicket = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Ticket created successfully!'),
          backgroundColor: const Color(0xFF107C41),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _subjectController.clear();
      _descriptionController.clear();
      setState(() {});
    }
  }

  Future<void> _handleSubmitLeave() async {
    final isCustomerLeave = _leaveCategory == 'Customer / Retailer Leave';
    if (isCustomerLeave && _selectedLeaveOutlet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an outlet for customer shop closure / leave')),
      );
      return;
    }
    if (_leaveReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter reason / justification for leave')),
      );
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date cannot be earlier than start date')),
      );
      return;
    }

    setState(() => _isSubmittingLeave = true);

    final leaveType = _selectedLeaveType ??
        (isCustomerLeave ? 'Customer / Shop Closed' : 'Casual Leave');

    final totalDays = (_endDate.difference(_startDate).inDays + 1).toDouble();

    final res = await widget.dynamicService.submitLeaveRequest(
      leaveCategory: _leaveCategory,
      leaveType: leaveType,
      outletId: isCustomerLeave ? _selectedLeaveOutlet?.id : null,
      outletName: isCustomerLeave ? _selectedLeaveOutlet?.shopName : null,
      beatId: isCustomerLeave ? _selectedLeaveBeat?.id : null,
      beatName: isCustomerLeave ? _selectedLeaveBeat?.name : null,
      startDate: _startDate,
      endDate: _endDate,
      totalDays: totalDays,
      reason: _leaveReasonController.text.trim(),
    );

    setState(() => _isSubmittingLeave = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Leave request submitted successfully!'),
          backgroundColor: const Color(0xFF107C41),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _leaveReasonController.clear();
      setState(() {});
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF0B5CAB),
            colorScheme: const ColorScheme.light(primary: Color(0xFF0B5CAB)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'Support & Leave Center',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0B5CAB),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.headset_mic_outlined), text: 'Store Grievances'),
            Tab(icon: Icon(Icons.event_busy_outlined), text: 'Leave & Closures'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGrievancesTab(),
          _buildLeavesTab(),
        ],
      ),
    );
  }

  // TAB 1: Support Tickets / Grievances
  Widget _buildGrievancesTab() {
    final categories = widget.dynamicService.metadata.ticketCategories;
    final priorities = widget.dynamicService.metadata.ticketPriorities;
    final rawPjps = widget.dynamicService.pjps;
    final Map<String, PjpModel> pjpMap = {};
    for (var p in rawPjps) {
      if (p.id.isNotEmpty) pjpMap[p.id] = p;
    }
    final pjps = pjpMap.values.toList();

    final PjpModel? currentPjp = pjps.isNotEmpty
        ? (pjps.any((p) => p.id == _selectedPjp?.id)
            ? pjps.firstWhere((p) => p.id == _selectedPjp?.id)
            : pjps.first)
        : null;

    final rawBeats = currentPjp?.beats ?? [];
    final Map<String, BeatModel> beatMap = {};
    for (var b in rawBeats) {
      if (b.id.isNotEmpty) beatMap[b.id] = b;
    }
    final availableBeats = beatMap.values.toList();

    final BeatModel? currentBeat = availableBeats.isNotEmpty
        ? (availableBeats.any((b) => b.id == _selectedBeat?.id)
            ? availableBeats.firstWhere((b) => b.id == _selectedBeat?.id)
            : availableBeats.first)
        : null;

    final rawOutlets = currentBeat?.retailers ?? [];
    final Map<String, RetailerModel> outletMap = {};
    for (var o in rawOutlets) {
      if (o.id.isNotEmpty) outletMap[o.id] = o;
    }
    final availableOutlets = outletMap.values.toList();

    final RetailerModel? currentOutlet = availableOutlets.isNotEmpty
        ? (availableOutlets.any((o) => o.id == _selectedOutlet?.id)
            ? availableOutlets.firstWhere((o) => o.id == _selectedOutlet?.id)
            : availableOutlets.first)
        : null;

    final tickets = widget.dynamicService.tickets;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF90CAF9)),
            ),
            child: const Row(
              children: [
                Icon(Icons.headset_mic, color: Color(0xFF0B5CAB), size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Raise dealer/retailer disputes and operational issues directly into Salesforce Support Cloud.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF0D47A1)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
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
                const Text('Raise Grievance for Outlet',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF263238))),
                const SizedBox(height: 14),
                const Text('1. Select Journey Plan (PJP)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                DropdownButtonFormField<PjpModel>(
                  isExpanded: true,
                  value: currentPjp,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: pjps
                      .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.name,
                              style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedPjp = val;
                      _selectedBeat = val?.beats.isNotEmpty == true ? val!.beats.first : null;
                      _selectedOutlet =
                          _selectedBeat?.retailers.isNotEmpty == true ? _selectedBeat!.retailers.first : null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                const Text('2. Select Route Beat',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                DropdownButtonFormField<BeatModel>(
                  isExpanded: true,
                  value: currentBeat,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: availableBeats
                      .map((b) => DropdownMenuItem(
                          value: b,
                          child: Text(b.name,
                              style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedBeat = val;
                      _selectedOutlet =
                          val?.retailers.isNotEmpty == true ? val!.retailers.first : null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                const Text('3. Select Outlet / Shop',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                DropdownButtonFormField<RetailerModel>(
                  isExpanded: true,
                  value: currentOutlet,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: availableOutlets
                      .map((o) => DropdownMenuItem(
                          value: o,
                          child: Text('${o.shopName} (${o.code})',
                              style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedOutlet = val),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Category',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _selectedCategory ??
                                (categories.isNotEmpty ? categories.first : 'Billing & Invoice'),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            items: categories
                                .map((c) =>
                                    DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12))))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedCategory = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Priority',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _selectedPriority,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            items: priorities
                                .map((p) =>
                                    DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 12))))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedPriority = v ?? 'Medium'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    labelText: 'Issue Subject (Brief summary)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Detailed Description of Complaint',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmittingTicket ? null : _handleSubmitTicket,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B5CAB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: _isSubmittingTicket
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, color: Colors.white),
                    label: const Text('Submit Ticket to Salesforce',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Recent Support Tickets',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF263238))),
          const SizedBox(height: 10),
          if (tickets.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const Center(
                child: Text('No active support tickets logged yet.',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tickets.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final t = tickets[idx];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(t.ticketNumber,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0B5CAB))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(t.status,
                                style: const TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(t.subject, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('${t.category} • Priority: ${t.priority}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      if (t.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(t.description,
                            style: const TextStyle(fontSize: 11, color: Colors.black87),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // TAB 2: Leave & Shop Closures
  Widget _buildLeavesTab() {
    final isCustomerLeave = _leaveCategory == 'Customer / Retailer Leave';
    final rawPjps = widget.dynamicService.pjps;
    final Map<String, PjpModel> pjpMap = {};
    for (var p in rawPjps) {
      if (p.id.isNotEmpty) pjpMap[p.id] = p;
    }
    final pjps = pjpMap.values.toList();

    final PjpModel? currentLeavePjp = pjps.isNotEmpty
        ? (pjps.any((p) => p.id == _selectedLeavePjp?.id)
            ? pjps.firstWhere((p) => p.id == _selectedLeavePjp?.id)
            : pjps.first)
        : null;

    final rawBeats = currentLeavePjp?.beats ?? [];
    final Map<String, BeatModel> beatMap = {};
    for (var b in rawBeats) {
      if (b.id.isNotEmpty) beatMap[b.id] = b;
    }
    final availableBeats = beatMap.values.toList();

    final BeatModel? currentLeaveBeat = availableBeats.isNotEmpty
        ? (availableBeats.any((b) => b.id == _selectedLeaveBeat?.id)
            ? availableBeats.firstWhere((b) => b.id == _selectedLeaveBeat?.id)
            : availableBeats.first)
        : null;

    final rawOutlets = currentLeaveBeat?.retailers ?? [];
    final Map<String, RetailerModel> outletMap = {};
    for (var o in rawOutlets) {
      if (o.id.isNotEmpty) outletMap[o.id] = o;
    }
    final availableOutlets = outletMap.values.toList();

    final RetailerModel? currentLeaveOutlet = availableOutlets.isNotEmpty
        ? (availableOutlets.any((o) => o.id == _selectedLeaveOutlet?.id)
            ? availableOutlets.firstWhere((o) => o.id == _selectedLeaveOutlet?.id)
            : availableOutlets.first)
        : null;

    final leaves = widget.dynamicService.leaves;
    final daysCount = _endDate.difference(_startDate).inDays + 1;

    final customerLeaveTypes = [
      'Customer / Shop Closed',
      'Retailer Vacation',
      'Shop Renovation',
      'Festival / Holiday',
      'Other',
    ];
    final executiveLeaveTypes = [
      'Casual Leave',
      'Sick Leave',
      'Annual Leave',
      'Half Day',
      'Other',
    ];
    final activeTypesList = isCustomerLeave ? customerLeaveTypes : executiveLeaveTypes;

    return RefreshIndicator(
      onRefresh: _refreshLeaves,
      color: const Color(0xFF0B5CAB),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Context Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Row(
                children: [
                  Icon(isCustomerLeave ? Icons.store_mall_directory : Icons.person_off,
                      color: const Color(0xFFF57F17), size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Record retailer shop closures to bypass visits cleanly, or submit sales executive leave directly to Salesforce.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF795548)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Form Card
            Container(
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
                  const Text('New Leave / Closure Application',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF263238))),
                  const SizedBox(height: 14),

                  // Category Selector: Customer vs Executive
                  const Text('Leave Category',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _leaveCategory = 'Customer / Retailer Leave';
                              _selectedLeaveType = customerLeaveTypes.first;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              color: isCustomerLeave ? const Color(0xFFE3F2FD) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: isCustomerLeave ? const Color(0xFF0B5CAB) : Colors.grey.shade300,
                                  width: isCustomerLeave ? 2 : 1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.store,
                                    size: 16,
                                    color: isCustomerLeave ? const Color(0xFF0B5CAB) : Colors.grey.shade700),
                                const SizedBox(width: 6),
                                Text(
                                  'Customer / Shop',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isCustomerLeave ? FontWeight.bold : FontWeight.normal,
                                    color: isCustomerLeave ? const Color(0xFF0B5CAB) : Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _leaveCategory = 'Sales Executive Leave';
                              _selectedLeaveType = executiveLeaveTypes.first;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              color: !isCustomerLeave ? const Color(0xFFF3E5F5) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: !isCustomerLeave ? Colors.purple.shade700 : Colors.grey.shade300,
                                  width: !isCustomerLeave ? 2 : 1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person,
                                    size: 16,
                                    color: !isCustomerLeave ? Colors.purple.shade700 : Colors.grey.shade700),
                                const SizedBox(width: 6),
                                Text(
                                  'Sales Executive',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: !isCustomerLeave ? FontWeight.bold : FontWeight.normal,
                                    color: !isCustomerLeave ? Colors.purple.shade700 : Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // If Customer Leave: Cascading PJP -> Beat -> Outlet
                  if (isCustomerLeave) ...[
                    const Text('1. Journey Plan (PJP)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<PjpModel>(
                      isExpanded: true,
                      value: currentLeavePjp,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: pjps
                          .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.name,
                                  style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedLeavePjp = val;
                          _selectedLeaveBeat = val?.beats.isNotEmpty == true ? val!.beats.first : null;
                          _selectedLeaveOutlet =
                              _selectedLeaveBeat?.retailers.isNotEmpty == true
                                  ? _selectedLeaveBeat!.retailers.first
                                  : null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('2. Route Beat',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<BeatModel>(
                      isExpanded: true,
                      value: currentLeaveBeat,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: availableBeats
                          .map((b) => DropdownMenuItem(
                              value: b,
                              child: Text(b.name,
                                  style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedLeaveBeat = val;
                          _selectedLeaveOutlet =
                              val?.retailers.isNotEmpty == true ? val!.retailers.first : null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('3. Outlet / Customer',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<RetailerModel>(
                      isExpanded: true,
                      value: currentLeaveOutlet,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: availableOutlets
                          .map((o) => DropdownMenuItem(
                              value: o,
                              child: Text('${o.shopName} (${o.code})',
                                  style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedLeaveOutlet = val),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Leave Type
                  Text(isCustomerLeave ? 'Closure Reason Type' : 'Leave Type',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedLeaveType ?? activeTypesList.first,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: activeTypesList
                        .map((t) =>
                            DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedLeaveType = v),
                  ),
                  const SizedBox(height: 14),

                  // Date Range Picker
                  const Text('Duration & Date Range',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _pickDateRange,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.date_range, color: Color(0xFF0B5CAB), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${DateFormat('dd MMM yyyy').format(_startDate)}  ➔  ${DateFormat('dd MMM yyyy').format(_endDate)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$daysCount ${daysCount == 1 ? 'Day' : 'Days'}',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Reason Controller
                  TextField(
                    controller: _leaveReasonController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: isCustomerLeave ? 'Reason for Shop Closure' : 'Reason for Executive Leave',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmittingLeave ? null : _handleSubmitLeave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCustomerLeave ? const Color(0xFF0B5CAB) : Colors.purple.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: _isSubmittingLeave
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send, color: Colors.white),
                      label: Text(
                        isCustomerLeave ? 'Submit Customer Leave Request' : 'Submit Executive Leave Request',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Records from Salesforce
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Live Leave & Closures History',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF263238))),
                IconButton(
                  onPressed: _isRefreshingLeaves ? null : _refreshLeaves,
                  icon: _isRefreshingLeaves
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh, size: 20, color: Color(0xFF0B5CAB)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (leaves.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const Center(
                  child: Text('No leave or shop closure records found in Salesforce.',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: leaves.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final l = leaves[idx];
                  final isCustomer = l.leaveCategory == 'Customer / Retailer Leave';

                  Color statusColor = const Color(0xFFF57F17);
                  Color statusBg = const Color(0xFFFFF8E1);
                  if (l.status == 'Approved') {
                    statusColor = const Color(0xFF2E7D32);
                    statusBg = const Color(0xFFE8F5E9);
                  } else if (l.status == 'Rejected') {
                    statusColor = Colors.red.shade700;
                    statusBg = Colors.red.shade50;
                  }

                  final startStr = l.startDate != null ? DateFormat('dd MMM yyyy').format(l.startDate!) : 'N/A';
                  final endStr = l.endDate != null ? DateFormat('dd MMM yyyy').format(l.endDate!) : 'N/A';

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
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
                            Text(l.name,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0B5CAB))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l.status,
                                style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isCustomer ? const Color(0xFFE3F2FD) : const Color(0xFFF3E5F5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isCustomer ? 'Customer Closure' : 'Executive Leave',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isCustomer ? const Color(0xFF0B5CAB) : Colors.purple.shade800),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l.leaveType,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (isCustomer && l.outletName != null && l.outletName!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.storefront, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${l.outletName}${l.beatName != null && l.beatName!.isNotEmpty ? ' (${l.beatName})' : ''}',
                                  style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF37474F)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '$startStr  ➔  $endStr  (${l.totalDays.toInt()} ${l.totalDays.toInt() == 1 ? 'Day' : 'Days'})',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        if (l.reason.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            l.reason,
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
