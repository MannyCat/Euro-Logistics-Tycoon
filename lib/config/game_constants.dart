import 'dart:math' as math;
import 'package:flutter/material.dart';

class AchievementDef {
  final String id;
  final String name;
  final String description;
  final String category; // fleet, logistics, finance, social, level
  final IconData icon;
  final Color color;
  final int reward; // XP reward
  final int tier; // 1=bronze, 2=silver, 3=gold

  const AchievementDef({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.color,
    this.reward = 50,
    this.tier = 1,
  });
}

class GameConstants {
  GameConstants._();

  static const int startingMoney = 1000000;
  static const double fuelCostPerLiter = 1.5;
  static const double baseFuelPrice = 1.5;

  // Dynamic fuel price (changes with time)
  static double currentFuelPricePerLiter = 1.5;

  /// Update fuel price based on time — simulates market fluctuations
  static void updateFuelPrice() {
    final hour = DateTime.now().hour;
    final dayOfWeek = DateTime.now().weekday;
    // Base fluctuation: ±15% based on hour of day
    double hourFactor = 1.0 + 0.15 * math.sin(hour * 0.26); // smooth sine wave
    // Weekend surge: +10% on Saturday/Sunday
    double weekendFactor = (dayOfWeek == 6 || dayOfWeek == 7) ? 1.10 : 1.0;
    currentFuelPricePerLiter = baseFuelPrice * hourFactor * weekendFactor;
    // Clamp between 1.0 and 2.5
    currentFuelPricePerLiter = currentFuelPricePerLiter.clamp(1.0, 2.5);
  }

  /// Effective fuel price after level discount
  static double effectiveFuelPrice(int companyLevel) {
    return currentFuelPricePerLiter * (1.0 - fuelDiscountAtLevel(companyLevel));
  }

  static const double sellBackRatio = 0.6;
  static const int maxTrucks = 20;
  static const int xpPerLevel = 1000;
  static const int maxReputation = 100;
  static const int depotFeePerCity = 500;
  static const int driverBaseSalary = 300;
  static const int driverHireCostMultiplier = 30;
  static const int fuelCostPer100km = 200;
  static const int repairCostPerPoint = 500;
  static const int conditionLossPerTrip = 3;
  static const int loadingDurationSeconds = 30;
  static const int contractRefreshSeconds = 5;
  static const int contractGenerationMinutes = 5;
  static const int clanCreateCost = 50000;
  static const int clanMaxMembers = 10;
  static const int clanXpPerLevel = 5000;

  // ===== LEVEL UNLOCKS =====
  static const List<LevelUnlock> levelUnlocks = [
    LevelUnlock(level: 1, description: 'Начало пути — 1 грузовик, базовые контракты'),
    LevelUnlock(level: 2, description: 'Макс. 3 грузовика, контракты средней сложности'),
    LevelUnlock(level: 3, description: 'Макс. 5 грузовиков, скидка 5% на топливо'),
    LevelUnlock(level: 4, description: 'Макс. 8 грузовиков, склады дают +10% дохода'),
    LevelUnlock(level: 5, description: 'Макс. 10 грузовиков, тяжёлые грузовики'),
    LevelUnlock(level: 6, description: 'Макс. 12 грузовиков, скидка 10% на ремонт'),
    LevelUnlock(level: 7, description: 'Макс. 14 грузовиков, спец. грузы'),
    LevelUnlock(level: 8, description: 'Макс. 16 грузовиков, водители экономят топливо -5%'),
    LevelUnlock(level: 9, description: 'Макс. 18 грузовиков, всё доступно'),
    LevelUnlock(level: 10, description: 'Макс. 20 грузовиков, логистическая империя'),
  ];

  /// Max trucks allowed at a given level
  static int maxTrucksAtLevel(int level) {
    for (final u in levelUnlocks.reversed) {
      if (level >= u.level) return switch (u.level) {
        1 => 1, 2 => 3, 3 => 5, 4 => 8, 5 => 10,
        6 => 12, 7 => 14, 8 => 16, 9 => 18, 10 => 20,
        _ => 20,
      };
    }
    return 1;
  }

  // ===== TOLL ROADS =====
  static const Map<String, int> tollRoads = {
    '2-6': 500,   // Hamburg → Berlin
    '6-12': 800,  // Berlin → Prague
    '1-5': 600,   // Amsterdam → Brussels
    '5-4': 400,   // Brussels → Paris
    '7-11': 700,  // Munich → Vienna
    '11-13': 600, // Vienna → Budapest
    '8-9': 300,   // Zurich → Milan
    '9-7': 500,   // Milan → Munich
  };

  /// Get toll cost for a route (sum of tolls on path)
  static int getTollCost(List<int> path) {
    int total = 0;
    for (int i = 0; i < path.length - 1; i++) {
      final a = path[i];
      final b = path[i + 1];
      final key1 = '${math.min(a, b)}-${math.max(a, b)}';
      total += tollRoads[key1] ?? 0;
    }
    return total;
  }

