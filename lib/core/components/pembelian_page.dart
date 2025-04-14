import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:grocery/core/components/app_back_button.dart';
import 'package:grocery/core/components/pembelian_dummy.dart';
import 'package:grocery/core/constants/app_defaults.dart';
import 'package:grocery/core/routes/app_routes.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';

class PembelianPage extends StatelessWidget {
  const PembelianPage({
    super.key,
    this.isHomePage = false,
  });

  final bool isHomePage;

  Future<void> _exportToExcel(BuildContext context) async {

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      final excel = Excel.createExcel();
      final Sheet sheet = excel['Sales Data'];
      final List<String> headers = [
        'No.',
        'Tanggal',
        'No. Invoice',
        'Customer Name',
        'Phone Number',
        'Points',
        'Subtotal',
        'Point Used',
        'Total Bayar',
        'Dibuat Oleh'
      ];

      for (var i = 0; i < headers.length; i++) {
        final cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      final salesQuery = await FirebaseFirestore.instance
          .collection('sales')
          .orderBy('date', descending: true)
          .get();

      int rowIndex = 1;
      for (var saleDoc in salesQuery.docs) {
        final saleData = saleDoc.data();
        final saleId = saleDoc.id;

        final date = saleData['date'] != null
            ? (saleData['date'] as Timestamp).toDate()
            : DateTime.now();
        final formattedDate = DateFormat('dd/MM/yyyy').format(date);

        String customerName = 'NON-MEMBER';
        String phoneNumber = '-';
        int points = 0;

        if (saleData['member_id'] != null) {
          try {
            final memberDoc = await FirebaseFirestore.instance
                .collection('members')
                .doc(saleData['member_id'])
                .get();

            if (memberDoc.exists) {
              final memberData = memberDoc.data()!;
              customerName = memberData['name'] ?? 'Unknown';
              phoneNumber = memberData['phone'] ?? '-';
              points = memberData['points'] ?? 0;
            }
          } catch (e) {
            debugPrint('Error fetching member data: $e');
          }
        }

        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = TextCellValue(rowIndex.toString());
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = TextCellValue(formattedDate);
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
            .value = TextCellValue(saleData['no_sales'] ?? saleId);
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
            .value = TextCellValue(customerName);
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
            .value = TextCellValue(phoneNumber);
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
            .value = IntCellValue(points);
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
            .value = DoubleCellValue(saleData['original_total']
                ?.toDouble() ??
            saleData['sub_total']?.toDouble() ??
            0);
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
            .value = IntCellValue(saleData['point_used'] ?? 0);
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
            .value = DoubleCellValue(saleData['sub_total']?.toDouble() ?? 0);
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex))
            .value = TextCellValue(saleData['created_by'] ?? 'Unknown');

        rowIndex++;
      }

      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20);
      }

      final fileBytes = excel.encode();
      if (fileBytes == null) {
        throw Exception("Failed to generate Excel file");
      }

      final directory = await getExternalStorageDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory!.path}/sales_data_$timestamp.xlsx';

      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel file saved successfully!'),
            action: SnackBarAction(
              label: 'Open',
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
            content: Text('Failed to export data: ${e.toString()}'),
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
        title: const Text('Pembelian'),
        leading: const AppBackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export to Excel',
            onPressed: () => _exportToExcel(context),
          ),
          if (role == 'petugas')
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Tambah Data',
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.addPembelian);
              },
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sales')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final salesDocs = snapshot.data?.docs ?? [];

          if (salesDocs.isEmpty) {
            return const Center(child: Text("Belum ada data penjualan"));
          }

          return GridView.builder(
            padding: const EdgeInsets.only(top: AppDefaults.padding),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              childAspectRatio: 0.90,
            ),
            itemCount: salesDocs.length,
            itemBuilder: (context, index) {
              final doc = salesDocs[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final saleId = doc.id;

              final date = data['date'] != null
                  ? (data['date'] as Timestamp).toDate()
                  : DateTime.now();
              final formattedDate = "${date.day}/${date.month}/${date.year}";

              return FutureBuilder<DocumentSnapshot>(
                future: data['member_id'] != null
                    ? FirebaseFirestore.instance
                        .collection('members')
                        .doc(data['member_id'])
                        .get()
                    : null,
                builder: (context, memberSnapshot) {
                  String memberStatus;
                  String memberName = 'Unknown';

                  if (data['member_id'] == null) {
                    memberStatus = 'NON-MEMBER';
                  } else if (memberSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    memberStatus = 'Loading...';
                  } else if (memberSnapshot.hasError) {
                    memberStatus = 'MEMBER - Error';
                  } else {
                    final memberData = memberSnapshot.data?.data();
                    if (memberData != null) {
                      memberName = (memberData as Map<String, dynamic>)['name']
                              ?.toString() ??
                          'Unknown';
                    }
                    memberStatus = '$memberName';
                  }

                  return PembelianDummy(
                    saleId: saleId,
                    memberStatus: memberStatus,
                    tanggal: formattedDate,
                    createdBy: data['created_by']?.toString() ?? 'Unknown',
                    total: (data['sub_total'] ?? 0),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}