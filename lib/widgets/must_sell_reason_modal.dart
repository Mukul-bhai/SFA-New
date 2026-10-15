import 'package:flutter/material.dart';
import '../models/models.dart';

/// Modal to capture mandatory non-purchase reasons for Must-Sell products as per BRD
class MustSellReasonModal extends StatefulWidget {
  final List<ProductModel> unpurchasedMustSellProducts;
  final String region;
  final String outletName;
  final Function(String productId) onQuickAddProduct;

  const MustSellReasonModal({
    super.key,
    required this.unpurchasedMustSellProducts,
    required this.region,
    required this.outletName,
    required this.onQuickAddProduct,
  });

  static Future<Map<String, String>?> show({
    required BuildContext context,
    required List<ProductModel> unpurchasedMustSellProducts,
    required String region,
    required String outletName,
    required Function(String productId) onQuickAddProduct,
  }) {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MustSellReasonModal(
        unpurchasedMustSellProducts: unpurchasedMustSellProducts,
        region: region,
        outletName: outletName,
        onQuickAddProduct: onQuickAddProduct,
      ),
    );
  }

  @override
  State<MustSellReasonModal> createState() => _MustSellReasonModalState();
}

class _MustSellReasonModalState extends State<MustSellReasonModal> {
  final Map<String, String> _selectedReasons = {};
  final Map<String, TextEditingController> _otherControllers = {};
  late List<ProductModel> _remainingProducts;

  final List<String> _standardReasons = const [
    'Stock Available',
    'Low demand',
    'Season expired',
    'No product demand',
    'Non movable',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _remainingProducts = List.from(widget.unpurchasedMustSellProducts);
    for (final p in _remainingProducts) {
      _selectedReasons[p.id] = _standardReasons.first; // Default to 'Stock Available'
      _otherControllers[p.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _otherControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _handleQuickAdd(ProductModel product) {
    widget.onQuickAddProduct(product.id);
    setState(() {
      _remainingProducts.removeWhere((p) => p.id == product.id);
      _selectedReasons.remove(product.id);
    });

    if (_remainingProducts.isEmpty) {
      Navigator.pop(context, <String, String>{});
    }
  }

  void _handleSubmit() {
    // Validate all remaining products have a reason
    final Map<String, String> finalReasons = {};
    for (final p in _remainingProducts) {
      final reason = _selectedReasons[p.id] ?? 'Stock Available';
      if (reason == 'Other') {
        final customText = _otherControllers[p.id]?.text.trim() ?? '';
        finalReasons[p.name] = customText.isNotEmpty ? 'Other: $customText' : 'Other reason';
      } else {
        finalReasons[p.name] = reason;
      }
    }

    Navigator.pop(context, finalReasons);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 18,
        right: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Must-Sell Products Notice',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                    ),
                    Text(
                      'Mandatory SKUs for Region: ${widget.region}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Text(
              '${widget.outletName} has not ordered the required Must-Sell items below. Company policy requires an order or an audited non-purchase reason.',
              style: const TextStyle(fontSize: 11, color: Color(0xFF5D4037)),
            ),
          ),
          const SizedBox(height: 12),

          // Products List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _remainingProducts.length,
              separatorBuilder: (_, _) => const Divider(height: 20),
              itemBuilder: (ctx, i) {
                final prod = _remainingProducts[i];
                final selectedReason = _selectedReasons[prod.id] ?? _standardReasons.first;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'MUST SELL',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      prod.name,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'SKU: ${prod.code} • Rate: Rs. ${prod.basePrice.toStringAsFixed(0)}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        // Quick Add +1 Button
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0B5CAB),
                            side: const BorderSide(color: Color(0xFF0B5CAB)),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () => _handleQuickAdd(prod),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Add 1 Pcs', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Non-purchase reason dropdown
                    const Text(
                      'Non-purchase reason:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: selectedReason,
                      isExpanded: true,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: _standardReasons.map((r) {
                        return DropdownMenuItem(
                          value: r,
                          child: Text(r, style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedReasons[prod.id] = val;
                          });
                        }
                      },
                    ),

                    if (selectedReason == 'Other') ...[
                      const SizedBox(height: 6),
                      TextField(
                        controller: _otherControllers[prod.id],
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Enter specific reason for not ordering...',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Bottom Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Modify Order'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B5CAB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _handleSubmit,
                  child: const Text('Proceed to Submit', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
