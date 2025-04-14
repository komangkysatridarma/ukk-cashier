
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grocery/core/components/app_back_button.dart';
import 'package:grocery/core/constants/app_colors.dart';
import 'package:grocery/core/constants/app_defaults.dart';
import 'package:grocery/core/routes/app_routes.dart';

class IsMember extends StatefulWidget {
  const IsMember({super.key});

  @override
  State<IsMember> createState() => _IsMemberState();
}

class _IsMemberState extends State<IsMember> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController pointsController = TextEditingController();
  int points = 0;
  bool isFirstTimePurchase = true;
  bool usePoints = false;
  DocumentSnapshot? memberData;
  int pointsToUse = 0;
  int totalPrice = 0;

  bool _isInitialized = false;
  late Map<String, dynamic> arguments;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      arguments =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
              {};
      phoneController.text = arguments['phoneNumber'] ?? '';

      // Set the class-level totalPrice variable
      totalPrice = arguments['totalPrice'] ?? 0;
      points = (totalPrice / 100).floor();
      pointsController.text = points.toString();

      // Check if member exists
      _checkMemberStatus();

      _isInitialized = true;
    }
  }

  Future<void> _checkMemberStatus() async {
    try {
      final FirebaseFirestore db = FirebaseFirestore.instance;
      final docRef = db.collection('members').doc(phoneController.text);
      memberData = await docRef.get();

      if (memberData!.exists) {
        // Member already exists, this is not their first purchase
        setState(() {
          isFirstTimePurchase = false;
          nameController.text = memberData!.get('name') ?? '';
          // Get existing points
          int existingPoints = memberData!.get('points') ?? 0;
          // Display total points (existing + new)
          pointsController.text = (existingPoints + points).toString();
        });
      } else {
        // New member, first time purchase
        setState(() {
          isFirstTimePurchase = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data member: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    pointsController.dispose();
    super.dispose();
  }

  Future<void> _saveMemberData() async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama member harus diisi'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final FirebaseFirestore db = FirebaseFirestore.instance;

      // Calculate points to save
      int pointsToSave = 0;
      int pointsUsed = usePoints ? (arguments['pointsUsed'] ?? 0) : 0;

      if (isFirstTimePurchase) {
        // First time purchase, just add new points
        pointsToSave = points;
      } else {
        // Existing member
        int existingPoints = memberData?.get('points') ?? 0;

        // Subtract used points and add new points
        pointsToSave = existingPoints - pointsUsed + points;
      }

      // Create data map for saving
      Map<String, dynamic> memberDataToSave = {
        'name': nameController.text,
        'phone': phoneController.text,
        'points': pointsToSave,
        'updated_at': Timestamp.now(),
      };

      // Only add created_at for new members
      if (isFirstTimePurchase) {
        memberDataToSave['created_at'] = Timestamp.now();
      }

      await db.collection('members').doc(phoneController.text).set(
            memberDataToSave,
            SetOptions(merge: true),
          );

      // Calculate discounted total
      int discountedTotal = totalPrice;
      if (usePoints) {
        discountedTotal = totalPrice - pointsUsed;
      }

      // Calculate the change amount
      int totalPaid = arguments['totalPaid'] ?? 0;
      int changeAmount = totalPaid - discountedTotal;

      // Also update the sale record to include point information
      final saleId = arguments['saleId'];
      await db.collection('sales').doc(saleId).update({
        'point_used': pointsUsed,
        'original_total': totalPrice, // Store the original total
        'sub_total':
            discountedTotal, // Update sub_total to the discounted amount
        'total_paid': totalPaid, // Add the total amount paid by customer
        'change': changeAmount, // Add the correct change amount
      });

      Navigator.pushNamed(
        context,
        AppRoutes.resultPembelian,
        arguments: {
          'message': isFirstTimePurchase
              ? 'Pembayaran berhasil! Member telah terdaftar.'
              : 'Pembayaran berhasil!',
          'saleId': saleId,
          'pointsUsed': pointsUsed,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan data member: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalPaid = arguments['totalPaid'] ?? 0;
    // Calculate the current total to pay based on points usage
    final int currentTotalToPay =
        usePoints ? (arguments['discountedTotal'] ?? totalPrice) : totalPrice;
    // Calculate the correct change amount
    final int changeAmount = totalPaid - currentTotalToPay;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TAMBAH MEMBER'),
        leading: const AppBackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDefaults.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ringkasan transaksi
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ringkasan Transaksi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryRow('Total Harga', 'Rp. $totalPrice'),
                  if (usePoints)
                    _buildSummaryRow('Diskon Poin',
                        '- Rp. ${arguments['pointsUsed'] ?? 0}'),
                  _buildSummaryRow('Total Bayar', 'Rp. $currentTotalToPay'),
                  _buildSummaryRow('Kembalian', 'Rp. $changeAmount'),
                  _buildSummaryRow('Poin Didapat', '$points poin'),
                  if (!isFirstTimePurchase && usePoints)
                    _buildSummaryRow('Poin Digunakan',
                        '${arguments['pointsUsed'] ?? 0} poin'),
                ],
                ),
              ),
            ),

            // Form data member
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data Member',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status Member
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isFirstTimePurchase
                            ? Colors.blue.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isFirstTimePurchase
                                ? Icons.person_add
                                : Icons.person,
                            color: isFirstTimePurchase
                                ? Colors.blue
                                : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isFirstTimePurchase
                                ? 'Member Baru'
                                : 'Member Terdaftar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isFirstTimePurchase
                                  ? Colors.blue
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nomor Telepon
                    const Text(
                      'No. Telepon',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      readOnly: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nama Member
                    const Text(
                      'Nama Member',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        hintText: 'Masukkan nama member',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Poin with Checkbox
                    Row(
                      children: [
                        const Text(
                          'Poin',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        if (!isFirstTimePurchase) ...[
                          const Text('Gunakan Poin'),
                          const SizedBox(width: 8),
                          Checkbox(
                            value: usePoints,
                            onChanged: (value) {
                              setState(() {
                                usePoints = value ?? false;
                                if (usePoints) {
                                  // When toggled on, calculate available points to use
                                  int existingPoints =
                                      memberData?.get('points') ?? 0;
                                  pointsToUse = existingPoints > totalPrice
                                      ? totalPrice
                                      : existingPoints;

                                  // Update the arguments to include points used
                                  arguments['pointsUsed'] = pointsToUse;
                                  arguments['discountedTotal'] =
                                      totalPrice - pointsToUse;
                                } else {
                                  pointsToUse = 0;
                                  arguments['pointsUsed'] = 0;
                                  arguments['discountedTotal'] = totalPrice;
                                }
                              });
                            },
                          )
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: pointsController,
                      readOnly: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        suffixText: 'poin',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isFirstTimePurchase)
                      Text(
                        'Poin tidak bisa digunakan saat pertama kali belanja!',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (!isFirstTimePurchase && usePoints)
                      Text(
                        'Poin yang digunakan: ${arguments['pointsUsed'] ?? 0} poin',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppDefaults.padding),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _saveMemberData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isFirstTimePurchase ? 'Simpan Data Member' : 'Simpan Perubahan',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}