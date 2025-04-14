
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:grocery/core/components/network_image.dart';
import 'package:grocery/core/constants/app_colors.dart';
import 'package:grocery/core/constants/app_defaults.dart';
import 'package:grocery/core/models/dummy_product_model.dart';
import 'package:grocery/core/routes/app_routes.dart';

class TambahPembelianPage extends StatefulWidget {
  const TambahPembelianPage({
    super.key,
    required this.data,
    this.documentId,
    this.documentData,
    required this.onQuantityChanged,
    this.initialQuantity = 0,
  });

  final ProductModel data;
  final String? documentId;
  final Map<String, dynamic>? documentData;
  final int initialQuantity;
  final Function(ProductModel, int, String?) onQuantityChanged; // Updated this line

  @override
  State<TambahPembelianPage> createState() => _TambahPembelianPageState();
}

class _TambahPembelianPageState extends State<TambahPembelianPage> {
  late int jumlah;

  @override
  void initState() {
    super.initState();
    jumlah = widget.initialQuantity;
  }

  void _tambahJumlah() {
    if (jumlah < widget.data.stock) {
      setState(() {
        jumlah++;
      });
      widget.onQuantityChanged(widget.data, jumlah, widget.documentId);
    }
  }

  void _kurangiJumlah() {
    if (jumlah > 0) {
      setState(() {
        jumlah--;
      });
      widget.onQuantityChanged(widget.data, jumlah, widget.documentId);
    }
  }

  int get subtotal => jumlah * widget.data.price.toInt();

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
            height: 400,
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
                const SizedBox(height: 4),
                Text("Stok: ${widget.data.stock}"),
                const SizedBox(height: 4),
                Text("Rp. ${widget.data.price.toInt()}"),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _kurangiJumlah,
                      icon: const Icon(Icons.remove),
                    ),
                    Text('$jumlah'),
                    IconButton(
                      onPressed: _tambahJumlah,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                Text(
                  'Sub Total: Rp. $subtotal',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}