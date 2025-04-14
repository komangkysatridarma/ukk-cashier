
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grocery/core/components/product_tile_square.dart';
import 'package:grocery/core/constants/constants.dart';
import 'package:grocery/core/models/dummy_product_model.dart';
import 'package:grocery/core/routes/app_routes.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class CategoryProductPage extends StatefulWidget {
  const CategoryProductPage({super.key});

  @override
  State<CategoryProductPage> createState() => _CategoryProductPageState();
}

class _CategoryProductPageState extends State<CategoryProductPage> {
  Future<void> _exportProdukToExcel(BuildContext context) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const Center(child: CircularProgressIndicator());
    },
  );

  try {
    final excel = Excel.createExcel();
    final sheet = excel['Produk'];

    final List<String> headers = ['Nama', 'Harga', 'Stok'];

    // Tambahkan header
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Ambil data produk dari Firestore
    final produkQuery = await FirebaseFirestore.instance.collection('produk').get();

    int rowIndex = 1;
    for (var doc in produkQuery.docs) {
      final data = doc.data();
      final nama = data['nama'] ?? 'Tidak Diketahui';
      final harga = data['harga']?.toString() ?? '0';
      final stok = data['stok']?.toString() ?? '0';

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value =
          TextCellValue(nama);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value =
          TextCellValue(harga);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value =
          TextCellValue(stok);

      rowIndex++;
    }

    // Set lebar kolom
    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    final fileBytes = excel.encode();
    if (fileBytes == null) throw Exception("Gagal membuat file Excel");

    final directory = await getExternalStorageDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${directory!.path}/produk_data_$timestamp.xlsx';

    final file = File(filePath);
    await file.writeAsBytes(fileBytes);

    if (context.mounted) Navigator.pop(context);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('File Excel berhasil disimpan!'),
          action: SnackBarAction(
            label: 'Buka',
            onPressed: () {
              OpenFile.open(filePath);
            },
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) Navigator.pop(context);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengekspor data: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final role = args?['role'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk'),
        leading: const BackButton(),
        actions: [
          if (role == 'admin') ...[
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Tambah Data',
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.addProduct);
              },
            ),
            IconButton(
              icon: const Icon(Icons.file_download),
              tooltip: 'Export ke Excel',
              onPressed: () => _exportProdukToExcel(context),
            ),
        ],
        ]
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

          return GridView.builder(
            padding: const EdgeInsets.only(top: AppDefaults.padding),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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

              return ProductTileSquare(
                data: product,
                documentId: documentId,
                documentData: data,
              );
            },
          );
        },
      ),
    );
  }
}