  // ===== SUPPLY / DEMAND =====
  static const Map<int, Map<String, double>> cityCargoDemand = {
    2: {'Electronics': 1.3, 'Machinery': 1.2},
    6: {'Building Materials': 1.25, 'Machinery': 1.2},
    1: {'FMCG': 1.2, 'Electronics': 1.15},
    4: {'Food': 1.3, 'FMCG': 1.2},
    3: {'Chemicals': 1.3, 'Machinery': 1.2},
    9: {'Fashion': 1.2},
    7: {'Building Materials': 1.2, 'Food': 1.15},
    11: {'Food': 1.2, 'FMCG': 1.15},
    12: {'Machinery': 1.25},
    13: {'Food': 1.3, 'Building Materials': 1.15},
  };

  /// Get demand multiplier for cargo type at destination city
  static double getCargoDemandMultiplier(int destinationCityId, String cargoType) {
    final demand = cityCargoDemand[destinationCityId];
    if (demand == null) return 1.0;
    return demand[cargoType] ?? 1.0;
  }

  /// Fuel discount percentage at level (0-20)
  static double fuelDiscountAtLevel(int level) {
    if (level >= 8) return 0.15;
    if (level >= 3) return 0.05;
    return 0;
  }

  /// Repair discount percentage at level (0-20)
  static double repairDiscountAtLevel(int level) {
    if (level >= 10) return 0.15;
    if (level >= 6) return 0.10;
    return 0;
  }

  // ===== ACHIEVEMENTS =====
  static const List<AchievementDef> achievements = [
    // Fleet
    AchievementDef(id: 'first_truck', name: 'Первый грузовик', description: 'Купить первый грузовик', category: 'fleet', icon: Icons.local_shipping, color: Color(0xFF42A5F5), reward: 25),
    AchievementDef(id: 'fleet_3', name: 'Малый автопарк', description: 'Владеть 3 грузовиками', category: 'fleet', icon: Icons.local_shipping, color: Color(0xFF42A5F5), reward: 50),
    AchievementDef(id: 'fleet_5', name: 'Автопарк', description: 'Владеть 5 грузовиками', category: 'fleet', icon: Icons.local_shipping, color: Color(0xFF42A5F5), reward: 100, tier: 2),
    AchievementDef(id: 'fleet_10', name: 'Транспортный магнат', description: 'Владеть 10 грузовиками', category: 'fleet', icon: Icons.local_shipping, color: Color(0xFF42A5F5), reward: 200, tier: 2),
    AchievementDef(id: 'fleet_20', name: 'Логистическая империя', description: 'Владеть 20 грузовиками', category: 'fleet', icon: Icons.local_shipping, color: Color(0xFF42A5F5), reward: 500, tier: 3),

    // Logistics
    AchievementDef(id: 'first_delivery', name: 'Первый рейс', description: 'Выполнить первый контракт', category: 'logistics', icon: Icons.check_circle, color: Color(0xFF66BB6A), reward: 25),
    AchievementDef(id: 'deliveries_10', name: 'Опытный перевозчик', description: 'Выполнить 10 контрактов', category: 'logistics', icon: Icons.check_circle, color: Color(0xFF66BB6A), reward: 75),
    AchievementDef(id: 'deliveries_50', name: 'Мастер логистики', description: 'Выполнить 50 контрактов', category: 'logistics', icon: Icons.check_circle, color: Color(0xFF66BB6A), reward: 200, tier: 2),
    AchievementDef(id: 'deliveries_100', name: 'Легенда дорог', description: 'Выполнить 100 контрактов', category: 'logistics', icon: Icons.check_circle, color: Color(0xFF66BB6A), reward: 500, tier: 3),
    AchievementDef(id: 'cities_5', name: 'Междугородний', description: 'Доставить груз в 5 разных городов', category: 'logistics', icon: Icons.location_city, color: Color(0xFF66BB6A), reward: 75),
    AchievementDef(id: 'cities_all', name: 'Евротур', description: 'Доставить груз во все города', category: 'logistics', icon: Icons.public, color: Color(0xFF66BB6A), reward: 500, tier: 3),

    // Finance
    AchievementDef(id: 'earned_100k', name: 'Первая прибыль', description: 'Заработать €100K на контрактах', category: 'finance', icon: Icons.euro, color: Color(0xFFF5C542), reward: 25),
    AchievementDef(id: 'earned_1m', name: 'Миллионер', description: 'Заработать €1M на контрактах', category: 'finance', icon: Icons.euro, color: Color(0xFFF5C542), reward: 100, tier: 2),
    AchievementDef(id: 'earned_10m', name: 'Тайкон', description: 'Заработать €10M на контрактах', category: 'finance', icon: Icons.euro, color: Color(0xFFF5C542), reward: 300, tier: 3),
    AchievementDef(id: 'money_5m', name: 'Капитал', description: 'Накопить €5M на балансе', category: 'finance', icon: Icons.account_balance, color: Color(0xFFF5C542), reward: 200, tier: 2),

    // Infrastructure
    AchievementDef(id: 'first_warehouse', name: 'Первый склад', description: 'Купить первый склад', category: 'infra', icon: Icons.warehouse, color: Color(0xFFCE93D8), reward: 50),
    AchievementDef(id: 'warehouses_3', name: 'Сеть складов', description: 'Владеть 3 складами', category: 'infra', icon: Icons.warehouse, color: Color(0xFFCE93D8), reward: 100),
    AchievementDef(id: 'first_driver', name: 'Первый водитель', description: 'Нанять первого водителя', category: 'infra', icon: Icons.person, color: Color(0xFFCE93D8), reward: 25),
    AchievementDef(id: 'drivers_5', name: 'Команда', description: 'Нанять 5 водителей', category: 'infra', icon: Icons.groups, color: Color(0xFFCE93D8), reward: 100, tier: 2),

    // Level
    AchievementDef(id: 'level_5', name: 'Растущая компания', description: 'Достичь 5-го уровня', category: 'level', icon: Icons.star, color: Color(0xFFFF9800), reward: 100, tier: 2),
    AchievementDef(id: 'level_10', name: 'Лидер рынка', description: 'Достичь 10-го уровня', category: 'level', icon: Icons.star, color: Color(0xFFFF9800), reward: 300, tier: 3),
    AchievementDef(id: 'reputation_max', name: 'Безупречная репутация', description: 'Достичь максимальной репутации', category: 'level', icon: Icons.verified, color: Color(0xFFFF9800), reward: 200, tier: 3),
  ];

