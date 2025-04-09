class ProductModel {
  String name;
  String weight;
  String stock;
  String cover;
  List<String> images;
  double price;
  double mainPrice;
  ProductModel({
    required this.name,
    required this.weight,
    required this.stock,
    required this.cover,
    required this.images,
    required this.price,
    required this.mainPrice,
  });
}
