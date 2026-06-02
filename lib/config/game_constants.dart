class ShipTypeDefinition {
  final String id;
  final String name;
  final String type;
  final int dwt;
  final int teu;
  final double speed;
  final double fuelPerNm;
  final int basePrice;
  final int maxAge;
  final int crewSize;

  const ShipTypeDefinition({
    required this.id,
    required this.name,
    required this.type,
    required this.dwt,
    required this.teu,
    required this.speed,
    required this.fuelPerNm,
    required this.basePrice,
    required this.maxAge,
    required this.crewSize,
  });
}

class PortDefinition {
  final String id;
  final String name;
  final String country;
  final String region;
  final double latitude;
  final double longitude;
  final bool hasFuel;
  final bool hasDock;
  final double taxRate;

  const PortDefinition({
    required this.id,
    required this.name,
    required this.country,
    required this.region,
    required this.latitude,
    required this.longitude,
    required this.hasFuel,
    required this.hasDock,
    required this.taxRate,
  });
}

class GoodDefinition {
  final String id;
  final String name;
  final String category;
  final String unit;
  final int basePrice;

  const GoodDefinition({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.basePrice,
  });
}

class GameConstants {
  // ---- Starting balance ----
  static const int startingMoney = 500000;
  static const int startingReputation = 50;
  static const int startingLevel = 1;
  static const int startingXp = 0;

  // ---- XP thresholds ----
  static const int xpPerLevel = 1000;

  // ---- Financial ----
  static const double maxLoanInterest = 0.15; // 15% годовых
  static const int minLoanAmount = 50000;
  static const int maxLoanAmount = 5000000;
  static const List<int> loanTerms = [6, 12, 24, 36]; // месяцы
  static const double taxRateBase = 0.05;

  // ---- Fuel ----
  static const double fuelPricePerLiter = 1.2; // \$
  static const double fuelTankMultiplier = 0.8; // 80% от dwt = макс. топлива

  // ---- Ships degrade ----
  static const double conditionLossPerVoyage = 2.0; // % за рейс
  static const double repairCostPerPoint = 500; // \$ за 1% восстановления
  static const double maxShipAgeYears = 30;

  // ---- Voyage ----
  static const double fuelConsumptionMultiplier = 1.0;
  static const int maxCargoPerShip = 100;

  // ---- Crew ----
  static const int baseCaptainSalary = 8000;
  static const int baseEngineerSalary = 6000;
  static const int baseSailorSalary = 3000;
  static const int baseBrokerSalary = 5000;

  // ---- Market ----
  static const double marketFee = 0.05; // 5% комиссия
  static const int marketListingDurationDays = 7;

  // ---- Prices fluctuation ----
  static const double priceFluctuationMin = -0.20;
  static const double priceFluctuationMax = 0.20;

  // ---- Reputation ----
  static const int repGainOnTimeDelivery = 3;
  static const int repLossOnLateDelivery = 5;
  static const int repGainOnLoanRepay = 2;
  static const int repLossOnLoanDefault = 10;

  // ---- Production ----
  static const int factoryBaseBuildCost = 200000;
  static const int factoryUpgradeCost = 100000;

  // ---- Ship types ----
  static const List<ShipTypeDefinition> shipTypes = [
    ShipTypeDefinition(
      id: 'sloop',
      name: 'Шлюп',
      type: 'Малый',
      dwt: 500,
      teu: 20,
      speed: 12.0,
      fuelPerNm: 15.0,
      basePrice: 150000,
      maxAge: 20,
      crewSize: 5,
    ),
    ShipTypeDefinition(
      id: 'barge',
      name: 'Баржа',
      type: 'Малый',
      dwt: 1500,
      teu: 60,
      speed: 8.0,
      fuelPerNm: 25.0,
      basePrice: 250000,
      maxAge: 25,
      crewSize: 8,
    ),
    ShipTypeDefinition(
      id: 'coaster',
      name: 'Костер',
      type: 'Средний',
      dwt: 3000,
      teu: 150,
      speed: 14.0,
      fuelPerNm: 40.0,
      basePrice: 450000,
      maxAge: 25,
      crewSize: 12,
    ),
    ShipTypeDefinition(
      id: 'handysize',
      name: 'Хэндисайз',
      type: 'Средний',
      dwt: 10000,
      teu: 500,
      speed: 14.0,
      fuelPerNm: 80.0,
      basePrice: 900000,
      maxAge: 25,
      crewSize: 18,
    ),
    ShipTypeDefinition(
      id: 'handymax',
      name: 'Хэндимакс',
      type: 'Средний',
      dwt: 35000,
      teu: 1500,
      speed: 15.0,
      fuelPerNm: 120.0,
      basePrice: 1800000,
      maxAge: 28,
      crewSize: 22,
    ),
    ShipTypeDefinition(
      id: 'supramax',
      name: 'Супрамакс',
      type: 'Большой',
      dwt: 55000,
      teu: 2500,
      speed: 15.5,
      fuelPerNm: 160.0,
      basePrice: 2800000,
      maxAge: 28,
      crewSize: 25,
    ),
    ShipTypeDefinition(
      id: 'panamax',
      name: 'Панамакс',
      type: 'Большой',
      dwt: 80000,
      teu: 4000,
      speed: 16.0,
      fuelPerNm: 200.0,
      basePrice: 3800000,
      maxAge: 30,
      crewSize: 28,
    ),
    ShipTypeDefinition(
      id: 'vlcc',
      name: 'ВЛКК',
      type: 'Сверхбольшой',
      dwt: 300000,
      teu: 0,
      speed: 15.0,
      fuelPerNm: 350.0,
      basePrice: 8000000,
      maxAge: 30,
      crewSize: 35,
    ),
  ];

