
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grocery/core/components/data_user.dart';
import 'package:grocery/core/components/product_tile_square.dart';
import 'package:grocery/core/constants/constants.dart';
import 'package:grocery/core/models/dummy_product_model.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:grocery/core/routes/app_routes.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
   Future<void> _exportToExcel(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final excel = Excel.createExcel();
      final sheet = excel['User Data'];
      final List<String> headers = ['Name', 'Email', 'Role'];

      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);  // Gunakan TextCellValue
        cell.cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      // Ambil data pengguna dari Firestore
      final userQuery = await FirebaseFirestore.instance.collection('user').get();
      int rowIndex = 1;
      for (var userDoc in userQuery.docs) {
        final userData = userDoc.data();
        final name = userData['name'] ?? 'Unknown';
        final email = userData['email'] ?? 'Unknown';
        final role = userData['role'] ?? 'Unknown';

        // Masukkan data pengguna ke Excel
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = TextCellValue(name);  // Gunakan TextCellValue
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = TextCellValue(email); // Gunakan TextCellValue
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
            .value = TextCellValue(role);  // Gunakan TextCellValue

        rowIndex++;
      }

      // Atur lebar kolom
      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20);
      }

      final fileBytes = excel.encode();
      if (fileBytes == null) {
        throw Exception("Failed to generate Excel file");
      }

      final directory = await getExternalStorageDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory!.path}/user_data_$timestamp.xlsx';

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
        title: const Text('User'),
        leading: const BackButton(),
        actions: [
          if (role == 'admin')
           IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export to Excel',
            onPressed: () => _exportToExcel(context),
          ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Tambah Data',
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.addUser);
              },
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('user').snapshots(),
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
              childAspectRatio: 1.2,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final document = docs[index];
              final documentId = document.id;
              final data = document.data() as Map<String, dynamic>;
              final user = UserModel.fromFirestore(data);

              return DataUser(
                data: user,
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
