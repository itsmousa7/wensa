class WaylLineItem {
  final String label;
  final double amount;
  final String type;

  const WaylLineItem({
    required this.label,
    required this.amount,
    this.type = 'increase',
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'amount': amount.toInt(),
        'type': type,
      };
}
