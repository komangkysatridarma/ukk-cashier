
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grocery/core/components/app_back_button.dart';
import 'package:grocery/core/constants/app_colors.dart';
import 'package:grocery/core/constants/app_defaults.dart';
import 'package:grocery/core/models/dummy_product_model.dart';
import 'package:grocery/core/routes/app_routes.dart';

class DataMemberPage extends StatefulWidget {
  const DataMemberPage({super.key});

  @override
  State<DataMemberPage> createState() => _DataMemberPageState();
}

class _DataMemberPageState extends State<DataMemberPage> {
  String memberStatus = 'Non Member';
  final List<String> memberOptions = ['Member', 'Non Member'];
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController totalBayarController = TextEditingController();
  bool isMember = false;

  @override
  void dispose() {
    phoneController.dispose();
    totalBayarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> arguments =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final Map<String, Map<String, dynamic>> products = arguments['products'];
    final int totalPrice = arguments['totalPrice'];
    final int totalItems = arguments['totalItems'];

    totalBayarController.text =
        totalPrice.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('PENJUALAN'),
        leading: const AppBackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDefaults.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Produk yang dipilih',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Nama Produk',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Harga',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Jumlah',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Subtotal',
                            textAlign: TextAlign.end,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    ...products.entries.map((entry) {
                      final product = entry.value['product'] as ProductModel;
                      final quantity = entry.value['quantity'] as int? ?? 0;
                      final subtotal = entry.value['subtotal'] as int? ?? 0;

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(product.name),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('Rp. ${product.price.toInt()}'),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '$quantity',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Rp. $subtotal',
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                        ],
                      );
                    }).toList(),

                    // Total
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'Total Harga : ',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Rp. $totalPrice',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),


            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Member Status',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: memberStatus,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          items: memberOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              memberStatus = newValue!;
                              isMember = memberStatus == 'Member';
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (isMember) ...[
                      const Text(
                        'No. Telepon',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          hintText: 'Masukkan nomor telepon',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Total Bayar field
                    // const Text(
                    //   'Total Bayar',
                    //   style: TextStyle(fontWeight: FontWeight.w500),
                    // ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: totalBayarController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppDefaults.padding),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () async {
              final String totalBayarText = totalBayarController.text;
              print("Raw totalBayarText: '$totalBayarText'");

              final String cleanedText =
                  totalBayarText.replaceAll(RegExp(r'[^0-9]'), '');
              print("Cleaned totalBayarText: '$cleanedText'");

              int? totalBayar;
              try {
                totalBayar = int.parse(cleanedText);
                print("Parsed totalBayar: $totalBayar");
              } catch (e) {
                print("Parse error: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Total bayar harus berupa angka yang valid'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }

              if (totalBayar < totalPrice) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Total bayar harus lebih besar atau sama dengan total harga'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }

              if (isMember && phoneController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nomor telepon harus diisi'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }

              try {
                final FirebaseFirestore db = FirebaseFirestore.instance;

                final DocumentReference salesRef =
                    await db.collection('sales').add({
                  'date': Timestamp.now(),
                  'no_sales': 'SLS-${DateTime.now().millisecondsSinceEpoch}',
                  'amount_paid': totalBayar,
                  'change': totalBayar - totalPrice,
                  'point_used': 0,
                  'sub_total': totalPrice,
                  'created_by': 'Petugas',
                  'member_id': isMember
                      ? phoneController.text
                      : null, 
                });

                for (var entry in products.entries) {
                  final product = entry.value['product'] as ProductModel;
                  final quantity = entry.value['quantity'] as int? ?? 0;
                  final subtotal = entry.value['subtotal'] as int? ?? 0;
                  final documentId = entry.value['documentId'] as String?;
                  if (documentId == null) {
                    print(
                        "Warning: documentId is null for product ${product.name}");
                    continue;
                  }

                  await db.collection('sale_details').add({
                    'sale_id': salesRef.id,
                    'product_id': documentId,
                    'qty': quantity,
                    'total_price': subtotal,
                  });

                  // Update stok produk
                  try {
                    final docRef = db.collection('produk').doc(documentId);
                    final docSnap = await docRef.get();
                    if (docSnap.exists) {
                      final data = docSnap.data() as Map<String, dynamic>?;
                      if (data != null) {
                        final currentStock = data['stok'] as int? ?? 0;
                        await docRef.update({'stok': currentStock - quantity});
                      }
                    }
                  } catch (e) {
                    print(
                        "Error updating stock for product ${product.name}: $e");
                  }
                }
                if (isMember) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.isMember,
                    arguments: {
                      'phoneNumber': phoneController.text,
                      'saleId': salesRef.id,
                      'totalPrice': totalPrice,
                      'totalPaid': totalBayar,
                    },
                  );
                } else {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.resultPembelian,
                    arguments: {
                      'message': 'Pembayaran berhasil!',
                      'saleId': salesRef.id,
                    },
                  );
                }
              } catch (e) {
                print("Error during Firebase operations: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Terjadi kesalahan: $e'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.primary, 
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isMember ? 'Lanjutkan' : 'Pesan',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}