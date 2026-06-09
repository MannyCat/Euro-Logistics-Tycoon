class Clan {
  final String id;
  final String name;
  final String tag;
  final String description;
  final String? leaderId;
  final int level;
  final int xp;
  final int maxMembers;
  final DateTime createdAt;

  Clan({
    required this.id,
    required this.name,
    required this.tag,
    this.description = '',
    this.leaderId,
    this.level = 1,
    this.xp = 0,
    this.maxMembers = 10,
    required this.createdAt,
  });

  factory Clan.fromJson(Map<String, dynamic> json) {
    return Clan(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      tag: json['tag'] as String? ?? '',
      description: json['description'] as String? ?? '',
      leaderId: json['leader_id'] as String?,
      level: (json['level'] as num?)?.toInt() ?? 1,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      maxMembers: (json['max_members'] as num?)?.toInt() ?? 10,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}

class ClanMember {
  final String clanId;
  final String companyId;
  final String? companyName;
  final String role; // 'leader', 'officer', 'member'
  final int? companyLevel;
  final int? companyMoney;
  final int? truckCount;
  final DateTime joinedAt;

  ClanMember({
    required this.clanId,
    required this.companyId,
    this.companyName,
    required this.role,
    this.companyLevel,
    this.companyMoney,
    this.truckCount,
    required this.joinedAt,
  });

  factory ClanMember.fromJson(Map<String, dynamic> json) {
    return ClanMember(
      clanId: json['clan_id'] as String,
      companyId: json['company_id'] as String,
      companyName: json['company_name'] as String?,
      role: json['role'] as String? ?? 'member',
      companyLevel: (json['level'] as num?)?.toInt(),
      companyMoney: (json['money'] as num?)?.toInt(),
      truckCount: (json['truck_count'] as num?)?.toInt(),
      joinedAt: DateTime.parse(json['joined_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  bool get isLeader => role == 'leader';
  bool get isOfficer => role == 'officer';
  bool get canManage => role == 'leader' || role == 'officer';

  String get roleDisplay => switch (role) {
    'leader' => 'Лидер',
    'officer' => 'Офицер',
    _ => 'Участник',
  };

  String get roleColorHex => switch (role) {
    'leader' => 'FFF5C542',
    'officer' => 'FF42A5F5',
    _ => 'FF888888',
  };
}
