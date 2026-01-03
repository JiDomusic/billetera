enum TransactionType { transfer, deposit, withdraw, convert }

class TransactionModel {
  final String id;
  final String? fromWalletId;
  final String? toWalletId;
  final TransactionType type;
  final double amount;
  final String currency;
  final double? exchangeRate;
  final String? description;
  final String status;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    this.fromWalletId,
    this.toWalletId,
    required this.type,
    required this.amount,
    required this.currency,
    this.exchangeRate,
    this.description,
    required this.status,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      fromWalletId: json['from_wallet_id'],
      toWalletId: json['to_wallet_id'],
      type: _parseType(json['type']),
      amount: double.parse(json['amount'].toString()),
      currency: json['currency'],
      exchangeRate: json['exchange_rate'] != null
          ? double.parse(json['exchange_rate'].toString())
          : null,
      description: json['description'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static TransactionType _parseType(String type) {
    switch (type) {
      case 'transfer':
        return TransactionType.transfer;
      case 'deposit':
        return TransactionType.deposit;
      case 'withdraw':
        return TransactionType.withdraw;
      case 'convert':
        return TransactionType.convert;
      default:
        return TransactionType.transfer;
    }
  }

  String get typeString {
    switch (type) {
      case TransactionType.transfer:
        return 'transfer';
      case TransactionType.deposit:
        return 'deposit';
      case TransactionType.withdraw:
        return 'withdraw';
      case TransactionType.convert:
        return 'convert';
    }
  }

  String get typeLabel {
    switch (type) {
      case TransactionType.transfer:
        return 'Transferencia';
      case TransactionType.deposit:
        return 'Deposito';
      case TransactionType.withdraw:
        return 'Retiro';
      case TransactionType.convert:
        return 'Conversion';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_wallet_id': fromWalletId,
      'to_wallet_id': toWalletId,
      'type': typeString,
      'amount': amount,
      'currency': currency,
      'exchange_rate': exchangeRate,
      'description': description,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
