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

class VehicleAlert {
  final String id;
  final String vehicleId;
  final String vehicleLabel;
  final String alertType;
  final String severity;
  final String message;
  final double? latitude;
  final double? longitude;
  final bool isAcknowledged;
  final DateTime createdAt;

  const VehicleAlert({
    required this.id,
    required this.vehicleId,
    required this.vehicleLabel,
    required this.alertType,
    required this.severity,
    required this.message,
    this.latitude,
    this.longitude,
    required this.isAcknowledged,
    required this.createdAt,
  });

  factory VehicleAlert.fromJson(Map<String, dynamic> json) => VehicleAlert(
    id: json['id'] ?? '',
    vehicleId: json['vehicle_id'] ?? '',
    vehicleLabel: json['vehicles']?['vehicle_id'] ?? 'Unknown',
    alertType: json['alert_type'] ?? 'speed',
    severity: json['severity'] ?? 'medium',
    message: json['message'] ?? '',
    latitude: json['latitude']?.toDouble(),
    longitude: json['longitude']?.toDouble(),
    isAcknowledged: json['is_acknowledged'] ?? false,
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
  );
}
