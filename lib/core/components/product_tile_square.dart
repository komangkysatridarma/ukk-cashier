import 'dart:convert';
// ignore: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../constants/constants.dart';
import '../models/dummy_product_model.dart';
import '../routes/app_routes.dart';

class ProductTileSquare extends StatefulWidget {
  const ProductTileSquare({
    super.key,
    required this.data,
    this.documentId,
    this.documentData,
  });

  final ProductModel data;
  final String? documentId;
  final Map<String, dynamic>? documentData;

  @override
  State<ProductTileSquare> createState() => _ProductTileSquareState();
}

class _ProductTileSquareState extends State<ProductTileSquare> {
  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final role = args?['role'];
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
                Padding(
                  padding: const EdgeInsets.all(AppDefaults.padding / 2),
                  child: AspectRatio(
                    aspectRatio: 1 / 1,
                    child: widget.data.images.isNotEmpty
                        ? Image.memory(
                            base64Decode(
                              widget.data.images.contains(',')
                                  ? widget.data.images.split(',').last
                                  : widget.data.images,
                            ),
                            fit: BoxFit.contain,
                          )
                        : const Placeholder(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.data.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.black),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text("Stok: ${widget.data.stock}"),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rp. ${widget.data.price.toInt()}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (role == 'admin') ...[
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {
                        print("DocumentID: ${widget.documentId}");
                        print("Product Data: ${widget.data.toString()}");

                        if (widget.documentId != null) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.editProduct,
                            arguments: {
                              'product': widget.data,
                              'productId': widget.documentId,
                            },
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('ID Produk tidak ditemukan')),
                          );
                        }
                      },
                    ),
                   
                        IconButton(
                          icon: const Icon(Icons.inventory, size: 20),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.updateStokProduct,
                              arguments: {'productId': widget.documentId},
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () async {
                            bool confirmDelete = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Hapus Produk'),
                                content: const Text('Apakah Anda yakin ingin menghapus produk ini?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );

                            if (confirmDelete == true && widget.documentId != null) {
                              try {
                                await FirebaseFirestore.instance
                                    .collection('produk')
                                    .doc(widget.documentId)
                                    .delete();

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Produk berhasil dihapus')),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Gagal menghapus produk: $e')),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ]
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