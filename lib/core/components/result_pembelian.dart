import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grocery/core/components/app_back_button.dart';
import 'package:grocery/core/constants/app_colors.dart';
import 'package:grocery/core/constants/app_defaults.dart';
import 'package:grocery/core/routes/app_routes.dart';
import 'package:grocery/views/entrypoint/entrypoint_ui.dart';
// import 'package:grocery/views/entrypoint/entrypoint_petugas_ui.dart';
import 'package:intl/intl.dart';

class ResultPembelianPage extends StatefulWidget {
  const ResultPembelianPage({super.key});

  @override
  State<ResultPembelianPage> createState() => _ResultPembelianPageState();
}

class _ResultPembelianPageState extends State<ResultPembelianPage> {
  String saleId = '';
  Map<String, dynamic>? saleData;
  List<Map<String, dynamic>> saleDetails = [];
  bool isLoading = true;
  bool _didInitialize = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only run this once when the widget is first built
    if (!_didInitialize) {
      _didInitialize = true;

      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        saleId = args['saleId'] ?? '';
        _fetchSaleData();
      } else {
        setState(() {
          isLoading = false;
        });

        // Show error if no arguments were passed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No sale ID provided')),
          );
        });
      }
    }
  }

  Future<void> _fetchSaleData() async {
    try {
      // Get sale data
      final saleDoc = await FirebaseFirestore.instance
          .collection('sales')
          .doc(saleId)
          .get();

      if (saleDoc.exists) {
        setState(() {
          saleData = saleDoc.data();
        });

        // Get sale details
        final detailsQuery = await FirebaseFirestore.instance
            .collection('sale_details')
            .where('sale_id', isEqualTo: saleId)
            .get();

        final details = detailsQuery.docs.map((doc) {
          final data = doc.data();
          return {
            'product_id': data['product_id'],
            'qty': data['qty'],
            'total_price': data['total_price'],
          };
        }).toList();

        // Get product names
        for (var detail in details) {
          final productDoc = await FirebaseFirestore.instance
              .collection('produk')
              .doc(detail['product_id'])
              .get();

          if (productDoc.exists) {
            detail['product_name'] =
                productDoc.data()?['nama'] ?? 'Unknown Product';
            detail['product_price'] = productDoc.data()?['harga'] ?? 0;
          }
        }

        setState(() {
          saleDetails = details;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });

        // Show error if sale document doesn't exist
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sale with ID $saleId not found')),
          );
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      // Show error message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp. ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Pembelian'),
        leading: const AppBackButton(),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDefaults.padding),
              child: Column(
                children: [
                  // Header
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Invoice - #${saleData?['no_sales'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('dd MMMM yyyy').format(
                            (saleData?['date'] as Timestamp?)?.toDate() ??
                                DateTime.now(),
                          ),
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

                  // Product Table
                  Table(
                    border: TableBorder.all(color: Colors.grey.shade300),
                    columnWidths: const {
                      0: FlexColumnWidth(3),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(1),
                      3: FlexColumnWidth(2),
                    },
                    children: [
                      // Header Row
                      const TableRow(
                        decoration: BoxDecoration(
                          color: AppColors.scaffoldBackground,
                        ),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Produk',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Harga',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Qty',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Sub Total',
                              textAlign: TextAlign.end,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),

                      // Product Rows
                      ...saleDetails.map((detail) => TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(detail['product_name'] ?? ''),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(currencyFormat
                                    .format(detail['product_price'] ?? 0)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('${detail['qty'] ?? 0}'),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  currencyFormat
                                      .format(detail['total_price'] ?? 0),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          )),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Additional Info
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1),
                      1: FlexColumnWidth(2),
                    },
                    children: [
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('POIN DIGUNAKAN'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('${saleData?['point_used'] ?? 0}'),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('KASIR'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(saleData?['created_by'] ?? 'Petugas'),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('KEMBALIAN'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              currencyFormat.format(saleData?['change'] ?? 0),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Total
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        // Original Subtotal
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'SUBTOTAL',
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              currencyFormat.format(
                                  saleData?['original_total'] ??
                                      saleData?['sub_total'] ??
                                      0),
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),

// Show discount if points were used
                        if ((saleData?['point_used'] ?? 0) > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'DISKON POIN',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.red,
                                  ),
                                ),
                                Text(
                                  '- ${currencyFormat.format(saleData?['point_used'] ?? 0)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),

// Divider for visual separation
                        const Divider(),

// Final total after discount
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL BAYAR',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              currencyFormat
                                  .format(saleData?['sub_total'] ?? 0),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Implement print functionality
                          },
                          child: const Text('Cetak'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                           Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EntryPointUI(
                                  initialIndex: 2,
                                ),
                              ),
                              (route) => false,
                            );
                          },
                          child: const Text('Selesai'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}