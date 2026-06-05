class Driver {
  final String id;
  final String companyId;
  final String name;
  final int skillLevel;
  final int salaryDaily;
  final String status;
  final String? assignedTruckId;

  const Driver({
    required this.id,
    required this.companyId,
    required this.name,
    required this.skillLevel,
    required this.salaryDaily,
    required this.status,
    this.assignedTruckId,
  });

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
    id: json['id'] as String? ?? '',
    companyId: json['company_id'] as String? ?? '',
    name: json['name'] as String? ?? 'Driver',
    skillLevel: (json['skill_level'] as num?)?.toInt() ?? 1,
    salaryDaily: (json['salary_daily'] as num?)?.toInt() ?? 300,
    status: json['status'] as String? ?? 'available',
    assignedTruckId: json['assigned_truck_id'] as String?,
  );

  bool get isAvailable => status == 'available';
}
