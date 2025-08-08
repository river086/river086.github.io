class StockPrice {
  final String symbol;
  final DateTime date;
  final double price;
  final int volume;

  StockPrice({
    required this.symbol,
    required this.date,
    required this.price,
    required this.volume,
  });

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'date': date.toIso8601String(),
    'price': price,
    'volume': volume,
  };

  factory StockPrice.fromJson(Map<String, dynamic> json) => StockPrice(
    symbol: json['symbol'],
    date: DateTime.parse(json['date']),
    price: json['price'].toDouble(),
    volume: json['volume'],
  );
}

class StockHolding {
  final String symbol;
  int shares;
  final double purchasePrice;
  final DateTime purchaseDate;

  StockHolding({
    required this.symbol,
    required this.shares,
    required this.purchasePrice,
    required this.purchaseDate,
  });

  double getCurrentValue(double currentPrice) {
    return shares * currentPrice;
  }

  double getProfit(double currentPrice) {
    return (currentPrice - purchasePrice) * shares;
  }

  double getProfitPercentage(double currentPrice) {
    if (purchasePrice == 0) return 0.0;
    return ((currentPrice - purchasePrice) / purchasePrice) * 100;
  }

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'shares': shares,
    'purchasePrice': purchasePrice,
    'purchaseDate': purchaseDate.toIso8601String(),
  };

  factory StockHolding.fromJson(Map<String, dynamic> json) => StockHolding(
    symbol: json['symbol'],
    shares: json['shares'],
    purchasePrice: json['purchasePrice'].toDouble(),
    purchaseDate: DateTime.parse(json['purchaseDate']),
  );
}