class UserModel {
  final String id;
  final String firebaseUid;
  final String email;
  final String? fullName;
  final String? phone;
  final String? cvu;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.firebaseUid,
    required this.email,
    this.fullName,
    this.phone,
    this.cvu,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      firebaseUid: json['firebase_uid'],
      email: json['email'],
      fullName: json['full_name'],
      phone: json['phone'],
      cvu: json['cvu'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebase_uid': firebaseUid,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'cvu': cvu,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
