class ProductModel {
  final String? id;
  final String title;
  final String imagePath;
  final int price;
  final double rating;
  final int stock;
  final String description;
  final bool isRentable;
  final String? category;
  final int deposit;
  final int rentalDuration;
  final int maxQty;
  final List<String>? colors;
  final List<String>? sizes;
  final String? sizeGuide;
  final String? specifications;
  final int lateFee;

  ProductModel({
    this.id,
    required this.title,
    required this.imagePath,
    required this.price,
    required this.rating,
    this.stock = 24,
    this.description =
        'Kaos resmi dengan bahan cotton combed premium, nyaman digunakan untuk aktivitas sehari-hari.',
    this.isRentable = false,
    this.category,
    this.deposit = 0,
    this.rentalDuration = 3,
    this.maxQty = 5,
    this.colors,
    this.sizes,
    this.sizeGuide,
    this.specifications,
    this.lateFee = 0,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id']?.toString(),
      title: map['title'] ?? '',
      imagePath: map['image_path'] ?? '',
      price: map['price']?.toInt() ?? 0,
      rating: (map['rating'] ?? 0).toDouble(),
      stock: map['stock']?.toInt() ?? 0,
      description: map['description'] ?? '',
      isRentable: map['is_rentable'] ?? false,
      category: map['category'],
      deposit: map['deposit']?.toInt() ?? 0,
      rentalDuration: map['rental_duration']?.toInt() ?? 3,
      maxQty: map['max_qty']?.toInt() ?? 5,
      colors: map['colors'] is List ? List<String>.from(map['colors']) : null,
      sizes: map['sizes'] is List ? List<String>.from(map['sizes']) : null,
      sizeGuide: map['size_guide'],
      specifications: map['specifications'],
      lateFee: map['late_fee']?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'image_path': imagePath,
      'price': price,
      'rating': rating,
      'stock': stock,
      'description': description,
      'is_rentable': isRentable,
      'category': category,
      'deposit': deposit,
      'rental_duration': rentalDuration,
      'max_qty': maxQty,
      'colors': colors ?? [],
      'sizes': sizes ?? [],
      'size_guide': sizeGuide,
      'specifications': specifications,
      'late_fee': lateFee,
    };
  }
}

final List<ProductModel> dummyProducts = [
  ProductModel(
    title: 'T-shirt Unmul',
    imagePath: 'assets/images/tshirt.jpeg',
    price: 100000,
    rating: 4.8,
  ),
  ProductModel(
    title: 'Work-Shirt',
    imagePath: 'assets/images/workshirt.jpeg',
    price: 100000,
    rating: 4.8,
  ),
  ProductModel(
    title: 'Almamater Unmul',
    imagePath: 'assets/images/almet.png',
    price: 180000,
    rating: 4.8,
  ),
  ProductModel(
    id: '4',
    title: 'Toga Unmul Terbaru',
    imagePath: 'assets/images/toga.png',
    price: 100000,
    rating: 4.8,
    isRentable: true,
    deposit: 50000,
    rentalDuration: 3,
    description:
        'Toga wisuda resmi Universitas Mulawarman dengan bahan nyaman dan standar akademik.',
    specifications:
        'Bahan: Bestway Premium, Warna: Hitam Hitam, Set: Topa + Jubah',
    sizeGuide: 'S: 150-160cm, M: 160-170cm, L: 170-180cm',
    sizes: ['S', 'M', 'L', 'XL'],
  ),
  ProductModel(
    title: 'Work-Shirt',
    imagePath: 'assets/images/tshirt2.webp',
    price: 100000,
    rating: 4.8,
    colors: ['Hijau', 'Hitam'],
    sizes: ['M', 'L', 'XL'],
    specifications: 'Bahan: Cotton Combed 30s, Sablon: DTF',
  ),
  ProductModel(
    title: 'Gantungan Kunci',
    imagePath: 'assets/images/gantungan.png',
    price: 100000,
    rating: 4.8,
    description: 'Gantungan kunci akrilik khas Unmul.',
  ),
  ProductModel(
    title: 'Mug Khas Unmul',
    imagePath: 'assets/images/mug.webp',
    price: 100000,
    rating: 4.8,
  ),
  ProductModel(
    title: 'Work-Jacket Inforsa',
    imagePath: 'assets/images/jaket.webp',
    price: 100000,
    rating: 4.8,
  ),
  ProductModel(
    title: 'Tote Bag',
    imagePath: 'assets/images/totebag.webp',
    price: 100000,
    rating: 4.8,
  ),
];
