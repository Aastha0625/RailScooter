/// AppUser represents a user in the app_users table,
/// linked to Supabase Auth via their auth UID.
class AppUser {
  final String id;
  final String fullName;
  final String? employeeId;
  final String role;
  final String phone;
  final bool isActive;

  final String approvalStatus; // 'pending' | 'approved' | 'rejected'
  final String? firstName;
  final String? lastName;
  final String? gender;
  final String? zone;
  final String? division;
  final List<String>? regions;
  final DateTime? createdAt;

  const AppUser({
    required this.id,
    required this.fullName,
    this.employeeId,
    required this.role,
    required this.phone,
    required this.isActive,
    this.approvalStatus = 'approved',
    this.firstName,
    this.lastName,
    this.gender,
    this.zone,
    this.division,
    this.regions,
    this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] ?? '',
    fullName: json['full_name'] ?? '',
    employeeId: json['employee_id'],
    role: json['role'] ?? 'trackman',
    phone: json['phone'] ?? '',
    isActive: json['is_active'] ?? true,
    approvalStatus: json['approval_status'] ?? 'approved',
    firstName: json['first_name'],
    lastName: json['last_name'],
    gender: json['gender'],
    zone: json['zone'],
    division: json['division'],
    regions: json['regions'] != null ? List<String>.from(json['regions']) : null,
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'employee_id': employeeId,
    'role': role,
    'phone': phone,
    'is_active': isActive,
    'approval_status': approvalStatus,
    'first_name': firstName,
    'last_name': lastName,
    'gender': gender,
    'zone': zone,
    'division': division,
    'regions': regions,
  };

  AppUser copyWith({
    String? fullName,
    String? employeeId,
    String? role,
    String? phone,
    bool? isActive,
    String? approvalStatus,
    String? firstName,
    String? lastName,
    String? gender,
    String? zone,
    String? division,
    List<String>? regions,
  }) => AppUser(
    id: id,
    fullName: fullName ?? this.fullName,
    employeeId: employeeId ?? this.employeeId,
    role: role ?? this.role,
    phone: phone ?? this.phone,
    isActive: isActive ?? this.isActive,
    approvalStatus: approvalStatus ?? this.approvalStatus,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    gender: gender ?? this.gender,
    zone: zone ?? this.zone,
    division: division ?? this.division,
    regions: regions ?? this.regions,
    createdAt: createdAt,
  );
}
