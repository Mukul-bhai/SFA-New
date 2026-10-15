import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/order_sharing_service.dart';
import '../services/salesforce_dynamic_service.dart';
import '../widgets/visit_checkout_modal.dart';
import '../widgets/must_sell_reason_modal.dart';

class VisitHubScreen extends StatefulWidget {
  final RetailerModel outlet;
  final String beatName;
  final SalesforceDynamicService dynamicService;
  final DateTime? entryTime;
  final double? entryLat;
  final double? entryLon;

  const VisitHubScreen({
    super.key,
    required this.outlet,
    required this.beatName,
    required this.dynamicService,
    this.entryTime,
    this.entryLat,
    this.entryLon,
  });

  @override
  State<VisitHubScreen> createState() => _VisitHubScreenState();
}

class _VisitHubScreenState extends State<VisitHubScreen> with SingleTickerProviderStateMixin {
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2);
  late TabController _tabController;

  // Visit Timing & GPS
  late DateTime _visitEntryTime;
  double _currentLat = 19.0760;
  double _currentLon = 72.8777;
  Timer? _durationTimer;
  String _elapsedDurationStr = '00:00';

  // Region-wise product configuration state
  late String _activeRegion;
  String _selectedSellFilter = 'All'; // 'All', 'Must Sell', 'Focused Sell', 'Suggested Sell'

  // Order Cart state
  final Map<String, int> _cartQuantities = {};
  bool _isSubmittingOrder = false;
  String? _lastSubmittedOrderNumber;
  List<OrderItemModel>? _lastSubmittedItems;
  double _lastOrderSubTotal = 0;
  double _lastOrderTax = 0;
  double _lastOrderDiscount = 0;
  double _lastOrderTotal = 0;

  // In-visit forms
  final _compBrandController = TextEditingController();
  final _compProductController = TextEditingController();
  final _compPriceController = TextEditingController();
  final _compSchemeController = TextEditingController();
  final _compNotesController = TextEditingController();
  double _shelfShare = 20.0;

  final _returnBatchController = TextEditingController();
  final _returnQtyController = TextEditingController();
  String? _selectedReturnReason;
  String? _selectedReturnProductId;

  @override
  void initState() {
    super.initState();
    _activeRegion = widget.outlet.state.isNotEmpty ? widget.outlet.state : 'Madhya Pradesh';
    _tabController = TabController(length: 4, vsync: this);
    _visitEntryTime = widget.entryTime ?? widget.dynamicService.visitStartTime ?? DateTime.now();
    _currentLat = widget.entryLat ?? widget.outlet.latitude;
    _currentLon = widget.entryLon ?? widget.outlet.longitude;
    _startDurationTimer();
    _pingCurrentGps();

    if (widget.dynamicService.products.isEmpty) {
      widget.dynamicService.fetchProducts();
    }
  }

  void _startDurationTimer() {
    _updateDurationString();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateDurationString();
      }
    });
  }

  void _updateDurationString() {
    final diff = DateTime.now().difference(_visitEntryTime);
    final mins = diff.inMinutes;
    final secs = diff.inSeconds % 60;
    setState(() {
      _elapsedDurationStr = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _pingCurrentGps() async {
    try {
      final pos = await Geolocator.getLastKnownPosition();
      if (pos != null && mounted) {
        setState(() {
          _currentLat = pos.latitude;
          _currentLon = pos.longitude;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _tabController.dispose();
    _compBrandController.dispose();
    _compProductController.dispose();
    _compPriceController.dispose();
    _compSchemeController.dispose();
    _compNotesController.dispose();
    _returnBatchController.dispose();
    _returnQtyController.dispose();
    super.dispose();
  }

  // --- Order Calculation Logic with Dynamic Schemes ---
  List<OrderItemModel> _calculateCurrentOrderItems() {
    final List<OrderItemModel> items = [];
    final products = widget.dynamicService.products;
    final schemes = widget.dynamicService.schemes;

    for (var p in products) {
      final qty = _cartQuantities[p.id] ?? 0;
      if (qty > 0) {
        int freeQty = 0;
        double discountPct = 0.0;

        // Auto-apply Slide 11 schemes
        for (var s in schemes) {
          if (s.type == 'BUY_X_GET_Y' && s.buyQuantity > 0 && qty >= s.buyQuantity) {
            freeQty += ((qty / s.buyQuantity).floor() * s.getQuantity).toInt();
          } else if (s.type == 'SLAB_DISCOUNT') {
            discountPct = s.discountPercentage;
          }
        }

        final lineTotal = (qty * p.basePrice) * (1.0 - discountPct / 100.0);

        items.add(OrderItemModel(
          productId: p.id,
          productName: p.name,
          productCode: p.code,
          quantity: qty,
          freeQuantity: freeQty,
          unitPrice: p.basePrice,
          discountPercent: discountPct,
          totalAmount: lineTotal,
        ));
      }
    }
    return items;
  }

  double _calculateSubtotal(List<OrderItemModel> items) {
    return items.fold(0.0, (sum, it) => sum + (it.quantity * it.unitPrice));
  }

  double _calculateDiscount(List<OrderItemModel> items) {
    return items.fold(0.0, (sum, it) => sum + ((it.quantity * it.unitPrice) * (it.discountPercent / 100.0)));
  }

  double _calculateTax(double netAmount) {
    return netAmount * 0.18; // 18% GST
  }

  Future<void> _handleSubmitOrder() async {
    final items = _calculateCurrentOrderItems();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 1 product quantity')),
      );
      return;
    }

    // Enterprise BRD Rule: Must-Sell compliance for active region
    final allProducts = widget.dynamicService.products;
    final mustSellProducts = allProducts.where((p) => p.isMustSellInRegion(_activeRegion)).toList();
    final unpurchasedMustSell = mustSellProducts.where((p) => (_cartQuantities[p.id] ?? 0) <= 0).toList();

    String? mustSellReasonsSummary;
    if (unpurchasedMustSell.isNotEmpty) {
      final reasons = await MustSellReasonModal.show(
        context: context,
        unpurchasedMustSellProducts: unpurchasedMustSell,
        region: _activeRegion,
        outletName: widget.outlet.shopName,
        onQuickAddProduct: (prodId) {
          setState(() {
            _cartQuantities[prodId] = (_cartQuantities[prodId] ?? 0) + 1;
          });
        },
      );

      // If user cancelled, return to cart
      if (reasons == null) {
        return;
      }

      if (reasons.isNotEmpty) {
        mustSellReasonsSummary = reasons.entries.map((e) => '${e.key}: ${e.value}').join('; ');
      }
    }

    // Re-calculate after potential quick additions
    final finalItems = _calculateCurrentOrderItems();
    if (finalItems.isEmpty) return;

    final subTotal = _calculateSubtotal(finalItems);
    final discount = _calculateDiscount(finalItems);
    final taxable = subTotal - discount;
    final tax = _calculateTax(taxable);
    final total = taxable + tax;

    setState(() => _isSubmittingOrder = true);

    final res = await widget.dynamicService.submitOrder(
      outlet: widget.outlet,
      items: finalItems,
      subTotal: subTotal,
      taxAmount: tax,
      discountAmount: discount,
      totalAmount: total,
      mustSellNonPurchaseReasons: mustSellReasonsSummary,
    );

    setState(() {
      _isSubmittingOrder = false;
      _lastSubmittedOrderNumber = res['orderNumber'] ?? 'ORD-CONFIRMED';
      _lastSubmittedItems = items;
      _lastOrderSubTotal = subTotal;
      _lastOrderTax = tax;
      _lastOrderDiscount = discount;
      _lastOrderTotal = total;
      _cartQuantities.clear();
    });

    if (mounted) {
      _showOrderSuccessAndShareSheet();
    }
  }

  void _showOrderSuccessAndShareSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 48),
              ),
              const SizedBox(height: 12),
              const Text('Order Placed Successfully!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Order Ref: $_lastSubmittedOrderNumber', style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 6),
              Text(
                'Total Value: ${currencyFormat.format(_lastOrderTotal)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B5CAB)),
              ),
              const SizedBox(height: 10),

              // Ordered Products Summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCCE4FF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF0B5CAB)),
                            const SizedBox(width: 6),
                            Text(
                              'Total Products: ${_lastSubmittedItems?.length ?? 0} SKUs',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0B5CAB)),
                            ),
                          ],
                        ),
                        Text(
                          '${_lastSubmittedItems?.fold<double>(0, (s, i) => s + i.quantity).toInt() ?? 0} Total Units',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0B5CAB)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: Color(0xFFCCE4FF)),
                    const SizedBox(height: 8),
                    if (_lastSubmittedItems != null)
                      ..._lastSubmittedItems!.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
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
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                            ),
                          ],
                        ),
                      )),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Updated dynamically in Salesforce Outlet Outstanding Balance & Executive Revenue.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              const Divider(height: 24),
              const Text('Share Order with Retailer / Distributor:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),

              // Multi-Channel Share Buttons
              Row(
                children: [
                  // PDF Share
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B5CAB),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        OrderSharingService.shareOrderPdf(
                          outlet: widget.outlet,
                          items: _lastSubmittedItems!,
                          subTotal: _lastOrderSubTotal,
                          taxAmount: _lastOrderTax,
                          discountAmount: _lastOrderDiscount,
                          totalAmount: _lastOrderTotal,
                          orderNumber: _lastSubmittedOrderNumber!,
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.white),
                      label: const Text('Share PDF', style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Excel Share
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF107C41),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        OrderSharingService.shareOrderExcel(
                          outlet: widget.outlet,
                          items: _lastSubmittedItems!,
                          subTotal: _lastOrderSubTotal,
                          taxAmount: _lastOrderTax,
                          discountAmount: _lastOrderDiscount,
                          totalAmount: _lastOrderTotal,
                          orderNumber: _lastSubmittedOrderNumber!,
                        );
                      },
                      icon: const Icon(Icons.table_chart, size: 16, color: Colors.white),
                      label: const Text('Share Excel', style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // WhatsApp Share
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF25D366),
                        side: const BorderSide(color: Color(0xFF25D366)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        OrderSharingService.shareViaWhatsApp(
                          outlet: widget.outlet,
                          items: _lastSubmittedItems!,
                          totalAmount: _lastOrderTotal,
                          orderNumber: _lastSubmittedOrderNumber!,
                        );
                      },
                      icon: const Icon(Icons.chat, size: 16),
                      label: const Text('WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Email Share
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0B5CAB),
                        side: const BorderSide(color: Color(0xFF0B5CAB)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        OrderSharingService.shareViaEmail(
                          outlet: widget.outlet,
                          items: _lastSubmittedItems!,
                          totalAmount: _lastOrderTotal,
                          orderNumber: _lastSubmittedOrderNumber!,
                        );
                      },
                      icon: const Icon(Icons.email, size: 16),
                      label: const Text('Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Continue Visit Activities', style: TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleCompetitorSubmit() async {
    if (_compBrandController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter competitor brand')));
      return;
    }
    await widget.dynamicService.logCompetitorActivity(
      brandName: _compBrandController.text.trim(),
      productName: _compProductController.text.trim(),
      mrp: double.tryParse(_compPriceController.text) ?? 0.0,
      promoScheme: _compSchemeController.text.trim(),
      shelfSharePercent: _shelfShare,
      notes: _compNotesController.text.trim(),
    );
    _compBrandController.clear();
    _compProductController.clear();
    _compPriceController.clear();
    _compSchemeController.clear();
    _compNotesController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Competitor Intelligence logged to Salesforce'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _handleReturnSubmit() async {
    if (_selectedReturnProductId == null || _returnQtyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select product and enter return quantity')));
      return;
    }
    await widget.dynamicService.logProductReturn(
      productId: _selectedReturnProductId!,
      quantity: int.tryParse(_returnQtyController.text) ?? 1,
      reason: _selectedReturnReason ?? 'Damaged Packaging',
      batchNumber: _returnBatchController.text.trim(),
    );
    _returnQtyController.clear();
    _returnBatchController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Return Voucher registered in Salesforce'), backgroundColor: Colors.green),
      );
    }
  }


  Future<void> _handleCheckoutVisit() async {
    final completed = await VisitCheckoutModal.show(
      context,
      outlet: widget.outlet,
      visitEntryTime: _visitEntryTime,
      dynamicService: widget.dynamicService,
      onVisitCompleted: () {},
    );

    if (completed == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOrderBlocked = widget.outlet.isOrderBlockedDueToCredit;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.outlet.shopName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            const Text('Store Visit in Progress', style: TextStyle(fontSize: 11, color: Color(0xFFFFD54F))),
          ],
        ),
        backgroundColor: const Color(0xFF0B5CAB),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            onPressed: _handleCheckoutVisit,
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: const Text('Checkout', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD54F),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_cart, size: 18), text: 'Take Order'),
            Tab(icon: Icon(Icons.analytics_outlined, size: 18), text: 'Competitor'),
            Tab(icon: Icon(Icons.assignment_return_outlined, size: 18), text: 'Returns'),
            Tab(icon: Icon(Icons.store, size: 18), text: 'Audit / POSM'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Persistent Top Visit Timing & GPS Tracking Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF001E3C),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.login, color: Color(0xFF4ADE80), size: 16),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Entry: ${DateFormat('hh:mm:ss a').format(_visitEntryTime)}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'GPS: ${_currentLat.toStringAsFixed(4)}, ${_currentLon.toStringAsFixed(4)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _elapsedDurationStr,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Take Order with Catalog & Sharing
                _buildTakeOrderTab(isOrderBlocked),

                // Tab 2: Competitor Intelligence
                _buildCompetitorTab(),

                // Tab 3: Product Returns
                _buildReturnsTab(),

                // Tab 4: Display Audit & Merchandising
                _buildAuditTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTakeOrderTab(bool isOrderBlocked) {
    if (isOrderBlocked) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                child: Icon(Icons.block, size: 48, color: Colors.red.shade700),
              ),
              const SizedBox(height: 16),
              const Text(
                'Order Booking Locked',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 8),
              Text(
                'Outstanding Balance (${currencyFormat.format(widget.outlet.outstandingBalance)}) exceeds Credit Limit (${currencyFormat.format(widget.outlet.creditLimit)}).',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enterprise Rule: Executive can only take order when outstanding balance is within sanctioned limit.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final allProducts = widget.dynamicService.products;
    
    // Category counts for active region
    final mustSellProducts = allProducts.where((p) => p.isMustSellInRegion(_activeRegion)).toList();
    final focusedSellProducts = allProducts.where((p) => p.isFocusedSellInRegion(_activeRegion)).toList();
    final suggestedSellProducts = allProducts.where((p) => p.isSuggestedSellInRegion(_activeRegion)).toList();

    // Filter products according to selected chip
    List<ProductModel> displayedProducts = allProducts;
    if (_selectedSellFilter == 'Must Sell') {
      displayedProducts = mustSellProducts;
    } else if (_selectedSellFilter == 'Focused Sell') {
      displayedProducts = focusedSellProducts;
    } else if (_selectedSellFilter == 'Suggested Sell') {
      displayedProducts = suggestedSellProducts;
    }

    final orderItems = _calculateCurrentOrderItems();
    final subTotal = _calculateSubtotal(orderItems);
    final discount = _calculateDiscount(orderItems);
    final taxable = subTotal - discount;
    final tax = _calculateTax(taxable);
    final grandTotal = taxable + tax;

    return Column(
      children: [
        // 1. Region Selector Bar (Supports MP, Karnataka, Maharashtra, Gujarat)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: const Color(0xFF0B5CAB).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.location_on, size: 14, color: Color(0xFF0B5CAB)),
              ),
              const SizedBox(width: 8),
              const Text(
                'Target Region:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: ['Madhya Pradesh', 'Karnataka', 'Maharashtra', 'Gujarat'].contains(_activeRegion)
                        ? _activeRegion
                        : 'Madhya Pradesh',
                    isDense: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0B5CAB), size: 20),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0B5CAB)),
                    items: const [
                      DropdownMenuItem(value: 'Madhya Pradesh', child: Text('Madhya Pradesh (MP)')),
                      DropdownMenuItem(value: 'Karnataka', child: Text('Karnataka (KA)')),
                      DropdownMenuItem(value: 'Maharashtra', child: Text('Maharashtra (MH)')),
                      DropdownMenuItem(value: 'Gujarat', child: Text('Gujarat (GJ)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _activeRegion = val);
                      }
                    },
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${mustSellProducts.length} Must-Sell',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                ),
              ),
            ],
          ),
        ),

        // 2. Selling Classification Filter Chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryFilterChip(
                  label: 'All (${allProducts.length})',
                  category: 'All',
                  icon: Icons.apps,
                  color: const Color(0xFF475569),
                ),
                const SizedBox(width: 8),
                _buildCategoryFilterChip(
                  label: '🔴 Must Sell (${mustSellProducts.length})',
                  category: 'Must Sell',
                  icon: Icons.local_fire_department,
                  color: const Color(0xFFDC2626),
                ),
                const SizedBox(width: 8),
                _buildCategoryFilterChip(
                  label: '⭐ Focused Sell (${focusedSellProducts.length})',
                  category: 'Focused Sell',
                  icon: Icons.star,
                  color: const Color(0xFF7C3AED),
                ),
                const SizedBox(width: 8),
                _buildCategoryFilterChip(
                  label: '💡 Suggested Sell (${suggestedSellProducts.length})',
                  category: 'Suggested Sell',
                  icon: Icons.lightbulb,
                  color: const Color(0xFFD97706),
                ),
              ],
            ),
          ),
        ),

        // 3. Product Catalog List
        Expanded(
          child: displayedProducts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('No products in $_selectedSellFilter for $_activeRegion', style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: displayedProducts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final prod = displayedProducts[idx];
                    final currentQty = _cartQuantities[prod.id] ?? 0;
                    final classification = prod.getSellClassificationForRegion(_activeRegion);
                    final isMustSell = classification.toLowerCase() == 'must sell';
                    final isFocusedSell = classification.toLowerCase() == 'focused sell';
                    final isSuggestedSell = classification.toLowerCase() == 'suggested sell';

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: isMustSell
                            ? Border.all(color: Colors.red.shade200, width: 1.2)
                            : (isFocusedSell
                                ? Border.all(color: Colors.purple.shade200, width: 1.2)
                                : null),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Product Icon with Classification Indicator
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isMustSell
                                  ? Colors.red.shade50
                                  : (isFocusedSell
                                      ? Colors.purple.shade50
                                      : (isSuggestedSell
                                          ? Colors.amber.shade50
                                          : const Color(0xFF0B5CAB).withValues(alpha: 0.08))),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isMustSell
                                  ? Icons.local_fire_department
                                  : (isFocusedSell ? Icons.star : Icons.cookie),
                              color: isMustSell
                                  ? Colors.red
                                  : (isFocusedSell
                                      ? Colors.deepPurple
                                      : (isSuggestedSell ? Colors.amber.shade800 : const Color(0xFF0B5CAB))),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        prod.name,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (isMustSell)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.red.shade300),
                                        ),
                                        child: Row(
                                          children: const [
                                            Icon(Icons.priority_high, color: Colors.red, size: 10),
                                            Text(
                                              'MUST SELL',
                                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red),
                                            ),
                                          ],
                                        ),
                                      )
                                    else if (isFocusedSell)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.purple.shade300),
                                        ),
                                        child: const Text(
                                          'FOCUSED',
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                                        ),
                                      )
                                    else if (isSuggestedSell)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.amber.shade300),
                                        ),
                                        child: Text(
                                          'SUGGESTED',
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text('${prod.code} • ${prod.packSize}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text('Rate: Rs. ${prod.basePrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0B5CAB))),
                                    const SizedBox(width: 8),
                                    Text('Stock: ${prod.availableStock.toInt()}', style: TextStyle(fontSize: 11, color: Colors.green.shade800)),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Quantity Stepper
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                                onPressed: currentQty > 0
                                    ? () {
                                        setState(() {
                                          _cartQuantities[prod.id] = currentQty - 1;
                                        });
                                      }
                                    : null,
                              ),
                              Text(
                                '$currentQty',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.add_circle,
                                  color: isMustSell ? Colors.red : const Color(0xFF0B5CAB),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _cartQuantities[prod.id] = currentQty + 1;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Order Summary Bottom Sheet
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -3)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${orderItems.length} Products Selected', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('GST (18%): Rs. ${tax.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Grand Total:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(
                    currencyFormat.format(grandTotal),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0B5CAB)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: (_isSubmittingOrder || orderItems.isEmpty) ? null : _handleSubmitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B5CAB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _isSubmittingOrder
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check, color: Colors.white),
                  label: const Text('Confirm & Book Order', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompetitorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Competitor Intelligence Record', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const Text('Track competitor biscuit brands, schemes, and shelf share in this store.', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 16),
          TextField(controller: _compBrandController, decoration: const InputDecoration(labelText: 'Competitor Brand (e.g. Britannia, Sunfeast)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _compProductController, decoration: const InputDecoration(labelText: 'Product / SKU Name (e.g. Marie Gold, Good Day)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _compPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Retail Price (MRP)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _compSchemeController, decoration: const InputDecoration(labelText: 'Competitor Scheme / Trade Promo (e.g. 10% Extra Margin)', border: OutlineInputBorder())),
          const SizedBox(height: 14),
          Text('Shelf Visibility Share: ${_shelfShare.toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Slider(
            value: _shelfShare,
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: const Color(0xFF0B5CAB),
            label: '${_shelfShare.toInt()}%',
            onChanged: (v) => setState(() => _shelfShare = v),
          ),
          const SizedBox(height: 8),
          TextField(controller: _compNotesController, maxLines: 2, decoration: const InputDecoration(labelText: 'Observations / Field Notes', border: OutlineInputBorder())),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B5CAB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: _handleCompetitorSubmit,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Save Competitor Activity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnsTab() {
    final products = widget.dynamicService.products;
    final reasons = widget.dynamicService.metadata.returnReasons;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Product Return & Damage Voucher', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const Text('Raise return request for damaged or expired biscuits.', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Select Product', border: OutlineInputBorder()),
            value: _selectedReturnProductId,
            items: products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, style: const TextStyle(fontSize: 12)))).toList(),
            onChanged: (v) => setState(() => _selectedReturnProductId = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Return Reason', border: OutlineInputBorder()),
            value: _selectedReturnReason ?? (reasons.isNotEmpty ? reasons.first : 'Damaged Packaging'),
            items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12)))).toList(),
            onChanged: (v) => setState(() => _selectedReturnReason = v),
          ),
          const SizedBox(height: 12),
          TextField(controller: _returnQtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Return Quantity (Packs)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _returnBatchController, decoration: const InputDecoration(labelText: 'Batch Number (from packaging)', border: OutlineInputBorder())),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: _handleReturnSubmit,
              icon: const Icon(Icons.assignment_return, color: Colors.white),
              label: const Text('Submit Return Voucher', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('In-Store POSM & Merchandising Audit', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const Text('Verify Parle floor stands, counter dispensers, and posters.', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 16),
          _buildAuditCheckItem('Parle Floor Standing Unit (FSU)', 'Operational & Well Stocked'),
          _buildAuditCheckItem('Counter Top Biscuit Dispenser', 'Clean & Visible at Billing Counter'),
          _buildAuditCheckItem('Festive Poster & Danglers', 'Affixed prominently on shop facade'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B5CAB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                widget.dynamicService.logAssetSurvey(
                  assetName: 'Parle Retail Display Stand',
                  status: 'Operational',
                  notes: 'Stand in good shape, all SKU faces visible.',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Display Audit submitted to Salesforce'), backgroundColor: Colors.green),
                );
              },
              icon: const Icon(Icons.verified, color: Colors.white),
              label: const Text('Confirm POSM Audit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditCheckItem(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF107C41), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterChip({
    required String label,
    required String category,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedSellFilter == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSellFilter = category;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
