class GameConstants {
  GameConstants._();

  static const int startingMoney = 1000000;
  static const int depotFeePerCity = 500;
  static const int driverBaseSalary = 300;
  static const int driverHireCostMultiplier = 30; // 30 days salary upfront
  static const int fuelCostPer100km = 200;
  static const int repairCostPerPoint = 500;
  static const int conditionLossPerTrip = 3;
  static const int loadingDurationSeconds = 30;
  static const int contractRefreshSeconds = 5;
  static const int contractGenerationMinutes = 5;

  static const List<TruckTypeInfo> truckTypes = [
    TruckTypeInfo(type: 'light', name: 'Mercedes Actros L', price: 80000, speed: 85, fuel: 120, capacity: 12, icon: '🚛'),
    TruckTypeInfo(type: 'medium', name: 'Volvo FH16', price: 150000, speed: 80, fuel: 200, capacity: 22, icon: '🚛'),
    TruckTypeInfo(type: 'heavy', name: 'Scania R730', price: 250000, speed: 75, fuel: 300, capacity: 30, icon: '🚛'),
    TruckTypeInfo(type: 'special', name: 'MAN TGX 41.680', price: 400000, speed: 70, fuel: 400, capacity: 44, icon: '🚛'),
  ];

  static const List<String> cargoTypes = ['FMCG', 'Machinery', 'Food', 'Electronics', 'Building Materials', 'Chemicals'];

  static const List<String> driverFirstNames = ['Hans', 'Pierre', 'Marco', 'Jan', 'Erik', 'Sven', 'Klaus', 'Olivier', 'Lukas', 'Fritz', 'Anton', 'Dieter', 'Max', 'Stefan', 'Wolfgang'];
  static const List<String> driverLastNames = ['Mueller', 'Dupont', 'Rossi', 'Jansen', 'Lindberg', 'Kowalski', 'Berg', 'Weber', 'Schmidt', 'Fischer', 'Hoffman', 'Klein', 'Braun', 'Zimmermann', 'Wagner'];

  static TruckTypeInfo? findTruckType(String type) {
    for (final t in truckTypes) {
      if (t.type == type) return t;
    }
    return null;
  }

  static String formatMoney(int amount) {
    if (amount >= 1000000) return '\u20AC${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '\u20AC${(amount / 1000).toStringAsFixed(0)}K';
    return '\u20AC$amount';
  }
}

class TruckTypeInfo {
  final String type;
  final String name;
  final int price;
  final int speed; // km/h
  final double fuel; // liters
  final int capacity; // tons
  final String icon;

  const TruckTypeInfo({required this.type, required this.name, required this.price, required this.speed, required this.fuel, required this.capacity, required this.icon});
}
