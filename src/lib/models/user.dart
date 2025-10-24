class User {
  final String id;
  final String displayName;
  final String? email;
  final String? imageUrl;
  final String? country;
  final String? product;

  User({
    required this.id,
    required this.displayName,
    this.email,
    this.imageUrl,
    this.country,
    this.product,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      displayName: json['display_name'] ?? '',
      email: json['email'],
      imageUrl: json['images']?.isNotEmpty == true 
          ? json['images'][0]['url'] 
          : null,
      country: json['country'],
      product: json['product'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'email': email,
      'image_url': imageUrl,
      'country': country,
      'product': product,
    };
  }

  @override
  String toString() {
    return 'User(id: $id, displayName: $displayName, email: $email)';
  }
}
