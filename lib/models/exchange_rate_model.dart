class ExchangeRateModel {
  final String id;
  final double buyRate;
  final double sellRate;
  final DateTime updatedAt;

  ExchangeRateModel({
    required this.id,
    required this.buyRate,
    required this.sellRate,
    required this.updatedAt,
  });

  factory ExchangeRateModel.fromJson(Map<String, dynamic> json) {
    return ExchangeRateModel(
      id: json['id'],
      buyRate: double.parse(json['buy_rate'].toString()),
      sellRate: double.parse(json['sell_rate'].toString()),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buy_rate': buyRate,
      'sell_rate': sellRate,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
