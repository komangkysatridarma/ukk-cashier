
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grocery/core/constants/app_colors.dart';
import 'package:grocery/core/constants/app_defaults.dart';
import 'package:grocery/core/routes/app_routes.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PembelianDummy extends StatefulWidget {
  const PembelianDummy({
    super.key,
    required this.saleId,
    required this.memberStatus,
    required this.tanggal,
    required this.createdBy,
    required this.total,
  });

  final String saleId;
  final String memberStatus;
  final String tanggal;
  final String createdBy;
  final int total;

  @override
  State<PembelianDummy> createState() => _PembelianDummyState();
}

class _PembelianDummyState extends State<PembelianDummy> {
  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void hideLoadingDialog(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> generatePdf(BuildContext context, String saleId) async {
    bool _isGeneratingPdf = false;
    if (!mounted) return;

    debugPrint('Starting PDF generation for sale $saleId');
    showLoadingDialog(context);

    try {
      final pdf = pw.Document();

      debugPrint('Creating PDF document');
      final currencyFormat = NumberFormat.currency(
        locale: 'id',
        symbol: 'Rp. ',
        decimalDigits: 0,
      );

      debugPrint('Fetching sale data from Firestore');
      final saleDoc = await FirebaseFirestore.instance
          .collection('sales')
          .doc(saleId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw TimeoutException('Fetching sale data timed out'),
          );

      if (!saleDoc.exists) {
        throw Exception('Sale with ID $saleId not found');
      }

      final saleData = saleDoc.data()!;
      debugPrint('Sale data fetched successfully');

      debugPrint('Fetching sale details');
      final detailsQuery = await FirebaseFirestore.instance
          .collection('sale_details')
          .where('sale_id', isEqualTo: saleId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw TimeoutException('Fetching sale details timed out'),
          );

      debugPrint(
          'Sale details fetched, found ${detailsQuery.docs.length} items');
      final details = <Map<String, dynamic>>[];

      debugPrint('Starting to fetch product details');
      for (var doc in detailsQuery.docs) {
        final data = doc.data();
        final productId = data['product_id'];
        debugPrint('Fetching product $productId');

        try {
          final productDoc = await FirebaseFirestore.instance
              .collection('produk')
              .doc(productId)
              .get()
              .timeout(
                const Duration(seconds: 5),
                onTimeout: () => throw TimeoutException(
                    'Fetching product info timed out for $productId'),
              );

          if (productDoc.exists) {
            final productData = productDoc.data()!;
            details.add({
              'product_name': productData['nama'] ?? 'Unknown Product',
              'product_price': productData['harga'] ?? 0,
              'qty': data['qty'],
              'total_price': data['total_price'],
            });
            debugPrint('Added product: ${productData['nama']} to details');
          } else {
            debugPrint('Product $productId not found, using fallback data');
            details.add({
              'product_name': 'Product ID: $productId',
              'product_price': data['price'] ?? 0,
              'qty': data['qty'],
              'total_price': data['total_price'],
            });
          }
        } catch (e) {
          debugPrint('Error fetching product $productId: $e');
          details.add({
            'product_name': 'Product ID: $productId (Error)',
            'product_price': data['price'] ?? 0,
            'qty': data['qty'],
            'total_price': data['total_price'],
          });
        }
      }

      debugPrint('All product details fetched, creating PDF content');

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('Invoice Pembelian',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text('Invoice - #${saleData['no_sales'] ?? saleId}',
                    style:
                        pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
              ),
              pw.Center(
                child: pw.Text(widget.tanggal,
                    style:
                        pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Produk',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Harga',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Qty',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Sub Total',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...details.map((detail) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(detail['product_name'] ?? ''),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(currencyFormat
                                .format(detail['product_price'] ?? 0)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('${detail['qty']}'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(currencyFormat
                                .format(detail['total_price'] ?? 0)),
                          ),
                        ],
                      )),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('POIN DIGUNAKAN'),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text('${saleData['point_used'] ?? 0}'),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('KASIR'),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(saleData['created_by'] ?? widget.createdBy),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('KEMBALIAN'),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child:
                        pw.Text(currencyFormat.format(saleData['change'] ?? 0)),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.green),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('SUBTOTAL', style: pw.TextStyle(fontSize: 14)),
                        pw.Text(
                            currencyFormat.format(saleData['original_total'] ??
                                saleData['sub_total'] ??
                                widget.total),
                            style: pw.TextStyle(fontSize: 14)),
                      ],
                    ),
                    if ((saleData['point_used'] ?? 0) > 0) ...[
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('DISKON POIN',
                              style: pw.TextStyle(
                                  fontSize: 14, color: PdfColors.red)),
                          pw.Text(
                              '- ${currencyFormat.format(saleData['point_used'] ?? 0)}',
                              style: pw.TextStyle(
                                  fontSize: 14, color: PdfColors.red)),
                        ],
                      ),
                    ],
                    pw.Divider(color: PdfColors.grey),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('TOTAL BAYAR',
                            style: pw.TextStyle(
                                fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                            currencyFormat
                                .format(saleData['sub_total'] ?? widget.total),
                            style: pw.TextStyle(
                                fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      debugPrint('PDF content created, closing loading dialog');
      if (mounted) {
        // Navigator.of(context).pushNamedAndRemoveUntil(
        //   AppRoutes.pembelianPage,
        //   (Route<dynamic> route) => false,
        // );
      }

      debugPrint('Showing PDF preview');

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      debugPrint('PDF generation completed successfully');
    } catch (e) {
      debugPrint('Error in PDF generation: $e');
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.pembelianPage,
          (Route<dynamic> route) => false,
        );
      }
    }
    _isGeneratingPdf = false;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDefaults.padding / 2),
      child: Material(
        borderRadius: AppDefaults.borderRadius,
        color: AppColors.scaffoldBackground,
        child: InkWell(
          borderRadius: AppDefaults.borderRadius,
          child: Container(
            width: 176,
            height: 296,
            padding: const EdgeInsets.all(AppDefaults.padding),
            decoration: BoxDecoration(
              border: Border.all(width: 0.1, color: AppColors.placeholder),
              borderRadius: AppDefaults.borderRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  widget.memberStatus,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.black),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Text(
                  "Tanggal: ${widget.tanggal}",
                ),
                SizedBox(height: 8),
                Text(
                  "Dibuat oleh: ${widget.createdBy}",
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Harga : Rp. ${widget.total}',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_red_eye, size: 20),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.resultPembelian,
                          arguments: {'saleId': widget.saleId},
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.download, size: 20),
                      onPressed: () {
                        generatePdf(context, widget.saleId);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}