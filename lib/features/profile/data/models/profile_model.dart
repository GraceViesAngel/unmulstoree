class ProfileModel {
  final String id;
  final String? fullName;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? city;
  final String? street;

  ProfileModel({
    required this.id,
    this.fullName,
    this.phoneNumber,
    this.avatarUrl,
    this.city,
    this.street,
  });

  String get fullAddress {
    final parts = <String>[];
    if (street != null && street!.isNotEmpty) parts.add(street!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    return parts.join(', ');
  }

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'],
      fullName: map['full_name'],
      phoneNumber: map['phone_number'],
      avatarUrl: map['avatar_url'],
      city: map['city'],
      street: map['street'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'full_name': fullName,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'city': city,
      'street': street,
    };
  }
}
