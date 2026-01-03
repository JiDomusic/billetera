class WalletModel {
  final String id;
  final String userId;
  final String currency;
  final double balance;
  final DateTime updatedAt;

  WalletModel({
    required this.id,
    required this.userId,
    required this.currency,
    required this.balance,
    required this.updatedAt,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'],
      userId: json['user_id'],
      currency: json['currency'],
      balance: double.parse(json['balance'].toString()),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'currency': currency,
      'balance': balance,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isARS => currency == 'ARS';
  bool get isUSD => currency == 'USD';
}
