class Department {
  final String id;
  final String name;
  final String code;
  final String description;
  final String headName;
  final String contactEmail;
  final String contactPhone;
  final String location;
  final bool isActive;
  final DateTime createdAt;

  const Department({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.headName,
    required this.contactEmail,
    required this.contactPhone,
    required this.location,
    required this.isActive,
    required this.createdAt,
  });

  factory Department.fromJson(Map<String, dynamic> json) => Department(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    code: json['code'] ?? '',
    description: json['description'] ?? '',
    headName: json['head_name'] ?? '',
    contactEmail: json['contact_email'] ?? '',
    contactPhone: json['contact_phone'] ?? '',
    location: json['location'] ?? '',
    isActive: json['is_active'] ?? true,
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
    'description': description,
    'head_name': headName,
    'contact_email': contactEmail,
    'contact_phone': contactPhone,
    'location': location,
    'is_active': isActive,
  };
}

class AppUser {
  final String id;
  final String fullName;
  final String? employeeId;
  final String role;
  final String? departmentId;
  final String? departmentName;
  final String phone;
  final bool isActive;

  const AppUser({
    required this.id,
    required this.fullName,
    this.employeeId,
    required this.role,
    this.departmentId,
    this.departmentName,
    required this.phone,
    required this.isActive,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] ?? '',
    fullName: json['full_name'] ?? '',
    employeeId: json['employee_id'],
    role: json['role'] ?? 'operator',
    departmentId: json['department_id'],
    departmentName: json['departments']?['name'],
    phone: json['phone'] ?? '',
    isActive: json['is_active'] ?? true,
  );
}
