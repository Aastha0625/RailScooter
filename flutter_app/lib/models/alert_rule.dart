class AlertRule {
  final String id;
  final String name;
  final String description;
  final String ruleType;
  final String severity;
  final String conditionOperator;
  final double conditionValue;
  final String conditionUnit;
  final bool isActive;
  final bool notificationEmail;
  final bool notificationPush;
  final bool notificationSms;
  final DateTime createdAt;

  const AlertRule({
    required this.id,
    required this.name,
    required this.description,
    required this.ruleType,
    required this.severity,
    required this.conditionOperator,
    required this.conditionValue,
    required this.conditionUnit,
    required this.isActive,
    required this.notificationEmail,
    required this.notificationPush,
    required this.notificationSms,
    required this.createdAt,
  });

  factory AlertRule.fromJson(Map<String, dynamic> json) => AlertRule(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    ruleType: json['rule_type'] ?? 'speed',
    severity: json['severity'] ?? 'medium',
    conditionOperator: json['condition_operator'] ?? 'gt',
    conditionValue: (json['condition_value'] ?? 0).toDouble(),
    conditionUnit: json['condition_unit'] ?? '',
    isActive: json['is_active'] ?? true,
    notificationEmail: json['notification_email'] ?? true,
    notificationPush: json['notification_push'] ?? true,
    notificationSms: json['notification_sms'] ?? false,
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'rule_type': ruleType,
    'severity': severity,
    'condition_operator': conditionOperator,
    'condition_value': conditionValue,
    'condition_unit': conditionUnit,
    'is_active': isActive,
    'notification_email': notificationEmail,
    'notification_push': notificationPush,
    'notification_sms': notificationSms,
  };
}

// VehicleAlert has been moved to models/vehicle_alert.dart
