import 'package:flutter/material.dart';

import '../../core/components/app_back_button.dart';
import '../../core/components/product_tile_square.dart';
import '../../core/constants/constants.dart';

class CategoryProductPage extends StatelessWidget {
  const CategoryProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product'),
        leading: const AppBackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Data',
            onPressed: () {
              // Aksi ketika tombol ditekan, misalnya buka form tambah produk
              // Navigator.pushNamed(context, AppRoutes.addProduct);
            },
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.only(top: AppDefaults.padding),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          childAspectRatio: 0.57,
        ),
        itemCount: 16,
        itemBuilder: (context, index) {
          return ProductTileSquare(
            data: Dummy.products.first,
          );
        },
      ),
    );
  }
}
