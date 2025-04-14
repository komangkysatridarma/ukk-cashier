import 'package:flutter/material.dart';
import 'package:grocery/core/components/app_back_button.dart';
import 'package:grocery/core/components/product_tile_square.dart';
import 'package:grocery/core/components/tambah_pembelian_page.dart';
import 'package:grocery/core/constants/app_defaults.dart';
import 'package:grocery/core/constants/dummy_data.dart';
import 'package:grocery/core/models/dummy_product_model.dart';
import 'package:grocery/core/routes/app_routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DataPembelianPage extends StatefulWidget {
  const DataPembelianPage({
    super.key,
    this.isHomePage = false,
  });

  final bool isHomePage;

  @override
  State<DataPembelianPage> createState() => _DataPembelianPageState();
}

class _DataPembelianPageState extends State<DataPembelianPage> {
  Map<String, Map<String, dynamic>> selectedProducts = {};
  int get totalSelectedProducts =>
      selectedProducts.values.where((data) => data['quantity'] > 0).length;

  int get totalPrice {
    int total = 0;
    try {
      selectedProducts.forEach((key, data) {
        final quantity = data['quantity'] as int? ?? 0;
        if (quantity > 0) {
          try {
            final subtotal = data['subtotal'];
            if (subtotal != null) {
              total += subtotal as int;
            } else {
              final product = data['product'] as ProductModel;
              total += product.price.toInt() * quantity;
            }
          } catch (e) {
            print("Error in totalPrice calculation: $e");
          }
        }
      });
    } catch (e) {
      print("Error in totalPrice: $e");
    }
    return total;
  }

  int get totalItems {
    int total = 0;
    selectedProducts.forEach((key, data) {
      final quantity = data['quantity'] as int? ?? 0;
      if (quantity > 0) {
        total += quantity;
      }
    });
    return total;
  }

  void _updateSelectedProduct(
      ProductModel product, int quantity, String? documentId) {
    if (documentId == null) return;

    try {
      final subtotal = product.price.toInt() * quantity;
      setState(() {
        selectedProducts[documentId] = {
          'product': product,
          'quantity': quantity,
          'subtotal': subtotal,
          'documentId': documentId,
        };
      });
    } catch (e) {
      print("Error in _updateSelectedProduct: $e for product: ${product.name}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Produk'),
        leading: const AppBackButton(),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('produk').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("Terjadi error: ${snapshot.error}"));
            }

            final docs = snapshot.data?.docs ?? [];

            return Column(
              children: [
                if (totalSelectedProducts > 0)
                  Container(
                    padding: const EdgeInsets.all(AppDefaults.padding),
                    margin: const EdgeInsets.all(AppDefaults.padding),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: AppDefaults.borderRadius,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Produk: $totalSelectedProducts jenis'),
                            Text('Total Item: $totalItems'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Harga:'),
                            Text(
                              'Rp. $totalPrice',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Grid produk
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.only(top: AppDefaults.padding),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.55,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final document = docs[index];
                      final documentId = document.id;
                      final data = document.data() as Map<String, dynamic>;
                      final product = ProductModel.fromFirestore(data);

                      // Get the current selection or default to 0
                      final currentSelection = selectedProducts[documentId];
                      final initialQuantity =
                          (currentSelection?['quantity'] as int?) ?? 0;

                      return TambahPembelianPage(
                        data: product,
                        documentId: documentId,
                        onQuantityChanged: (ProductModel product, int quantity,
                            String? docId) {
                          _updateSelectedProduct(product, quantity, docId);
                        },
                        initialQuantity: initialQuantity,
                      );
                    },
                  ),
                ),
              ],
            );
          }),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppDefaults.padding),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: totalSelectedProducts > 0
                ? () {
                    // Filter out products with quantity 0
                    final filteredProducts =
                        Map<String, Map<String, dynamic>>.from(selectedProducts)
                          ..removeWhere((key, value) => value['quantity'] <= 0);
                          
                    Navigator.pushNamed(
                      context,
                      AppRoutes.addMember,
                      arguments: {
                        'products': filteredProducts,
                        'totalPrice': totalPrice,
                        'totalItems': totalItems,
                      },
                    );
                  }
                : () {
                    // Tampilkan pesan untuk memilih produk
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Silakan pilih minimal 1 produk terlebih dahulu'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  totalSelectedProducts > 0 ? null : Colors.grey.shade300,
            ),
            child: Text(
              totalSelectedProducts > 0
                  ? 'Selanjutnya (Rp. $totalPrice)'
                  : 'Pilih minimal 1 produk',
              style: TextStyle(
                color: totalSelectedProducts > 0 ? null : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}