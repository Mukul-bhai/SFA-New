import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/salesforce_sync_service.dart';
import '../widgets/must_sell_reason_modal.dart';

class VisitOrderScreen extends StatefulWidget {
  final SalesforceSyncService syncService;

  const VisitOrderScreen({
    super.key,
    required this.syncService,
  });

  @override
  State<VisitOrderScreen> createState() => _VisitOrderScreenState();
}

class _VisitOrderScreenState extends State<VisitOrderScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, int> _cartQuantities = {};
  final _uuid = const Uuid();

  // Region and category filter state
  String _activeRegion = 'Madhya Pradesh';
  String _selectedSellFilter = 'All';

  // Survey state
  int _surveyRating = 4;
  String _stockFreshness = 'Good';
  final _surveyFeedbackCtrl = TextEditingController();

  // Merchandising state
  double _shelfShare = 45.0;
  bool _posmPresent = true;

  // Competition state
  final _compBrandCtrl = TextEditingController(text: 'Hindustan Unilever');
  final _compProductCtrl = TextEditingController(text: 'Dove Shampoo 180ml');
  final _compPriceCtrl = TextEditingController(text: '145');
  final _compSchemeCtrl = TextEditingController(text: '₹10 off on pack');

  // Stock Check state
  final Map<String, int> _shelfStock = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _surveyFeedbackCtrl.dispose();
    _compBrandCtrl.dispose();
    _compProductCtrl.dispose();
    _compPriceCtrl.dispose();
    _compSchemeCtrl.dispose();
    super.dispose();
  }

  void _incrementQty(String productId) {
    setState(() {
      _cartQuantities[productId] = (_cartQuantities[productId] ?? 0) + 1;
    });
  }

  void _decrementQty(String productId) {
    setState(() {
      final current = _cartQuantities[productId] ?? 0;
      if (current > 1) {
        _cartQuantities[productId] = current - 1;
      } else {
        _cartQuantities.remove(productId);
      }
    });
  }

  Map<String, dynamic> _calculateOrderSummary() {
    double subtotal = 0.0;
    int totalPcs = 0;
    int totalFreePcs = 0;
    final List<OrderItemModel> items = [];

    final products = widget.syncService.products;
    final schemes = widget.syncService.schemes;

    for (var p in products) {
      final qty = _cartQuantities[p.id] ?? 0;
      if (qty > 0) {
        int freeQty = 0;
        // Check Buy X Get Y schemes
        for (var s in schemes) {
          if (s.type == 'BUY_X_GET_Y' && s.buyQuantity > 0) {
            final sets = (qty / s.buyQuantity).floor();
            freeQty += (sets * s.getQuantity).toInt();
          }
        }

        final lineTotal = qty * p.basePrice;
        subtotal += lineTotal;
        totalPcs += qty;
        totalFreePcs += freeQty;

        items.add(OrderItemModel(
          productId: p.id,
          productName: p.name,
          productCode: p.code,
          quantity: qty,
          freeQuantity: freeQty,
          unitPrice: p.basePrice,
          totalAmount: lineTotal,
        ));
      }
    }

    // Slab discount
    double discount = 0.0;
    if (subtotal >= 10000) {
      discount = subtotal * 0.10; // 10%
    } else if (subtotal >= 5000) {
      discount = subtotal * 0.05; // 5%
    }

    final taxable = subtotal - discount;
    final gst = taxable * 0.18; // 18% GST
    final grandTotal = taxable + gst;

    return {
      'subtotal': subtotal,
      'discount': discount,
      'gst': gst,
      'grandTotal': grandTotal,
      'totalPcs': totalPcs,
      'totalFreePcs': totalFreePcs,
      'items': items,
    };
  }

  Future<void> _handlePlaceOrder(RetailerModel retailer) async {
    // Enterprise BRD Rule: Must-Sell compliance for active region
    final allProducts = widget.syncService.products;
    final mustSellProducts = allProducts.where((p) => p.isMustSellInRegion(_activeRegion)).toList();
    final unpurchasedMustSell = mustSellProducts.where((p) => (_cartQuantities[p.id] ?? 0) <= 0).toList();

    String? mustSellReasonsSummary;
    if (unpurchasedMustSell.isNotEmpty) {
      final reasons = await MustSellReasonModal.show(
        context: context,
        unpurchasedMustSellProducts: unpurchasedMustSell,
        region: _activeRegion,
        outletName: retailer.name,
        onQuickAddProduct: (prodId) {
          setState(() {
            _cartQuantities[prodId] = (_cartQuantities[prodId] ?? 0) + 1;
          });
        },
      );

      if (reasons == null) return;
      if (reasons.isNotEmpty) {
        mustSellReasonsSummary = reasons.entries.map((e) => '${e.key}: ${e.value}').join('; ');
      }
    }

    final summary = _calculateOrderSummary();
    final items = summary['items'] as List<OrderItemModel>;
    if (items.isEmpty) return;

    final grandTotal = summary['grandTotal'] as double;
    final projectedBalance = retailer.outstandingBalance + grandTotal;

    // Credit limit warning
    bool proceed = true;
    if (projectedBalance > retailer.creditLimit) {
      proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Credit Limit Warning', style: TextStyle(color: Colors.red)),
          content: Text(
            'This order total (₹${grandTotal.toStringAsFixed(0)}) pushes ${retailer.name}\'s balance to ₹${projectedBalance.toStringAsFixed(0)}, exceeding the credit limit of ₹${retailer.creditLimit.toStringAsFixed(0)}.\n\nDo you want to proceed and submit for manager approval?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Proceed with Hold'),
            ),
          ],
        ),
      ) ?? false;
    }

    if (!proceed) return;

    final newOrder = LocalOrderModel(
      localId: _uuid.v4(),
      retailerId: retailer.id,
      retailerName: retailer.name,
      items: items,
      subtotal: summary['subtotal'],
      discountAmount: summary['discount'],
      gstAmount: summary['gst'],
      totalAmount: grandTotal,
      distributorId: retailer.primaryDistributorId,
      orderDate: DateTime.now(),
      syncStatus: 'QUEUED',
      mustSellNonPurchaseReasons: mustSellReasonsSummary,
    );

    await widget.syncService.queueOrder(newOrder);

    setState(() {
      _cartQuantities.clear();
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order of ₹${grandTotal.toStringAsFixed(0)} placed and synced to Salesforce!'),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeRetailer = widget.syncService.activeVisitRetailer;

    if (activeRetailer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Store Visit & In-Store Actions')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.storefront_outlined, size: 72, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  'No Outlet Checked In',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please select and check into an outlet from "Today\'s Beat" tab to unlock order booking, merchandising, and survey audits.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final summary = _calculateOrderSummary();
    final totalItems = (summary['items'] as List).length;
    final grandTotal = summary['grandTotal'] as double;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(activeRetailer.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${activeRetailer.shopName} • In-Store Visit Active', style: const TextStyle(fontSize: 11, color: Colors.greenAccent)),
          ],
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('Check Out'),
            onPressed: () {
              widget.syncService.checkOutRetailer(activeRetailer);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Checked out from ${activeRetailer.name}')),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_bag), text: 'Take Order'),
            Tab(icon: Icon(Icons.rate_review), text: 'Survey'),
            Tab(icon: Icon(Icons.shelves), text: 'Planogram'),
            Tab(icon: Icon(Icons.insights), text: 'Competition'),
            Tab(icon: Icon(Icons.inventory_2), text: 'Shop Stock'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Take Order Tab
          _buildTakeOrderTab(activeRetailer, summary),
          // 2. Survey Tab
          _buildSurveyTab(activeRetailer),
          // 3. Planogram Tab
          _buildPlanogramTab(activeRetailer),
          // 4. Competition Tab
          _buildCompetitionTab(activeRetailer),
          // 5. Shop Stock Tab
          _buildShopStockTab(activeRetailer),
        ],
      ),
      // Bottom Order Checkout Bar
      bottomNavigationBar: _tabController.index == 0 && totalItems > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -3))],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$totalItems Items (${summary['totalPcs']} Pcs + ${summary['totalFreePcs']} Free)', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        Text('₹${grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0070D2))),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: () => _handlePlaceOrder(activeRetailer),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Book Order', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTakeOrderTab(RetailerModel retailer, Map<String, dynamic> summary) {
    final allProducts = widget.syncService.products;

    final mustSellProducts = allProducts.where((p) => p.isMustSellInRegion(_activeRegion)).toList();
    final focusedSellProducts = allProducts.where((p) => p.isFocusedSellInRegion(_activeRegion)).toList();
    final suggestedSellProducts = allProducts.where((p) => p.isSuggestedSellInRegion(_activeRegion)).toList();

    List<ProductModel> displayedProducts = allProducts;
    if (_selectedSellFilter == 'Must Sell') {
      displayedProducts = mustSellProducts;
    } else if (_selectedSellFilter == 'Focused Sell') {
      displayedProducts = focusedSellProducts;
    } else if (_selectedSellFilter == 'Suggested Sell') {
      displayedProducts = suggestedSellProducts;
    }

    return Column(
      children: [
        // Region Selector Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: const Color(0xFFF8FAFC),
          child: Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: Color(0xFF0070D2)),
              const SizedBox(width: 6),
              const Text('Region:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: ['Madhya Pradesh', 'Karnataka', 'Maharashtra', 'Gujarat'].contains(_activeRegion)
                        ? _activeRegion
                        : 'Madhya Pradesh',
                    isDense: true,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0070D2)),
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
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                child: Text('${mustSellProducts.length} Must-Sell', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade800)),
              ),
            ],
          ),
        ),

        // Filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildOrderFilterChip('All (${allProducts.length})', 'All', const Color(0xFF475569)),
                const SizedBox(width: 8),
                _buildOrderFilterChip('🔴 Must Sell (${mustSellProducts.length})', 'Must Sell', const Color(0xFFDC2626)),
                const SizedBox(width: 8),
                _buildOrderFilterChip('⭐ Focused Sell (${focusedSellProducts.length})', 'Focused Sell', const Color(0xFF7C3AED)),
                const SizedBox(width: 8),
                _buildOrderFilterChip('💡 Suggested Sell (${suggestedSellProducts.length})', 'Suggested Sell', const Color(0xFFD97706)),
              ],
            ),
          ),
        ),

        // Product list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: displayedProducts.length + 1,
            itemBuilder: (ctx, index) {
              if (index == 0) {
                // Top Active Schemes Banner
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.local_offer, color: Colors.amber, size: 24),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Active Schemes: Monsoon Boost (Buy 10 Get 1 Free) + 5% off above ₹5K, 10% off above ₹10K',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final product = displayedProducts[index - 1];
              final qty = _cartQuantities[product.id] ?? 0;
              final classification = product.getSellClassificationForRegion(_activeRegion);
              final isMustSell = classification.toLowerCase() == 'must sell';
              final isFocusedSell = classification.toLowerCase() == 'focused sell';
              final isSuggestedSell = classification.toLowerCase() == 'suggested sell';

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isMustSell
                      ? BorderSide(color: Colors.red.shade300, width: 1.2)
                      : (isFocusedSell ? BorderSide(color: Colors.purple.shade300, width: 1.2) : BorderSide.none),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                ),
                                if (isMustSell)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                                    child: const Text('MUST SELL', style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
                                  )
                                else if (isFocusedSell)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(4)),
                                    child: const Text('FOCUSED', style: TextStyle(color: Colors.deepPurple, fontSize: 9, fontWeight: FontWeight.bold)),
                                  )
                                else if (isSuggestedSell)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(4)),
                                    child: Text('SUGGESTED', style: TextStyle(color: Colors.amber.shade900, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            Text('${product.category} • SKU: ${product.code}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text('₹${product.basePrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0070D2))),
                                const SizedBox(width: 8),
                                Text('MRP: ₹${product.mrp.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                                  child: Text('Stock: ${product.availableStock.toInt()}', style: TextStyle(color: Colors.green.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Stepper Controls
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: qty > 0 ? () => _decrementQty(product.id) : null,
                          ),
                          Text('$qty', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: Icon(Icons.add_circle, color: isMustSell ? Colors.red : const Color(0xFF0070D2)),
                            onPressed: () => _incrementQty(product.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderFilterChip(String label, String category, Color color) {
    final isSelected = _selectedSellFilter == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedSellFilter = category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : color),
        ),
      ),
    );
  }

  Widget _buildSurveyTab(RetailerModel retailer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Outlet Satisfaction Survey', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Retailer Relationship Rating:'),
              Row(
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(index < _surveyRating ? Icons.star : Icons.star_border, color: Colors.amber, size: 32),
                  onPressed: () => setState(() => _surveyRating = index + 1),
                )),
              ),
              const SizedBox(height: 12),
              const Text('Stock Freshness Status:'),
              DropdownButton<String>(
                value: _stockFreshness,
                isExpanded: true,
                items: ['Good', 'Near Expiry Detected', 'Damage Reported', 'Damaged Packaging'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _stockFreshness = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _surveyFeedbackCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Retailer Feedback / Distributor Complaints',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0070D2), foregroundColor: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Survey Response recorded!')));
                },
                child: const Text('Save Survey Response'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanogramTab(RetailerModel retailer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Planogram & Merchandising Audit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('Brand Shelf Share: ${_shelfShare.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: _shelfShare,
                min: 0,
                max: 100,
                divisions: 20,
                label: '${_shelfShare.toInt()}%',
                activeColor: const Color(0xFF0070D2),
                onChanged: (val) => setState(() => _shelfShare = val),
              ),
              SwitchListTile(
                title: const Text('POSM Poster & Danglers Displayed'),
                value: _posmPresent,
                activeColor: const Color(0xFF16A34A),
                onChanged: (val) => setState(() => _posmPresent = val),
              ),
              const SizedBox(height: 12),
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.camera_alt, size: 36, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Capture Shelf Audit Photo', style: TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0070D2), foregroundColor: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Merchandising Audit verified!')));
                },
                child: const Text('Submit Audit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompetitionTab(RetailerModel retailer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Competition Intelligence Capture', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _compBrandCtrl,
                decoration: const InputDecoration(labelText: 'Competitor Brand', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _compProductCtrl,
                decoration: const InputDecoration(labelText: 'Competitor Product', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _compPriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Retail Price (₹)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _compSchemeCtrl,
                      decoration: const InputDecoration(labelText: 'Promotional Offers', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0070D2), foregroundColor: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Competition Intel captured!')));
                },
                child: const Text('Log Competition Activity'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShopStockTab(RetailerModel retailer) {
    final products = widget.syncService.products;

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: products.length,
      itemBuilder: (ctx, index) {
        final product = products[index];
        final currentStock = _shelfStock[product.id] ?? 5;

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Suggested Reorder: 15 units', style: TextStyle(color: Colors.orange.shade800, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: () {
                        if (currentStock > 0) {
                          setState(() => _shelfStock[product.id] = currentStock - 1);
                        }
                      },
                    ),
                    Text('$currentStock Shelf Qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () {
                        setState(() => _shelfStock[product.id] = currentStock + 1);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
