
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_defaults.dart';
import '../../core/routes/app_routes.dart';
import 'components/ad_space.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<List<int>> _getWeeklySales() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    List<int> weeklySales = [];

    for (var day in days) {
      final startOfDay = DateTime(day.year, day.month, day.day);
      final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);

      final query = await FirebaseFirestore.instance
          .collection('sales')
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThanOrEqualTo: endOfDay)
          .get();

      weeklySales.add(query.size);
    }

    return weeklySales;
  }

  Future<List<ProductSales>> _getProductSales() async {
    // Get all sales from the last 30 days
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    final salesQuery = await FirebaseFirestore.instance
        .collection('sales')
        .where('date', isGreaterThanOrEqualTo: thirtyDaysAgo)
        .get();

    // Get all sale details - handle Firestore's 30 element limit for 'in' queries
    final saleIds = salesQuery.docs.map((doc) => doc.id).toList();
    final List<QueryDocumentSnapshot> allDetailDocs = [];

    // Process saleIds in batches of 30 (Firestore's limit for 'in' operator)
    for (int i = 0; i < saleIds.length; i += 30) {
      final endIndex = (i + 30 < saleIds.length) ? i + 30 : saleIds.length;
      final batchIds = saleIds.sublist(i, endIndex);

      final batchQuery = await FirebaseFirestore.instance
          .collection('sale_details')
          .where('sale_id', whereIn: batchIds)
          .get();

      allDetailDocs.addAll(batchQuery.docs);
    }

    // Get all products
    final productsQuery =
        await FirebaseFirestore.instance.collection('produk').get();

    // Create product map for quick lookup
    final productMap = {
      for (var doc in productsQuery.docs) doc.id: doc.data()['nama'] as String
    };

    // Calculate product sales count
    final productSalesCount = <String, int>{};
    int totalSales = 0;

    for (var detail in allDetailDocs) {
      final data = detail.data() as Map<String, dynamic>;
      final productId = data['product_id'] as String?;
      final qty = data['qty'] as num?;

      if (productId == null || qty == null) continue;

      final productName = productMap[productId] ?? 'Unknown Product';

      productSalesCount.update(
        productName,
        (value) => value + qty.toInt(),
        ifAbsent: () => qty.toInt(),
      );

      totalSales += qty.toInt();
    }

    // Convert to percentage
    if (totalSales == 0) return [];

    return productSalesCount.entries
        .map((e) => ProductSales(
              e.key,
              ((e.value / totalSales) * 100).round(),
            ))
        .toList()
      ..sort((a, b) => b.percentage.compareTo(a.percentage));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              leading: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.drawerPage);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF2F6F3),
                    shape: const CircleBorder(),
                  ),
                  child: SvgPicture.asset(AppIcons.sidebarIcon),
                ),
              ),
              floating: true,
              title: SvgPicture.asset(
                "assets/images/app_logo.svg",
                height: 32,
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.search);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF2F6F3),
                      shape: const CircleBorder(),
                    ),
                    child: SvgPicture.asset(AppIcons.search),
                  ),
                ),
              ],
            ),
            const SliverToBoxAdapter(
              child: AdSpace(),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDefaults.padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selamat Datang, Administrator!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sales Quantity Section
                    FutureBuilder<List<int>>(
                      future: _getWeeklySales(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        return _buildSalesQuantitySection(
                            snapshot.data ?? List.filled(7, 0));
                      },
                    ),
                    const SizedBox(height: 24),

                    // Product Sales Percentage Section
                    FutureBuilder<List<ProductSales>>(
                      future: _getProductSales(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        return _buildProductSalesSection(snapshot.data ?? []);
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesQuantitySection(List<int> weeklySales) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDefaults.radius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDefaults.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jumlah Penjualan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: weeklySales.isEmpty
                      ? 10
                      : (weeklySales.reduce((a, b) => a > b ? a : b) * 1.2),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                     tooltipBorder: BorderSide(color: Colors.blue, width: 2),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${weeklySales[groupIndex]}',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = [
                            'Sen',
                            'Sel',
                            'Rab',
                            'Kam',
                            'Jum',
                            'Sab',
                            'Min'
                          ];
                          final index = value.toInt();
                          if (index >= 0 && index < days.length) {
                            return Text(
                              days[index],
                              style: const TextStyle(fontSize: 10),
                              textAlign: TextAlign.center,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: weeklySales.asMap().entries.map((entry) {
                    final index = entry.key;
                    final value = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: value.toDouble(),
                          color: Colors.blue,
                          width: 15,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Terakhir diperbarui: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSalesSection(List<ProductSales> productSales) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDefaults.radius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDefaults.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Persentase Penjualan Produk',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: productSales.length,
                itemBuilder: (context, index) {
                  final product = productSales[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            product.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: LinearProgressIndicator(
                            value: product.percentage / 100,
                            backgroundColor: Colors.grey[200],
                            color: Colors.green,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${product.percentage}%',
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Terakhir diperbarui: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductSales {
  final String name;
  final int percentage;

  const ProductSales(this.name, this.percentage);
}