  // ---- Ports ----
  static const List<PortDefinition> ports = [
    PortDefinition(
      id: 'rotterdam',
      name: 'Роттердам',
      country: 'Нидерланды',
      region: 'Европа',
      latitude: 51.9244,
      longitude: 4.4777,
      hasFuel: true,
      hasDock: true,
      taxRate: 0.08,
    ),
    PortDefinition(
      id: 'hamburg',
      name: 'Гамбург',
      country: 'Германия',
      region: 'Европа',
      latitude: 53.5511,
      longitude: 9.9937,
      hasFuel: true,
      hasDock: true,
      taxRate: 0.07,
    ),
    PortDefinition(
      id: 'antwerp',
      name: 'Антверпен',
      country: 'Бельгия',
      region: 'Европа',
      latitude: 51.2194,
      longitude: 4.4025,
      hasFuel: true,
      hasDock: true,
      taxRate: 0.06,
    ),
    PortDefinition(
      id: 'marsaxlokk',
      name: 'Марсашлокк',
      country: 'Мальта',
      region: 'Средиземноморье',
      latitude: 35.8375,
      longitude: 14.5378,
      hasFuel: true,
      hasDock: false,
      taxRate: 0.04,
    ),
    PortDefinition(
      id: 'piraeus',
      name: 'Пирей',
      country: 'Греция',
      region: 'Средиземноморье',
      latitude: 37.9424,
      longitude: 23.6465,
      hasFuel: true,
      hasDock: true,
      taxRate: 0.05,
    ),
    PortDefinition(
      id: 'istanbul',
      name: 'Стамбул',
      country: 'Турция',
      region: 'Средиземноморье',
      latitude: 41.0082,
      longitude: 28.9784,
      hasFuel: true,
      hasDock: true,
      taxRate: 0.06,
    ),
    PortDefinition(
      id: 'dubai',
      name: 'Дубай',
      country: 'ОАЭ',
      region: 'Ближний Восток',
      latitude: 25.2048,
      longitude: 55.2708,
      hasFuel: true,
      hasDock: true,
      taxRate: 0.03,
    ),
    PortDefinition(
      id: 'jebel_ali',
      name: 'Джебель-Али',
      country: 'ОАЭ',
      region: 'Ближний Восток',
      latitude: 24.9934,
      longitude: 55.0532,
      hasFuel: true,
      hasDock: true,
      taxRate: 0.03,
    ),
    PortDefinition(
      id: 'singapore',
      name: 'Сингапур',
      country: 'Сингапур',
      region: 'Азия',
      latitude: 1.3521,
      longitude: 103.8198,
      hasFuel: true,
      hasDock: true,
      taxRate: 0.05,
    ),
    PortDefinition(
      id: 'shanghai',
      name: 'Шанхай',
      country: 'Китай',
      region: 'Азия',
      latitude: 31.2304,
      longitude: 121.4737,
      hasFuel: true,
      hasDock: true,
      taxRate: 0.07,
    ),
    PortDefinition(
      id: 'busan',
      name: 'Пусан',
      country: 'Южная Корея',
      region: 'Азия',
      latitude: 35.1796,
      longitude: 129.0756,
      hasFuel: true,
      hasDock: true,
      taxRate: 0.06,
    ),
    PortDefinition(
      id: 'tokyo',
      name: 'Токио',
      country: 'Япония',
      region: 'Азия',
      latitude: 35.6762,
      longitude: 139.6503,
      hasFuel: true,
      hasDock: true,
      taxRate: 0.08,
    ),
    PortDefinition(
      id: 'hong_kong',
      name: 'Гонконг',
      country: 'Китай',
      region: 'Азия',
      latitude: 22.3193,
      longitude: 114.1694,
      hasFuel: true,
      hasDock: true,
      taxRate: 0.06,
    ),
    PortDefinition(
      id: 'mumbai',
      name: 'Мумбаи',
      country: 'Индия',
      region: 'Азия',
      latitude: 19.0760,
      longitude: 72.8777,
      hasFuel: true,
      hasDock: true,
      taxRate: 0.05,
    ),
    PortDefinition(
      id: 'long_beach',
      name: 'Лонг-Бич',
      country: 'США',
      region: 'Северная Америка',
      latitude: 33.7701,
      longitude: -118.1937,
      hasFuel: true,
      hasDock: true,
      taxRate: 0.08,
    ),
    PortDefinition(
      id: 'los_angeles',
      name: 'Лос-Анджелес',
      country: 'США',
      region: 'Северная Америка',
      latitude: 33.9425,
      longitude: -118.4081,
      hasFuel: true,
      hasDock: true,
      taxRate: 0.08,
    ),
    PortDefinition(
      id: 'new_york',
      name: 'Нью-Йорк',
      country: 'США',
      region: 'Северная Америка',
      latitude: 40.7128,
      longitude: -74.0060,
      hasFuel: true,
      hasDock: true,
      taxRate: 0.09,
    ),
    PortDefinition(
      id: 'houston',
      name: 'Хьюстон',
      country: 'США',
      region: 'Северная Америка',
      latitude: 29.7604,
      longitude: -95.3698,
      hasFuel: true,
      hasDock: true,
      taxRate: 0.07,
    ),
    PortDefinition(
      id: 'santos',
      name: 'Сантус',
      country: 'Бразилия',
      region: 'Южная Америка',
      latitude: -23.9608,
      longitude: -46.3336,
      hasFuel: true,
      hasDock: false,
      taxRate: 0.06,
    ),
    PortDefinition(
      id: 'buenos_aires',
      name: 'Буэнос-Айрес',
      country: 'Аргентина',
      region: 'Южная Америка',
      latitude: -34.6037,
      longitude: -58.3816,
      hasFuel: true,
      hasDock: true,
      taxRate: 0.07,
    ),
    PortDefinition(
      id: 'capetown',
      name: 'Кейптаун',
      country: 'ЮАР',
      region: 'Африка',
      latitude: -33.9249,
      longitude: 18.4241,
      hasFuel: true,
      hasDock: false,
      taxRate: 0.05,
    ),
    PortDefinition(
      id: 'lagos',
      name: 'Лагос',
      country: 'Нигерия',
      region: 'Африка',
      latitude: 6.5244,
      longitude: 3.3792,
      hasFuel: true,
      hasDock: false,
      taxRate: 0.04,
    ),
    PortDefinition(
      id: 'djibouti',
      name: 'Джибути',
      country: 'Джибути',
      region: 'Африка',
      latitude: 11.5880,
      longitude: 43.1456,
      hasFuel: true,
      hasDock: false,
      taxRate: 0.03,
    ),
    PortDefinition(
      id: 'vladivostok',
      name: 'Владивосток',
      country: 'Россия',
      region: 'Азия',
      latitude: 43.1155,
      longitude: 131.8855,
      hasFuel: true,
      hasDock: true,
      taxRate: 0.06,
    ),
    PortDefinition(
      id: 'st_petersburg',
      name: 'Санкт-Петербург',
      country: 'Россия',
      region: 'Европа',
      latitude: 59.9343,
      longitude: 30.3351,
      hasFuel: true,
      hasDock: true,
      taxRate: 0.07,
    ),
    PortDefinition(
      id: 'novorossiysk',
      name: 'Новороссийск',
      country: 'Россия',
      region: 'Европа',
      latitude: 44.7234,
      longitude: 37.7706,
      hasFuel: true,
      hasDock: true,
      taxRate: 0.05,
    ),
    PortDefinition(
      id: 'sydney',
      name: 'Сидней',
      country: 'Австралия',
      region: 'Океания',
      latitude: -33.8688,
      longitude: 151.2093,
      hasFuel: true,
      hasDock: true,
      taxRate: 0.07,
    ),
    PortDefinition(
      id: 'melbourne',
      name: 'Мельбурн',
      country: 'Австралия',
      region: 'Океания',
      latitude: -37.8136,
      longitude: 144.9631,
      hasFuel: true,
      hasDock: true,
      taxRate: 0.07,
    ),
  ];

