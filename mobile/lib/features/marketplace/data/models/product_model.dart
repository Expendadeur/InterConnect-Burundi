class ProductModel {
  final String id;
  final String sellerId;
  final String sellerName;
  final String? sellerAvatar;
  final String sellerPhone;
  final String title;
  final String description;
  final double price;
  final String currency;
  final String category;
  final String location;
  final String? imageUrl;
  final String originalLanguage;
  final String? translatedTitle;
  final String? translatedDescription;
  final bool isSponsored;
  final DateTime createdAt;

  const ProductModel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    this.sellerAvatar,
    required this.sellerPhone,
    required this.title,
    required this.description,
    required this.price,
    this.currency = 'BIF',
    required this.category,
    required this.location,
    this.imageUrl,
    this.originalLanguage = 'rn',
    this.translatedTitle,
    this.translatedDescription,
    this.isSponsored = false,
    required this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      sellerId: json['sellerId'] ?? '',
      sellerName: json['sellerName'] ?? 'Vendeur',
      sellerAvatar: json['sellerAvatar'],
      sellerPhone: json['sellerPhone'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] != null) ? double.tryParse(json['price'].toString()) ?? 0.0 : 0.0,
      currency: json['currency'] ?? 'BIF',
      category: json['category'] ?? 'Général',
      location: json['location'] ?? 'Bujumbura',
      imageUrl: json['imageUrl'],
      originalLanguage: json['originalLanguage'] ?? 'rn',
      translatedTitle: json['translatedTitle'],
      translatedDescription: json['translatedDescription'],
      isSponsored: json['isSponsored'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerAvatar': sellerAvatar,
      'sellerPhone': sellerPhone,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'category': category,
      'location': location,
      'imageUrl': imageUrl,
      'originalLanguage': originalLanguage,
      'translatedTitle': translatedTitle,
      'translatedDescription': translatedDescription,
      'isSponsored': isSponsored,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ProductModel copyWith({
    String? translatedTitle,
    String? translatedDescription,
  }) {
    return ProductModel(
      id: id,
      sellerId: sellerId,
      sellerName: sellerName,
      sellerAvatar: sellerAvatar,
      sellerPhone: sellerPhone,
      title: title,
      description: description,
      price: price,
      currency: currency,
      category: category,
      location: location,
      imageUrl: imageUrl,
      originalLanguage: originalLanguage,
      translatedTitle: translatedTitle ?? this.translatedTitle,
      translatedDescription: translatedDescription ?? this.translatedDescription,
      isSponsored: isSponsored,
      createdAt: createdAt,
    );
  }
}

