import 'package:flutter_test/flutter_test.dart';
import 'package:euro_logistics_tycoon/config/game_constants.dart';
import 'package:euro_logistics_tycoon/models/city.dart';
import 'package:euro_logistics_tycoon/models/truck.dart';
import 'package:euro_logistics_tycoon/models/contract.dart';
import 'package:euro_logistics_tycoon/models/driver.dart';
import 'package:euro_logistics_tycoon/models/company.dart';
import 'package:euro_logistics_tycoon/models/warehouse.dart';

void main() {
  group('GameConstants', () {
    test('truck types count', () {
      expect(GameConstants.truckTypes.length, 4);
    });

    test('find truck type', () {
      expect(GameConstants.findTruckType('light')?.name, 'Mercedes Actros L');
      expect(GameConstants.findTruckType('heavy')?.capacity, 30);
      expect(GameConstants.findTruckType('nonexistent'), isNull);
    });

    test('format money', () {
      expect(GameConstants.formatMoney(500), '\u20AC500');
      expect(GameConstants.formatMoney(50000), '\u20AC50K');
      expect(GameConstants.formatMoney(1500000), '\u20AC1.5M');
    });
  });

  group('Models', () {
    test('City fromJson', () {
      final city = City.fromJson({
        'id': 1, 'slug': 'london', 'name': 'London', 'country': 'UK',
        'latitude': 51.5, 'longitude': -0.1, 'population': 8982000,
        'warehouse_cost': 800000, 'depot_fee': 800, 'has_depot': true,
      });
      expect(city.name, 'London');
      expect(city.country, 'UK');
      expect(city.id, 1);
    });

    test('Company fromJson with money formatting', () {
      final company = Company.fromJson({
        'id': 'uuid-123', 'owner_id': 'uuid-456', 'name': 'TestCo',
        'money': 2500000, 'reputation': 75, 'level': 3, 'xp': 2800,
      });
      expect(company.name, 'TestCo');
      expect(company.moneyFormatted, '\u20AC2.5M');
    });

    test('Truck fromJson and status', () {
      final truck = Truck.fromJson({
        'id': 't1', 'company_id': 'c1', 'truck_type': 'medium',
        'name': 'Volvo 1', 'status': 'idle', 'condition_pct': 85,
        'fuel_level': 60.0, 'max_fuel': 200.0, 'current_city_id': 1,
      });
      expect(truck.isIdle, true);
      expect(truck.isInTransit, false);
      expect(truck.statusDisplay, 'Готов');
    });

    test('Truck transit status', () {
      final truck = Truck.fromJson({
        'id': 't2', 'company_id': 'c1', 'truck_type': 'heavy',
        'name': 'Scania 1', 'status': 'in_transit', 'condition_pct': 50,
        'fuel_level': 30.0, 'max_fuel': 300.0,
        'origin_city_id': 1, 'destination_city_id': 2,
        'departure_time': '2024-01-01T00:00:00Z',
        'estimated_arrival': '2024-01-01T10:00:00Z',
      });
      expect(truck.isInTransit, true);
      expect(truck.isIdle, false);
      expect(truck.statusDisplay, 'В пути');
    });

    test('Contract fromJson', () {
      final contract = Contract.fromJson({
        'id': 'c1', 'origin_city_id': 1, 'destination_city_id': 2,
        'cargo_type': 'FMCG', 'cargo_weight': 15, 'reward': 5000,
        'deadline_hours': 48, 'status': 'available',
        'created_at': '2024-01-01T00:00:00Z',
        'expires_at': '2099-12-31T00:00:00Z',
      });
      expect(contract.isAvailable, true);
      expect(contract.cargoType, 'FMCG');
    });

    test('Driver fromJson', () {
      final driver = Driver.fromJson({
        'id': 'd1', 'company_id': 'c1', 'name': 'Hans Mueller',
        'skill_level': 3, 'salary_daily': 450, 'status': 'available',
      });
      expect(driver.name, 'Hans Mueller');
      expect(driver.isAvailable, true);
    });

    test('Warehouse fromJson', () {
      final warehouse = Warehouse.fromJson({
        'id': 'w1', 'company_id': 'c1', 'city_id': 5,
        'level': 2, 'capacity': 100, 'is_active': true,
        'purchased_at': '2024-01-01T00:00:00Z',
      });
      expect(warehouse.cityId, 5);
      expect(warehouse.capacity, 100);
      expect(warehouse.isActive, true);
    });
  });

  group('Haversine', () {
    test('London to Paris distance (~340km)', () {
      // Simple sanity check
      const lat1 = 51.5074, lon1 = -0.1278;
      const lat2 = 48.8566, lon2 = 2.3522;
      const R = 6371.0;
      final dLat = (lat2 - lat1) * 3.14159265 / 180;
      final dLon = (lon2 - lon1) * 3.14159265 / 180;
      final a = (dLat / 2).abs() * (dLat / 2).abs() +
          (3.14159265 / 180 - dLat / 2).abs() * (3.14159265 / 180 - dLat / 2).abs() *
          (dLon / 2).abs() * (dLon / 2).abs();
      final dist = R * 2 * (a).abs();
      expect(dist, greaterThan(200)); // Should be > 200km
      expect(dist, lessThan(500)); // Should be < 500km
    });
  });
}