  // ---- Goods ----
  static const List<GoodDefinition> goods = [
    GoodDefinition(
      id: 'crude_oil',
      name: 'Сырая нефть',
      category: 'Энергоресурсы',
      unit: 'баррель',
      basePrice: 80,
    ),
    GoodDefinition(
      id: 'refined_fuel',
      name: 'Рефинированное топливо',
      category: 'Энергоресурсы',
      unit: 'баррель',
      basePrice: 95,
    ),
    GoodDefinition(
      id: 'coal',
      name: 'Уголь',
      category: 'Энергоресурсы',
      unit: 'тонна',
      basePrice: 120,
    ),
    GoodDefinition(
      id: 'lng',
      name: 'СПГ',
      category: 'Энергоресурсы',
      unit: 'тонна',
      basePrice: 450,
    ),
    GoodDefinition(
      id: 'iron_ore',
      name: 'Железная руда',
      category: 'Сырьё',
      unit: 'тонна',
      basePrice: 100,
    ),
    GoodDefinition(
      id: 'steel',
      name: 'Сталь',
      category: 'Сырьё',
      unit: 'тонна',
      basePrice: 600,
    ),
    GoodDefinition(
      id: 'copper',
      name: 'Медь',
      category: 'Сырьё',
      unit: 'тонна',
      basePrice: 8500,
    ),
    GoodDefinition(
      id: 'aluminum',
      name: 'Алюминий',
      category: 'Сырьё',
      unit: 'тонна',
      basePrice: 2200,
    ),
    GoodDefinition(
      id: 'grain',
      name: 'Зерно',
      category: 'Сельхоз',
      unit: 'тонна',
      basePrice: 250,
    ),
    GoodDefinition(
      id: 'rice',
      name: 'Рис',
      category: 'Сельхоз',
      unit: 'тонна',
      basePrice: 350,
    ),
    GoodDefinition(
      id: 'coffee',
      name: 'Кофе',
      category: 'Сельхоз',
      unit: 'тонна',
      basePrice: 3000,
    ),
    GoodDefinition(
      id: 'sugar',
      name: 'Сахар',
      category: 'Сельхоз',
      unit: 'тонна',
      basePrice: 400,
    ),
    GoodDefinition(
      id: 'cars',
      name: 'Автомобили',
      category: 'Промышленность',
      unit: 'штука',
      basePrice: 25000,
    ),
    GoodDefinition(
      id: 'electronics',
      name: 'Электроника',
      category: 'Промышленность',
      unit: 'контейнер',
      basePrice: 50000,
    ),
    GoodDefinition(
      id: 'machinery',
      name: 'Машины',
      category: 'Промышленность',
      unit: 'тонна',
      basePrice: 8000,
    ),
    GoodDefinition(
      id: 'textiles',
      name: 'Текстиль',
      category: 'Промышленность',
      unit: 'контейнер',
      basePrice: 15000,
    ),
    GoodDefinition(
      id: 'fertilizer',
      name: 'Удобрения',
      category: 'Химия',
      unit: 'тонна',
      basePrice: 350,
    ),
    GoodDefinition(
      id: 'chemicals',
      name: 'Химикаты',
      category: 'Химия',
      unit: 'тонна',
      basePrice: 1200,
    ),
    GoodDefinition(
      id: 'containers_general',
      name: 'Генеральные грузы',
      category: 'Прочее',
      unit: 'контейнер',
      basePrice: 3000,
    ),
    GoodDefinition(
      id: 'lumber',
      name: 'Лесоматериалы',
      category: 'Прочее',
      unit: 'тонна',
      basePrice: 200,
    ),
  ];

  // ---- Helper: find ship type by id ----
  static ShipTypeDefinition? findShipType(String id) {
    for (final st in shipTypes) {
      if (st.id == id) return st;
    }
    return null;
  }

  // ---- Helper: find port by id ----
  static PortDefinition? findPort(String id) {
    for (final p in ports) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ---- Helper: find good by id ----
  static GoodDefinition? findGood(String id) {
    for (final g in goods) {
      if (g.id == id) return g;
    }
    return null;
  }

  // ---- Helper: all unique regions ----
  static List<String> get allRegions {
    final regions = <String>{};
    for (final p in ports) {
      regions.add(p.region);
    }
    return regions.toList()..sort();
  }

  // ---- Helper: all unique good categories ----
  static List<String> get allGoodCategories {
    final cats = <String>{};
    for (final g in goods) {
      cats.add(g.category);
    }
    return cats.toList()..sort();
  }
}
