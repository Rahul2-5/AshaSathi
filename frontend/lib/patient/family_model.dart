class FamilyInfo {
  final String headOfFamilyName;
  final int numberOfMembers;
  final String address;
  final bool sameAddressForAll;

  FamilyInfo({
    required this.headOfFamilyName,
    required this.numberOfMembers,
    required this.address,
    this.sameAddressForAll = true,
  });

  FamilyInfo copyWith({
    String? headOfFamilyName,
    int? numberOfMembers,
    String? address,
    bool? sameAddressForAll,
  }) {
    return FamilyInfo(
      headOfFamilyName: headOfFamilyName ?? this.headOfFamilyName,
      numberOfMembers: numberOfMembers ?? this.numberOfMembers,
      address: address ?? this.address,
      sameAddressForAll: sameAddressForAll ?? this.sameAddressForAll,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'headOfFamilyName': headOfFamilyName,
      'numberOfMembers': numberOfMembers,
      'address': address,
      'sameAddressForAll': sameAddressForAll,
    };
  }

  factory FamilyInfo.fromJson(Map<String, dynamic> json) {
    return FamilyInfo(
      headOfFamilyName: json['headOfFamilyName'] ?? '',
      numberOfMembers: json['numberOfMembers'] ?? 2,
      address: json['address'] ?? '',
      sameAddressForAll: json['sameAddressForAll'] ?? true,
    );
  }
}
