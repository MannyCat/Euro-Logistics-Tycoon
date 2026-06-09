class Company {
  final String id;
  final String ownerId;
  final String name;
  int money;
  int reputation;
  int level;
  int xp;
  final int prestigeLevel;

  Company({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.money,
    required this.reputation,
    required this.level,
    required this.xp,
    this.prestigeLevel = 0,
  });

  factory Company.fromJson(Map<String, dynamic> json) => Company(
    id: json['id'] as String? ?? '',
    ownerId: json['owner_id'] as String? ?? '',
    name: json['name'] as String? ?? 'My Company',
    money: (json['money'] as num?)?.toInt() ?? 0,
    reputation: (json['reputation'] as num?)?.toInt() ?? 50,
    level: (json['level'] as num?)?.toInt() ?? 1,
    xp: (json['xp'] as num?)?.toInt() ?? 0,
    prestigeLevel: (json['prestige_level'] as num?)?.toInt() ?? 0,
  );

  String get moneyFormatted {
    if (money >= 1000000) return '\u20AC${(money / 1000000).toStringAsFixed(1)}M';
    if (money >= 1000) return '\u20AC${(money / 1000).toStringAsFixed(0)}K';
    return '\u20AC$money';
  }

  /// Prestige stars display (up to 5 stars)
  String get prestigeDisplay {
    if (prestigeLevel == 0) return '';
    final count = prestigeLevel.clamp(0, 5);
    return '⭐' * count;
  }

  /// Prestige income bonus: +5% per level
  double get prestigeIncomeBonus => prestigeLevel * 0.05;

  /// Prestige XP bonus: +10% per level
  double get prestigeXpBonus => prestigeLevel * 0.10;

  /// Prestige fuel discount: +3% per level
  double get prestigeFuelDiscount => prestigeLevel * 0.03;

  /// Whether the company can prestige (level >= 10)
  bool get canPrestige => level >= 10;
}
