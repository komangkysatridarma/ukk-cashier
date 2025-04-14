
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/scheduler.dart';
import 'package:grocery/core/models/dummy_product_model.dart';
import 'package:image_picker/image_picker.dart';

class EditProductPage extends StatefulWidget {
  const EditProductPage({super.key});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _gambarController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();

  late String _productId;
  File? gambar;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args != null && args is Map<String, dynamic>) {
      final product = args['product'] as ProductModel?;
      final String? productId = args['productId'];

      if (product != null && productId != null) {
        _productId = productId;
        _namaController.text = product.name;
        _gambarController.text = product.images;
        _hargaController.text = product.price.toString();
      } else {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data produk tidak lengkap')));
          Navigator.pop(context);
        });
      }
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada data produk')));
        Navigator.pop(context);
      });
    }
  }

  Future<void> pilihGambar() async {
    final img = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img != null) setState(() => gambar = File(img.path));
  }

  Future<void> _simpanProduk() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String base64Image;

        if (gambar != null) {
          final bytes = await gambar!.readAsBytes();
          base64Image = base64Encode(bytes);
        } else {
          base64Image = _gambarController.text;
        }

        await FirebaseFirestore.instance
            .collection('produk')
            .doc(_productId)
            .update({
          'nama': _namaController.text,
          'gambarBase64': base64Image,
          'harga': int.parse(_hargaController.text),
        }).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Timeout saat update data');
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Produk berhasil diupdate')));
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal update produk: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Produk')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _namaController,
                        decoration:
                            const InputDecoration(labelText: 'Nama Produk'),
                        validator: (value) =>
                            value!.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: pilihGambar,
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: gambar != null
                              ? Image.file(gambar!, fit: BoxFit.cover)
                              : _gambarController.text.isNotEmpty
                                  ? Image.memory(
                                      base64Decode(
                                        _gambarController.text.contains(',')
                                            ? _gambarController.text
                                                .split(',')
                                                .last
                                            : _gambarController.text,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : const Center(child: Text('Pilih Gambar')),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _hargaController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Harga Produk'),
                        validator: (value) =>
                            value!.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _simpanProduk,
                        child: const Text('Simpan Perubahan'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _gambarController.dispose();
    _hargaController.dispose();
    super.dispose();
  }
}