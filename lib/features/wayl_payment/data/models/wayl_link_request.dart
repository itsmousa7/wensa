import 'wayl_line_item.dart';

class WaylLinkRequest {
  final String env;
  final String referenceId;
  final double total;
  final String currency;
  final List<WaylLineItem>? lineItem;
  final String? webhookUrl;
  final String? webhookSecret;
  final String? redirectionUrl;
  final String? customParameter;

  const WaylLinkRequest({
    required this.env,
    required this.referenceId,
    required this.total,
    this.currency = 'IQD',
    this.lineItem,
    this.webhookUrl,
    this.webhookSecret,
    this.redirectionUrl,
    this.customParameter,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'env': env,
      'referenceId': referenceId,
      'total': total.toInt(),
      'currency': currency,
      'customParameter': customParameter ?? '',
      'lineItem': (lineItem ?? []).map((i) => i.toJson()).toList(),
    };
    map['webhookUrl'] = webhookUrl ?? '';
    map['webhookSecret'] = webhookSecret ?? '';
    map['redirectionUrl'] = redirectionUrl ?? '';
    return map;
  }
}
