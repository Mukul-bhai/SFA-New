import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';

class OrderSharingService {
  static final NumberFormat currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2);

  /// 1. Generate & Share PDF Order Invoice
  static Future<void> shareOrderPdf({
    required RetailerModel outlet,
    required List<OrderItemModel> items,
    required double subTotal,
    required double taxAmount,
    required double discountAmount,
    required double totalAmount,
    required String orderNumber,
  }) async {
    final pdf = pw.Document();

    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('PARLE PRODUCTS PVT. LTD.', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.Text('Enterprise SFA & Distribution Network', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.Text('Sales Force Automation Order Confirmation', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('ORDER INVOICE', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                      pw.Text('Ref: $orderNumber', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1.5, color: PdfColors.blue800),
              pw.SizedBox(height: 10),

              // Outlet Details Card
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('BILL TO / OUTLET:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                          pw.Text(outlet.shopName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          pw.Text('Owner: ${outlet.name}', style: const pw.TextStyle(fontSize: 10)),
                          pw.Text('Code: ${outlet.code}', style: const pw.TextStyle(fontSize: 10)),
                          pw.Text('Contact: ${outlet.phone}', style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('FULFILLMENT DISTRIBUTOR:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                          pw.Text(outlet.primaryDistributorName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          pw.Text('Payment Terms: Credit Account', style: const pw.TextStyle(fontSize: 10)),
                          pw.Text('Outstanding Balance: Rs. ${outlet.outstandingBalance.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Items Table
              pw.Text('ORDERED PRODUCTS & SCHEMES', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                headers: ['#', 'Product', 'Code', 'Qty', 'Free Qty', 'Rate (Rs.)', 'Total (Rs.)'],
                data: List<List<String>>.generate(items.length, (index) {
                  final it = items[index];
                  return [
                    '${index + 1}',
                    it.productName,
                    it.productCode,
                    '${it.quantity}',
                    it.freeQuantity > 0 ? '+${it.freeQuantity} FREE' : '-',
                    it.unitPrice.toStringAsFixed(2),
                    it.totalAmount.toStringAsFixed(2),
                  ];
                }),
              ),
              pw.SizedBox(height: 14),

              // Financial Summary Table
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 220,
                    child: pw.Column(
                      children: [
                        _buildPdfSummaryRow('Subtotal', 'Rs. ${subTotal.toStringAsFixed(2)}'),
                        if (discountAmount > 0)
                          _buildPdfSummaryRow('Trade Discount', '- Rs. ${discountAmount.toStringAsFixed(2)}', isGreen: true),
                        _buildPdfSummaryRow('GST (18% Applicable)', 'Rs. ${taxAmount.toStringAsFixed(2)}'),
                        pw.Divider(thickness: 1, color: PdfColors.grey400),
                        _buildPdfSummaryRow('Net Grand Total', 'Rs. ${totalAmount.toStringAsFixed(2)}', isBold: true, fontSize: 13),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),

              // Footer Note
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generated electronically via Parle SFA Mobile App', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                  pw.Text('Authorized FMCG Field Order', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Save and Share File
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/Order_${orderNumber}_Invoice.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Order Invoice #$orderNumber - ${outlet.shopName}',
      text: 'Order confirmation invoice #$orderNumber for ${outlet.shopName}. Net Payable: Rs. ${totalAmount.toStringAsFixed(2)}',
    );
  }

  static pw.Widget _buildPdfSummaryRow(String label, String value, {bool isBold = false, bool isGreen = false, double fontSize = 10}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: isGreen ? PdfColors.green700 : (isBold ? PdfColors.blue900 : PdfColors.black),
          )),
        ],
      ),
    );
  }

  /// 2. Generate & Share Excel (.xlsx) Order Sheet
  static Future<void> shareOrderExcel({
    required RetailerModel outlet,
    required List<OrderItemModel> items,
    required double subTotal,
    required double taxAmount,
    required double discountAmount,
    required double totalAmount,
    required String orderNumber,
  }) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Order Details'];
    excel.delete('Sheet1'); // remove default sheet

    // Header Title
    sheet.appendRow([
      TextCellValue('PARLE BISCUITS - SFA ORDER CONFIRMATION SHEET'),
    ]);
    sheet.appendRow([
      TextCellValue('Order Ref: $orderNumber'),
      TextCellValue('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
    ]);
    sheet.appendRow([
      TextCellValue('Shop Name: ${outlet.shopName}'),
      TextCellValue('Outlet Code: ${outlet.code}'),
      TextCellValue('Distributor: ${outlet.primaryDistributorName}'),
    ]);
    sheet.appendRow([]); // empty row

    // Table Column Headers
    sheet.appendRow([
      TextCellValue('Sl No'),
      TextCellValue('Product Code'),
      TextCellValue('Product Name'),
      TextCellValue('Billed Quantity'),
      TextCellValue('Free Scheme Qty'),
      TextCellValue('Unit Price (INR)'),
      TextCellValue('Discount %'),
      TextCellValue('Line Total (INR)'),
    ]);

    // Data Rows
    for (int i = 0; i < items.length; i++) {
      final it = items[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(it.productCode),
        TextCellValue(it.productName),
        IntCellValue(it.quantity),
        IntCellValue(it.freeQuantity),
        DoubleCellValue(it.unitPrice),
        DoubleCellValue(it.discountPercent),
        DoubleCellValue(it.totalAmount),
      ]);
    }

    // Totals Rows
    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('Subtotal:'),
      DoubleCellValue(subTotal),
    ]);
    if (discountAmount > 0) {
      sheet.appendRow([
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue('Trade Discount:'),
        DoubleCellValue(-discountAmount),
      ]);
    }
    sheet.appendRow([
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('GST (18%):'),
      DoubleCellValue(taxAmount),
    ]);
    sheet.appendRow([
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('GRAND TOTAL:'),
      DoubleCellValue(totalAmount),
    ]);

    // Save File
    final fileBytes = excel.save();
    if (fileBytes != null) {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/Order_${orderNumber}_Sheet.xlsx');
      await file.writeAsBytes(fileBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Order Sheet #$orderNumber - ${outlet.shopName}',
        text: 'Order Excel Sheet #$orderNumber for ${outlet.shopName}. Total: Rs. ${totalAmount.toStringAsFixed(2)}',
      );
    }
  }

  /// 3. Direct Share via WhatsApp
  static Future<void> shareViaWhatsApp({
    required RetailerModel outlet,
    required List<OrderItemModel> items,
    required double totalAmount,
    required String orderNumber,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('🛒 *PARLE BISCUITS - ORDER CONFIRMATION*');
    buffer.writeln('📋 *Order Ref:* $orderNumber');
    buffer.writeln('🏪 *Shop:* ${outlet.shopName} (${outlet.code})');
    buffer.writeln('📅 *Date:* ${DateFormat('dd-MMM-yyyy').format(DateTime.now())}');
    buffer.writeln('-----------------------------------');
    for (var it in items) {
      final freeText = it.freeQuantity > 0 ? ' _(+${it.freeQuantity} Free)_' : '';
      buffer.writeln('• ${it.productName} x ${it.quantity}$freeText = Rs. ${it.totalAmount.toStringAsFixed(2)}');
    }
    buffer.writeln('-----------------------------------');
    buffer.writeln('💰 *Total Payable:* Rs. ${totalAmount.toStringAsFixed(2)}');
    buffer.writeln('🚚 Fulfillment via *${outlet.primaryDistributorName}*');
    buffer.writeln('Thank you for your business!');

    final encodedText = Uri.encodeComponent(buffer.toString());
    final phoneClean = outlet.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('whatsapp://send?phone=$phoneClean&text=$encodedText');
    final fallbackUri = Uri.parse('https://api.whatsapp.com/send?text=$encodedText');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
    }
  }

  /// 4. Direct Share via Email
  static Future<void> shareViaEmail({
    required RetailerModel outlet,
    required List<OrderItemModel> items,
    required double totalAmount,
    required String orderNumber,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('Dear Customer,\n');
    buffer.writeln('Your order with Parle Biscuits has been booked successfully.\n');
    buffer.writeln('Order Reference: $orderNumber');
    buffer.writeln('Outlet: ${outlet.shopName} (${outlet.code})');
    buffer.writeln('Distributor: ${outlet.primaryDistributorName}\n');
    buffer.writeln('ITEMS:');
    for (var it in items) {
      final freeText = it.freeQuantity > 0 ? ' (+${it.freeQuantity} Free Scheme)' : '';
      buffer.writeln('- ${it.productName}: Qty ${it.quantity}$freeText | Rs. ${it.totalAmount.toStringAsFixed(2)}');
    }
    buffer.writeln('\nGRAND TOTAL: Rs. ${totalAmount.toStringAsFixed(2)}');
    buffer.writeln('\nRegards,\nParle Sales Force Automation');

    final subject = Uri.encodeComponent('Order Confirmation #$orderNumber - ${outlet.shopName}');
    final body = Uri.encodeComponent(buffer.toString());
    final uri = Uri.parse('mailto:?subject=$subject&body=$body');

    try {
      await launchUrl(uri);
    } catch (_) {}
  }
}
