class Company {
  final String id;
  final String ownerId;
  final String name;
  int money;
  int reputation;
  int level;
  int xp;

  Company({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.money,
    required this.reputation,
    required this.level,
    required this.xp,
  });

  factory Company.fromJson(Map<String, dynamic> json) => Company(
    id: json['id'] as String? ?? '',
    ownerId: json['owner_id'] as String? ?? '',
    name: json['name'] as String? ?? 'My Company',
    money: (json['money'] as num?)?.toInt() ?? 0,
    reputation: (json['reputation'] as num?)?.toInt() ?? 50,
    level: (json['level'] as num?)?.toInt() ?? 1,
    xp: (json['xp'] as num?)?.toInt() ?? 0,
  );

  String get moneyFormatted {
    if (money >= 1000000) return '\u20AC${(money / 1000000).toStringAsFixed(1)}M';
    if (money >= 1000) return '\u20AC${(money / 1000).toStringAsFixed(0)}K';
    return '\u20AC$money';
  }
}
