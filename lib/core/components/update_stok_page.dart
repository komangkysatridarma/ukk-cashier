import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UpdateStokPage extends StatefulWidget {
  const UpdateStokPage({super.key});

  @override
  State<UpdateStokPage> createState() => _UpdateStokPageState();
}

class _UpdateStokPageState extends State<UpdateStokPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _stokController = TextEditingController();
  late String _productId;
  String _productName = '';
  int _currentStock = 0;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args != null && args is Map<String, dynamic>) {
      final String? productId = args['productId'];

      if (productId != null) {
        _productId = productId;
        _fetchProductData();
      } else {
        _showError('ID Produk tidak valid');
      }
    } else {
      _showError('Tidak ada data yang dikirim');
    }
  }

  void _showError(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      Navigator.pop(context);
    });
  }

  Future<void> _fetchProductData() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('produk')
          .doc(_productId)
          .get();

      if (!docSnapshot.exists) {
        _showError('Produk tidak ditemukan');
        return;
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      setState(() {
        _productName = data['nama'] ?? 'Produk';
        _currentStock = data['stok'] ?? 0;
        _stokController.text = _currentStock.toString();
        _isLoading = false;
      });
    } catch (e) {
      _showError('Gagal memuat data produk: $e');
    }
  }

  Future<void> _updateStock() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final newStock = int.parse(_stokController.text);

        await FirebaseFirestore.instance
            .collection('produk') 
            .doc(_productId)
            .update({
          'stok': newStock,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Stok berhasil diupdate')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update stok: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Stok Produk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchProductData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nama Produk',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            Text(
                              _productName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Stok Saat Ini',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            Text(
                              '$_currentStock',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _stokController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stok Baru',
                        border: OutlineInputBorder(),
                        hintText: 'Masukkan jumlah stok baru',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Stok tidak boleh kosong';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Stok harus berupa angka';
                        }
                        if (int.parse(value) < 0) {
                          return 'Stok tidak boleh negatif';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.remove),
                            label: const Text('Kurangi 1'),
                            onPressed: () {
                              int current =
                                  int.tryParse(_stokController.text) ?? 0;
                              if (current > 0) {
                                _stokController.text = (current - 1).toString();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Tambah 1'),
                            onPressed: () {
                              int current =
                                  int.tryParse(_stokController.text) ?? 0;
                              _stokController.text = (current + 1).toString();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateStock,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('SIMPAN PERUBAHAN STOK'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _stokController.dispose();
    super.dispose();
  }
}