class ProductModel {
  String name;
  int stock;
  String images;
  int price;
  ProductModel({
  required this.name,
  required this.stock,
   required this.images,
  required this.price,
  });

  factory ProductModel.fromFirestore(Map<String, dynamic> map) {
    return ProductModel(
      name: map['nama'] ?? '',
      stock: map['stok'] ?? 0,
      images: map['gambarBase64'] ?? '',
      price: map['harga'] ?? 0,
    );
  }
}

class PembelianModel {
  String name;
  String tanggal;
  double total;
  String createdBy;
  PembelianModel({
  required this.name,
    required this.tanggal,
    required this.total,
    required this.createdBy,
  });
}

class UserModel {
  String email;
  String name;
  String role;
  String password;
  UserModel({
    required this.email,
    required this.name,
    required this.role,
    required this.password,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> map) {
    return UserModel(
        email: map['email'],
        name: map['name'],
        role: map['role'],
        password: map['password']);
  }
}