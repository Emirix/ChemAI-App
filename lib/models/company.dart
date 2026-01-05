class Company {
  final String? id;
  final String userId;
  final String companyName;
  final String? address;
  final String? city;
  final String? postalCode;
  final String? country;
  final String? phone;
  final String? emergencyPhone;
  final String email;
  final String? website;
  final String? fax;
  final String? logoUrl;
  final String? signatureUrl;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Company({
    this.id,
    required this.userId,
    required this.companyName,
    this.address,
    this.city,
    this.postalCode,
    this.country,
    this.phone,
    this.emergencyPhone,
    required this.email,
    this.website,
    this.fax,
    this.logoUrl,
    this.signatureUrl,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor from JSON
  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as String?,
      userId: json['user_id'] as String? ?? json['userId'] as String,
      companyName:
          json['company_name'] as String? ?? json['companyName'] as String,
      address: json['address'] as String?,
      city: json['city'] as String?,
      postalCode:
          json['postal_code'] as String? ?? json['postalCode'] as String?,
      country: json['country'] as String?,
      phone: json['phone'] as String?,
      emergencyPhone:
          json['emergency_phone'] as String? ??
          json['emergencyPhone'] as String?,
      email: json['email'] as String,
      website: json['website'] as String?,
      fax: json['fax'] as String?,
      logoUrl: json['logo_url'] as String? ?? json['logoUrl'] as String?,
      signatureUrl:
          json['signature_url'] as String? ?? json['signatureUrl'] as String?,
      isDefault:
          json['is_default'] as bool? ?? json['isDefault'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'companyName': companyName,
      'address': address,
      'city': city,
      'postalCode': postalCode,
      'country': country,
      'phone': phone,
      'emergencyPhone': emergencyPhone,
      'email': email,
      'website': website,
      'fax': fax,
      'logoUrl': logoUrl,
      'signatureUrl': signatureUrl,
      'isDefault': isDefault,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  // CopyWith method for easy updates
  Company copyWith({
    String? id,
    String? userId,
    String? companyName,
    String? address,
    String? city,
    String? postalCode,
    String? country,
    String? phone,
    String? emergencyPhone,
    String? email,
    String? website,
    String? fax,
    String? logoUrl,
    String? signatureUrl,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Company(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      companyName: companyName ?? this.companyName,
      address: address ?? this.address,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      email: email ?? this.email,
      website: website ?? this.website,
      fax: fax ?? this.fax,
      logoUrl: logoUrl ?? this.logoUrl,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get formatted full address
  String getFullAddress() {
    final parts = <String>[];

    if (address != null && address!.isNotEmpty) {
      parts.add(address!);
    }

    final cityLine = <String>[];
    if (postalCode != null && postalCode!.isNotEmpty) {
      cityLine.add(postalCode!);
    }
    if (city != null && city!.isNotEmpty) {
      cityLine.add(city!);
    }
    if (cityLine.isNotEmpty) {
      parts.add(cityLine.join(' '));
    }

    if (country != null && country!.isNotEmpty) {
      parts.add(country!);
    }

    return parts.join(', ');
  }

  /// Check if company has complete information
  bool isComplete() {
    return companyName.isNotEmpty &&
        email.isNotEmpty &&
        phone != null &&
        phone!.isNotEmpty &&
        address != null &&
        address!.isNotEmpty &&
        city != null &&
        city!.isNotEmpty &&
        country != null &&
        country!.isNotEmpty;
  }

  @override
  String toString() {
    return 'Company(id: $id, name: $companyName, email: $email, isDefault: $isDefault)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Company &&
        other.id == id &&
        other.userId == userId &&
        other.companyName == companyName &&
        other.email == email;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        companyName.hashCode ^
        email.hashCode;
  }
}