  static AchievementDef? findAchievement(String id) {
    for (final a in achievements) { if (a.id == id) return a; }
    return null;
  }

  static const List<TruckTypeInfo> truckTypes = [
    TruckTypeInfo(type: 'light', name: 'Mercedes Actros L', price: 80000, speed: 85, fuel: 120, capacity: 12, icon: '🚚'),
    TruckTypeInfo(type: 'medium', name: 'Volvo FH16', price: 150000, speed: 80, fuel: 200, capacity: 22, icon: '🚛'),
    TruckTypeInfo(type: 'heavy', name: 'Scania R730', price: 250000, speed: 75, fuel: 300, capacity: 30, icon: '🚚'),
    TruckTypeInfo(type: 'special', name: 'MAN TGX 41.680', price: 400000, speed: 70, fuel: 400, capacity: 44, icon: '🚛'),
  ];

  static const List<String> cargoTypes = ['FMCG', 'Machinery', 'Food', 'Electronics', 'Building Materials', 'Chemicals'];

  static const Map<String, String> _cargoAssetMap = {
    'FMCG': 'assets/cargo/fmcg.png',
    'Machinery': 'assets/cargo/machinery.png',
    'Food': 'assets/cargo/food.png',
    'Electronics': 'assets/cargo/electronics.png',
    'Building Materials': 'assets/cargo/building_materials.png',
    'Chemicals': 'assets/cargo/chemicals.png',
  };

  static String cargoAssetPath(String type) => _cargoAssetMap[type] ?? '';

  static const List<String> driverFirstNames = ['Hans', 'Pierre', 'Marco', 'Jan', 'Erik', 'Sven', 'Klaus', 'Olivier', 'Lukas', 'Fritz', 'Anton', 'Dieter', 'Max', 'Stefan', 'Wolfgang'];
  static const List<String> driverLastNames = ['Mueller', 'Dupont', 'Rossi', 'Jansen', 'Lindberg', 'Kowalski', 'Berg', 'Weber', 'Schmidt', 'Fischer', 'Hoffman', 'Klein', 'Braun', 'Zimmermann', 'Wagner'];

  static String truckAssetPath(String type) => 'assets/trucks/$type.png';

  static TruckTypeInfo? findTruckType(String type) {
    for (final t in truckTypes) {
      if (t.type == type) return t;
    }
    return null;
  }

  static String formatMoney(int amount) {
    final sign = amount < 0 ? '-' : '';
    final abs = amount.abs();
    if (abs >= 1000000) return '$sign\u20AC${(abs / 1000000).toStringAsFixed(1)}M';
    if (abs >= 1000) return '$sign\u20AC${(abs / 1000).toStringAsFixed(0)}K';
    return '$sign\u20AC$abs';
  }
}

class TruckTypeInfo {
  final String type;
  final String name;
  final int price;
  final int speed;
  final double fuel;
  final int capacity;
  final String icon;

  const TruckTypeInfo({required this.type, required this.name, required this.price, required this.speed, required this.fuel, required this.capacity, required this.icon});
}

class LevelUnlock {
  final int level;
  final String description;

  const LevelUnlock({required this.level, required this.description});
}
