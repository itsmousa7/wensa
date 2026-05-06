class WaylLinkResponse {
  final String id;
  final String? code;
  final String referenceId;
  final String url;
  final String status;
  final String total;
  final String currency;
  final String? type;
  final String? paymentMethod;
  final String? completedAt;
  final String? customParameter;
  final String? webhookUrl;
  final String? redirectionUrl;
  final String createdAt;
  final String updatedAt;

  const WaylLinkResponse({
    required this.id,
    this.code,
    required this.referenceId,
    required this.url,
    required this.status,
    required this.total,
    required this.currency,
    this.type,
    this.paymentMethod,
    this.completedAt,
    this.customParameter,
    this.webhookUrl,
    this.redirectionUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WaylLinkResponse.fromJson(Map<String, dynamic> json) {
    return WaylLinkResponse(
      id: json['id'] as String? ?? '',
      code: json['code'] as String?,
      referenceId: json['referenceId'] as String? ?? '',
      url: json['url'] as String? ?? '',
      status: json['status'] as String? ?? '',
      total: json['total']?.toString() ?? '0',
      currency: json['currency'] as String? ?? 'IQD',
      type: json['type'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      completedAt: json['completedAt'] as String?,
      customParameter: json['customParameter'] as String?,
      webhookUrl: json['webhookUrl'] as String?,
      redirectionUrl: json['redirectionUrl'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}
