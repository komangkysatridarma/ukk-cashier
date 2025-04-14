import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class TambahProdukPage extends StatefulWidget {
  const TambahProdukPage({super.key});
  @override
  State<TambahProdukPage> createState() => _TambahProdukPageState();
}

class _TambahProdukPageState extends State<TambahProdukPage> {
  final _formKey = GlobalKey<FormState>();
  final namaC = TextEditingController(),
      hargaC = TextEditingController(),
      stokC = TextEditingController();
  File? gambar;
  bool loading = false;

  Future<void> pilihGambar() async {
    final img = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img != null) setState(() => gambar = File(img.path));
  }

  Future<void> simpanProduk() async {
  if (!_formKey.currentState!.validate() || gambar == null) return;
  setState(() => loading = true);
  try {
    final bytes = await gambar!.readAsBytes();
    final base64Image = base64Encode(bytes);

    final docRef = await FirebaseFirestore.instance.collection('produk').add({
      'nama': namaC.text,
      'harga': int.parse(hargaC.text),
      'stok': int.parse(stokC.text),
      'gambarBase64': base64Image,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await docRef.update({'id': docRef.id});

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Produk disimpan')));
      Navigator.pop(context);
    }
  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Error: $e')));
  } finally {
    if (mounted) setState(() => loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Produk')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                  controller: namaC,
                  decoration: const InputDecoration(labelText: 'Nama'),
                  validator: (v) => v!.isEmpty ? 'Isi' : null),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: pilihGambar,
                child: Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: gambar != null
                      ? Image.file(gambar!, fit: BoxFit.cover)
                      : const Center(child: Text('Pilih Gambar')),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                  controller: hargaC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Harga'),
                  validator: (v) => v!.isEmpty ? 'Isi' : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: stokC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stok'),
                  validator: (v) => v!.isEmpty ? 'Isi' : null),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: loading ? null : simpanProduk,
                child: Text(loading ? 'Menyimpan...' : 'Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}